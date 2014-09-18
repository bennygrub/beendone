task :flight_test => :environment do
	#Resque.enqueue(DeltaGrab, 18)
	Resque.enqueue(JetblueGrab, 18)
end