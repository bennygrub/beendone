class AuthController < ApplicationController
  def connect
  	api = ContextIO.new('d67xxta6', 'AtuL8ONalrRJpQC0') #connect to contextio
  	callback_url = "http://localhost:3000/auth/receive" #set call back url
  	response = api.connect_tokens.create(callback_url, options = {'email' => current_user.email})
	#redirect for user to verify
	redirect_to response.browser_redirect_url

  end

  def receive
  	contextio_token = params[:contextio_token]
  	api = ContextIO.new('d67xxta6', 'AtuL8ONalrRJpQC0') #connect to contextio
  	response = api.connect_tokens[contextio_token]
  	uid = response.account.id
  	Authentication.create(user_id: current_user.id, provider: "contextio", uid: uid)
  	Resque.enqueue(VirginGrab, current_user.id)
  	Resque.enqueue(JetblueGrab, current_user.id)
  	Resque.enqueue(CheapoGrab, current_user.id)
  	Resque.enqueue(DeltaGrab, current_user.id)
  	Resque.enqueue(UnitedGrab, current_user.id)
  	Resque.enqueue(OrbitzGrab, current_user.id)
    Resque.enqueue(FlighthubGrab, current_user.id)
  	#Resque.enqueue(AaGrab, current_user.id)
  	flash[:notice] = "You're Map is being created, we will email you when you its ready"
  	redirect_to root_path
  end
end
