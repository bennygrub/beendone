class RegistrationsController < Devise::RegistrationsController

  protected

  def after_sign_up_path_for(resource)
    #auth_connect_path
    api = ContextIO.new('d67xxta6', 'AtuL8ONalrRJpQC0') #connect to contextio
  	callback_url = "http://localhost:3000/auth/receive" #set call back url
  	response = api.connect_tokens.create(callback_url, options = {'email' => current_user.email})
	#redirect for user to verify
	response.browser_redirect_url
  end
end