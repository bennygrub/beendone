task :import_airports => :environment do
	require 'csv'    
	csv_path = Rails.root.join("public", "airports.csv")
	csv_text = File.read(csv_path)
	csv = CSV.parse(csv_text, :headers => true)
	csv.each do |row|
	  Airport.create!(row.to_hash)
	end
end