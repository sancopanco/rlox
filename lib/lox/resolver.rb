module Lox
  # The scope stack is only used for local block scopes.
  # Variables declared at the top level in the global scope are not tracked by the resolver
  # since they are more dynamic
  # When resolving a variable, if we can’t find it in the stack of local scopes, we assume it must be global.
  # Resolver needs to visit every node in the syntax tree
  class Resolver
    module FunctionType
      NONE = 'none'.freeze
      FUNCTION = 'function'.freeze
    end

    def initialize(interpreter)
      @interpreter = interpreter

      # Tracks whether or not the current code is inside a function decleration
      @current_function = FunctionType::NONE

      # Keeps track of stack of scopes
      # Each element is a hash representing a single block scope
      # Keys are variable names
      # map :<string, boolean>
      @scopes = []
    end

    # A block statement introduce a new scope for the statements it contains
    # Begin an new scope, traverses into the statements inside the block, and discard the scope
    def visit_block_stmt(block_stmt)
      begin_scope
      resolve(block_stmt.statements)
      end_scope

      nil
    end

    # Contains a single expression to traverse
    def visit_expression_stmt(stmt)
      resolve_expr(stmt.expr)
      nil
    end

    # Functions both bind name and introduce a scope
    # The name of the function itself is bound in the surrounding scope where the function is declared
    # When we step into the function's body, we also bind its parameters into that inner scope
    # Define name eagerly, before resolving function's body. This lets a function recursively refer to itself inside its own body
    def visit_function_decleration_stmt(stmt)
      declare(stmt.name)

      define(stmt.name)

      resolve_function(stmt, FunctionType::FUNCTION)

      nil
    end

    def visit_return_stmt(stmt)
      # whether or not we're inside a function decleration, check before resolving return statement
      if current_function == FunctionType::NONE
        Lox.error(stmt.keyword, 'Cannot return from top-level code.')
      end

      resolve_expr(stmt.value) if stmt.value
      nil
    end

    # Resolution is different from interpretation
    # When er resolve an if statement, there is no control flow. We resolve the condition and both branches
    # A dynamic execution, in the interpreter, only steps into the branch that is run
    # A static analysis, in the resolver, analyzes **any branh** that could be run
    # It resolves both since either one could be reached at runtime
    def visit_if_stmt(stmt)
      resolve(stmt.condition)
      resolve(stmt.then_branch)
      resolve(stmt.else_branch) unless stmt.else_branch.nil?
      nil
    end

    # A print statement contains a single sub expression
    def visit_print_stmt(stmt)
      resolve_expr(stmt.expr)
      nil
    end

    # Resolving a variable decleration adds a new entry to the current innermost scope's hash
    def visit_var_stmt(var_stmt)
      declare(var_stmt.name)
      resolve_expr(var_stmt.initializer) unless var_stmt.initializer.nil?
      define(var_stmt.name)

      nil
    end

    # As in if statements, we resolve its condition and body exactly once
    def visit_while_stmt(stmt)
      resolve_expr(stmt.condition_expr)
      resolve_stmt(stmt.body_stmt)
      nil
    end

    def visit_variable_expr(expr)
      # Variable exists in the current scope -- declared but not yet defined
      if !scopes.empty? && (scopes.last[expr.name.lexeme] == false)
        Lox.error('Can not read local variable in its own initializer')
      end

      resolve_local(expr, expr.name)

      nil
    end

    def visit_assign_expr(expr)
      resolve_expr(expr.value)
      resolve_local(expr, expr.name)

      nil
    end

    # Traverse into and resolve both operands
    def visit_binary_expr(expr)
      resolve_expr(expr.left_expr)
      resolve_expr(expr.right_expr)
      nil
    end

    # The thing being called, callee, is also an expression(usally a variable exp) so that gets resolved
    # Walk the argument list and resolve them all
    def visit_function_call_expr(expr)
      resolve_expr(expr.callee)

      expr.arguments.each do |argument|
        resolve_expr(argument)
      end

      nil
    end

    #
    def visit_grouping_expr(expr)
      resolve_expr(expr.expr)
      nil
    end

    # Literal expr doesn't mention any variables, does not contain any subexpressions
    def visit_literal_expr(_expr)
      nil
    end

    # A static analysis does no control flow or short-circuiting
    def visit_logical_expr(expr)
      resolve_expr(expr.left_expr)
      resolve_expr(expr.right_expr)
      nil
    end

    # Resolve its one operand
    def visit_unary_expr(expr)
      resolve(expr.right_expr)
      nil
    end

    # Walks a list of statement and resolve each one
    def resolve(statements)
      statements.each { |statement| resolve_stmt(statement) }
    end

    private

    attr_accessor :scopes, :current_function
    attr_reader :interpreter

    # Lexical scope bost nest in interpreter and resolver. They behave like a **stack**
    # Interpreter implements that **stack** usin a linked list, resolver uses stack
    def begin_scope
      # {} -> Map<String, Boolean>
      scopes.push({})
    end

    def end_scope
      scopes.pop
    end

    # When we declare a variable in a local scope, we already know the names of every
    # variable previously declared in that scope, if we see a colission, we report an error
    def declare(name)
      return if scopes.empty?
      scope = scopes.last # peek

      if scope.key?(name.lexeme)
        Lox.error(name, 'Variable with this name already declared in this scope.')
      end

      # Adds variable to the innermost scope so that it shadows any outer one
      # mark it as 'not ready yet' by binding its name to false in the scope map
      scope[name.lexeme] = false
    end

    def define(name)
      return if scopes.empty?
      scope = scopes.last
      # mark it as `fully initialized` and available for use
      scope[name.lexeme] = true
    end

    # Start at the innermost scope and work outwords, looking in each hash for a matching name
    # If we find the variable, tell the inperpreter it has been resolved
    # passing in the number of scopes between the current innermost scope and the scope where the variable was found
    def resolve_local(expr, name)
      scope_size = scopes.size
      (scope_size - 1).downto(0).each do |i|
        if scopes[i].key?(name.lexeme)
          interpreter.resolve(expr, scope_size - 1 - i)
          return
        end
      end
    end

    # Creates a new scope for the body and binds the variables for each of the function's parameters
    # In a static analysis, we immediately traverse into the function's body
    # This is different from how the interpreter handles function declerations.
    # At runtime, declaring a function does not do anyting with with the function's body.
    # that **doesn't get touched** until later when the function is called
    def resolve_function(function_stmt, function_type)
      # has local functions, so you can nest function declarations arbitrarily deeply.
      # We need to keep track not just that we’re in a function, but how many we’re in
      enclosing_function = current_function
      current_function = function_type

      begin_scope
      function_stmt.params.each do |param|
        declare(param)
        define(param)
      end
      resolve(function_stmt.body)
      end_scope

      current_function = enclosing_function
    end

    def resolve_stmt(stmt)
      stmt.accept(self)
    end

    def resolve_expr(expr)
      expr.accept(self)
    end
  end
end