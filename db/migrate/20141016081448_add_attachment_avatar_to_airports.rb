class AddAttachmentAvatarToAirports < ActiveRecord::Migration
  def self.up
    change_table :airports do |t|
      t.attachment :avatar
    end
  end

  def self.down
    remove_attachment :airports, :avatar
  end
end
