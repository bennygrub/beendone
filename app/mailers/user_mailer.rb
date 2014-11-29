class UserMailer < ActionMailer::Base
  default from: "Ben at BoardingPast <ben@boardingpast.com>"
  include ApplicationHelper
  helper :application

  def finished_scan(user)
    @user = User.find(user)
    @trips = @user.trips.select{|trip| trip.flights.count > 0}
    #find a couple of fun stats to send with it
    mail(to: "#{@user.name} <#{@user.email}>", subject: "Your map is ready: we found #{@trips.count} of your trips")
  end
  
  def new_user_admin(user)
    @user = User.find(user)
    mail(to: "blgruber@gmail.com", subject: "A New User Signed Up for BoardingPast")
  end

  def invite(user, invitee_email, invitee_name, trip)
    @user = User.find(user)
    @trip = Trip.find(trip)
    @invitee_name = invitee_name
    @invitee_email = invitee_email
    destination = destination_city(@trip)
    @name = @trip.name.blank? ? destination.city : @trip.name
    mail(to: "#{@invitee_name} <#{@invitee_email}>", subject: "#{@user.name} wants you to share in the memories of your #{@name} trip", from: "#{@user.name} <#{@user.email}>")
  end

end
