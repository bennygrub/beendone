HireFire::Resource.configure do |config|
  config.dyno(:worker) do
    HireFire::Macro::Resque.queue
  end
  config.dyno(:resque) do
    HireFire::Macro::Resque.queue
  end
  config.dyno(:scheduler) do
    HireFire::Macro::Resque.queue
  end
end