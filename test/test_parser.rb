require 'minitest/autorun'
require_relative '../lib/lox/scanner'
require_relative '../lib/lox/parser'
require_relative '../lib/lox/ast_printer'

class TestParser < Minitest::Test
  def test_equality_expr
    source = '2 == 2 == 2'
    assert_equal print_ast(source), '(== (== 2.0 2.0) 2.0)'
  end

  def test_comparison_expr
    source = '2 >= 1 + 1'
    assert_equal print_ast(source), '(>= 2.0 (+ 1.0 1.0))'
  end

  def test_addition_expr
    source = '2 * 3 + 3 * 4'
    assert_equal print_ast(source), '(+ (* 2.0 3.0) (* 3.0 4.0))'
  end

  def test_unary_expr
    source = '-3 / -4'
    assert_equal print_ast(source), '(/ (- 3.0) (- 4.0))'
  end

  def test_primary
    source = '!( 3 == -3) == true'
    assert_equal print_ast(source), '(== (! (group (== 3.0 (- 3.0)))) true)'
  end

  private

  def print_ast(source)
    Lox::ASTPrinter.new.print(parse(source))
  end

  def parse(source)
    parser(source).parse
  end

  def parser(source)
    scanner = Lox::Scanner.new(source)
    tokens = scanner.scan_tokens
    Lox::Parser.new(tokens)
  end
end
