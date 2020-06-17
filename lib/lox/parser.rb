
## Expression grammer

# expression     → assignment ;
# assignment -> IDENTIFIER "=" assignment | equality  | logical_or ;
# logical_or -> logical_and ("or" logical_and)* ;
# logical_and -> equality ("and" equality)* ;
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
require_relative 'expr/expr'
require_relative 'stmt/stmt'

module Lox
  class Parser
    def initialize(tokens)
      @tokens = tokens
      @current = 0
    end

    # A program is a list of declaration/statements, we parse series of of statements,
    # as many as we can find until it hits the end of the input
    # program -> declaration* EOF ;
    # Translation of `program` rule into recursive descent style
    # produce statement syntax trees
    def parse
      statements = []
      statements << declaration until at_end?
      statements
    end

    private

    class ParseError < StandardError; end

    # declaration -> funDecl | varDecl | statement
    # Like all statements declarations are recognized by the leading keyword -- match and comsume
    def declaration
      return var_declaration if match(TokenType::VAR)
      return function_declaration('function') if match(TokenType::FUN)
      statement
    rescue ParseError
      # error recovery when the parser goes into panic mode
      # get it back to trying to parse the begining of the next statement/declaration
      synchronize
      nil
    end

    # varDecl -> "var" IDENTIFIER ("=" expression)? ";" ;
    # Consume identifer token for the variable name,
    # it parses initializer expr if there is one
    # returns Stmt:Var syntax tree node
    def var_declaration
      var_name = consume(TokenType::IDENTIFIER, 'Expect variable name.')
      initializer = nil
      initializer = expression if match(TokenType::EQUAL)
      consume(TokenType::SEMICOLON, "Expect ';' after variable declaration")
      Stmt::Var.new(var_name, initializer)
    end

    # funDecl -> "fun" function ;
    # function -> IDENTIFIER "(" parameters? ")" block ;
    # parameters -> IDENTIFIER ("," IDENTIFIER)* ;
    # Function declarations, like variables, bind a name
    # Each parameter is an identifier, not an expression
    # kind `method` or `function`
    # function declerations are allowed anywhere a name can be bound
    def function_declaration(kind)
      puts 'function decleration'
      # consume identifier token for the function's name
      name = consume(TokenType::IDENTIFIER, "Expect #{kind} name.")

      # Parameter list and the pair of parens wrapped around it
      consume(TokenType::LEFT_PAREN, "Expect after #{kind} name.")
      parameters = []
      unless check(TokenType::RIGHT_PAREN) # zero param case
        # parses parameters as long as we find commas to seperate them
        loop do
          if parameters.size > 255
            error(peek, 'Cannot have mor than 255 parameters.')
          end
          parameters << consume(TokenType::IDENTIFIER, 'Expect parameter name.')
          break unless match(TokenType::COMMA)
        end
      end
      consume(TokenType::RIGHT_PAREN, "Expect ')' after parameters.")

      # Parse body
      # we consume the { at the beginning of the body here before calling block().
      # That’s because block() assumes that token has already been matched.
      consume(TokenType::LEFT_BRACE, "Expect before #{kind} body.")
      body = block

      # Wrap it all up in a function node
      Stmt::Function.new(name, parameters, body)
    end

    # region Statement Rules

    # Statement rule
    # statement -> exprStmt | forStmt | ifStmt | printStmt | returnStmt | whileStmt | block ;
    def statement
      # detect and match the leading keyword
      return if_statement if match(TokenType::IF)
      return print_statement if match(TokenType::PRINT)
      return return_statement if match(TokenType::RETURN)
      return while_statement if match(TokenType::WHILE)
      return for_statement if match(TokenType::FOR)
      return Stmt::Block.new(block) if match(TokenType::LEFT_BRACE)
      expression_statement
    end

    # exprStmt -> expression ";" ;
    def expression_statement
      expr = expression
      consume(TokenType::SEMICOLON, "Expect ';' after value.")
      Lox::Stmt::Expression.new(expr)
    end

    # Eeach satement type gets its own method
    # printStmt -> "print" expression ";" ;
    # It parses the subsequent expression, consumes the terminating semicolon,
    # and emits the syntax tree
    def print_statement
      value = expression
      consume(TokenType::SEMICOLON, "Expect ';' after value.")
      Lox::Stmt::Print.new(value)
    end

    # Getting results back out in functions
    # If it was an expression-oriented languaga like ruby, scheme, body would be an
    # expression whose value is implicitly the function's result
    # But here the body of a function is list of statements which don't produce value
    # Every function must return something, there are no void functions in dynamically typed lang
    # returnStmt -> "return" expression? ";" ;
    def return_statement
      keyword = previous

      value = nil
      # semi colon can't occur in an expression
      value = expression unless check(TokenType::SEMICOLON)

      consume(TokenType::SEMICOLON, "Expect ';' after return value")

      Stmt::Return.new(keyword, value)
    end

    # ifStmt -> "if" "(" expression ")" statement ("else" statement)? ;
    # Execute the statement if the condition is truthy
    def if_statement
      print 'if statement'
      consume(TokenType::LEFT_PAREN, "Expext '(' after 'if'.")
      condition = expression
      consume(TokenType::RIGHT_PAREN, "Expect ')' after if condition.")

      then_branch = statement
      else_branch = nil
      else_branch = statement if match(TokenType::ELSE)
      Stmt::If.new(condition, then_branch, else_branch)
    end

    # whileStmt -> "while" "(" expression ")" statement ;
    def while_statement
      consume(TokenType::LEFT_PAREN, "Expect '(' after 'while'.")
      condition_expr = expression
      consume(TokenType::RIGHT_PAREN, "Expect ')' after 'while'.")
      body_stmt = statement
      Stmt::While.new(condition_expr, body_stmt)
    end

    # forStmt -> "for" "("  ( varDecl | exprStmt | ";" ) expression? ";" expression? ")" statement ;
    # The first clause is initializer. It executed only once, brefore anything else
    # It is usually an expression, also allow variable declaration. In that case, the variable is
    # is scoped to the rest of the for loop
    # Next is the condition
    # The last clause is the increment
    # Use while primitive statement
    def for_statement
      consume(TokenType::LEFT_PAREN, "Expect '(' after 'for'.")
      puts 'for_statement'
      # initializer statement clause
      initializer_stmt = if match(TokenType::SEMICOLON)
                           nil
                         elsif match(TokenType::VAR)
                           var_declaration
                         else
                           expression_statement
                         end

      # Loop condition expression
      condition_expr = nil
      # look for semicolon to see if the clause has been omitted
      condition_expr = expression unless check(TokenType::SEMICOLON)
      consume(TokenType::SEMICOLON, "Expect ';' after loop condition.")

      # Increment expresion
      increment = nil
      increment = expression unless check(TokenType::RIGHT_PAREN)
      consume(TokenType::RIGHT_PAREN, "Expect ')' after for clauses.")

      # Body statement
      body = statement

      # desugaring

      # The increment, if there is one, executes after the body in each iteration
      # We do that by replacing the body with a block contains the original body
      # followed by increment expression statement
      unless increment.nil?
        body = Stmt::Block.new([body, Stmt::Expression.new(increment)])
      end

      # Take the condition expression and body and build the loop using a primitive while loop
      # If the condition expresion is ommited, we jam in `true` to make an infinite loop
      condition_expr = Expr::Literal.new(true) if condition_expr.nil?
      body = Stmt::While.new(condition_expr, body)

      # If there is an initializer, it runs once before the entire loop
      # Replace the whole statement with block that runs initializer and the executes the loop
      unless initializer_stmt.nil?
        body = Stmt::Block.new([initializer_stmt, body])
      end

      body
    end

    # A block statement is a seris of declaration or statements surrounded by "}"
    # block -> "{" declaration* "}"
    def block
      statements = []
      statements << declaration while !check(TokenType::RIGHT_BRACE) && !at_end?
      consume(TokenType::RIGHT_BRACE, "Expect '}' after block")
      statements
    end

    # region Expression Rules

    # Expression rule
    # expresssoin -> assignment; -- lowest precedence expression form
    def expression
      assignment
    end

    # Assignment rule
    # assignment -> IDENTIFER "=" assignment | logical_or ;
    # assignment is right-associative
    def assignment
      expr = logical_or

      if match(TokenType::EQUAL)
        equals = previous
        value = assignment

        if expr.is_a?(Lox::Expr::Variable)
          name = expr.name
          return Expr::Assign.new(name, value)
        end
        error(equals, 'Invalid assignment target.')
      end

      expr
    end

    # logical_or -> logical_and ( "or" logical_and )* ;
    # lower precedence then logical `and`
    def logical_or
      expr = logical_and

      while match(TokenType::OR)
        operator = previous
        right_expr = logical_and
        expr = Expr::Logical.new(expr, operator, right_expr)
      end

      expr
    end

    # logical_and -> equality ("and" equality)* ;
    def logical_and
      expr = equality

      while match(TokenType::AND)
        operator = previous
        right_expr = equality
        expr = Expr::Logical.new(expr, operator, right_expr)
      end

      expr
    end

    # comparison > equality -- presedence
    # equality -> comparison ( ("!=" | "==") comparison )* ;
    # matches an equality operator or anything of higher precedence
    # left-associates, has higher precedence than logical operator `and` and `or`
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
        expr = Expr::Binary.new(expr, operator, right)
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
        expr = Expr::Binary.new(expr, operator, right)
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
        expr = Expr::Binary.new(expr, operator, right)
      end

      expr
    end

    # unary > multiplication -- precedence
    # unary -> ("!" | "-") unary | function_call
    # right-associates
    def unary
      if match(TokenType::BANG, TokenType::MINUS)
        operator = previous
        right = unary
        return Unary.new(operator, right)
      end
      function_call
    end

    # function_call > unary -- precedence
    # function_call -> primary ("(" arguments ")") * ;
    # arguments -> expression ("," expression) * ;
    # The name of the function being called isn't actually part of the call syntax
    # The thing being called -- callee -- can be any expresssion that evaluates to a function
    # ex f(a)(b)(c) -- currying
    # It is the parentheses following an expressiont that indicate a function call
    # Can be thought of as an postfix operator starts with `(`
    def function_call
      #  a primary expression, the “left operand” to the call
      expr = primary

      # Each time you see a `(` we call finish_function_call to
      # parse call expression using the previously parse expr as an the callee
      loop do
        break unless match(TokenType::LEFT_PAREN)
        expr = finish_function_call(expr)
      end

      expr
    end

    def finish_function_call(callee_expr)
      arguments = []
      unless check(TokenType::RIGHT_PAREN) # zero-argument case
        loop do
          # Upper limit for argument number
          if arguments.size >= 255
            error(peek, 'Can not have more than 255 arguments')
          end

          arguments << expression
          # argument list is done, if cant find comma
          break unless match(TokenType::COMMA)
        end
      end

      paren = consume(TokenType::RIGHT_PAREN, "Expect ')' after arguments")
      Expr::FunctionCall.new(callee_expr, paren, arguments)
    end

    # highest precedence
    # primary -> NUMBER | STRING | "false" | "true" | "nil" | "(" expression ")" | IDENTIFIER ;
    def primary
      return Expr::Literal.new(false) if match(TokenType::FALSE)
      return Expr::Literal.new(true) if match(TokenType::TRUE)
      return Expr::Literal.new(nil) if match(TokenType::NIL)
      return Expr::Literal.new(previous.literal) if match(TokenType::NUMBER, TokenType::STRING)

      # Variable expressions
      return Expr::Variable.new(previous) if match(TokenType::IDENTIFIER)

      if match(TokenType::LEFT_PAREN)
        expr = expression
        # After we match ( and parse exxpresion inside , we must find a ) token
        consume(TokenType::RIGHT_PAREN, "Expect ')' after expression")
        return Expr::Grouping.new(expr)
      end

      # As the parser descends through the parsing methods for each grammer rule
      # it eventually hits here, it means we're sitting on a token that can not start an expression
      raise error(peek, 'Expect expression.')
    end

    # endregion

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
