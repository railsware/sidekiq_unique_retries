require 'spec_helper'

require 'sidekiq/processor'

RSpec.describe Sidekiq::Processor do
  let(:processor) do
    described_class.new(manager)
  end
  let(:manager) do
    Struct.new(:options).new(
      queues: ['test']
    )
  end

  let(:initial_lock_hash) { nil }

  let(:lock_hash) { $redis.hgetall('bg:uniqueretries') }

  before do
    $redis.hmset('bg:uniqueretries', *initial_lock_hash.flatten) if initial_lock_hash
  end

  describe '#process_one' do
    subject { processor.send :process_one }

    let(:lock_hash) { $redis.hgetall('bg:uniqueretries') }
    let(:queue_size) { Sidekiq::Queue.new('test').size }
    let(:retry_items)  { Sidekiq::RetrySet.new.sort_by(&:created_at).map(&:item) }
    let(:dead_items)  { Sidekiq::DeadSet.new.sort_by(&:created_at).map(&:item) }

    context 'single job' do
      let(:job_options) { {} }

      before do
        DivisionJob.set(
          {
            unique: 'until_executed',
            unique_digest: 'digest1',
            jid: 'jid1',
            retry: 5
          }.merge(job_options)
        ).perform_async(1, 0)
      end

      context 'empty uniqueretries hash' do
        it 'puts job into retries set' do
          expect { subject }.to raise_error(ZeroDivisionError, 'divided by 0')

          expect(retry_items.size).to eq(1)
          expect(retry_items[0]).to include(
            'class' => 'DivisionJob',
            'args' => [1, 0],
            'retry' => 5,
            'retry_count' => 0,
            'queue' => 'test',
            'jid' => 'jid1',
            'unique' => 'until_executed',
            'unique_digest' => 'digest1',
            'error_class' => 'ZeroDivisionError',
            'error_message' => 'divided by 0'
          )
          expect(dead_items.size).to eq(0)
          expect(lock_hash).to eq(
            'digest1' => 'jid1'
          )
        end
      end

      context 'uniqueretries has key with another job id' do
        let(:initial_lock_hash) do
          {
            'digest1' => 'jid2'
          }
        end

        it 'does NOT put job into retries set' do
          expect { subject }.to raise_error(ZeroDivisionError, 'divided by 0')

          expect(retry_items.size).to eq(0)
          expect(dead_items.size).to eq(0)
          expect(lock_hash).to eq(
            'digest1' => 'jid2'
          )
        end
      end

      context 'uniqueretries has key with this job id' do
        let(:initial_lock_hash) do
          {
            'digest1' => 'jid1'
          }
        end

        context 'continue retries' do
          let(:job_options) { {retry_count: 3} }

          it 'puts job into retries set' do
            expect { subject }.to raise_error(ZeroDivisionError, 'divided by 0')

            expect(retry_items.size).to eq(1)
            expect(retry_items[0]).to include(
              'class' => 'DivisionJob',
              'args' => [1, 0],
              'retry' => 5,
              'retry_count' => 4,
              'queue' => 'test',
              'jid' => 'jid1',
              'unique' => 'until_executed',
              'unique_digest' => 'digest1',
              'error_class' => 'ZeroDivisionError',
              'error_message' => 'divided by 0'
            )
            expect(dead_items.size).to eq(0)
            expect(lock_hash).to eq(
              'digest1' => 'jid1'
            )
          end
        end

        context 'retries exhausted' do
          let(:job_options) { {retry_count: 4} }

          it 'puts job into dead set' do
            expect { subject }.to raise_error(ZeroDivisionError, 'divided by 0')
            expect(retry_items.size).to eq(0)
            expect(dead_items.size).to eq(1)
            expect(dead_items[0]).to include(
              'class' => 'DivisionJob',
              'args' => [1, 0],
              'retry' => 5,
              'retry_count' => 5,
              'queue' => 'test',
              'jid' => 'jid1',
              'unique' => 'until_executed',
              'unique_digest' => 'digest1',
              'error_class' => 'ZeroDivisionError',
              'error_message' => 'divided by 0',
            )
            expect(lock_hash).to be_empty
          end
        end
      end
    end

    context 'multiple jpbs' do
      it 'puts only one unique jobs into retries set' do
        DivisionJob.set(
          unique: 'until_executed',
          unique_digest: 'digest1',
          jid: 'jid1',
          retry: 1
        ).perform_async(1, 0)
        DivisionJob.set(
          unique: 'until_executed',
          unique_digest: 'digest1',
          jid: 'jid2',
          retry: 1
        ).perform_async(2, 0)
        DivisionJob.set(
          unique: 'until_executed',
          unique_digest: 'digest2',
          jid: 'jid3',
          retry: 1
        ).perform_async(3, 0)
        DivisionJob.set(
          unique: 'until_executed',
          unique_digest: 'digest2',
          jid: 'jid4',
          retry: 1
        ).perform_async(4, 0)

        expect(Sidekiq::Queue.new('test').size).to eq(4)

        expect { processor.send :process_one }.to raise_error(ZeroDivisionError, 'divided by 0')
        expect(Sidekiq::Queue.new('test').size).to eq(3)
        retry_items = Sidekiq::RetrySet.new.sort_by(&:created_at).map(&:item)
        expect(retry_items.size).to eq(1)
        expect(retry_items[0]).to include(
          'jid' => 'jid1',
          'class' => 'DivisionJob',
          'args' => [1, 0],
          'retry' => 1,
          'retry_count' => 0,
          'queue' => 'test',
          'unique' => 'until_executed',
          'unique_digest' => 'digest1',
          'error_class' => 'ZeroDivisionError',
          'error_message' => 'divided by 0'
        )

        expect { processor.send :process_one }.to raise_error(ZeroDivisionError, 'divided by 0')
        expect(Sidekiq::Queue.new('test').size).to eq(2)
        retry_items = Sidekiq::RetrySet.new.sort_by(&:created_at).map(&:item)
        expect(retry_items.size).to eq(1)
        expect(retry_items[0]).to include(
          'jid' => 'jid1',
          'class' => 'DivisionJob',
          'args' => [1, 0],
          'retry' => 1,
          'retry_count' => 0,
          'queue' => 'test',
          'unique' => 'until_executed',
          'unique_digest' => 'digest1',
          'error_class' => 'ZeroDivisionError',
          'error_message' => 'divided by 0'
        )

        expect { processor.send :process_one }.to raise_error(ZeroDivisionError, 'divided by 0')
        expect(Sidekiq::Queue.new('test').size).to eq(1)
        retry_items = Sidekiq::RetrySet.new.sort_by(&:created_at).map(&:item)
        expect(retry_items.size).to eq(2)
        expect(retry_items[0]).to include(
          'jid' => 'jid1',
          'class' => 'DivisionJob',
          'args' => [1, 0],
          'retry' => 1,
          'retry_count' => 0,
          'queue' => 'test',
          'unique' => 'until_executed',
          'unique_digest' => 'digest1',
          'error_class' => 'ZeroDivisionError',
          'error_message' => 'divided by 0'
        )
        expect(retry_items[1]).to include(
          'jid' => 'jid3',
          'class' => 'DivisionJob',
          'args' => [3, 0],
          'retry' => 1,
          'retry_count' => 0,
          'queue' => 'test',
          'unique' => 'until_executed',
          'unique_digest' => 'digest2',
          'error_class' => 'ZeroDivisionError',
          'error_message' => 'divided by 0'
        )

        expect { processor.send :process_one }.to raise_error(ZeroDivisionError, 'divided by 0')
        expect(Sidekiq::Queue.new('test').size).to eq(0)
        retry_items = Sidekiq::RetrySet.new.sort_by(&:created_at).map(&:item)
        expect(retry_items.size).to eq(2)
        expect(retry_items[0]).to include(
          'jid' => 'jid1',
          'class' => 'DivisionJob',
          'args' => [1, 0],
          'retry' => 1,
          'retry_count' => 0,
          'queue' => 'test',
          'unique' => 'until_executed',
          'unique_digest' => 'digest1',
          'error_class' => 'ZeroDivisionError',
          'error_message' => 'divided by 0'
        )
        expect(retry_items[1]).to include(
          'jid' => 'jid3',
          'class' => 'DivisionJob',
          'args' => [3, 0],
          'retry' => 1,
          'retry_count' => 0,
          'queue' => 'test',
          'unique' => 'until_executed',
          'unique_digest' => 'digest2',
          'error_class' => 'ZeroDivisionError',
          'error_message' => 'divided by 0'
        )
      end
    end
  end
end
