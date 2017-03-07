class FetchUrnsController < ApplicationController

  set_access_control "manage_repository" => [ :index, :create]
  
  def index
    @job = JSONModel(:fetch_urn_job).new._always_valid!
  end

  def create
    
    job_data = params['job'].reject{|k,v| k === '_resolved'} 
    job_data["repo_id"] ||= session[:repo_id] 
    job_data["owner_code"] = params["fetch_urn_job"]["owner_code"].upcase
    job_data["source"] = params["fetch_urn_job"]["ref"]
    refarray = params["fetch_urn_job"]["ref"].split("/")
    job_data["resource_id"] = refarray[-1]
Rails.logger.info(job_data)

    begin
    job = Job.new('fetch_urn_job', JSONModel(:fetch_urn_job).from_hash( job_data ) , []) 
    rescue JSONModel::ValidationException => e
      @exceptions = e.invalid_object._exceptions
      @job = e.invalid_object
      @job_types = ['fetch_urn_job']
      @job_type = params['job']['job_type']
      
      if params[:iframePOST] # IE saviour. Render the form in a textarea for the AjaxPost plugin to pick out.
        return render_aspace_partial :partial => "jobs/form_for_iframepost", :status => 400
      else
        return render_aspace_partial :partial => "jobs/form", :status => 400
      end
    end
      
    if params[:iframePOST] # IE saviour. Render the form in a textarea for the AjaxPost plugin to pick out.
      render :text => "<textarea data-type='json'>#{job.upload.to_json}</textarea>"
    else
      render :json => job.upload
    end

  end

end