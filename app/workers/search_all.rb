require 'res_helper'
class SearchAll
  extend ResHelper
  extend Resque::Plugins::Retry
  include Resque::Plugins::Status
  include ResHelper
  @queue = :search_queue

  def self.perform(user_id)
  	job_ids = Array.new
    job_ids << VirginGrab.create(:user_id => user_id)
    job_ids << AaGrab.create(:user_id => user_id)
    job_ids << CheapoGrab.create(:user_id => user_id)
    job_ids << JetblueGrab.create(:user_id => user_id)
    job_ids << DeltaGrab.create(:user_id => user_id)
    job_ids << UnitedGrab.create(:user_id => user_id)
    job_ids << OrbitzGrab.create(:user_id => user_id)
    job_ids << FlighthubGrab.create(:user_id => user_id)
    job_ids << TacaGrab.create(:user_id => user_id)
    job_ids << UsairwaysGrab.create(:user_id => user_id)
    job_ids << NorthwestGrab.create(:user_id => user_id)
    job_ids << SouthwestGrab.create(:user_id => user_id)
    job_ids << PricelineGrab.create(:user_id => user_id)
    job_ids << HotwireGrab.create(:user_id => user_id)
    job_ids << EmiratesGrab.create(:user_id => user_id)

    Resque.enqueue(StatusCheck, job_ids, user_id)
  end
end