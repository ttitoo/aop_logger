# frozen_string_literal: true

module MiraclePlus
  module Logger
    class LoggingController < ActionController::Base
      protect_from_forgery except: :index

      def index; end

      def targets
        MiraclePlus::Logger::Redis.get('logging')
        render json: {
          targets: MiraclePlus::Logger::Redis.smembers('logging:targets')
        }
      end

      def candidates
        class_name = params.require(:target)
        res = if MiraclePlus::Logger::Redis.sismember('logging:targets', class_name)
                target = class_name.constantize
                {
                  candidates: target.instance_methods(false)# - target.superclass.send(:instance_methods)
                }
              else
                { error: 'Illegal target class.' }
              end
        render json: res
      end
    end
  end
end
