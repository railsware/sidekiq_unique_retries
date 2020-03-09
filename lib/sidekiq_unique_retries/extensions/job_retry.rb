require 'sidekiq/job_retry'

module SidekiqUniqueRetries
  module Extensions
    module JobRetry
      def attempt_retry(worker, msg, queue, exception)
        if SidekiqUniqueRetries.lockable?(msg)
          if SidekiqUniqueRetries.lock(msg)
            super
          else
            logger.info { "Ignore retry for #{msg['class']} job #{msg['jid']}" }
          end
        else
          super
        end
      end

      def retries_exhausted(worker, msg, exception)
        if SidekiqUniqueRetries.lockable?(msg)
          SidekiqUniqueRetries.unlock(msg)
        end

        super
      end
    end
  end
end

Sidekiq::JobRetry.prepend SidekiqUniqueRetries::Extensions::JobRetry
