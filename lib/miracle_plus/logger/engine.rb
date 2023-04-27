# frozen_string_literal: true
# 用途：

require 'hashids'
require 'ougai'
require 'redis'
require 'request_store'
require 'parser/current'
require_relative './context_middleware'
require_relative './wrapper'

module MiraclePlus
  module Logger
    class Engine < ::Rails::Engine
      isolate_namespace MiraclePlus::Logger

      MiraclePlus::Logger::Callbacks = OpenStruct.new(
        sidekiq: OpenStruct.new(error: nil, success: nil)
      )

      # 检查是不是 Rake 命令。
      rake_env = defined?(Rake) && Rake.try(:application).try(:top_level_tasks).present?
      
      # 插入中间层。
      config.app_middleware.insert_after(Warden::Manager, MiraclePlus::Logger::ContextMiddleware) unless Rails.env.test?
      
      initializer :initialize_logging_redis do |_app, args|
        MiraclePlus::Logger::Instance = MiraclePlus::Logger::Wrapper.new

        unless rake_env
          create_redis = lambda do
            if Object.const_defined?('MiraclePlus::RedisManager')
              MiraclePlus::RedisManager.instance.get(:cache)
            else
              host = ENV['REDIS_HOST']
              port = ENV['REDIS_PORT']
              password = ENV['REDIS_PASSWORD']
              db_index = ENV['REDIS_LOGGING_DB_INDEX'] || MiraclePlus::Logger::RedisDatabaseIndex
              url = "redis://#{password.present? ? ":#{password}@" : ''}#{host}:#{port}/#{db_index}"
              ::Redis.new(driver: :hiredis, url: url)
            end
          end
          MiraclePlus::Logger::Redis = create_redis.call
          MiraclePlus::Logger::SubRedis = create_redis.call
          MiraclePlus::Logger::RedisDatabaseIndex = MiraclePlus::Logger::Redis.try(:database_index) || 15
        end
      end

      # 初始化后
      config.after_initialize do |app|
        # 把路径挂载上去。
        Rails.application.routes.append do
          mount MiraclePlus::Logger::Engine => '/logging'
        end

        unless rake_env
          defined?(Sidekiq) &&
            Sidekiq.configure_server do |config|
              config.logger = ::Logger.new('/dev/null')
              config.server_middleware do |chain|
                chain.add(MiraclePlus::Logger::SidekiqLoggerMiddleware)
              end
            end

          Object.include(MiraclePlus::Logger::Loggable)
          # [ActiveRecord::Base, ActionController::API, ActionController::Base].each do |klass|
          #   klass.include(MiraclePlus::Logger::Loggable)
          # end
          # Object.include(MiraclePlus::Logger::Concerns::Logging)
          ActiveRecord::Base.include(MiraclePlus::Logger::Concerns::Logging)

          MiraclePlus::Logger::Subscription.subscribe(app)

          MiraclePlus::Logger::Redis.del('logging:targets')
          # TODO: dirs可设置
          dirs = %w[models services]
          targets = dirs.map do |dir|
            prefix = "#{Rails.root}/app/#{dir}"
            Dir.glob("#{prefix}/**/*.rb").map do |file|
              file.delete_prefix("#{prefix}/")
                  .delete_prefix('concerns/')
                  .delete_suffix('.rb')
                  .camelize
                  .to_s
            end
          end.flatten
          targets.select! do |name|
            klass = name.constantize
            enable = klass.respond_to?(:superclass)
            klass.include(MiraclePlus::Logger::Concerns::Logging) if enable
            enable
          end
          MiraclePlus::Logger::Redis.sadd('logging:targets', targets)
          MiraclePlus::Logger::ScriptsManager.locate_assets
          MiraclePlus::Logger::ScriptsManager.init_scripts
          MiraclePlus::Logger::ScriptsManager.subscribe_expiration
        end
      end
    end
  end
end
