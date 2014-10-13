task :flight_test => :environment do
	#Resque.enqueue(DeltaGrab, 18)
	AaGrab.create(1)
end