# frozen_string_literal: true

require 'socket'

module MiraclePlus
  module Logger
    module Loggable
      %i[trace debug info warning error fatal].each do |name|
        define_method name do |msg, context = {}|
          get_logger.send(name, msg, with_tracking(context))
        end
      end

      private

      def with_tracking(context)
        if RequestStore.store[:logging].try(:key?, :track_id)
          context[:track_id] = RequestStore.store[:logging][:track_id]
        end

        context
      end

      def get_logger
        # RequestStore.store[:logging] || MiraclePlus::Logger::LoggerWrapper.new.pop
        RequestStore.store[:logging] || MiraclePlus::Logger::Wrapper.new.pop
      end
    end
  end
end
