task :flight_test, [:uid] => :environment do |t, arg|
	JetblueGrab.create(:user_id => arg[:uid])
end