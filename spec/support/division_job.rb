class DivisionJob
  include Sidekiq::Worker

  sidekiq_options(
    queue: 'test'
  )

  def perform(a, b)
    a/b
  end

end
