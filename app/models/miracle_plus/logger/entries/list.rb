# frozen_string_literal: true

module MiraclePlus
  module Logger
    module Entries
      module List
        def list(page: 1, per: 15, ip: nil)
          ids = ip.nil? ? Redis.lrange(entries_key, (page - 1) * per, page * per) : Redis.smembers(ip_entries_key(ip))
          fetch_detail(ids)
        end

        def fetch_detail(ids)
          ids.map do |id|
            res = Redis.hgetall(entry_key(id))
            next if res.empty?

            res.merge!(JSON.parse(res['payload'])).delete('payload')
            res.merge(id: id)
          end.compact
        end

        def entry_key(id)
          manager = ScriptsManager.instance
          "#{manager.send(:prefix)}:#{manager.send(:entry_key_identifier)}:#{id}"
        end

        # def target_entity
        #   Entry.new('', '')
        # end
        # private_class_method :target_entity

        def entries_key
          manager = ScriptsManager.instance
          "#{manager.send(:prefix)}:#{manager.send(:entries_key_identifier)}"
        end

        def ip_entries_key(ip)
          manager = ScriptsManager.instance
          "#{manager.send(:prefix)}:#{manager.send(:ip_entry_key_identifier)}:#{ip}"
        end
      end
    end
  end
end
