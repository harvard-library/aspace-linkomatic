require 'db/migrations/utils'

Sequel.migration do

  up do
    enum = self[:enumeration].filter(:name => "job_type").select(:id)
    val = self[:enumeration_value].filter(:value => 'fetch_urn_job', :enumeration_id => enum ).select(:id).all
    count =  self[:enumeration_value].filter(:enumeration_id => enum).order( Sequel.desc(:position)).get(:position)
    if val.length == 0
      self[:enumeration_value].insert(:enumeration_id => enum,
        :value => 'fetch_urn_job',
        :position => count+1,
        :readonly => 0)
    end
  end

end
