class AddAttachmentCoverToTrips < ActiveRecord::Migration
  def self.up
    change_table :trips do |t|
      t.attachment :cover
    end
  end

  def self.down
    remove_attachment :trips, :cover
  end
end
