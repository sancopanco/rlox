module Lox
  module Stmt
    class Function < Statement
      attr_reader :name, :params, :body
      def initialize(name, params, body)
        @name = name
        @params = params
        @body = body
      end

      def accept(visitor)
        visitor.visit_function_decleration_stmt(self)
      end
    end
  end
end
