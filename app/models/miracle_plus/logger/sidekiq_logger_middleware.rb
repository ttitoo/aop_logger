# frozen_string_literal: true

module MiraclePlus
  module Logger
    class SidekiqLoggerMiddleware
      include Loggable
      include Concerns::ExceptionParser

      # @param [Object] worker the worker instance
      # @param [Hash] job the full job payload
      #   * @see https://github.com/mperham/sidekiq/wiki/Job-Format
      # @param [String] queue the name of the queue the job was pulled from
      # @yield the next middleware in the chain or worker `perform` method
      # @return [Void]
      def call(worker, job, queue)
        start_ts = DateTime.current.to_f
        yield
        stop_ts = DateTime.current.to_f
        info(
          'Job success',
          payload: job,
          queue: queue,
          duration: ((stop_ts - start_ts) * 1000).round
        )
      rescue StandardError => e
        error(
          'Job failure',
          {
            payload: job,
            queue: queue
          }.merge(exception_to_json(e, false))
        )
        MiraclePlus::Logger::Callbacks.sidekiq.error.is_a?(Proc) &&
          MiraclePlus::Logger::Callbacks.sidekiq.error.call(e)
      end
    end
  end
end
