task :flight_test => :environment do
	#Resque.enqueue(DeltaGrab, 18)
	CheapoGrab.create(1)
	#UsairwaysGrab.create(1)
end