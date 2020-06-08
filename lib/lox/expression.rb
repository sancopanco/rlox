# expression → literal
#            | unary
#            | binary
#            | grouping ;

# literal    → NUMBER | STRING | "true" | "false" | "nil" ;
# grouping   → "(" expression ")" ;
# unary      → ( "-" | "!" ) expression ;
# binary     → expression operator expression ;
# operator   → "==" | "!=" | "<" | "<=" | ">" | ">="
#            | "+"  | "-"  | "*" | "/" ;

require_relative 'token'
require_relative 'token_type'

module Lox
  class Expression
  end

  class Binary < Expression
    attr_reader :operator, :left_expr, :right_expr

    def initialize(left_expr, operator, right_expr)
      @left_expr = left_expr
      @right_expr = right_expr
      @operator = operator # token
    end

    def accept(visitor)
      visitor.visit_binary_expr(self)
    end
  end

  # A Grouping node has a reference to an inner node
  # the expression contained inside the parantheses
  class Grouping < Expression
    attr_reader :expr

    def initialize(expr)
      @expr = expr
    end

    def accept(visitor)
      visitor.visit_grouping_expr(self)
    end
  end

  # The leaves of an expression tree -- the atomic bits of syntax
  # that all other expressions are composed of
  class Literal < Expression
    attr_reader :value

    def initialize(value)
      @value = value
    end

    def accept(visitor)
      visitor.visit_literal_expr(self)
    end
  end

  class Unary < Expression
    attr_reader :operator, :right_expr
    def initialize(operator, right_expr)
      @operator = operator
      @right_expr = right_expr
    end

    def accept(visitor)
      visitor.visit_unary_expr(self)
    end
  end
end
