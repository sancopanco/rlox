# A bundle containing the raw lexeme along with the oher things
# the scanner learned about it
module Lox
  # A Token represents a unit of code at a specific place in the source text
  class Token
    attr_reader :type, :lexeme, :literal, :line

    def initialize(type, lexeme, literal, line)
      @type = type
      @lexeme = lexeme
      @literal = literal
      # need to tell users where error occurred
      @line = line
    end

    def to_s
      "#{type} #{lexeme} #{line}"
    end
  end
end
