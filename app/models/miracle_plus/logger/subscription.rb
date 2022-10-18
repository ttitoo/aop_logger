# frozen_string_literal: true

module MiraclePlus
  module Logger
    class Subscription
      def self.subscribe(_app)
        ActiveSupport::Notifications.subscribe('process_action.action_controller') do |_name, _started, _finished, _unique_id, data|
          path = data[:path].to_s.split('?').first
          json = data.as_json(only: %i[controller action format method status])
                     .merge(
                       path: path,
                       params: data[:params].as_json(except: %i[controller action format]),
                       view: data[:view_runtime]&.round,
                       db: data[:db_runtime]&.round
                     )
          RequestStore.store[:tracing] = json
        end
        ActiveSupport::Notifications.subscribe('process_action.action_controller') do |event|
          res = { allocations: event.allocations, duration: event.duration.round }
          res[:errors] = RequestStore.store[:errors] if RequestStore.store[:errors].present?
          RequestStore.store[:logging].info('Action statistics', RequestStore.store[:tracing].merge(res).compact)
        end
      end
    end
  end
end
