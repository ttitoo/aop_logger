# frozen_string_literal: true

require 'socket'

module MiraclePlus
  module Logger
    class ContextMiddleware
      def initialize(app)
        @app = app
      end

      def call(env)
        current_user = current_user(env)
        entries = Entry.list(env['REMOTE_ADDR'])
        RequestStore.store[:need_tracking] = entries.present?
        RequestStore.store[:entries] = entries
        ids = uniq_ids.prepend(current_user.try(:id) || 0)
        RequestStore.store[:logging] =
          MiraclePlus::Logger::Instance.pop(track_id: hashids.encode(*ids), current_user_id: current_user.try(:id))

        @app.call(env)
      end

      private

      def redis
        MiraclePlus::Logger::Redis
      end

      def current_user(env)
        env['warden']&.user
      end

      def hashids
        @hashids ||= Hashids.new(Socket.gethostname, 12)
      end

      def uniq_ids
        DateTime.current
                .to_f
                .to_s
                .split('.')
                .prepend(Random.new.rand(1_000_000))
                .map(&:to_i)
      end
    end
  end
end
