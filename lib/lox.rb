# There are two way you can run some code
# 1. from the command line and give it a path to a file -- run_file
# 2. run it interactively -- run_prompt
require_relative 'lox/token_type'
require_relative 'lox/token'
require_relative 'lox/scanner'
require_relative 'lox/parser'
require_relative 'lox/interpreter'

module Lox
  # to ensure that we don't try to execute code that has a known error
  # exit with a non-zero exit code
  @had_error = false
  @had_runtime_error = false

  def self.interpreter
    @interpreter ||= Lox::Interpreter.new
  end

  # Runtime errors
  def self.runtime_error(error)
    puts "#{error.message} \n[line #{error.token.line}]"
    @had_runtime_error = true
  end

  module_function

  def main
    # puts ARGV.inspect
    # puts @had_error
    if ARGV.size > 1
      puts 'Usage: jlox [script]'
      exit(64)
    elsif ARGV.size == 1
      run_file(ARGV[0])
    else
      run_prompt
    end
  end

  # Running the script from a file
  # Give it a path to a file, it reads the file and executes it
  def run_file(path)
    content = File.read(path)
    run(content)
    exit(65) if @had_error
    exit(70) if @had_runtime_error # let the calling process know
  end

  # REPL
  # It drops you into a prompt where you can enter
  # and execute code one line at a time
  # (print (eval (read)))
  # Read a line of input
  # Evaluate it
  # Print the result
  # the loop and do it all over again
  def run_prompt
    loop do
      puts '> '
      run(STDIN.gets)
      @had_error = false
    end
  end

  def run(source)
    scanner = Lox::Scanner.new(source)
    tokens = scanner.scan_tokens
    parser = Lox::Parser.new(tokens)
    statements = parser.parse

    # Stop if there is a syntax error
    return if @had_error

    # ASTPrinter.new.print(expression)
    interpreter.interpret(statements)
  end

  # Syntax Error handling
  def error(line, message)
    report(line, '', message)
  end

  def error_token(token, message)
    if token.type == TokenType::EOF
      report(token.line, ' at end', message)
    else
      report(token.line, " at '#{token.lexeme}'", message)
    end
  end

  # Tell users some syntax error occured on a given line
  def report(line, where, message)
    puts "[Line #{line} ] Error #{where}: #{message}"
    @had_error = true
  end
end
