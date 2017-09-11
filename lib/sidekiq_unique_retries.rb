require 'sidekiq_unique_retries/lock'
require 'sidekiq_unique_retries/extensions/api'
require 'sidekiq_unique_retries/extensions/job_retry'

module SidekiqUniqueRetries

  class << self
    attr_reader :adapter

    def adapter=(name)
      @adapter = adapter_for(name)
    end

    def lockable?(item)
      adapter.lockable?(item)
    end

    def lock(item)
      Lock.new(item, adapter).acquire
    end

    def unlock(item)
      Lock.new(item, adapter).release
    end

    private

    def adapter_for(object)
      case object
      when Symbol
        load_adapter(object)
        build_adapter(object)
      else
        object
      end
    end

    def load_adapter(name)
      require "sidekiq_unique_retries/adapters/#{name}"
    end

    def build_adapter(name)
      class_name = name.to_s.split('_').map(&:capitalize).join
      klass = self::Adapters.const_get(class_name, false)
      klass.new
    end
  end

  self.adapter = :sidekiq_unique_jobs

end
