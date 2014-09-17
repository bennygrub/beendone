json.array!(@airports) do |airport|
  json.extract! airport, :id, :name, :city, :country, :faa, :icao, :latitude, :longitude, :altitude, :timezone, :dst
  json.url airport_url(airport, format: :json)
end
