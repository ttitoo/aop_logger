# Patch the Rails::Server log_to_stdout so that it logs via SemanticLogger
require "rails"

Rails::Server.class_eval do
  private

  def log_to_stdout
    wrapped_app # touch the app so the logger is set up

    # SemanticLogger.add_appender(io: $stdout, formatter: :color) unless SemanticLogger.appenders.console_output?
    # byebug
    nil
  end
end
