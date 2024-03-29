require 'minitest/autorun'
require_relative '../lib/lox/scanner.rb'
require_relative '../lib/lox/token_type'

class TestScanner < Minitest::Test
  def test_scan_tokens
    source = 'var language = "lox";'
    scanner = Lox::Scanner.new(source)
    tokens = scanner.scan_tokens

    assert_equal tokens.size, 6
    assert_equal Lox::TokenType::VAR, tokens[0].type
    assert_equal 'var', tokens[0].lexeme
    assert_nil tokens[0].literal
    assert_equal 1, tokens[1].line

    assert_equal Lox::TokenType::IDENTIFIER, tokens[1].type
    assert_equal 'language', tokens[1].lexeme
    assert_nil tokens[1].literal

    assert_equal Lox::TokenType::EQUAL, tokens[2].type
    assert_equal '=', tokens[2].lexeme
    assert_nil tokens[2].literal

    assert_equal Lox::TokenType::STRING, tokens[3].type
    assert_equal '"lox"', tokens[3].lexeme
    assert_equal 'lox', tokens[3].literal

    assert_equal Lox::TokenType::SEMICOLON, tokens[4].type
    assert_equal ';', tokens[4].lexeme
    assert_nil tokens[4].literal

    assert_equal Lox::TokenType::EOF, tokens[5].type
    assert_equal '', tokens[5].lexeme
    assert_nil tokens[5].literal
  end
end
