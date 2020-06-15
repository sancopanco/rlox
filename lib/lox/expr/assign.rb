module Lox
  module Expr
    class Assign < Expression
      attr_reader :name, :value

      def initialize(name, value)
        @name = name
        @value = value
      end

      def accept(visitor)
        visitor.visit_assign_expr(self)
      end
    end
  end
end
