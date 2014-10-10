Resque::Failure::Notifier.configure do |config|
  config.from = 'ben@boardingpast.com' # from address
  config.to = 'blgruber@gmail.com' # to address
  config.include_payload = true # enabled by default
end