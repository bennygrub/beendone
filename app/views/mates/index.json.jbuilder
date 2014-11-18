json.array!(@mates) do |mate|
  json.extract! mate, :id, :trip_id, :email, :name
  json.url mate_url(mate, format: :json)
end
