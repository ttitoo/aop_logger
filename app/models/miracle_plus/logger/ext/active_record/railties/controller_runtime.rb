# frozen_string_literal: true

module ActiveRecord
  module Railties # :nodoc:
    module ControllerRuntime # :nodoc:

      private
        def cleanup_view_runtime
          # byebug
          if logger && logger.info? && ActiveRecord::Base.connected?
            db_rt_before_render = ActiveRecord::LogSubscriber.reset_runtime
            self.db_runtime = (db_runtime || 0) + db_rt_before_render
            runtime = super
            db_rt_after_render = ActiveRecord::LogSubscriber.reset_runtime
            self.db_runtime += db_rt_after_render
            runtime - db_rt_after_render
          else
            super
          end
        end
    end
  end
end
