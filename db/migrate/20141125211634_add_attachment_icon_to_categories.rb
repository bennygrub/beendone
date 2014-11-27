class AddAttachmentIconToCategories < ActiveRecord::Migration
  def self.up
    change_table :categories do |t|
      t.attachment :icon
    end
  end

  def self.down
    remove_attachment :categories, :icon
  end
end
