json.array!(@flight_fixes) do |flight_fix|
  json.extract! flight_fix, :id, :airline_mapping_id, :flight_id, :direction, :status, :trip_id
  json.url flight_fix_url(flight_fix, format: :json)
end
