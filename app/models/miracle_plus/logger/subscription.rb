# frozen_string_literal: true

module MiraclePlus
  module Logger
    class Subscription
      def self.subscribe(_app)
        ActiveSupport::Notifications.subscribe('process_action.action_controller') do |_name, _started, _finished, _unique_id, data|
          json = base_json(data)
          if data.key?(:exception) && data.key?(:exception_object)
            json.merge!(prepare_exception_json(data))
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

      def self.prepare_exception_json(data)
        prefix = "#{Rails.root}/"
        {
          status: ActionDispatch::ExceptionWrapper.status_code_for_exception(data[:exception].first),
          error: {
            exception: data[:exception].first,
            message: data[:exception].last,
            backtrace: data[:exception_object].backtrace.map do |e|
              next if %w[/gems/ruby /mp_logger/lib/miracle_plus/logger/context_middleware].any? { |s| e.index(s) }

              e.remove(prefix)
            end.compact
          }
        }
      end
      private_class_method :prepare_exception_json
    end
  end
end
