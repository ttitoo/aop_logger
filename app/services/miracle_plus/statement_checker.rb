# frozen_string_literal: true

module MiraclePlus
  module StatementChecker
    def ensure_statements_valid(statements)
      statements.each do |statement|
        ensure_variable_names_legal(statement['variable'])
        ensure_method_valid(statement['class'], statement['method'])
      end
    end

    def ensure_variable_names_legal(name)
      return if legal_variable_name?(name)

      raise(ArgumentError, "Invalid variable name: #{name}")
    end

    def ensure_method_valid(class_name, method_name)
      MiraclePlus::Logger::Redis.sismember('logging:targets', class_name)
      return if class_name.constantize.instance_methods(false).include?(method_name.to_sym)

      raise(ArgumentError, "Invalid or invisible method: #{class_name}##{method_name}")
    end

    def ensure_code_valid(code)
      AstValidator.new(code).perform
    end
  end
end
