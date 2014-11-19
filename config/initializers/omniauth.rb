Rails.application.config.middleware.use OmniAuth::Builder do
  if Rails.env.development?
  	#provider :google_oauth2, ENV["GOOGLE_CLIENT_ID"], ENV["GOOGLE_CLIENT_SECRET"],{:name => "google",:scope => "email, profile, plus.me, https://www.googleapis.com/auth/gmail.readonly"}
  	provider :google_oauth2, "329607164099-q5968gbogqqq6dkl4us5i70k6fmn7a0c.apps.googleusercontent.com", "V1ig_Cca7-Jq9t1UPrRQgDBW",{:name => "google",:scope => "https://www.googleapis.com/auth/userinfo.email, https://www.googleapis.com/auth/userinfo.profile, plus.me, https://www.googleapis.com/auth/gmail.readonly", :prompt => "consent"}
  	provider :instagram, "41017ae5361445219154f3faca7bcb81", "ceaa616f9fc24f979964cbea54406d93"
  	provider :twitter, "KXxqcOE3eqI6sddRyavNeHTtL", "ZLDWYmWOzP7cU26BjJe3NPflNRu9iRtYwy6RMDD8RTUWGRMxNH"
  	provider :facebook, "530970186991602", "62f04a5549bbcf9e890c0a77096a01ac"
  else
  	provider :instagram, "d8210bc4d87a44b3a7d13e7865c35cb9", "3670bd619cd549ad8fad663a591ca0f1"
  	provider :twitter, "lIsxQnuCiG9kwNvOJwsjFg3ao", "GTR5WZzZIqllS07wK1jsWsyKeDFX6qxBg9oVdGufbOJA1lHGL3"
  	provider :facebook, "350650685106906", "eef12f48abf9b4d8137ac3cea10ed847"
  end
end