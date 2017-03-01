# coding: utf-8
# This background worker, given a component ID and an OwnerCode(authpath),
#   fetches an Oracle ID, then uses that Oracle ID to fetch a URN for that component
require 'jsonmodel' 
 
class URNFetcher
  
  require 'net/http'
  require 'json'
  require 'thread'
  
  ##################################################
  # Url parts and helpers                          #
  ##################################################

  NRS_SERVER = "#{ENV.fetch('NRS_URL', 'http://nrstest.harvard.edu:9031/')}"
  OLIVIA = URI("#{ENV.fetch('OLIVIA_URL', 'http://oliviatest.lib.harvard.edu:9016')}/olivia/servlet/OliviaServlet")
  OID_Q_BASE = {storedProcedure: "getOracleID",
                callingApplication: "OASIS"}
  OID_Q_OPTS = {quality: "NA",
                role: "NA",
                purpose: "NA"}

                
  

  # Finds all archival objects for the resource and adds a digital object if one is available
  def perform(resource_id, owner_code, repo_id)
    
    @owner_code = owner_code
    @repo_id = repo_id
    
    resourcetree = URIResolver.resolve_references(Resource.to_jsonmodel(resource_id.to_i), ['tree'])
   
    thread_array = []
      
    archival_object_searched = 0
    digital_objects_created = 0
       
    work_q = Queue.new   

    prepare_tree_nodes(resourcetree['tree']["_resolved"]) do |child|
      Log.info(child.inspect)
      if child['node_type'] == 'archival_object'
          Log.info('ARCHIVAL OBJECT FOUND: '+child['title'])
          archival_id = child['id']
          #If a digital object does not already exist for the archival object, create one
          if !child['instance_types'].include?('digital_object')
            Log.info("Adding " + archival_id.to_s + " to queue")
            work_q << archival_id
            archival_object_searched = archival_object_searched + 1
          end
          
      end
    end
    
    responses = []
    osn_errors = []
    no_osn = []
    mutex = Mutex.new
      
    workers = (0...4).map do
      thread = Thread.new do
        begin
          while archival_id = work_q.pop(true)
            Log.info("Poppped " + archival_id.to_s + " from queue")
            RequestContext.open(:repo_id => repo_id) do                          
              archival_object = ArchivalObject.to_jsonmodel(archival_id.to_i)
              
              Log.info('ARCHIVAL OBJECT RETRIEVED: '+archival_object.to_json)
              #create digital object
              t = create_digital_object(archival_object)
              mutex.synchronize do
                if (t.has_key?('error'))
                  Log.error(t['error'])
                  osn_errors << t['osn']
                elsif (t.has_key?('urn_created'))
                  Log.info('URN created for' + t['osn'])
                  digital_objects_created = digital_objects_created + 1
                elsif (t.has_key?('no_urn'))
                  Log.info('No URN found for' + t['osn'])
                  no_osn << t['osn']
                end
              end
            end
          end
        rescue ThreadError
        end
      end
      thread_array << thread
      thread.join
    end
        
    response = {:resource_id => resource_id, :osn_errors=>osn_errors, :no_osns=>no_osn, :archival_objects_searched => archival_object_searched, :digital_objects_created => digital_objects_created}
  end

  
