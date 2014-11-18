json.array!(@highlights) do |highlight|
  json.extract! highlight, :id, :user_id, :trip_id, :category_id, :name, :description
  json.url highlight_url(highlight, format: :json)
end
