# frozen_string_literal: true
# 用途：把传进来的代码用 AST(abstract syntax tree) 分析，把危险的操作删除掉。

module MiraclePlus
  module Logger
    class AstValidator
      AstPayload = Struct.new(:type, :ext)

      def initialize(code)
        raise('Empty snippet') if code.blank?

        @node = Parser::CurrentRuby.parse(code)
      rescue StandardError => e
        raise(ArgumentError, e.message)
      end

      # will raise exception if invalid
      def perform
        illegal_operation?(@node)
      end

      protected

      def targets
        @targets = %i[
          kernel_method?
          shell_command?
          blacklisted?
        ]
      end

      private

      def check_nodes(nodes)
        nodes.any? { |node| illegal_operation?(node) }
      end

      def true?
        @blk = ->(val) { val }
      end

      def illegal_operation?(node)
        return unless node.is_a?(Parser::AST::Node)

        payload = AstPayload.new(node.send(:fancy_type), node.children[1])
        if (result = targets.map { |name| send(name, payload) }).any?(&true?)
          raise(MiraclePlus::Logger::Errors::InvalidStatementError, error_message(targets[result.index(&true?)][0..-2]))
        end

        node.respond_to?(:children) && check_nodes(node.children)
      end

      def shell_command?(payload)
        payload.type.in?(%w[xstr])
      end

      def kernel_method?(payload)
        (payload.type == 'send' && payload.ext.in?(Kernel.methods)) ||
          payload.type == 'const' && payload.ext.in?(%i[Kernel])
      end

      def blacklisted?(payload)
        payload.type == 'const' &&
          payload.ext.in?(%i[
                            PTY
                            Open3
                            IO
                            File
                            FileUtils
                            Dir
                            Net::HTTP
                          ])
      end

      def error_message(error)
        I18n.t(error, scope: %i[mp_logger errors code])
      end
    end
  end
end
