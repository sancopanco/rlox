module Lox
  module Expr
    module Visitor
      # def visit(subject)
      #   method_name = "visit_#{subject.class}".to_sym
      #   send(method_name, subject)
      # end

      def visit_binary_expr(expr_left, expr_right); end

      def visit_grouping_expr(expr); end

      def visit_literal_expr(expr); end

      def visit_unary_expr(expr); end

      def accept(visitor); end
    end

    class Expression
    end

    require_relative 'literal'
    require_relative 'binary'
    require_relative 'unary'
    require_relative 'grouping'
    require_relative 'variable'
    require_relative 'assign'
  end
end
