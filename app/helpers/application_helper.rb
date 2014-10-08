module ApplicationHelper

	def destination_city(trip)
    	if trip.flights.count < 3 #if the trip has 1 or 2 flights
        	return Airport.find(trip.flights.first.arrival_airport).city#destination is the arrival of the first flight
        elsif trip.flights.count.even? #if the trip has 3 or more flights and is even its probably the middle one
        	x = (trip.flights.count/2)-1
        	middle = trip.flights[x]
        	return Airport.find(middle.arrival_airport).city
        else#if the trip has 3 or more flights and is odd its probably the first of the middle ones
        	x = (trip.flights.count/2)-0.5
        	middle = trip.flights[x]
        	return Airport.find(middle.arrival_airport).city
        end
	end

	def days_visited(trip)
    	if trip.flights.count < 3 #if the trip has 1 or 2 flights
        	if trip.flights.count == 2
        		a_time = trip.flights.first.arrival_time #destination is the arrival of the first flight
        		d_time = trip.flights.last.depart_time
        		return ((d_time - a_time)/1.day).round
        	else
        		return 0
        	end
        elsif trip.flights.count.even?#if the trip has 3 or more flights and is even its probably the middle one
        	x = (trip.flights.count/2)-1
        	middle = trip.flights[x]
        	a_time = middle.arrival_time
        	d_time = trip.flights[x+1].depart_time
        	return ((d_time - a_time)/1.day).round
        else#if the trip has 3 or more flights and is odd its probably the first of the middle ones
        	x = (trip.flights.count/2)-0.5
        	middle = trip.flights[x]
        	a_time = middle.arrival_time
        	d_time = trip.flights[x+1].depart_time
        	return ((d_time - a_time)/1.day).round
        end
	end
	def in_out_flights(trip)
    	if trip.flights.count < 3 #if the trip has 1 or 2 flights
        	if trip.flights.count == 2
        		return [trip.flights[0],trip.flights[1]]
        	else
        		return [trip.flights[0], trip.flights[0]]
        	end
        elsif trip.flights.count.even? #if the trip has 3 or more flights and is even its probably the middle one
        	x = (trip.flights.count/2)-1
        	return [trip.flights[x], trip.flights[x+1]]
        else#if the trip has 3 or more flights and is odd its probably the first of the middle ones
        	x = (trip.flights.count/2)-0.5
        	return [trip.flights[x], trip.flights[x+1]]
        end
	end
	def is_destination(flight)
    	trip = Trip.find(flight.trip_id)
    	flight_index = trip.flights.map{|flight| flight.id}.index(flight.id)
    	destination_flight = destination_flight_number(trip)
    	return destination_flight == flight_index ? true : false
	end

	def destination_flight_number(trip)
    	if trip.flights.count < 3 #if the trip has 1 or 2 flights
        	return 0
        elsif trip.flights.count.even? #if the trip has 3 or more flights and is even its probably the middle one
        	return (trip.flights.count/2)-1
        else#if the trip has 3 or more flights and is odd its probably the first of the middle ones
        	return (trip.flights.count/2)-0.5
        end
	end
end
