class UserMailer < ActionMailer::Base
  default from: "Ben at BoardingPast <ben@boardingpast.com>"
  helper ApplicationHelper

  def finished_scan(user)
    @user = User.find(user)
    @trips = @user.trips.select{|trip| trip.flights.count > 0}
    #find a couple of fun stats to send with it
    mail(to: "#{@user.name} <#{@user.email}>", subject: "Your map is ready: we found #{@trips.count} of your trips")
  end
end
