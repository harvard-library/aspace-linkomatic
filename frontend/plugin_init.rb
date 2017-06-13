require 'rubygems'

my_routes = File.join(File.dirname(__FILE__), "routes.rb")

# support extending routes for plugin in both V1 & V2
if ArchivesSpace::Application.respond_to?(:extend_aspace_routes)
  ArchivesSpace::Application.extend_aspace_routes(my_routes)
else
  ArchivesSpace::Application.config.paths['config/routes'].concat([my_routes])
end
  
Rails.application.config.after_initialize do 
    JSONModel(:fetch_urn_job) 
end
