class UserMailer < ActionMailer::Base
  default from: "Ben at BoardingPast <ben@boardingpast.com>"

  def finished_scan(user)
    #@user = User.find(user)
    mail(to: "blgruber@gmail.com", subject: 'Finished Scan')
  end
end
