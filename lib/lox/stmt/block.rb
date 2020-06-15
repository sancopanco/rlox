module Lox
  module Stmt
    class Block < Statement
      attr_reader :statements

      def initialize(statements)
        @statements = statements
      end

      def accept(visitor)
        visitor.visit_block_stmt(self)
      end
    end
  end
end
