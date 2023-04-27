# frozen_string_literal: true
# 用途1：ScriptsManager 是管理前端资源文件。
# 用途2：把 Entry 存到 Redis 里（而不是数据库里）
# require 'singleton'

module MiraclePlus
  module Logger
    class ScriptsManager
      extend MiraclePlus::StatementChecker
      include Singleton
      include Loggable

      # 只有编辑(update) 和 删除(destroy) Entry 的功能。
      ACTIONS = %i[update destroy].freeze

      def self.init_scripts
        scripts = Hash[
          ACTIONS.map do |action|
            sha = restore_script(action)
            [action, sha]
          end
        ]
        Redis.hset('scripts', *scripts)
      end

      def self.redis_assets_key
        'logging:assets'
      end

      def self.assets
        Redis.lrange(redis_assets_key, 0, -1)
      end

      def self.locate_assets
        key = redis_assets_key
        Redis.del(key)
        folder = File.join(MiraclePlus::Logger::Engine.root, 'dist')
        locate = lambda do
          Dir.glob("#{folder}/logging-*").each do |file|
            filename = File.basename(file)
            Redis.lpush(key, filename)
            dst = File.join(Rails.root, 'public', 'assets', filename)
            next if File.exist?(dst)

            FileUtils.copy_file(file, dst, true)
          end
        end
        if Rails.env.development? && !Dir.exist?(folder)
          fork do
            system("cd #{MiraclePlus::Logger::Engine.root};yarn install > /dev/null 2>&1; yarn run build > /dev/null 2>&1")
            locate.call
          end
        else
          locate.call
        end
      end

      def self.subscribe_expiration
        Thread.new do
          SubRedis.psubscribe("__keyevent@#{MiraclePlus::Logger::RedisDatabaseIndex}__:expired") do |on|
            on.pmessage do |_pattern, _channel, key|
              identifier, ip, id = key.split(':')
              identifier == 'expire' &&
                exec(:destroy, argv: [ip, id])
            end
          end
        end
      end

      def self.restore_script(action)
        Redis.script('load', instance.send("script_#{action}"))
      end

      def self.ensure_action_legal(action)
        return unless ACTIONS.index(action).nil?

        raise(ArgumentError, 'Illegal script action.')
      end

      def self.exec(action, args)
        ensure_action_legal(action)
        action.to_sym == :create &&
          ensure_statements_valid(JSON.parse(args[:argv].last)['statements'])

        sha = Redis.hget('scripts', action)
        restore_script(action) unless sha.present? && Redis.script('exists', sha)
        Redis.evalsha(sha, args) == 'success'
      rescue StandardError => e
        e.message
      end

      def entry_key_namespace
        "#{prefix}:#{entry_key_identifier}"
      end

      def prefix
        'logging'
      end

      def entry_key_identifier
        'entry'
      end

      def ip_entry_key_identifier
        'ip'
      end

      def entries_key_identifier
        'entries'
      end

      # 需要的参数:
      # * id
      # * ip

      # 1. 给指定的entry_key赋值(Hashes)
      # 2. 给指定entry_key设置过期时间
      # 3.
      def script_update
        <<-LUA
          -- local payload = {}
          -- local dict = cjson.decode(ARGV[3])
          -- print(dict)
          -- for key, value in pairs(dict) do
          --   table.insert(payload, key)
          --   table.insert(payload, value)
          -- end
          local entry_key = "#{prefix}:#{entry_key_identifier}:"..ARGV[2]
          if (redis.call('EXISTS', entry_key))
          then
            local ip = redis.call('HGET', entry_key, 'ip')
            if ip == false or ip ~= ARGV[1]
            then
              redis.call('HSET', entry_key, 'ip', ARGV[1])
              local ip_entries_key_prefix = "#{prefix}:#{ip_entry_key_identifier}:"
              if ip ~= false then
                if redis.call('SISMEMBER', ip_entries_key_prefix..ip, ARGV[2]) == 1
                then
                  redis.call('SREM', ip_entries_key_prefix..ip, ARGV[2])
                end
              end
              redis.call('SADD', ip_entries_key_prefix..ARGV[1], ARGV[2])
            end
          end
          redis.call('HSET', entry_key, 'payload', ARGV[3])
          redis.call('SET', 'expire:'..ARGV[1]..':'..ARGV[2], 1, 'EX', 3600 * 7)

          if (redis.call('LPOS', "#{prefix}:#{entries_key_identifier}", ARGV[2]) or '') == ''
          then
            redis.call('RPUSH', "#{prefix}:#{entries_key_identifier}", ARGV[2])
          end
          return 'success'
        LUA
      end

      def script_destroy
        <<-LUA
          local entry_key = "#{prefix}:#{entry_key_identifier}:"..ARGV[2]
          if (redis.call('EXISTS', entry_key))
          then
            local ip = redis.call('HGET', entry_key, 'ip')
            if ip == ARGV[1]
            then
              local ip_entries_key_prefix = "#{prefix}:#{ip_entry_key_identifier}:"
              redis.call('LREM', "#{prefix}:#{entries_key_identifier}", 0, ARGV[2])
              redis.call('SREM', ip_entries_key_prefix..ip, ARGV[2])
              redis.call('DEL', entry_key)
            end
          end

          return 'success'
        LUA
      end
    end
  end
end
