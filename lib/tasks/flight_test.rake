task :flight_test => :environment do
	#Resque.enqueue(DeltaGrab, 18)
	Resque.enqueue(VirginGrab, 18)
end