ArchivesSpace::Application.routes.draw do
  match '/plugins/linkomatic/fetch_digital_objects' => 'linkomatic#fetch_digital_objects', :via => [:get]
  match '/plugins/linkomatic/in_fetch_session' => 'linkomatic#in_fetch_session', :via => [:get]
  match '/plugins/linkomatic/clear_fetch_session' => 'linkomatic#clear_fetch_session', :via => [:get]
  match '/plugins/linkomatic/digital_objects_fetched' => 'linkomatic#digital_objects_fetched', :via => [:get]
  match('/plugins/fetch_urns' => 'fetch_urns#index', :via => [:get])
  match('/plugins/fetch_urns/create' => 'fetch_urns#create', :via => [:post])
      
end
