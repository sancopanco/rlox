module Lox
  module Stmt
    class Return < Statement
      attr_reader :keyword, :value

      def initialize(keyword, value)
        @keyword = keyword
        @value = value
      end

      def accept(visitor)
        visitor.visit_return_stmt(self)
      end
    end
  end
end
