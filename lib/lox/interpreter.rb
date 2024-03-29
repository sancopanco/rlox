require_relative 'runtime_error'
require_relative 'stmt/stmt'
require_relative 'expr/expr'
require_relative 'environment'
require_relative 'callable'
require_relative 'function'
require_relative 'return'
require_relative 'lox_class'
require_relative 'lox_instance'
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
      puts "[Set Interpreter Global Environment] #{@environment.object_id}"
      # map: <Expr, Integer>
      # Associates each syntax tree node with its resolved data
      @locals = {}

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
    end

    # stmt analogue to the evaluate() for expressions
    def execute(stmt)
      stmt.accept(self)
    end

    # depth: this corresponds to the number of environments  between
    # the current one and the enclosing one where the interpreter can find the variable's value
    # Resolver hands that number to the interpreter
    def resolve(expr, depth)
      locals[expr] = depth
    end

    ## Statements Interpretation
    # Unlike expressions, statements produce no value

    # To execute a block, we create a new environment for the block's scope
    def visit_block_stmt(stmt)
      execute_block(stmt.statements, Environment.new(environment))
    end

    # Declera the class's name in the current environment
    # Turn the class syntax node, its AST, (class_stmt) into a LoxClass, the runtime representation of a class
    # Store the class object in the variable we previously declared
    # That two-stage variable binding process allows references to the class inside its own methods.
    # Each methods decleration will be turned into Runtime LoxFunction as well
    def visit_class_stmt(class_stmt)
      puts ['class_stmts', class_stmt, class_stmt.method_stmts].inspect
      environment.define(class_stmt.name.lexeme, nil)

      methods = {}
      class_stmt.method_stmts.each do |method_stmt|
        function = Function.new(method_stmt, environment, method_stmt.name.lexeme == 'init')
        methods[method_stmt.name.lexeme] = function
      end

      puts "methods:#{methods}"

      klass = Lox::LoxClass.new(class_stmt.name.lexeme, methods)

      puts "klass method table:#{klass.methods_table}"

      environment.assign(class_stmt.name, klass)

      nil
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
      function = Function.new(stmt, environment, false)
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

    # It evaluates the right hand side to get the value
    # We look up the variable's scope distance, if not found we assume it's global and assign name with avlue
    # Otherwise, It walks a fixed number(distance) of environments, and then stuffs the new value in that env - map
    def visit_assign_expr(expr)
      value = evaluate(expr.value)
      distance = locals[expr]
      if distance
        environment.assign_at(distance, expr.name, value)
        return
      end
      globals.assign(expr.name, value)
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
      lookup_variable(expr.name, expr)
    end

    # Lookup the resolved distance in the map -- we only resolved local variables
    # If we don't find the distance in the map, it must be global -- lookup,dynamically,in the global env
    # That throws a runtime error if the variable isn't defined
    # If we did get a distance, we have a local variable,and we get to take advantage of the results of static analysis
    def lookup_variable(name, expr)
      distance = locals[expr]
      puts "[Lookup Var] #{name}, distance: #{distance}"
      return environment.get_at(distance, name.lexeme) unless distance.nil?
      globals.get(name)
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
        raise RuntimeError.new(expr.paren_token, "Expected #{function.arity} arguments but got #{arguments.size} .")
      end

      # Once we've got the callee and the arguments ready, perform the call

      function.call(self, arguments)
    end

    # Evaluate the expression whose property is being accessed.
    # In lox, only instances have props. If the object is some other type like number it is runtime error
    # If object is a LoxInstance, ask it to look up the property
    def visit_get_expr(expr)
      object = evaluate(expr.object_expr)
      return object.get(expr.name) if object.is_a?(Lox::LoxInstance)
      raise RuntimeError.new(expr.name, 'Only instances have properties')
    end

    # We evaluate the object(expr) whose property is being set
    # Check to see if it's a LoxInstance. If not,that's a runtime error.
    # Otherwise, evaluate the value(expr) being set and store it on the instance
    def visit_set_expr(expr)
      object = evaluate(expr.object_expr)
      unless object.is_a?(Lox::LoxInstance)
        raise RuntimeError.new(expr.name, 'Only instances have properties')
      end
      value = evaluate(expr.value_expr)
      object.set(expr.name. value)
      value
    end

    # Same as interpresting a variable expression
    def visit_this_expr(expr)
      lookup_variable(expr.keyword, expr)
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
    attr_reader :locals

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
