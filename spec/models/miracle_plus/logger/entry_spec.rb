# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MiraclePlus::Logger::Entry, type: :model do
  before(:each) do
    # MiraclePlus::Logger::Redis.flushdb
    MiraclePlus::Logger::Redis.script 'flush'
    MiraclePlus::Logger::ScriptsManager.init_scripts
  end
  let(:script_manager) { MiraclePlus::Logger::ScriptsManager.instance }
  let(:ip) { '127.0.0.1' }
  subject(:entry) { described_class.new(ip, nil) }
  let(:redis) { MiraclePlus::Logger::Redis }
  let(:key) { "#{entry.entry_key_namespace}:#{entry.id}" }

  describe '#init_scripts' do
    subject { entry }

    context 'when scripts initialized' do
      it 'generates instance variable "scripts"' do
        expect(script_manager.instance_variable_get('@scripts')).not_to be_nil
      end

      it 'loads scripts into redis' do
        script_manager.instance_variable_get('@scripts').each_value do |sha|
          expect(MiraclePlus::Logger::Redis.script('exists', sha)).to eq true
        end
      end
    end
  end

  describe '#persist' do
    subject! do
      entry.persist(default_params)
    end

    context 'when persisted' do
      it 'return true' do
        expect(subject).to eq true
      end

      it 'create the specific key' do
        expect(redis.exists(key)).to eq 1
      end

      it 'store the specific ip' do
        expect(redis.hget(key, :ip)).to eq ip
      end

      it 'append id into the "entries" list' do
        ids = redis.lrange(logging_entries_key, 0, -1)
        expect(entry.id.in?(ids)).to eq true
      end
    end

    context 'when ip changed after persisted' do
      let(:new_ip) { '8.8.8.8' }
      subject! do
        entry.persist(default_params)
        @original_ip = entry.ip
        described_class.new(new_ip, entry.id).persist(default_params)
      end

      it 'spec_name' do
        result = EnterpriseScriptService.run(
          input: { result: [26_803_196_617, 0.475] }, # (1)
          sources: [
            ['foo', 'raise "why"'],
            ['stdout', '@stdout_buffer = "googooo"'],
            ['bar', '@output = foo[:result]']
          ],
          instructions: nil, # (3)
          timeout: 10.0, # (4)
          instruction_quota: 100_000, # (5)
          instruction_quota_start: 1, # (6)
          memory_quota: 8 << 20 # (7)
        )
        ap result
      end

      it 'return true' do
        expect(subject).to eq true
      end

      it 'create the specific key' do
        expect(redis.exists(key)).to eq 1
      end

      it 'change the ip to new_ip' do
        expect(redis.hget(key, :ip)).to eq new_ip
      end

      it 'is a member of specific key' do
        expect(redis.sismember(logging_ip_key(new_ip), entry.id)).to eq true
      end

      it 'is not a member of old key' do
        expect(redis.sismember(logging_ip_key(@original_ip), entry.id)).to eq false
      end

      it 'append id into the "entries" list' do
        ids = redis.lrange(logging_entries_key, 0, -1)
        expect(entry.id.in?(ids)).to eq true
      end

      it 'will append id once' do
        ids = redis.lrange(logging_entries_key, 0, -1)
        expect(ids.length).to eq ids.uniq.length
      end
    end
  end

  private

  def default_params
    # {
    #   class: 'Dog',
    #   code: '',
    #   hint: 'Just for test',
    #   method: 'bark'
    # }
    {
      "name": 'test',
      "statements": [
        {
          "class": 'CompanyNote',
          "code": 'args.first',
          "variable": '是大理解的撒',
          "method": 'keys'
        }
      ]
    }
    # { \"statements\": [ { \"class\": 'CompanyNote', \"code\": 'output = args.first', \"hint\": '是大理解的撒', \"method\": 'keys' } ] }
  end

  def logging_ip_key(ip)
    "#{script_manager.send(:prefix)}:#{script_manager.send(:ip_entry_key_identifier)}:#{ip}"
  end

  def logging_entries_key
    "#{script_manager.send(:prefix)}:#{script_manager.send(:entries_key_identifier)}"
  end
end
