task :flight_test => :environment do
	#Resque.enqueue(DeltaGrab, 18)
	JetblueGrab.create(:user_id =>1)
	#ExampleJob.create(:id => 1)
	#UsairwaysGrab.create(1)
end