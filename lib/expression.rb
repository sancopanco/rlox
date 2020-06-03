# expression → literal
#            | unary
#            | binary
#            | grouping ;

# literal    → NUMBER | STRING | "true" | "false" | "nil" ;
# grouping   → "(" expression ")" ;
# unary      → ( "-" | "!" ) expression ;
# binary     → expression operator expression ;
# operator   → "==" | "!=" | "<" | "<=" | ">" | ">="
#            | "+"  | "-"  | "*" | "/" ;

require_relative 'token'
require_relative 'token_type'

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

class Expression
end

class Binary < Expression
  attr_reader :operator, :left_expr, :right_expr

  def initialize(left_expr, operator, right_expr)
    @left_expr = left_expr
    @right_expr = right_expr
    @operator = operator # token
  end

  def accept(visitor)
    visitor.visit_binary_expr(self)
  end
end

class Grouping < Expression
  attr_reader :expr

  def initialize(expr)
    @expr = expr
  end

  def accept(visitor)
    visitor.visit_grouping_expr(self)
  end
end

class Literal < Expression
  attr_reader :value

  def initialize(value)
    @value = value
  end

  def accept(visitor)
    visitor.visit_literal_expr(self)
  end
end

class Unary < Expression
  attr_reader :operator, :right_expr
  def initialize(operator, right_expr)
    @operator = operator
    @right_expr = right_expr
  end

  def accept(visitor)
    visitor.visit_unary_expr(self)
  end
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

def main
  l_expr = Literal.new(123)
  exp_1 = Unary.new(Token.new(TokenType::MINUS, '-', nil, 1), l_expr)
  oper  = Token.new(TokenType::STAR, '*', nil, 1)
  exp_2 = Grouping.new(Literal.new(45.67))
  exp = Binary.new(exp_1, oper, exp_2)

  # (* (- 123) (group 45.67))
  puts ASTPrinter.new.print(exp)
end
main
