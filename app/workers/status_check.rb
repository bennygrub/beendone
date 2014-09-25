require 'res_helper'
require 'resque-retry'
class StatusCheck
  extend ResHelper
  extend Resque::Plugins::Retry
  include Resque::Plugins::Status

  @queue = :status_queue

  def self.perform(job_ids)
  	finished = Array.new
    while finished.size < job_ids.size
      job_ids.each do |id|
        finished << id if job_finished(id)
      end
      sleep 10
    end
    Resque.enqueue(FlightGrab, user_id)
  end
end