# There are two way you can run some code
# 1. from the command line and give it a path to a file -- run_file
# 2. run it interactively -- run_prompt
require_relative 'scanner'

module Lox
  # to ensure that we don't try to execute code that has a known error
  # exit with a non-zero exit code
  @had_error = false

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

  # Give it a path to a file, it reads the file and executes it
  def run_file(path)
    content = File.read(path)
    run(content)
    exit(65) if @had_error
  end

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
    scanner = Scanner.new(source)
    tokens = scanner.scan_tokens
    tokens.each do |token|
      p token
    end
  end

  # Syntax Error handling
  def error(line, message)
    report(line, '', message)
  end

  # Tell users some syntax error occured on a given line
  def report(line, where, message)
    puts "[Line #{line} ] Error #{where}: #{message}"
    @had_error = true
  end
end

Lox.main
