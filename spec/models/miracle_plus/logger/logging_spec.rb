# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MiraclePlus::Logger::Concerns::Logging, type: :model do
  describe '#initialize' do
    context 'when has no parameters' do
      subject do
        Class.new do
          include MiraclePlus::Logger::Concerns::Logging

          def initialize
            puts 'initialized'
          end
        end
      end

      it 'create the instance' do
        expect { subject.new }.not_to raise_error
      end
    end

    context 'when has hash parameters' do
      subject do
        Class.new do
          include MiraclePlus::Logger::Concerns::Logging

          def initialize(arg1:nil, arg2:nil)
            puts 'initialized'
          end
        end
      end

      it 'create the instance' do
        expect { subject.new }.not_to raise_error
      end
    end

    context 'when has array parameters' do
      subject do
        Class.new do
          include MiraclePlus::Logger::Concerns::Logging

          def initialize(payloads = [])
            puts 'initialized'
          end
        end
      end

      it 'create the instance' do
        expect { subject.new([1, 2, 3]) }.not_to raise_error
      end
    end
  end
end
