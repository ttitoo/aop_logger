# frozen_string_literal: true

require 'socket'

module MiraclePlus
  module Logger
    class Wrapper
      attr_reader :logger

      def initialize
        @logger = begin
          log = Ougai::Logger.new("#{Rails.root}/log/#{Socket.gethostname}.log")
          log.default_message = '<no content>'
          log.sev_threshold = Ougai::Logger::TRACE
          log.level = Ougai::Logger::TRACE
          log.formatter = MiraclePlus::Logger::Formatter.new
          log
        end
      end

      def pop(with_fields = {})
        child = @logger.child
        child.with_fields = with_fields.compact
        child
      end
    end
  end
end
