class AddTokenToAuthentications < ActiveRecord::Migration
  def change
    add_column :authentications, :token, :text
  end
end
