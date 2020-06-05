require 'minitest/autorun'
require_relative '../lib/lox/token_type'
require_relative '../lib/lox/token'
require_relative '../lib/lox/expression'
require_relative '../lib/lox/ast_printer'

class TestExpression < Minitest::Test
  def test_binary_expr
    l_expr = Lox::Literal.new(123)
    exp_1 = Lox::Unary.new(Lox::Token.new(Lox::TokenType::MINUS, '-', nil, 1), l_expr)
    oper  = Lox::Token.new(Lox::TokenType::STAR, '*', nil, 1)
    exp_2 = Lox::Grouping.new(Lox::Literal.new(45.67))
    exp = Lox::Binary.new(exp_1, oper, exp_2)

    assert_equal Lox::ASTPrinter.new.print(exp), '(* (- 123) (group 45.67))'
  end
end
