# frozen_string_literal: true

require 'socket'

module MiraclePlus
  module Logger
    class ContextMiddleware
      def initialize(app)
        @app = app
      end

      def call(env)
        user_id = current_user_id(env)
        entries = Entry.list(ip: env['REMOTE_ADDR'])
        ids = uniq_ids.prepend(user_id || 0)
        RequestStore.store = {
          need_tracking: entries.present?,
          entries: entries,
          logging: MiraclePlus::Logger::Instance.pop(track_id: hashids.encode(*ids), current_user_id: user_id),
          errors: []
        }

        @app.call(env)
      end

      private

      def redis
        MiraclePlus::Logger::Redis
      end

      def current_user(env)
        env['warden']&.user
      end

      def current_user_id(env)
        current_user(env).try(:id)
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
