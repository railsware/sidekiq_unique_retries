require 'spec_helper'

RSpec.describe SidekiqUniqueRetries do

  describe '.lockable?' do
    subject { described_class.lockable?(item) }

    context 'item with jid only' do
      let(:item) do
        {
          'jid' => 'testjob0'
        }
      end

      specify { is_expected.to eq false }
    end

    context 'item with unique key' do
      let(:item) do
        {
          'jid' => 'testjob0',
          'unique' => unique
        }
      end

      context 'unique: while_executing' do
        let(:unique) { 'while_executing' }

        specify  { is_expected.to eq false }
      end

      context 'unique until_executing' do
        let(:unique) { 'until_executing' }

        specify  { is_expected.to eq true }
      end

      context 'unique: until_executed' do
        let(:unique) { 'until_executed' }

        specify  { is_expected.to eq true }
      end

      context 'unique: until_timeout' do
        let(:unique) { 'until_timeout' }

        specify  { is_expected.to eq true }
      end

      context 'unique: until_and_while_executing' do
        let(:unique) { 'until_and_while_executing' }

        specify  { is_expected.to eq true }
      end
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
