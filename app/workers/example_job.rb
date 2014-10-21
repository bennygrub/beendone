class ExampleJob
  include Resque::Plugins::Status

  def perform(j,s)
    num = 10
    i = 0
    while i < num
      i += 1
      at(i, num)
    end
    completed("Finished!")
  end

end