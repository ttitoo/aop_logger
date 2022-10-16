# frozen_string_literal: true

module MiraclePlus
  module Logger
    module Entries
      module Script
        ACTIONS = %i[update].freeze

        def self.init_scripts
          @scripts = Hash[
            ACTIONS.map do |action|
              sha = restore_script(action)
              info("Script '#{action}' is loaded as: #{sha}")
              [action, sha]
            end
          ]
        end

        def self.restore_script(action)
          Redis.script('load', send("script_#{action}"))
        end

        def entry_key_identifier
          'entry'
        end

        def ip_entry_key_identifier
          'ip'
        end

        protected

        def exec(action, args)
          ensure_action_legal(action)

          sha = @scripts[action]
          restore_script(action) unless sha.present? && Redis.script('exists', sha)
          Redis.evalsha(sha, args) == 'success'
        end

        private

        # 需要的参数:
        # * id
        # * ip

        # 1. 给指定的entry_key赋值(Hashes)
        # 2. 给指定entry_key设置过期时间
        # 3.
        def script_update
          <<-LUA
            local payload = {}
            local dict = cjson.decode(ARGV[3])
            for key, value in pairs(dict) do
              table.insert(payload, key)
              table.insert(payload, value)
            end
            local entry_key = "#{prefix}:#{entry_key_identifier}:"..ARGV[2]
            if (redis.call('EXISTS', entry_key))
            then
              local ip = redis.call('HGET', entry_key, 'ip')
              if ip ~= false and ip ~= ARGV[1]
              then
                local ip_entries_key_prefix = "#{prefix}:#{ip_entry_key_identifier}:"
                if redis.call('SISMEMBER', ip_entries_key_prefix..ip, ip)
                then
                  redis.call('SREM', ip_entries_key_prefix..ip, ip)
                end
                redis.call('SADD', ip_entries_key_prefix..ARGV[1], ARGV[2])
              end
            end
            redis.call('HSET', entry_key, unpack(payload))
            redis.call('EXPIRE', entry_key, 600)

            if !redis.call('SISMEMBER', "#{ip_entries_key_prefix}:#{entries_key_suffix}", ARGV[2])
            then
              redis.call('SADD', "#{ip_entries_key_prefix}:#{entries_key_suffix}", ARGV[2])
            end

            return 'success'
          LUA
        end

        def ensure_action_legal(action)
          return unless ACTIONS.index(action).nil?

          raise(ArgumentError, 'Illegal script action.')
        end
      end
    end
  end
end
