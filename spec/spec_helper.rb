require "bundler/setup"
require "sidekiq_unique_retries"

Dir[File.join(__dir__, 'support', '**', '*.rb')].each { |f| require f }

redis_options = {
  namespace: 'bg',
  db: 1
}

$redis = Redis.new(redis_options)

Sidekiq.configure_client do |config|
  config.redis = redis_options
end

Sidekiq.configure_server do |config|
  config.redis = redis_options
end

Sidekiq.logger.level = Logger::ERROR

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.before(:each) do
    $redis.flushdb
  end
end
