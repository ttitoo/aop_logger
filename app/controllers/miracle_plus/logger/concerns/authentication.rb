# frozen_string_literal: true
# 这个是鉴权用的，如果没有登录则会抛出异常，如果有登录则会调用自定义的 MiraclePlus::Logger::Authorize 方法，如果返回 true 则表示有权限，否则抛出异常。

module MiraclePlus
  module Logger
    module Concerns
      module Authentication
        extend ActiveSupport::Concern

        included do
          # 如果出错权限不足，返回一个 json 包含错误信息。
          rescue_from MiraclePlus::Logger::Errors::AuthorizationError do |e|
            render json: { error: e.message }
          end

          before_action :check_authorization

          private

          def check_authorization
            # 判断是否有自定义的 MiraclePlus::Logger::Authorize 方法，而且类型必须是 Proc，如果没有则抛出异常。
            raise(MiraclePlus::Logger::Errors::AuthorizationError, 'No authorization set.') unless Object.const_defined?('MiraclePlus::Logger::Authorize') && MiraclePlus::Logger::Authorize.is_a?(Proc)

            # 调用自定义的 MiraclePlus::Logger::Authorize 方法，如果返回 true 则表示有权限，否则抛出异常。
            return if MiraclePlus::Logger::Authorize.call(current_user)
            raise(MiraclePlus::Logger::Errors::AuthorizationError, '您未登录')
          end
        end
      end
    end
  end
end
