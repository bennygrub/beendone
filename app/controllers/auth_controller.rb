class AuthController < ApplicationController
  def connect
  	api = ContextIO.new('d67xxta6', 'AtuL8ONalrRJpQC0') #connect to contextio
  	
    if Rails.env.production?
      callback_url = "http://www.boardingpast.com/auth/receive" #set call back url
    else
      callback_url = "http://localhost:3000/auth/receive" #set call back url
    end
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
  	Resque.enqueue(SearchAll, current_user.id, 0)
  	#flash[:notice] = "You're Map is being created, we will email you when you its ready"
  	redirect_to root_path
  end

  def recheck
    user = params[:who]
    email = params[:email]
    send = 1
    send = 2 if email == 2
    Resque.enqueue(SearchAll, user, send)
    redirect_to '/resque'
  end
end
