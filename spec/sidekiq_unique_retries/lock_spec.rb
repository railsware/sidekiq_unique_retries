require 'spec_helper'

RSpec.describe SidekiqUniqueRetries do

  describe '.lockable?' do
    let(:item0) do
      {
        'jid' => 'testjob0'
      }
    end
    let(:item10) do
      {
        'jid' => 'testjob10',
        'unique_digest' => 'uniquejobs:abcdef1'
      }
    end
    let(:item11) do
      {
        'jid' => 'testjob11',
        'unique_digest' => 'uniquejobs:abcdef1'
      }
    end
    let(:item20) do
      {
        'jid' => 'testjob20',
        'unique_digest' => 'uniquejobs:abcdef2'
      }
    end
    let(:item21) do
      {
        'jid' => 'testjob21',
        'unique_digest' => 'uniquejobs:abcdef2'
      }
    end

    specify do
      expect(described_class.lockable?(item0)).to eq false
    end

    specify do
      expect(described_class.lockable?(item10)).to eq true
    end

    specify do
      expect(described_class.lockable?(item11)).to eq true
    end

    specify do
      expect(described_class.lockable?(item20)).to eq true
    end

    specify do
      expect(described_class.lockable?(item21)).to eq true
    end
  end

  context 'locking' do
    let(:item) do
      {
        'jid' => 'testjob10',
        'unique_digest' => 'uniquejobs:abcdef1'
      }
    end

    before do
      $redis.hmset('bg:uniqueretries', *initial_lock_hash.flatten) if initial_lock_hash
      subject
    end

    describe '.lock' do
      subject { described_class.lock(item) }

      let(:lock_hash) { $redis.hgetall('bg:uniqueretries') }

      context 'lock hash does not exists' do
        let(:initial_lock_hash) { nil }

        specify do
          expect(subject).to eq(true)
        end

        specify do
          expect(lock_hash).to eq(
            'uniquejobs:abcdef1' => 'testjob10'
          )
        end
      end

      context 'lock hash does not contains unique job key' do
        let(:initial_lock_hash) { {'uniquejobs:foo' => 'abcdef'} }

        specify do
          expect(subject).to eq(true)
        end

        specify do
          expect(lock_hash).to eq(
            'uniquejobs:abcdef1' => 'testjob10',
            'uniquejobs:foo' => 'abcdef'
          )
        end
      end

      context 'lock hash contains unique that does NOT match job id' do
        let(:initial_lock_hash) { {'uniquejobs:abcdef1' => 'abcdef'} }

        specify do
          expect(subject).to eq(false)
        end

        specify do
          expect(lock_hash).to eq(
            'uniquejobs:abcdef1' => 'abcdef'
          )
        end
      end

      context 'lock hash contains unique that matches job id' do
        let(:initial_lock_hash) { {'uniquejobs:abcdef1' => 'testjob10'} }

        specify do
          expect(subject).to eq(true)
        end

        specify do
          expect(lock_hash).to eq(
            'uniquejobs:abcdef1' => 'testjob10'
          )
        end
      end
    end

    describe '.unlock' do
      subject { described_class.unlock(item) }

      let(:lock_hash) { $redis.hgetall('bg:uniqueretries') }

      context 'lock hash does not exists' do
        let(:initial_lock_hash) { nil }

        specify do
          expect(subject).to eq(true)
        end

        specify do
          expect(lock_hash).to eq({})
        end
      end

      context 'lock hash does not contains unique job key' do
        let(:initial_lock_hash) { {'uniquejobs:foo' => 'abcdef'} }

        specify do
          expect(subject).to eq(true)
        end

        specify do
          expect(lock_hash).to eq(
            'uniquejobs:foo' => 'abcdef'
          )
        end
      end

      context 'lock hash contains unique that does NOT match job id' do
        let(:initial_lock_hash) { {'uniquejobs:abcdef1' => 'abcdef'} }

        specify do
          expect(subject).to eq(true)
        end

        specify do
          expect(lock_hash).to eq({})
        end
      end

      context 'lock hash contains unique that matches job id' do
        let(:initial_lock_hash) { {'uniquejobs:abcdef1' => 'testjob10'} }

        specify do
          expect(subject).to eq(true)
        end

        specify do
          expect(lock_hash).to eq({})
        end
      end
    end
  end
end
