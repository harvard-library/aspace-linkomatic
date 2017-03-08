class LinkomaticController < ApplicationController
 
  #require 'urn_fetcher'
  #skip_before_filter :unauthorised_access
  set_access_control "view_repository" => [:fetch_digital_objects, :view_job]
  
  
    
  def fetch_digital_objects
    if user_can?('update_digital_object_record') && user_can?('view_repository') && user_can?('cancel_importer_job') && user_can?('import_records')
        
      job_data = {"repo_id" => session[:repo_id].to_s,
                  "owner_code" => params[:other].upcase,
                  "resource_id" => params[:resource_id],
                  "source" => "/repositories/" + session[:repo_id].to_s + "/resources/" + params[:resource_id]}
        
      fetch_job = JSONModel(:fetch_urn_job).from_hash(job_data)
        
      job = Job.new("fetch_urn_job", fetch_job, [])
      
      jobresponse = job.upload
      
      jobresponsearray = jobresponse[:uri].split("/")
      job_uri = "/" + jobresponsearray[-2] + "/" + jobresponsearray[-1]
      response = {:success => {:uri => job_uri}}
      
      render :json => response.to_json
    else
      Rails.logger.error("You do not have sufficient permissions to perform this task. Please contact your ASpace administrator.")
      response = {error: 'You do not have sufficient permissions to perform this task. Please contact your ASpace administrator.'}
      render :json => response.to_json
    end
    
  end
  
  def view_job
    redirect_to(params[:uri])
  end
  
  

end

