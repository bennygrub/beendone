Instagram.configure do |config|
  if Rails.env.development?
  	config.client_id = "41017ae5361445219154f3faca7bcb81"
  	config.client_secret = "ceaa616f9fc24f979964cbea54406d93"
  else
  	config.client_id = "d8210bc4d87a44b3a7d13e7865c35cb9"
  	config.client_secret = "3670bd619cd549ad8fad663a591ca0f1"
  end
end