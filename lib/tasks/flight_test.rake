task :flight_test => :environment do
	#Resque.enqueue(DeltaGrab, 18)
	#EmiratesGrab.create(:user_id => 18)
	VirginGrab.create(:user_id => 18)
	#ExampleJob.create(:id => 1)
	#UsairwaysGrab.create(1)
end