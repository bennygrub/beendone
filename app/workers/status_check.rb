require 'res_helper'
require 'resque-retry'
class StatusCheck
  extend ResHelper
  extend Resque::Plugins::Retry
  include Resque::Plugins::Status
  include ResHelper

  @queue = :status_queue

  def self.perform(job_ids, user_id)
  	finished = Array.new
    while finished.count < job_ids.count
      job_ids.each do |id|
        finished << id if job_finished(id)
      end
      sleep 3
    end
    #update user_db
    user = User.find(user_id)
    user.scan = false
    user.save
    unused_trips = user.trips.select{|t| t if t.flights.count == 0}
    unused_trips.each do |t|
      t.destroy
    end
    UserMailer.finished_scan(user_id).deliver
  end
end