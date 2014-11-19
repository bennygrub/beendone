class OmniauthCallbacksController < Devise::OmniauthCallbacksController  
  def google
      # You need to implement the method below in your model (e.g. app/models/user.rb)
      #raise "#{request.env["omniauth.auth"]}"
      @user = User.find_for_google_oauth2(request.env["omniauth.auth"], current_user)
      
      if @user.persisted?
        flash[:notice] = I18n.t "devise.omniauth_callbacks.success", :kind => "Google"
        sign_in_and_redirect @user, :event => :authentication
      else
        session["devise.google_data"] = request.env["omniauth.auth"]
        redirect_to new_user_registration_url
      end
  end

  def instagram
    uid = request.env["omniauth.auth"].uid
    token = request.env["omniauth.auth"].credentials["token"]
    Authentication.create(user_id: current_user.id, provider: "instagram", uid: uid, token: token )
    redirect_to user_path(current_user)
  end
  
  def twitter
    uid = request.env["omniauth.auth"].uid
    token = request.env["omniauth.auth"].credentials["token"]
    secret = request.env["omniauth.auth"].credentials["secret"]
    Authentication.create(user_id: current_user.id, provider: "twitter", uid: uid, token: token, secret: secret )
    redirect_to user_path(current_user)
  end

end