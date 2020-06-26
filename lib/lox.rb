# There are two way you can run some code
# 1. from the command line and give it a path to a file -- run_file
# 2. run it interactively -- run_prompt
require_relative 'lox/token_type'
require_relative 'lox/token'
require_relative 'lox/scanner'
require_relative 'lox/parser'
require_relative 'lox/interpreter'
require_relative 'lox/resolver'

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
    puts '[Start Scanning] -- Lexical Analysis'
    scanner = Lox::Scanner.new(source)
    tokens = scanner.scan_tokens

    puts '[Start Parsing] -- Sementic Analysis'
    parser = Lox::Parser.new(tokens)
    statements = parser.parse

    # Stop if there is a syntax error
    # Don't run resolver or interpreter if there is a syntax error
    return if @had_error

    # Do semantic analysis pass after parser does its magic
    # Helps users catch bugs early before running their code
    # has a reference to the interpreter
    # and pokes the resolution data directly into it as it walks over the variables
    # So before running the interpreter, it has everthing it needs
    puts '[Start Resolving] -- Static Analysis'
    resolver = Resolver.new(interpreter)
    resolver.resolve(statements)

    # Skip the interpreter if there is a resolution errors --  code has semantic errors
    return if @had_error
    puts '[Start Interpreting] -- Runtime'
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
