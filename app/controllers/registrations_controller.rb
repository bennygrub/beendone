class RegistrationsController < Devise::RegistrationsController
  def update
    account_update_params = devise_parameter_sanitizer.sanitize(:account_update)

    # required for settings form to submit when password is left blank
    if account_update_params[:password].blank?
      account_update_params.delete("password")
      account_update_params.delete("password_confirmation")
    end

    @user = User.find(current_user.id)
    if @user.update_attributes(account_update_params)
      set_flash_message :notice, :updated
      sign_in @user, :bypass => true
      redirect_to current_user
    else
      render "edit"
    end
  end
  
  protected

  def after_sign_up_path_for(resource)
    #auth_connect_path
    api = ContextIO.new('d67xxta6', 'AtuL8ONalrRJpQC0') #connect to contextio
  	if Rails.env.production?
      callback_url = "http://ancient-citadel-8002.herokuapp.com/auth/receive" #set call back url
    else
      callback_url = "http://localhost:3000/auth/receive" #set call back url
    end
  	response = api.connect_tokens.create(callback_url, options = {'email' => current_user.email})
	  #redirect for user to verify
	  response.browser_redirect_url
  end

  def after_sign_in_path_for(resource)
    sign_in_url = url_for(:action => 'new', :controller => 'sessions', :only_path => false, :protocol => 'http')
    if request.referer == sign_in_url
      super
    else
      stored_location_for(resource) || request.referer || current_user
    end
  end


end
