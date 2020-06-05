
## Expression grammer

# expression     → equality ;
# equality       → comparison ( ( "!=" | "==" ) comparison )* ;
# comparison     → addition ( ( ">" | ">=" | "<" | "<=" ) addition )* ;
# addition       → multiplication ( ( "-" | "+" ) multiplication )* ;
# multiplication → unary ( ( "/" | "*" ) unary )* ;
# unary          → ( "!" | "-" ) unary
#                | primary ;
# primary        → NUMBER | STRING | "false" | "true" | "nil"
#                | "(" expression ")" ;

# A recursive descent parser is a literal translation
# of the grammar's rules into imperative code -- Each rule becames a function

# Parser has two jobs:
# 1. Given a valid sequence of tokens, produce a corresponding syntax tree
# 2. Given an invalid sequence of token, detect any errors and tell the user about the mistakes

# Requirements
# it must detect and report the error
# I must not crash or hang
# Be fast
# Report as many distinct errors as there are
# Minimize cascaded errors
require_relative 'expression'

module Lox
  class Parser
    def initialize(tokens)
      @tokens = tokens
      @current = 0
    end

    def parse
      expression
    rescue ParseError
      nil
    end

    private

    class ParseError < StandardError; end

    # First rule
    def expression
      equality
    end

    # comparison > equality -- presedence
    # equality -> comparison ( ("!=" | "==") comparison )* ;
    # matches an equality operator or anything of higher precedence
    # left-associates
    def equality
      expr = comparison
      # creates left-associative nested-tree of of binary operator nodes
      while match(TokenType::BANG_EQUAL, TokenType::EQUAL_EQAUL)
        operator = previous
        right = comparison
        # wrap that all up in a binary expression syntax tree
        expr = Binary.new(expr, operator, right)
      end

      expr
    end

    # addition > comparison -- presedence
    # comparison -> addition ( (">" | ">=" | "<=" | "<") addition )* ;
    # left-associates
    def comparison
      expr = addition

      while match(TokenType::GREATER, TokenType::GREATER_EQUAL, TokenType::LESS, TokenType::LESS_EQUAL)
        operator = previous
        right = addition
        expr = Binary.new(expr, operator, right)
      end

      expr
    end

    # multiplication > addition -- precedence
    # addition -> multiplication ( ("-" | "+") multiplication )* ;
    # left-associates
    def addition
      expr = multiplication

      while match(TokenType::MINUS, TokenType::PLUS)
        operator = previous
        right = multiplication
        expr = Binary.new(expr, operator, right)
      end

      expr
    end

    # unary > multiplication -- precedence
    # multiplication -> unary ( ("/" | "*") unary )* ;
    # left-associates
    def multiplication
      expr = unary

      while match(TokenType::SLASH, TokenType::STAR)
        operator = previous
        right = unary
        expr = Binary.new(expr, operator, right)
      end

      expr
    end

    # unary > multiplication -- precedence
    # unary -> ("!" | "-") unary | primary
    # right-associates
    def unary
      if match(TokenType::BANG, TokenType::MINUS)
        operator = previous
        right = unary
        return Unary.new(operator, right)
      end
      primary
    end

    # highest precedence
    # primary -> NUMBER | STRING | "false" | "true" | "nil" | "(" expression ")" ;
    def primary
      return Literal.new(false) if match(TokenType::FALSE)
      return Literal.new(true) if match(TokenType::TRUE)
      return Literal.new(nil) if match(TokenType::NIL)
      return Literal.new(previous.literal) if match(TokenType::NUMBER, TokenType::STRING)

      if match(TokenType::LEFT_PAREN)
        expr = expression
        # After we match ( and parse exxpresion inside , we must find a ) token
        consume(TokenType::RIGHT_PAREN, "Expect ')' after expression")
        return Grouping.new(expr)
      end

      # As the parser descends through the parsing methods for each grammer rule
      # it eventually hits here, it means we're sitting on a token that can not start an expression
      raise error(peek, 'Expect expression.')
    end

    def consume(token_type, message)
      # check to see if the next_token is of the expected type. If so, it consumes it
      # otherwise, we've hit an error, report it
      return advance if check(token_type)
      raise error(peek, message)
    end

    def error(token, message)
      Lox.error_token(token, message)
      # Returns it instead of throwing, let the caller decide whether to unwind or not
      ParseError.new
    end

    # Discarding token that would have likely caused cascaded errors
    # Keep on parsing the rest of the file starting at the next statement
    def synchronize
      advance

      until at_end?

        # discard token until we're at the beginning of the next statement
        # After a semicolon we're finished with a statement
        return if previous.type == TokenType::SEMICOLON

        # When the next token is any of those, we're about to start a statement
        case peek.type
        when TokenType::CLASS, TokenType::FUN, TokenType::VAR, TokenType::WHILE,
          TokenType::FOR, TokenType::PRINT, TokenType::RETURN
          return
        end

        advance
      end
    end

    def match(*token_types)
      token_types.each do |type|
        if check(type)
          advance
          return true
        end
      end

      false
    end

    # if the current token is given type
    def check(type)
      return false if at_end?
      peek.type == type
    end

    # Consumes the current token and returns it
    def advance
      @current += 1 unless at_end?
      previous
    end

    # return the current token we've yet to consume
    def peek
      tokens[current]
    end

    # return most recently consumed one
    def previous
      tokens[current - 1]
    end

    # If we run out of tokens
    def at_end?
      peek.type == TokenType::EOF
    end

    attr_reader :tokens
    # points to the next token
    attr_accessor :current
  end
end
