# frozen_string_literal: true

require 'socket'
require_relative './formatter'

module MiraclePlus
  module Logger
    class Wrapper
      attr_reader :logger

      def initialize
        @logger = begin
          std = Ougai::Logger.new(logger_dst)
          std.default_message = '<no content>'
          std.sev_threshold = Ougai::Logger::TRACE
          std.level = Ougai::Logger::TRACE
          std.formatter = MiraclePlus::Logger::Formatter.new
          std
        end
      end

      def pop(with_fields = {})
        child = @logger.child
        child.with_fields = with_fields.compact
        child
      end

      private

      def logger_dst
        Rails.env.production? ? $stdout : "#{Rails.root}/log/#{Socket.gethostname}.log"
      end
    end
  end
end
