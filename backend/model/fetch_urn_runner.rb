require_relative 'urn_fetcher'
  
class FetchUrnRunner < JobRunner

  def self.instance_for(job)
    if job.job_type == "fetch_urn_job"
      self.new(job)
    else
      nil
    end
  end


  def run
    super
    begin
    job_data = @json.job

    owner_code = job_data['owner_code']
    resource_id = job_data['resource_id']
      
    DB.open( DB.supports_mvcc?,
       :retry_on_optimistic_locking_fail => true ) do
         
       begin
         
       RequestContext.open(:current_username => @job.owner.username,
          :repo_id => @job.repo_id) do   
            
            @job.write_output("Beginning fetch job")           
            response = URNFetcher.new.perform(resource_id, owner_code, @job.repo_id)

            @job.write_output("Number of Archival Objects searched: " + response[:archival_objects_searched].to_s)
            @job.write_output("Number of Digital Objects created: " + response[:digital_objects_created].to_s)
            if (!response[:osn_errors].empty?)
              #write it in a nice format
              prefix = "Errors occured in creating Digital Objects for: "
              osns_split = response[:osn_errors].each_slice(4).to_a
              osns_split.each do |small_osn_array|
                @job.write_output(prefix + small_osn_array.join(", "))
                  prefix = "        "
              end

            end
            if (!response[:no_osns].empty?)
              #write it in a nice format
              prefix = "No Digital Objects exist for: "
              no_osns_split = response[:no_osns].each_slice(4).to_a
              no_osns_split.each do |small_osn_array|
                @job.write_output(prefix + small_osn_array.join(", "))
                prefix = "        "
              end
            end                         
            self.success!
          end
       rescue Exception => e
           terminal_error = e
           Log.error(terminal_error.message)
           Log.error(terminal_error.backtrace)
           @job.write_output(terminal_error.message)
           @job.write_output(terminal_error.backtrace)
           raise Sequel::Rollback
         end
       end
     
     rescue
       terminal_error = $!
     end

    if terminal_error
      @job.write_output(terminal_error.message)
      @job.write_output(terminal_error.backtrace)
  
      raise terminal_error
    end

    end
end
  
