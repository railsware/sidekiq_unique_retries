require 'sidekiq/api'

module SidekiqUniqueRetries
  module Extensions
    module SortedEntry

      def delete
        if SidekiqUniqueRetries.lockable?(item)
          SidekiqUniqueRetries.unlock(item)
        end

        super
      end

      def retry
        if SidekiqUniqueRetries.lockable?(item)
          SidekiqUniqueRetries.unlock(item)
        end

        super
      end

      def kill
        if SidekiqUniqueRetries.lockable?(item)
          SidekiqUniqueRetries.unlock(item)
        end

        super
      end

    end
  end
end

Sidekiq::SortedEntry.prepend SidekiqUniqueRetries::Extensions::SortedEntry
