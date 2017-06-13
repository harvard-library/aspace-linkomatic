ArchivesSpace::Application.routes.draw do
  match '/plugins/linkomatic/ownercode' => 'linkomatic#owner_code', :via => [:post]
  match '/plugins/linkomatic/fetch_digital_objects' => 'linkomatic#fetch_digital_objects', :via => [:get]
  match '/plugins/linkomatic/view_job' => 'linkomatic#view_job', :via => [:get]
  match('/plugins/fetch_urns' => 'fetch_urns#index', :via => [:get])
  match('/plugins/fetch_urns/create' => 'fetch_urns#create', :via => [:post])
      
end
