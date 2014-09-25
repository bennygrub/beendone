require 'res_helper'
class SearchAll
  extend ResHelper
  @queue = :search_queue

  def self.perform(user_id)
  	Resque.enqueue(VirginGrab, user_id)
  	Resque.enqueue(JetblueGrab, user_id)
  	Resque.enqueue(CheapoGrab, user_id)
  	Resque.enqueue(DeltaGrab, user_id)
  	Resque.enqueue(UnitedGrab, user_id)
  	Resque.enqueue(OrbitzGrab, user_id)
    Resque.enqueue(FlighthubGrab, user_id)
  end
end