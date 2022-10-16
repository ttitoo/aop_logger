# frozen_string_literal: true

module MiraclePlus
  module Logger
    module Entries
      module Crud
        def show
          Redis.hgetall(entry_key(@id))
        end

        def persist(payload)
          ScriptsManager.exec(:update, argv: [@ip, @id, payload.to_json])
        end

        def destroy
          ScriptsManager.exec(:destroy, argv: [@ip, @id])
        end

        private

        def next_id(ip = nil)
          @hashids ||= Hashids.new('logging-context-entry')
          @hashids.encode((ip || @ip).split('.').concat(DateTime.current.to_f.to_s.split('.').map(&:to_i)))
        end

        def prepare_data(params)
          {}
        end
      end
    end
  end
end
