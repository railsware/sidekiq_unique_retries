module SidekiqUniqueRetries
  class Lock

    HASH_KEY = 'uniqueretries'.freeze

    attr_reader \
      :job_id,
      :unique_digest

    def initialize(item, adapter)
      @job_id = adapter.job_id(item)
      @unique_digest = adapter.unique_digest(item)
    end

    def acquire
      lock_id = get_lock

      if lock_id
        job_id == lock_id
      else
        set_lock(job_id)
        true
      end
    end

    def release
      remove_lock
      true
    end

    private

    def get_lock
      Sidekiq.redis do |conn|
        conn.hget HASH_KEY, unique_digest
      end
    end

    def set_lock(value)
      Sidekiq.redis do |conn|
        conn.hset HASH_KEY, unique_digest, value
      end
    end

    def remove_lock
      Sidekiq.redis do |conn|
        conn.hdel HASH_KEY, unique_digest
      end
    end
  end

end
