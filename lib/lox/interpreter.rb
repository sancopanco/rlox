require_relative 'visitor'
require_relative 'runtime_error'

module Lox
  class Interpreter
    include Lox::Visitor

    # Public API
    # Takes a syntax tree for an expression and evaluates it
    # Converts that to a string  and shows it to the user
    # Report the run time errors and to user and continue
    def interpret(expression)
      # value is ruby object
      value = evaluate(expression)
      p stringify(value)
    rescue Lox::RuntimeError => error
      Lox.runtime_error(error)
      # puts error
    end

    # Convert literal tree node into a runtime value
    def visit_literal_expr(expr)
      expr.value
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

    private

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
