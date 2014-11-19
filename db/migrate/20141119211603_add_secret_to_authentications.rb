class AddSecretToAuthentications < ActiveRecord::Migration
  def change
    add_column :authentications, :secret, :text
  end
end
