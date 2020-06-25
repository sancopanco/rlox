module Lox
  module Stmt
    class LoxClass < Statement
      attr_reader :name, :superclass, :method_stmts

      # name: class_name token
      # superclass: variable expr
      # method_stmts: list of function stmt
      def initialize(name, method_stmts, superclass = nil)
        @name = name
        @superclass = superclass
        @method_stmts = method_stmts
      end

      def accept(visitor)
        visitor.visit_class_stmt(self)
      end
    end
  end
end
