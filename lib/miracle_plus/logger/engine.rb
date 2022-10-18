# frozen_string_literal: true

require 'hashids'
require 'ougai'
require 'redis'
require 'request_store'
# require 'enterprise_script_service'
require_relative './context_middleware'
require_relative './wrapper'

module MiraclePlus
  module Logger
    class Engine < ::Rails::Engine
      isolate_namespace MiraclePlus::Logger

      rake_env = defined?(Rake) && Rake.application.top_level_tasks.present?
      config.app_middleware.insert_after(Warden::Manager, MiraclePlus::Logger::ContextMiddleware) unless Rails.env.test?
      initializer :initialize_logging_redis do |_app, args|
        MiraclePlus::Logger::Instance = MiraclePlus::Logger::Wrapper.new

        unless rake_env
          MiraclePlus::Logger::Redis =  if Object.const_defined?('MiraclePlus::RedisManager')
                                          MiraclePlus::RedisManager.instance.get(:cache)
                                        else
                                          host = ENV['REDIS_HOST']
                                          port = ENV['REDIS_PORT']
                                          password = ENV['REDIS_PASSWORD']
                                          db_index = ENV['REDIS_LOGGING_DB_INDEX'] || 12
                                          url = "redis://#{password.present? ? ":#{password}@" : ''}#{host}:#{port}/#{db_index}"
                                          Redis.new(driver: :hiredis, url: url)
                                        end
        end
      end
      # initializer :cors do
      # end
      config.after_initialize do |app|
        # mount routes
        Rails.application.routes.append do
          mount MiraclePlus::Logger::Engine => '/logging'
        end

        unless rake_env
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
          MiraclePlus::Logger::ScriptsManager.init_scripts
        end
      end
    end
  end
end
