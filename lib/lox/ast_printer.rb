module Lox
  module Visitor
    # def visit(subject)
    #   method_name = "visit_#{subject.class}".to_sym
    #   send(method_name, subject)
    # end

    def visit_binary_expr(expr); end

    def visit_grouping_expr; end

    def visit_literal_expr; end

    def visit_unary_expr; end

    def accept(visitor); end
  end

  class ASTPrinter
    include Visitor

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
