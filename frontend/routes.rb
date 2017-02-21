ArchivesSpace::Application.routes.draw do
  match '/plugins/linkomatic/fetch_digital_objects' => 'linkomatic#fetch_digital_objects', :via => [:get]
  match '/plugins/linkomatic/in_fetch_session' => 'linkomatic#in_fetch_session', :via => [:get]
  match '/plugins/linkomatic/clear_fetch_session' => 'linkomatic#clear_fetch_session', :via => [:get]
  match '/plugins/linkomatic/digital_objects_fetched' => 'linkomatic#digital_objects_fetched', :via => [:get]
      
#  require 'sidekiq/web'
#    mount Sidekiq::Web => '/sidekiq'
#
#  Sidekiq.configure_server do |config|
#    config.redis = { :url => ENV['REDIS_URL'] || 'redis://localhost:6379/12', :namespace => 'linkomatic' }
#  end
#  
#  Sidekiq.configure_client do |config|
#    config.redis = { :url => ENV['REDIS_URL'] || 'redis://localhost:6379/12', :namespace => 'linkomatic' }
#  end
end
