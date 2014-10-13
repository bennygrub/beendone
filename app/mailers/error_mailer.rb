class ErrorMailer < ActionMailer::Base
  default from: "Its You <ben@boardingpast.com>"

  def uca(user, city, message_id, airline_id)
    @user = User.find(user)
    @city = city
    @message_id = message_id
    @airline_id = airline_id
    mail(to: "blgruber@gmail.com", subject: 'Unidentified City or Airport')
  end
end
