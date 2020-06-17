require_relative 'runtime_error'
require_relative 'stmt/stmt'
require_relative 'expr/expr'
require_relative 'environment'
require_relative 'callable'
require_relative 'function'
require_relative 'return'
module Lox
  class Interpreter
    include Lox::Expr::Visitor
    include Lox::Stmt::Visitor

    attr_reader :globals

    def initialize
      # variables stay in memory as long as the interpreter is running

      # holds a fixed reference to outermost global environment
      @globals = Lox::Environment.new
      # represents and tracks the current environment -- changes as we enter and exit local scopes
      @environment = @globals
      add_native_functions
    end

    # Public API
    # Takes a list of statements--in other words, a program
    # And execute them
    # Report the run time errors and to user and continue
    def interpret(statements)
      statements.each do |statement|
        execute(statement)
      end
    rescue Lox::RuntimeError => error
      Lox.runtime_error(error)
      # puts error
    end

    # stmt analogue to the evaluate() for expressions
    def execute(stmt)
      stmt.accept(self)
    end

    ## Statements
    # Unlike expressions, statements produce no value

    # To execute a block, we create a new environment for the block's scope
    def visit_block_stmt(stmt)
      execute_block(stmt.statements, Environment.new(environment))
    end

    # Evaluates inner expression and discards its value
    def visit_expression_stmt(stmt)
      evaluate(stmt.expr)
      nil
    end

    # We take a function syntax node, stmt -- a compile time representation of the function
    # And convert it to  its runtime representation -- here Function class wraps the synax node, stmt
    # Function declerations are different from other literal node in that the decleration also
    # binds the resulting object to a new variable
    # We create a new binding in the current environment and store a reference to it there
    # When we create a Function, we capture the current environment
    # This is the environment that is active when the function is **declared** not when it's **called**
    # It represents the lexical scope surrounding the function declaration
    def visit_function_decleration_stmt(stmt)
      function = Function.new(stmt, environment)
      environment.define(stmt.name.lexeme, function)

      nil
    end

    # Evaluates the condition, if it's truthy, it executes the then branch
    # Otherwise, if there is an else branch, it executes that
    def visit_if_stmt(stmt)
      if truthy?(evaluate(stmt.condition))
        execute(stmt.then_branch)
      elsif !stmt.else_branch.nil?
        execute(stmt.else_branch)
      end

      nil
    end

    # Dump the value to stdout
    def visit_print_stmt(stmt)
      value = evaluate(stmt.expr)
      puts stringify(value)
      nil
    end

    # If we have a return value expr, we evaluate it, otherwise, use nil - default return value
    # Take that value and wrap it in s custom exception class and throw it
    def visit_return_stmt(stmt)
      value = nil
      value = evaluate(stmt.value) unless stmt.value.nil?
      raise Return, value
    end

    # Declaration statements
    # If the variable has initializer, evaluate it
    # If not, set the value nil
    # Tell the environment bind the name to that value
    def visit_var_stmt(stmt)
      value = nil
      value = evaluate(stmt.initializer) if stmt.initializer
      environment.define(stmt.name.lexeme, value)
      nil
    end

    def visit_while_stmt(stmt)
      execute(stmt.body_stmt) while truthy?(evaluate(stmt.condition_expr))
      nil
    end

    ## Expressions semantics

    # I evaluates the right hand side to get the value,
    # then stores it in a named variable
    def visit_assign_expr(expr)
      value = evaluate(expr.value)
      environment.assign(expr.name, value)
      value
    end

    # Convert literal tree node into a runtime value
    def visit_literal_expr(expr)
      expr.value
    end

    # Evaluate the left operand first, look at its value to see if can short circuit
    # If not, and only then, do evaluate the right operand
    # Logical operator merely guarantees it will return a value with appropriate truthiness
    # Instead of promising to literally return `true` or `false`
    def visit_logical_expr(expr)
      left = evaluate(expr.left_expr)

      if expr.operator.type == TokenType::OR
        return left if truthy?(left)
      else
        return left unless truthy?(left)
      end

      evaluate(expr.right_expr)
    end

    # Recursively evaluate subexpression and return it
    def visit_grouping_expr(expr)
      evaluate(expr.expr)
    end

    # Unary expression have single subexpression that has to be
    # evaluated first
    # We can't evaluate it until after we evaluate its operand subexpr
    # Doing post-order traversal
    def visit_unary_expr(expr)
      right_expr = evaluate(expr.right_expr)

      case expr.operator.type
      when TokenType::MINUS
        # sub expr must be number
        check_number_operand(expr.operator, right_expr)
        return -right_expr.to_f
      when TokenType::BANG
        return !truthy?(right_expr)
      end

      nil
    end

    # Evaluate a variable expression
    # forwards to the environment--does the heavy lifting to make sure it's defined
    def visit_variable_expr(expr)
      environment.get(expr.name)
    end

    # Evaluating binary operator
    # We evaluate the operands in left-to-right order
    def visit_binary_expr(expr)
      left_expr = evaluate(expr.left_expr)
      right_expr = evaluate(expr.right_expr)

      # We assume ther operands are a certain type and cast them
      case expr.operator.type
      # Comparisions

      when TokenType::GREATER
        check_number_operands(expr.operator, left_expr, right_expr)
        return left_expr.to_f > right_expr.to_f
      when TokenType::GREATER_EQUAL
        check_number_operands(expr.operator, left_expr, right_expr)
        return left_expr.to_f >= right_expr.to_f
      when TokenType::LESS
        check_number_operands(expr.operator, left_expr, right_expr)
        return left_expr.to_f < right_expr.to_f
      when TokenType::LESS_EQUAL
        check_number_operands(expr.operator, left_expr, right_expr)
        return left_expr.to_f <= right_expr.to_f

      # Arithmetic
      when TokenType::MINUS # subtraction
        check_number_operands(expr.operator, left_expr, right_expr)
        return left_expr.to_f - right_expr.to_f
      when TokenType::SLASH # division
        check_number_operands(expr.operator, left_expr, right_expr)
        return left_expr.to_f / right_expr.to_f
      when TokenType::PLUS # addition
        # The pluse operator can also be used to concatenate two strings
        if left_expr.is_a?(Numeric) && right_expr.is_a?(Numeric)
          return left_expr.to_f + right_expr.to_f
        end
        if left_expr.is_a?(String) && right_expr.is_a?(String)
          return left_expr.to_s + right_expr.to_s
        end

        raise Lox::RuntimeError.new(expr.operator,
                                    'Operands must be two numbers or two strings')
      when TokenType::STAR # multiplication
        check_number_operands(expr.operator, left_expr, right_expr)
        return left_expr.to_f * right_expr.to_f

      # Equality
      # Unlike the comparison, equality operators support operands of any type
      # implementing in terms of ruby behaviour
      when TokenType::EQUAL_EQAUL
        return left_expr == right_expr
      when TokenType::BANG_EQUAL
        return left_expr != right_expr
      end

      # unreachable
      nil
    end

    # Evaluating function calls
    def visit_function_call_expr(expr)
      # Evaluate the calle expr. Typically, this expression is just an identifier
      # that looks up the function by its name, but it could be anything
      callee = evaluate(expr.callee)

      # Evaluate each of the argument expressions in order
      arguments = []
      expr.arguments.each do |argument|
        arguments << evaluate(argument)
      end

      # what happens if the callee isn't something you can not call -- like string
      unless callee.is_a?(Callable)
        raise RuntimeError.new(expr.paren_token, 'can only call functions and classes')
      end

      function = callee

      # Checking arity
      unless function.arity == arguments.size
        raise RuntimeError.new(expr.paren_token,
                               "Expected #{function.arity} arguments but got #{arguments.size} .")
      end

      # Once we've got the callee and the arguments ready, perform the call

      function.call(self, arguments)
    end

    # It executes a list of statements in the context of given environment
    # Restore the previous environment, gets restored even if an exception is thrown
    def execute_block(statements, new_environment)
      previous = environment
      self.environment = new_environment
      statements.each do |statement|
        execute(statement)
      end
    ensure
      self.environment = previous
    end

    private

    attr_accessor :environment

    # Stuff native functions in global scope
    def add_native_functions
      globals.define('clock', Class.new do
        include Callable

        def arity
          0
        end

        def call(_inpterpreter, _arguments)
          Time.now.to_f * 1000.0
        end

        def to_s
          'native <fn>'
        end
      end)
    end

    def check_number_operand(operator, operand)
      return if operand.is_a?(Numeric)
      raise Lox::RuntimeError.new(operator, 'Operand must be a number.')
    end

    def check_number_operands(operator, left_operand, right_operand)
      return if left_operand.is_a?(Numeric) && right_operand.is_a?(Numeric)
      raise Lox::RuntimeError.new(operator, 'Operands must be a number.')
    end

    # false and nil are falsey and everything else truthy
    def truthy?(obj)
      !!obj
    end

    # Sends the expr back into interpreter's visitor implementation
    def evaluate(expr)
      expr.accept(self)
    end

    # converts any Lox's value(obj) to a sting
    def stringify(obj)
      # same with ruby
      return 'nil' if obj.nil?
      # We use float numbers even for the integers, in
      # that case they should print out without a decimal point
      # Work around for integer valued floats
      if obj.is_a?(Numeric)
        obj_str = obj.to_s
        obj_str = obj_str[0..obj_str.size - 3] if obj_str.end_with?('.0')
        return obj_str
      end
      # otherwise ruby string represenation
      obj.to_s
    end
  end
end
