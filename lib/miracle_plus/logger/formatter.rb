# frozen_string_literal: true
# 用途：做 JSON 转换的。
# Ougai 一句话介绍就是处理 JSON 格式的 (https://github.com/tilfin/ougai)

class MiraclePlus::Logger::Formatter < Ougai::Formatters::Base
  include Ougai::Formatters::ForJson

  # Intialize a formatter
  # @param [String] app_name application name (execution program name if nil)
  # @param [String] hostname hostname (hostname if nil)
  # @param [Hash] opts the initial values of attributes
  # @option opts [String] :trace_indent (2) the value of trace_indent attribute
  # @option opts [String] :trace_max_lines (100) the value of trace_max_lines attribute
  # @option opts [String] :serialize_backtrace (true) the value of serialize_backtrace attribute
  # @option opts [String] :jsonize (true) the value of jsonize attribute
  # @option opts [String] :with_newline (true) the value of with_newline attribute
  def initialize(app_name = nil, hostname = nil, opts = {})
    aname, hname, opts = Ougai::Formatters::Base.parse_new_params([app_name, hostname, opts])
    super(aname, hname, opts)
    init_opts_for_json(opts)
  end

  def _call(severity, time, progname, data)
    dump({
      name: progname || @app_name,
      hostname: @hostname,
      pid: $PID,
      level: to_level(severity),
      time: time
    }.merge(data))
  end

  # 日期格式转换。
  def convert_time(data)
    data[:time] = format_datetime(data[:time])
  end
end

