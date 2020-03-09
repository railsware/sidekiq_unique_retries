require 'spec_helper'

RSpec.describe 'Sidekiq api' do
  let(:score) { Time.now.to_f.to_s }

  let(:item) do
    {
      'class' => 'Foo',
      'args' => [101],
      'jid' => 'jid_0',
      'unique' => 'until_executed',
      'unique_digest' => 'uniquejobs:b'
    }
  end

  let(:initial_lock_hash) do
    {
      'uniquejobs:a' => 'jid_1',
      'uniquejobs:b' => 'jid_2',
      'uniquejobs:c' => 'jid_3',
    }
  end

  let(:lock_hash) { $redis.hgetall('bg:uniqueretries') }

  before do
    $redis.zadd('bg:retry', score, Sidekiq.dump_json(item))
    $redis.hmset('bg:uniqueretries', *initial_lock_hash.flatten)
  end

  describe 'Retry entry' do
    let(:entry) { Sidekiq::RetrySet.new.first }

    context 'delete' do
      before { entry.delete }

      specify do
        expect(lock_hash).to eq(
          'uniquejobs:a' => 'jid_1',
          'uniquejobs:c' => 'jid_3',
        )
      end
    end

    context 'retry' do
      before { entry.retry }

      specify do
        expect(lock_hash).to eq(
          'uniquejobs:a' => 'jid_1',
          'uniquejobs:c' => 'jid_3'
        )
      end
    end

    context 'kill' do
      before { entry.kill }

      specify do
        expect(lock_hash).to eq(
          'uniquejobs:a' => 'jid_1',
          'uniquejobs:c' => 'jid_3',
        )
      end
    end
  end
end
