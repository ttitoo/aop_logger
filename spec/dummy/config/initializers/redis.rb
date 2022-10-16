# frozen_string_literal: true

return unless Rails.env.test?

ENV['REDIS_HOST'] = 'dev-redis'
ENV['REDIS_PORT'] = '6379'
ENV['REDIS_PASSWORD'] = '4cd018b7ad0ce698d02494542e8f6e70'
ENV['REDIS_LOGGING_DB_INDEX'] = '12'
