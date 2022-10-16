# frozen_string_literal: true

module MiraclePlus
  module Logger
    class Entry
      include Loggable
      include Entries::List
      include Entries::Crud
      include Entries::Expire
      # include Entries::Script

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
