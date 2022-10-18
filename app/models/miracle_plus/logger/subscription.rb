# frozen_string_literal: true

module MiraclePlus
  module Logger
    class Subscription
      extend Concerns::ExceptionParser

      def self.subscribe(_app)
        ActiveSupport::Notifications.subscribe('process_action.action_controller') do |_name, _started, _finished, _unique_id, data|
          json = base_json(data)
          if data.key?(:exception_object)
            json.merge!(exception_to_json(data[:exception_object]))
          elsif RequestStore.store[:errors].present?
            json.merge!(errors: RequestStore.store[:errors])
          end
          RequestStore.store[:tracing] = json
        end
        ActiveSupport::Notifications.subscribe('process_action.action_controller') do |event|
          RequestStore.store[:tracing].merge!(allocations: event.allocations, duration: event.duration.round)
          action = %i[error errors].any? { |key| RequestStore.store[:tracing][key].present? } ? :error : :info
          RequestStore.store[:logging].send(action, :Statistics, RequestStore.store[:tracing])
        end
      end

      def self.base_json(data)
        data
          .as_json(only: %i[controller action format method status])
          .merge(
            path: data[:path].to_s.split('?').first,
            params: data[:params].as_json(except: %i[authenticity_token controller action format]),
            view: data[:view_runtime]&.round || 0, # will be nil if 30X redirect
            db: data[:db_runtime]&.round
          )
      end
    end
  end
end
