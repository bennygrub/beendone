json.array!(@places) do |place|
  json.extract! place, :id, :trip_id, :user_id, :location
  json.url place_url(place, format: :json)
end
