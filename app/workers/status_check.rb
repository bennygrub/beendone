require 'res_helper'
require 'resque-retry'
class StatusCheck
  extend ResHelper
  extend Resque::Plugins::Retry
  include Resque::Plugins::Status

  @queue = :status_queue

  def self.perform(job_ids)
  	finished = Array.new
    while finished.count < job_ids.count
      job_ids.each do |id|
        finished << id if job_finished(id)
      end
      sleep 3
    end
    ErrorMailer.uca(1, "city", "message_id", 1 ).deliver
  end
end