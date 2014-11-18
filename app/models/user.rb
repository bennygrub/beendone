class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable, :omniauthable, :omniauth_providers => [:google, :instagram]

  has_many :authentications
  has_many :trips
  has_many :flights, through: :trips
  has_many :highlights
  has_many :mates
  has_many :places
  validates_presence_of :name, :email
  after_create :new_user
  extend FriendlyId
  friendly_id :name, use: [:slugged, :finders]

  has_attached_file :avatar, :styles => { :medium => "300x300>", :thumb => "100x100>" }, :default_url => "/images/user.png"
  validates_attachment_content_type :avatar, :content_type => /\Aimage\/.*\Z/

  def new_user
    UserMailer.new_user_admin(self.id).deliver
  end

  def self.find_for_google_oauth2(access_token, signed_in_resource=nil)
    data = access_token.extra["raw_info"]
    #raise "#{access_token.credentials['token']}"
    user = User.where(:email => data["email"]).first
    contextio = ContextIO.new('d67xxta6', 'AtuL8ONalrRJpQC0')
    account = contextio.accounts.create(email: data["email"])
    
    account.sources.create(
        data["email"],
        "imap.gmail.com",
        data["email"],
        1,
        993,
        'IMAP',
        provider_consumer_key: "329607164099-q5968gbogqqq6dkl4us5i70k6fmn7a0c.apps.googleusercontent.com",
        provider_refresh_token: access_token.credentials["refresh_token"],
        callback_url: "http:/localhost:3000"
	)
    

    # Uncomment the section below if you want users to be created if they don't exist
    unless user
        user = User.create(
        	name: data["name"],
            email: data["email"],
            password: Devise.friendly_token[0,20]
        )
    end
    user
  end
end
