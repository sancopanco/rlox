module Lox
  module Stmt
    module Visitor
      def visit_print_stmt(stmt); end

      def visit_expression_stmt(stmt); end

      def accept(visitor); end
    end

    # Statements form a secondary hierarchy of syntax tree nodes
    # independent of expressions
    class Statement
    end

    require_relative 'print'
    require_relative 'expression'
    require_relative 'var'
  end
end
