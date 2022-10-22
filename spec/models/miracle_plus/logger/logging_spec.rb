# frozen_string_literal: true

require 'rails_helper'

ActiveRecord::Base.logger = Logger.new(STDOUT)

RSpec.describe MiraclePlus::Logger::Concerns::Logging, type: :model do
  let(:io) do
    {
      args: [1, 2, 3],
      result: 10
    }
  end
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

  describe '#exec_in_transaction' do
    let(:instance) do
      Class.new do
        include MiraclePlus::Logger::Concerns::Logging
      end.new
    end
    subject do
      instance.send(:exec_in_transaction, statements, io)
    end

              # File.delete("#{Rails.root}/tmp/" + '1.test')
              # Kernel.raise('')
              # Dir.empty?("#{Rails.root}/tmp")
              # proc { `ls #{Rails.root}/tmp` }.call
              # ap `ls #{Rails.root}/tmp` && a = args.first
              # ap `ls ./`; b = args.last

    context 'when contains rm command' do
      let(:file) { "#{Rails.root}/tmp/1.test" }
      let(:statements) do
        [
          {
            variable: 'name',
            code: <<-RUBY
              %x|ls|
              a = 100
              result * a
            RUBY
          }.with_indifferent_access
        ]
      end

      it 'will not delete the file' do
        FileUtils.touch(file)
        ap File.file?(file)
        ap subject
        ap File.file?(file)
        expect(File.file?(file)).to eq(true)
      end
    end
  end
end
