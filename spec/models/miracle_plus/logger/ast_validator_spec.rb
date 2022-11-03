# frozen_string_literal: true

require 'rails_helper'

ActiveRecord::Base.logger = Logger.new(STDOUT)

RSpec.describe MiraclePlus::Logger::AstValidator, type: :service do
  describe '#initialize' do
    context 'when code is nil' do
      it 'raise error' do
        expect { described_class.new(nil) } .to raise_error(ArgumentError)
      end
    end

    context 'when code is empty' do
      it 'raise error' do
        expect { described_class.new('') }.to raise_error(ArgumentError)
      end
    end

    context 'when code is present' do
      it 'create the instance' do
        expect { described_class.new('a = 1') }.not_to raise_error
      end
    end
  end

  describe '#illegal_operation?' do
    context 'when code contains shell command' do
      it 'raise InvalidStatementError' do
        expect { described_class.new('`ls /`').perform }.to raise_error(MiraclePlus::Logger::Errors::InvalidStatementError)
      end

      it 'raise InvalidStatementError' do
        expect { described_class.new('%x|ls /|').perform }.to raise_error(MiraclePlus::Logger::Errors::InvalidStatementError)
      end

      it 'raise InvalidStatementError' do
        expect { described_class.new("system('ls /')").perform }.to raise_error(MiraclePlus::Logger::Errors::InvalidStatementError)
      end
    end

    context 'when code contains kernel method' do
      it 'riase InvalidStatementError' do
        expect { described_class.new('fork { puts 1 }').perform }.to raise_error(MiraclePlus::Logger::Errors::InvalidStatementError)
      end

      it 'riase InvalidStatementError' do
        expect { described_class.new('raise 123').perform }.to raise_error(MiraclePlus::Logger::Errors::InvalidStatementError)
      end
    end

    context 'when code contains forbidden classes' do
      it 'riase InvalidStatementError' do
        expect { described_class.new("File.open('./log/test.log')").perform }.to raise_error(MiraclePlus::Logger::Errors::InvalidStatementError)
      end

      it 'riase InvalidStatementError' do
        expect { described_class.new("Kernel.raise('test')").perform }.to raise_error(MiraclePlus::Logger::Errors::InvalidStatementError)
      end
    end
  end
end
