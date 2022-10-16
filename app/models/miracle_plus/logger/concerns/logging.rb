# frozen_string_literal: true

module MiraclePlus
  module Logger
    module Concerns
      module Logging
        extend ActiveSupport::Concern

        included do
          include Loggable

          if respond_to?(:after_initialize)
            after_initialize :enable_tracking
          else
            def self.new(*args, &blk)
              entity = allocate
              entity.send(:initialize, *args, &blk)
              entity.send(:enable_tracking)
              entity
            end
          end
          after_validation :logging_errors if respond_to?(:after_validation)

          private

          def need_tracking?
            RequestStore.store[:need_tracking]
          end

          def enable_tracking
            return unless need_tracking?

            origin_entries = RequestStore.store[:entries]
            klass = self.class
            entries = origin_entries.filter do |e|
                        result = e['statements'].any? { |s| s['class'] == klass.to_s }
                        result &&
                          e['statements'].select! { |s| s['class'] == klass.to_s && s.merge!(uid: e[:id]).present? }
                        result
                      end
            return unless entries.present?

            klass.class_eval do
              def metaclass
                class << self; self; end
              end
            end
            capture_methods = entries.map { |e| e['statements'] }
                                     .flatten
                                     .group_by { |e| e['method'] }
                                     .with_indifferent_access
            tracking_alias_method_prefix = :__origin_
            instance_eval do
              (klass.instance_methods(false) & capture_methods.keys.map(&:to_sym)).each do |name|
                alias_name = "#{tracking_alias_method_prefix}#{name}"
                next if respond_to?(alias_name)

                metaclass.send(:alias_method, alias_name, name)
                metaclass.define_method name do |*args|
                  result = send("#{tracking_alias_method_prefix}#{name}", *args)
                  io = { args: args, result: result }
                  begin
                    Timeout::timeout(10) do
                      capture_methods[name]
                        .group_by { |e| e['uid'] }
                        .each_pair do |uid, statements|
                          output = exec_in_transaction(statements, io)
                          trace('Injected', uid: uid, method: "#{klass}##{name}", output: output)
                        end
                    end
                  rescue StandardError => e
                    error('Injecting timeout.', error: e.message)
                  end
                end
              end
            end
          end

          # def exec(entry, io)
          #   content = entry['statements'].map do |statement|
          #     <<-RUBY
          #       @output[:#{statement['variable']}] = begin
          #         #{statement['code']}
          #       end
          #     RUBY
          #   end.join('')
          #   script = <<-RUBY
          #     args = io[:args]
          #     result = io[:result]
          #     @output = {}
          #     #{content}
          #   RUBY
          #   res = EnterpriseScriptService.run(
          #     input: io,
          #     sources: [
          #       # ['stdout', "@stdout_buffer = ''"],
          #       ['output', script]
          #     ],
          #     timeout: 10.0,
          #     instruction_quota: 100_000,
          #     instruction_quota_start: 1,
          #     memory_quota: 8 << 20
          #   )
          #   ap res
          #   res.output
          # end

          def exec_in_transaction(statements, io)
            content = statements.map do |statement|
              <<-RUBY
                output[:'#{statement['variable']}'] = begin
                  #{statement['code']}
                end
              RUBY
            end.join('')
            script = <<-RUBY
              args = io[:args]
              result = io[:result]
              output = {}
              #{content}
              output
            RUBY
            output = nil
            ActiveRecord::Base.transaction do
              output = eval(script)
              raise ActiveRecord::Rollback
            end
            output
          end

          def logging_errors
            return unless is_a?(ActiveRecord::Base) && errors.present?

            RequestStore.store[:errors].push(
              as_json(except: %i[deleted_at created_at updated_at]).compact.merge(errors: errors.as_json)
            )
          end
        end
      end
    end
  end
end
