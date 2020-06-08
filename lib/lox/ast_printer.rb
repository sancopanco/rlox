require_relative 'visitor'
module Lox
  # Take in a syntax tree and recursively traverse it, build up a string
  class ASTPrinter
    include Lox::Visitor

    def print(expr)
      expr.accept(self)
    end

    def visit_binary_expr(expr)
      paranthesize(expr.operator.lexeme, expr.left_expr, expr.right_expr)
    end

    def visit_grouping_expr(expr)
      paranthesize('group', expr.expr)
    end

    def visit_literal_expr(expr)
      return 'nil' if expr.value.nil?
      expr.value.to_s
    end

    def visit_unary_expr(expr)
      paranthesize(expr.operator.lexeme, expr.right_expr)
    end

    def paranthesize(name, *exprs)
      result = ['(']
      result << name
      exprs.each do |expr|
        result << ' '
        result << expr.accept(self)
      end
      result << ')'
      result.join
    end
  end
end
