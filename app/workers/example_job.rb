class ExampleJob
  include Resque::Plugins::Status

  def self.perform(job_id, options)
    id = options['id']
    num = 10
    i = 0
    while i < num
      i += 1
      at(i, num)
    end
    completed("Finished! #{id}")
  end

end