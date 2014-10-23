class AddScanToUsers < ActiveRecord::Migration
  def change
    add_column :users, :scan, :boolean, default: true
  end
end
