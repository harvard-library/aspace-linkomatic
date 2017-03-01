enum = Enumeration.filter(:name => "job_type").get(:id)  

ev = EnumerationValue.filter( :enumeration_id => enum, :value => "fetch_urn_job").count

unless ev > 0 
  count = EnumerationValue.filter( :enumeration_id => enum ).count 
  EnumerationValue.insert( :enumeration_id => enum, :value => "fetch_urn_job",
   :position => count + 1, :readonly => 0 ) 
   Enumeration.broadcast_changes 
end