private

  def prepare_tree_nodes(node, &block)
    if (!node['children'].nil?)
      node['children'].map{|child_node| prepare_tree_nodes(child_node, &block) }
      block.call(node)
    end
  end
  
  #Creates a digital object and link it to the archival object
  def create_digital_object(archival_object) 
    osn = archival_object.ref_id
    
    begin
      actionable_urn = fetch_urn(osn) 
    rescue Exception => e
      return {'error' => e.message, 'osn' => osn}
    end
    begin
      actionable_thumbnail_urn = fetch_thumbnail_urn(osn)
    rescue Exception => e
      return {'error' => e.message, 'osn' => osn}
    end
    if (!actionable_thumbnail_urn.nil? && !actionable_thumbnail_urn.empty?)
      actionable_thumbnail_urn = NRS_SERVER + actionable_thumbnail_urn
    end
   
    # Tell all the clients a job has finished
    if (!actionable_urn.nil? && !actionable_urn.empty?)
      actionable_urn = NRS_SERVER + actionable_urn
      
      #create the digital object
      do_json_response = call_digital_object_api(archival_object, actionable_urn, actionable_thumbnail_urn)
      if (!do_json_response.is_a? Numeric)
        return {'error' => do_json_response['error'], 'osn' => osn}
      end
      
      #link the digital object to the archival object
      ao_json_response = link_ao_do(archival_object, do_json_response)       
      if (!ao_json_response.is_a? Numeric)
        #Remove the newly created DO if this fails
        digitalobject = DigitalObject.to_jsonmodel(do_json_response.to_i)
        #TODO This isn't working - fixme
        raise Sequel::Rollback
        return {'error' => ao_json_response['error'], 'osn' => osn}
      end
    else
      return {'no_urn' => "No URNs were found for #{@owner_code} : #{osn}", 'osn' => osn}
    end
    return {'urn_created' => 'Success', 'osn' => osn}
  end
  
  #Link the digital object ot the archival object using the AS API
  def link_ao_do(archival_object, do_id)
    digitalobject = DigitalObject.get_or_die(do_id.to_i)
    
    #Create the DO Instance from the response data
    digital_object_instance = {
      "lock_version" => digitalobject.lock_version,
      "instance_type" => "digital_object",
      "jsonmodel_type" => "instance",
      "digital_object"=> {"ref" => digitalobject.uri}
    }
    #Add the digital object instance to the archival object
    
    archival_object.instances ||= []
    archival_object.instances << digital_object_instance
    
    #Update archival object with DO link
    ao_response = nil
    begin
      ao_object = ArchivalObject.get_or_die(archival_object.id)
    qao = ao_object.update_from_json(archival_object)
      ao_response = ao.id
      Log.info("UPDATE AO RESPONSE: " + ao_response.to_s)
    rescue Exception => e
      Log.info("UPDATE AO RESPONSE: " + e.message)
      ao_response = {'error' => e.message}
    end
    
    ao_response
  end
  
  #Create the digital object using the AS API
  def call_digital_object_api(archival_object, actionable_urn, actionable_thumbnail_urn)
    osn = archival_object.ref_id
    digial_object_title = archival_object.display_string
    
    digital_object_data = {
          :jsonmodel_type  => 'digital_object',
          :title => digial_object_title,
          :digital_object_id => osn + 'd',
          :publish => true,
          :restrictions => false,
          :file_versions => [{
            :file_uri => actionable_urn,
            :publish => true,
            :xlink_actuate_attribute => 'onRequest',
            :xlink_show_attribute => 'new'
          }]
      }
      
      if (actionable_thumbnail_urn) 
        digital_object_data[:file_versions] << { 
            :file_uri => actionable_thumbnail_urn,
            :publish => true,
            :xlink_actuate_attribute => 'onLoad',
            :xlink_show_attribute => 'embed',
            :is_representative => true
        }
      end
      
      digobj = JSONModel::JSONModel("digital_object".intern).from_hash(digital_object_data, true, true)
      do_response = nil
      begin
        digitalobject = DigitalObject.create_from_json(digobj)
        do_response = digitalobject.id
        Log.info("CREATE DO RESPONSE: " + do_response.to_s)
      rescue Exception => e
        Log.error("CREATE DO RESPONSE: " + e.message)
        do_response = {'error' => e.message}
      end
      
      do_response       
  end
  
  #Fetch the URN for the archival object with the user-entered owner code
  #and the archival object's ref_id (the OSN)
  def fetch_urn(osn)
    Log.info "Fetching: #{@owner_code} : #{osn}'s OID"
    oid = nil
    urns = nil
    actionable_urn = nil
    if (oid = get_oid(osn, @owner_code))
      get_urns(oid).each{|urn| actionable_urn = urn }
    elsif not (urns = get_drs2_pds_urns(osn, @owner_code)).empty?
      urns.each{|urn|  actionable_urn = urn }
    elsif not (urns = get_drs2_pds_urns("#{osn}-METS", @owner_code)).empty?
      urns.each{|urn|  actionable_urn = urn }  
    elsif not (urns = get_drs2_pds_urns("#{osn}_METS", @owner_code)).empty?
      urns.each{|urn|  actionable_urn = urn }  
    elsif not (urns = get_drs2_pds_urns("#{osn}-mets", @owner_code)).empty?
      urns.each{|urn|  actionable_urn = urn }  
    elsif not (urns = get_drs2_pds_urns("#{osn}_mets", @owner_code)).empty?
      urns.each{|urn|  actionable_urn = urn }  
    end
    Log.info "Done trying to fetch  #{@owner_code} : #{osn}'s OID"
    actionable_urn
  end
  
  #Fetch the Thumbnail URN for the archival object with the user-entered owner code
  #and the archival object's ref_id (the OSN)
  def fetch_thumbnail_urn(osn)
    Log.info "Fetching thumb urn: #{@owner_code} : #{osn}'s OID"
    oid = nil
    urns = nil
    actionable_urn = nil
    if (oid = get_thumbnail_oid(osn, @owner_code))
      get_urns(oid).each{|urn| actionable_urn = urn }
    end
    Log.info "Done trying to fetch  #{@owner_code} : #{osn}'s OID"
    actionable_urn
  end

  
  # Helper method which returns {response, false}
  def try_request(component_id, authpath, opts = {})
    http = Net::HTTP.new(OLIVIA.host, OLIVIA.port)
    http.read_timeout = 120
    count = 0
    path = oid_path(component_id, authpath, opts)
    begin
      (res = http.request(Net::HTTP::Get.new(path))).code == "200" ? res : false
    rescue Errno::ECONNRESET => e
      count += 1
      retry unless count > 5
      Log.error("Attempted request 5 times and couldn't get #{path}: #{e}")
    end

  end

  ##################################################
  # OID and URN fetchers                           #
  ##################################################

  # Fetch OID. Returns OID or nil
  def get_oid(component_id, authpath)
    

    # The first two attempts represent current correct practice
    # DRS2 objects look like these, DRS1 SHOULD going forward
    oid_html = if res = try_request(component_id, authpath,    role: "DELIVERABLE", quality: "NA")
       res.body
     elsif res = try_request(component_id, authpath, role: "DELIVERABLE", quality: "5")
       res.body
     # The next three attempts represent common legacy practice in DRS1
     elsif res = try_request(component_id, authpath)
       res.body
     # A number of PDS records have malformed component IDs with a '_mets' suffix. ಠ_ಠ
     elsif res = try_request("#{component_id}_mets", authpath)
       res.body
     # A number of PDS records have malformed component IDs with a '-METS' suffix. ಠ_ಠ
     elsif res = try_request("#{component_id}-METS", authpath)
       res.body
     elsif res = try_request(component_id, authpath, quality: "5")
       res.body
     else
      Log.info "Failure: NO URN FOR C_ID: #{component_id} and ownerCode: #{authpath}"
        ""
    end

    oid_html.match(/(?<=Oracle ID: ).+?(?=<br>)/)
  rescue Timeout::Error
    Log.info "Timeout error in get_oid"
    nil
  end
  
  # Fetch OID. Returns OID or nil
  def get_thumbnail_oid(component_id, authpath)
    
    # The first two attempts represent current correct practice
    # DRS2 objects look like these, DRS1 SHOULD going forward
    oid_html = if res = try_request(component_id, authpath,    role: "THUMBNAIL", quality: "NA")
       res.body
     elsif res = try_request(component_id, authpath, role: "DELIVERABLE", quality: "1")
       res.body
     else
      Log.info "Failure: NO URN FOR C_ID: #{component_id} and ownerCode: #{authpath}"
        ""
    end

    oid_html.match(/(?<=Oracle ID: ).+?(?=<br>)/)
  rescue Timeout::Error
    Log.info "Timeout error in get_oid"
    nil
  end

  # Fetches URNs. Returns array of URNs (can be empty)
  def get_urns(oid)
    http = Net::HTTP.new(OLIVIA.host, OLIVIA.port)
    http.read_timeout = 120

    Log.info "Fetch URNs via OLIVIA for #{oid} at #{urns_path(oid)}"
    if (res = http.request(Net::HTTP::Get.new(urns_path(oid)))).code == "200"
      if (urns = res.body.match(/(?<=URN: ).+?(?=<br>)/))
        Log.info "URNs returned: #{urns}"
        urns.to_s.split(',')
      else
        []
      end
    else
      []
    end
  end

  # Fetches URNs for objects whose URNs point at PDS objects rather than files
  def get_drs2_pds_urns(component_id, authpath)
    http = Net::HTTP.new(OLIVIA.host, OLIVIA.port)
    http.read_timeout = 120

    Log.info "Fetch URNs from DRS2 for #{authpath}: #{component_id}"
    if (res = http.request(Net::HTTP::Get.new(urns2_path(component_id, authpath)))).code == "200"
      if (urns = res.body.match(/(?<=URN: ).+?(?=<br>)/))
        Log.info "URNs returned: #{urns}"
        urns.to_s.split(',')
      else
        []
      end
    else
      []
    end
  end
  
  def oid_path(component_id, authpath, opts = {})
    query = OID_Q_BASE.merge(OID_Q_OPTS).merge(ownerCode: "#{authpath}",
                                               localName: "#{component_id}").merge(opts)

    OLIVIA.request_uri + '?' + URI.encode_www_form(query)
  end

  def urns_path(oid)
    OLIVIA.request_uri + '?' + URI.encode("storedProcedure=getURN&oracleID=#{oid}")
  end

  # URN for component with URN pointing at PDS object
  def urns2_path(component_id, authpath)
    query = OID_Q_BASE.merge(storedProcedure: "getDrs2ObjectUrn",
                             ownerCode: "#{authpath}",
                             localName: "#{component_id}")

    OLIVIA.request_uri + '?' + URI.encode_www_form(query)
  end

  
  
end
