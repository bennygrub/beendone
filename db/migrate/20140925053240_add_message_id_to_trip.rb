class AddMessageIdToTrip < ActiveRecord::Migration
  def change
    add_column :trips, :message_id, :string
  end
end
