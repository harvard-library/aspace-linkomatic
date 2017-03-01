require 'rubygems'

my_routes = [File.join(File.dirname(__FILE__), "routes.rb")]
ArchivesSpace::Application.config.paths['config/routes'].concat(my_routes)
  
Rails.application.config.after_initialize do 
    JSONModel(:fetch_urn_job) 
end
