Rails.application.config.middleware.use OmniAuth::Builder do
  if Rails.env.development?
  	#provider :google_oauth2, ENV["GOOGLE_CLIENT_ID"], ENV["GOOGLE_CLIENT_SECRET"],{:name => "google",:scope => "email, profile, plus.me, https://www.googleapis.com/auth/gmail.readonly"}
  	provider :google_oauth2, "329607164099-q5968gbogqqq6dkl4us5i70k6fmn7a0c.apps.googleusercontent.com", "V1ig_Cca7-Jq9t1UPrRQgDBW",{:name => "google",:scope => "https://www.googleapis.com/auth/userinfo.email, https://www.googleapis.com/auth/userinfo.profile, plus.me, https://www.googleapis.com/auth/gmail.readonly", :prompt => "consent"}
  	provider :instagram, "41017ae5361445219154f3faca7bcb81", "ceaa616f9fc24f979964cbea54406d93"
  else
  	provider :instagram, "d8210bc4d87a44b3a7d13e7865c35cb9", "3670bd619cd549ad8fad663a591ca0f1"
  end
end