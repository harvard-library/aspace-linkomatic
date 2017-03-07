class LinkomaticController < ApplicationController
 
  #require 'urn_fetcher'
  #skip_before_filter :unauthorised_access
  set_access_control "view_repository" => [:fetch_digital_objects, :clear_fetch_session, :in_fetch_session, :digital_objects_fetched]
  
  
    
  def fetch_digital_objects
    if user_can?('update_digital_object_record') && user_can?('view_repository')
        
      job_data = {"repo_id" => session[:repo_id].to_s,
                  "owner_code" => params[:other].upcase,
                  "resource_id" => params[:resource_id],
                  "source" => "/repositories/" + session[:repo_id].to_s + "/resources/" + params[:resource_id]}
        
      fetch_job = JSONModel(:fetch_urn_job).from_hash(job_data)
        
      job = Job.new("fetch_urn_job", fetch_job, [])
      
      jobresponse = job.upload
      #TODO: Fix this
      response = {:success => jobresponse['id']}
      
      render :json => response.to_json
    else
      unauthorised_access
    end
    
  end

   
  #Determine if the resource is already looking for digital objects
  def in_fetch_session
    in_fetch = false
    if (session[:fetch_digital_object_resource_ids])
      resource_ids = session[:fetch_digital_object_resource_ids]
      in_fetch = resource_ids.include?(params[:resource_id])
    end
    render :json => {:response => in_fetch}.to_json
  end
  
  def digital_objects_fetched
    fetchprogress = session[:fetch_status]
    Rails.logger.info("Progress: " + fetchprogress.to_s)
    render :json => {:response => fetchprogress}.to_json
  end

private
  
  #Remove the resource id from the session when it is finished 
  def clear_fetch_session
    resource_ids = session[:fetch_digital_object_resource_ids]
    resource_ids.delete(params[:resource_id])
    session[:fetch_digital_object_resource_ids] = resource_ids
  end
  
  

end

