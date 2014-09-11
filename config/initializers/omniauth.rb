Rails.application.config.middleware.use OmniAuth::Builder do
  if Rails.env.development?
  	#provider :google_oauth2, ENV["GOOGLE_CLIENT_ID"], ENV["GOOGLE_CLIENT_SECRET"],{:name => "google",:scope => "email, profile, plus.me, https://www.googleapis.com/auth/gmail.readonly"}
  	provider :google_oauth2, "329607164099-q5968gbogqqq6dkl4us5i70k6fmn7a0c.apps.googleusercontent.com", "V1ig_Cca7-Jq9t1UPrRQgDBW",{:name => "google",:scope => "https://www.googleapis.com/auth/userinfo.email, https://www.googleapis.com/auth/userinfo.profile, plus.me, https://www.googleapis.com/auth/gmail.readonly", :prompt => "consent"}
  end
end