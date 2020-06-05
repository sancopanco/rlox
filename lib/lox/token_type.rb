# We have a different type for each keyword, operator, bit of panctuation, and literal type
module Lox
  module TokenType
    # Single-character tokens
    LEFT_PAREN = 'LEFT_PAREN'.freeze
    RIGHT_PAREN = 'RIGHT_PAREN'.freeze
    LEFT_BRACE = 'LEFT_BRACE'.freeze
    RIGHT_BRACE = 'RIGHT_BRACE'.freeze
    COMMA = 'COMMA'.freeze
    DOT = 'DOT'.freeze
    MINUS = 'MINUS'.freeze
    PLUS = 'PLUS'.freeze
    SEMICOLON = 'SEMICOLON'.freeze
    SLASH = 'SLASH'.freeze
    STAR = 'STAR'.freeze

    # # One or two character tokens
    BANG = 'BANG'.freeze
    BANG_EQUAL = 'BANG_EQUAL'.freeze
    EQUAL = 'EQUAL'.freeze
    EQUAL_EQAUL = 'EQUAL_EQAUL'.freeze
    GREATER = 'GREATER'.freeze
    GREATER_EQUAL = 'GREATER_EQUAL'.freeze
    LESS = 'LESS'.freeze
    LESS_EQUAL = 'LESS_EQUAL'.freeze

    # Literals
    STRING = 'STRING'.freeze
    NUMBER = 'NUMBER'.freeze

    IDENTIFIER = 'IDENTIFIER'.freeze

    # # KEYWORDS
    AND = 'AND'.freeze
    CLASS = 'CLASS'.freeze
    ELSE = 'ELSE'.freeze
    FALSE = 'FALSE'.freeze
    FUN = 'FUN'.freeze
    FOR = 'FOR'.freeze
    IF = 'FUN'.freeze
    NIL = 'NIL'.freeze
    OR = 'OR'.freeze
    PRINT = 'PRINT'.freeze
    RETURN = 'RETURN'.freeze
    SUPER = 'SUPER'.freeze
    THIS = 'THIS'.freeze
    TRUE = 'TRUE'.freeze
    VAR = 'VAR'.freeze
    WHILE = 'WHILE'.freeze

    EOF = 'EOF'.freeze
  end
end
