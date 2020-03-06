module SidekiqUniqueRetries
  module Adapters
    class SidekiqUniqueJobs
      UNIQUE_RETRY_LOCKS = %w[
        until_executing
        until_executed
        until_timeout
        until_and_while_executing
      ].freeze

      JOB_ID_KEY = 'jid'.freeze
      LOCK_KEY = 'unique'.freeze
      DIGEST_KEY = 'unique_digest'.freeze

      def lockable?(item)
        UNIQUE_RETRY_LOCKS.include?(item[LOCK_KEY])
      end

      def job_id(item)
        item.fetch(JOB_ID_KEY)
      end

      def unique_digest(item)
        item.fetch(DIGEST_KEY)
      end
    end
  end
end
