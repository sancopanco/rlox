require 'minitest/autorun'
require_relative '../lib/lox/interpreter'
require_relative '../lib/lox/scanner'
require_relative '../lib/lox/parser'

class TestInterpreter < Minitest::Test
  def test_multiplication
    source = '2 * 3'
    assert_equal interpreter.interpret(get_ast(source)), '6'
  end

  def test_addition
    source = '2 * 3 + 2 * 5'
    assert_equal interpreter.interpret(get_ast(source)), '16'
  end

  def test_unarty
    source = '-3 / -4'
    assert_equal interpreter.interpret(get_ast(source)), '0.75'
  end

  def test_comparison
    source = '2 >= 1 + 1'
    assert_equal interpreter.interpret(get_ast(source)), 'true'
  end

  def test_equality
    source = '!( 3 == -3) == false'
    assert_equal interpreter.interpret(get_ast(source)), 'false'
  end

  private

  def interpreter
    @interpret = Lox::Interpreter.new
  end

  def get_ast(source)
    tokens = Lox::Scanner.new(source).scan_tokens
    Lox::Parser.new(tokens).parse
  end
end
