task :flight_test => :environment do
	#Resque.enqueue(DeltaGrab, 18)
	UnitedGrab.create(:user_id => 21)
	#ExampleJob.create(:id => 1)
	#UsairwaysGrab.create(1)
end