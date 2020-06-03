require_relative 'token_type'
require_relative 'token'

# Scan through the list of characters and group them together
# into the smallest sequences that still represent something
# Each of this blobs of characters is called a lexeme
# -- they are only raw substrings of the source code
# -- That is what lexical analysis about
class Scanner
  attr_reader :source, :tokens
  attr_accessor :current, :start, :line
  def initialize(source)
    puts "source: #{source}"
    @source = source
    @tokens = []
    @start = 0 # the first char in the current lexeme being scannes
    @current = 0 # the char we are currently considering
    @line = 1 # what source line `current`is on
  end

  # Works its way through the source code, adding tokeen, until it runs out of chars
  def scan_tokens
    until at_end?
      # We are at the begining of the next lexeme
      self.start = current
      scan_token
    end

    # Add final EOF token
    tokens << Token.new(TokenType::EOF, '', nil, line)
    tokens
  end

  private

  # Recognizing lexemes
  def scan_token
    c = advance

    case c
      # Single chars
    when '('
      add_token(TokenType::LEFT_PAREN)
    when ')'
      add_token(TokenType::RIGHT_PAREN)
    when '{'
      add_token(TokenType::LEFT_BRACE)
    when '}'
      add_token(TokenType::RIGHT_BRACE)
    when ','
      add_token(TokenType::COMMA)
    when '.'
      add_token(TokenType::DOT)
    when ';'
      add_token(TokenType::SEMICOLON)
    when '*'
      add_token(TokenType::STAR)
    when '+'
      add_token(TokenType::PLUS)
    when '-'
      add_token(TokenType::MINUS)

    # Operators

    when '!'
      add_token(match('=') ? TokenType::BANG_EQUAL : TokenType::BANG)
    when '='
      add_token(match('=') ? TokenType::EQUAL_EQAUL : TokenType::EQUAL)
    when '<'
      add_token(match('=') ? TokenType::LESS_EQUAL : TokenType::LESS)
    when '>'
      add_token(match('=') ? TokenType::GREATER_EQUAL : TokenType::GREATER)
    when '/'
      # comments begins with slash too
      if match('/')
        # A comments goes until the end of the line
        # We dont add comments to token so parser avoid them
        advance while peek != "\n" && !at_end?
      else
        add_token(TokenType::SLASH)
      end
    when "\t", "\r", ' '
      # When encountering whitespace, we go back to the beginning of the scan loop
      # That starts a new lexime after the whitespace character
      # ignore whitespace
      # puts 'whitespace'
    when "\n"
      # For the new lines, we increment the line counter
      self.line += 1
      puts 'NEW LINE'
    # Literals

    # String Literals
    when '"'
      string

    else
      # Number Literals
      if digit?(c)
        number
      elsif alpha?(c)
        identifier
      else
        Lox.error(line, "Unexpected character.#{c.inspect}")
      end
    end
  end

  def add_token(type, literal = nil)
    text = source[start...current]
    puts "#{start}, #{current}, type:#{type} text: #{text} line:#{line}"
    tokens << Token.new(type, text, literal, line)
  end

  # Consumes the next char and returns it
  def advance
    self.current += 1
    source[current - 1]
  end

  # Does not consume characters. This is called lookahead
  # It looks at the current unconsumed character, we have one char of lookahead
  # The smaller this number is, genarally, the faster the scanner runs
  def peek
    return '\0' if at_end?
    source[current]
  end

  def peek_next
    return '\0' if current + 1 >= source.size
    source[current + 1]
  end

  # Combines peek and advance
  def match(expected_char)
    return false if peek != expected_char
    advance
    true
  end

  # Consume number literal
  def number
    # consumes as many digits as it finds for the integer part
    advance while digit?(peek)
    # Look for fractional part
    # We dont want to consume the . until there is . after is
    # that is wht we have second lookahead -- peek_next
    if peek == '.' && digit?(peek_next)
      # consume the .
      advance

      # consume fractional part
      advance while digit?(peek)
    end

    # convert lexime to its numeric value
    # Using ruby parsing --could implement ourselves
    # will be using ruby float value
    number_value = source[start...current].to_f
    add_token(TokenType::NUMBER, number_value)
  end

  def digit?(c)
    c >= '0' && c <= '9'
  end

  # Maximal munch
  # Whenever two lexical grammar rules can both match a chunk of code
  # that the scanner is looking at, whichever one matches the most characters wins
  # or vs orchid case, for instance, orchid wins
  def identifier
    advance while alpha_numeric?(peek)

    # See if identifier is a reserved word. Otherwise, it's user-defined identifier
    word = source[start...current]
    type = Scanner.keywords.fetch(word, TokenType::IDENTIFIER)
    add_token(type)
  end

  def alpha?(c)
    (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') || c == '_'
  end

  def alpha_numeric?(c)
    alpha?(c) || digit?(c)
  end

  # reserved words map
  def self.keywords
    {
      'and' => TokenType::AND,
      'class' => TokenType::CLASS,
      'else' => TokenType::ELSE,
      'if' => TokenType::IF,
      'for' => TokenType::FOR,
      'var' => TokenType::VAR,
      'nil' => TokenType::NIL,
      'true' => TokenType::TRUE,
      'false' => TokenType::FALSE,
      'this' => TokenType::THIS,
      'while' => TokenType::WHILE,
      'super' => TokenType::SUPER,
      'return' => TokenType::RETURN,
      'print' => TokenType::PRINT,
      'or' => TokenType::OR
    }
  end

  # consume until hits the " that ends the string
  def string
    while peek != '"' && !at_end?
      # allow multi line string
      self.line += 1 if peek == '\n'
      advance
    end

    # Unterminated string
    Lox.error(line, 'UnTerminated string') if at_end?

    # The closing '""
    advance

    # Trim the surrounding quotes
    # Produce actual string value will be used later by interpreter
    val = source[start + 1...current - 1]
    add_token(TokenType::STRING, val)
  end

  # Tell us we've consumed all the chars
  def at_end?
    current >= source.size
  end
end
