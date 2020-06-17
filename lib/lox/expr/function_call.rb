module Lox
  module Expr
    # It storeds the callee expresion and a list od expresions for the arguments
    # It also stored the token for closing paren -- will be used to report runtime
    # error caused by function call
    class FunctionCall < Expression
      attr_reader :callee, :paren_token, :arguments

      def initialize(callee, paren_token, arguments)
        @callee = callee
        @paren_token = paren_token
        @arguments = arguments
      end

      def accept(visitor)
        visitor.visit_function_call_expr(self)
      end
    end
  end
end
