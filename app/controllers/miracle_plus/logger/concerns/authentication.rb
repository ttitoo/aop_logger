# frozen_string_literal: true

module MiraclePlus
  module Logger
    module Concerns
      module Authentication
        extend ActiveSupport::Concern

        included do
          rescue_from MiraclePlus::Logger::Errors::AuthorizationError do |e|
            render json: { error: e.message }
          end

          before_action :check_authorization

          private

          def check_authorization
            raise(MiraclePlus::Logger::Errors::AuthorizationError, 'No authorization set.') unless Object.const_defined?('MiraclePlus::Logger::Authorize') && MiraclePlus::Logger::Authorize.is_a?(Proc)

            return if MiraclePlus::Logger::Authorize.call(current_user)

            raise(MiraclePlus::Logger::Errors::AuthorizationError, 'Authorization failed.')
          end
        end
      end
    end
  end
end
