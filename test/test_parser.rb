require 'minitest/autorun'
require_relative '../lib/lox/scanner'
require_relative '../lib/lox/parser'

class TestParser < Minitest::Test
  def test_equality_expr
    source = '2 == 2 == 2'
    scanner = Lox::Scanner.new(source)
    tokens = scanner.scan_tokens
    parser = Lox::Parser.new(tokens)
    p parser.parse.inspect
  end

  def test_comparison_expr
    source = '2 >= 1'
    scanner = Lox::Scanner.new(source)
    tokens = scanner.scan_tokens
    parser = Lox::Parser.new(tokens)
    p parser.parse.inspect
  end
end
