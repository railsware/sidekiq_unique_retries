require 'sidekiq/job_retry'

module SidekiqUniqueRetries
  module Extensions
    module JobRetry

      def attempt_retry(worker, msg, queue, exception)
        if SidekiqUniqueRetries.lockable?(msg)
          raise exception unless SidekiqUniqueRetries.lock(msg)
        end

        super(worker, msg, queue, exception)
      end

      def retries_exhausted(worker, msg, exception)
        if SidekiqUniqueRetries.lockable?(msg)
          SidekiqUniqueRetries.unlock(msg)
        end

        super(worker, msg, exception)
      end

    end
  end
end

Sidekiq::JobRetry.prepend SidekiqUniqueRetries::Extensions::JobRetry
