# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MiraclePlus::Logger::ScriptsManager, type: :model do
  before(:each) do
    MiraclePlus::Logger::Redis.script 'flush'
  end
  let(:ip) { '127.0.0.1' }
  subject(:manager) { described_class.instance }
  let(:redis) { MiraclePlus::Logger::Redis }

  describe '.init_scripts' do
    subject! do
      manager.init_scripts
    end

    context 'when scripts initialized' do
      it 'generates instance variable "scripts"' do
        expect(manager.instance_variable_get('@scripts')).not_to be_nil
      end

      it 'loads scripts into redis' do
        manager.instance_variable_get('@scripts').each_value do |sha|
          expect(MiraclePlus::Logger::Redis.script('exists', sha)).to eq true
        end
      end
    end
  end
end
