# frozen_string_literal: true

module MiraclePlus
  module Logger
    class SidekiqLoggerMiddleware
      include Concerns::Loggable
      include Concerns::ExceptionParser

      # @param [Object] worker the worker instance
      # @param [Hash] job the full job payload
      #   * @see https://github.com/mperham/sidekiq/wiki/Job-Format
      # @param [String] queue the name of the queue the job was pulled from
      # @yield the next middleware in the chain or worker `perform` method
      # @return [Void]
      def call(worker, job, queue)
        yield
        info('Job done', worker: worker.class.to_s, payload: job, queue: queue)
      rescue StandardError => e
        error(
          'Error occured during sidekiq job',
          {
            worker: worker.class.to_s,
            payload: job,
            queue: queue
          }.merge(exception_to_json(e, false))
        )
      end
    end
  end
end
