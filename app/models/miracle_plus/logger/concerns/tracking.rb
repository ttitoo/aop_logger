# frozen_string_literal: true

module MiraclePlus
  module Logger
    module Concerns
      module Tracking
        extend ActiveSupport::Concern

        included do
          klass.define_singleton_method(:tracking_alias_method_prefix) { :__origin_ }
          klass.define_singleton_method(:tracking_methods_for) { [] }
          klass.define_singleton_method(:transform_to_readable_tracking_result) do |object|
            if object.is_a?(Array)
              object.map { |obj| get_identifier(obj) }
            elsif object.is_a?(Hash)
              Hash[object.keys.map { |key| [key, transform_to_readable_tracking_result(object[key])] }]
            elsif object.is_a?(ActiveRecord::Base)
              klass = object.class
              "#{klass}##{object.send(klass.primary_key)}"
            else
              object.as_json
            end
            object
          end

          # (klass.instance_methods & %i[stage]).each do |name|
          tracking_methods_for(klass).each do |name|
            klass.send(:alias_method, "#{klass.tracking_alias_method_prefix}#{name}", name)
            klass.define_method name do |*args|
              result = send("#{klass.tracking_alias_method_prefix}#{name}", *args)
              trace("Logging after #{name}", {
                method: "#{klass}##{name}",
                args: args,
                result: klass.transform_to_readable_tracking_result(result)
              })
              result
            end
          end
        end
      end
    end
  end
end
