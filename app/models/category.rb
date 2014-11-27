class Category < ActiveRecord::Base
  belongs_to :highlight
  has_attached_file :icon, :styles => { :medium => "300x300>", :thumb => "100x100>" }, :default_url => "/images/icon.png"
  validates_attachment_content_type :icon, :content_type => /\Aimage\/.*\Z/
end
