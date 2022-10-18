# frozen_string_literal: true

module MiraclePlus
  module Logger
    module Concerns
      module ExceptionParser
        def exception_to_json(exception, append_status = true)
          prefix = "#{Rails.root}/"
          res = {
            error: {
              exception: exception.class.to_s,
              message: exception.message,
              backtrace: exception.backtrace.map do |e|
                next if %w[/gems/ruby /mp_logger/lib/miracle_plus/logger/context_middleware].any? { |s| e.index(s) }

                e.remove(prefix)
              end.compact
            }
          }
          append_status &&
            res[:status] = ActionDispatch::ExceptionWrapper.status_code_for_exception(exception.class)

          res
        end
      end
    end
  end
end
