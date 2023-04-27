# frozen_string_literal: true
# 用途：一个 Entry 代表用户在 /logging 页面点击"添加"按钮后，加上的一组要追踪的代码。

module MiraclePlus
  module Logger
    class Entry
      extend Entries::List

      include Loggable
      include Entries::Crud

      attr_reader :ip, :id

      def initialize(ip, id)
        @ip = ip
        send(:uid=, id)
      end

      def entry_key_namespace
        ScriptsManager.instance.entry_key_namespace
      end

      private

      def uid=(id)
        @id = id || next_id(ip)
      end
    end
  end
end
