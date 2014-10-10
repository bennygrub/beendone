json.array!(@airport_mappings) do |airport_mapping|
  json.extract! airport_mapping, :id, :name, :city, :airport_id, :airline_id, :message_id, :note
  json.url airport_mapping_url(airport_mapping, format: :json)
end
