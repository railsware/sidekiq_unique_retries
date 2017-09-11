module SidekiqUniqueRetries
  module Adapters
    class SidekiqUniqueJobs

      JOB_ID_KEY = 'jid'.freeze
      UNIQUE_DIGEST_KEY = 'unique_digest'.freeze

      def lockable?(item)
        item.key?(UNIQUE_DIGEST_KEY)
      end

      def job_id(item)
        item.fetch(JOB_ID_KEY)
      end

      def unique_digest(item)
        item.fetch(UNIQUE_DIGEST_KEY)
      end

    end
  end
end
