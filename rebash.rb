$: << '/home/cout/git/rbsh/lib'
require 'rbsh/shell'

def format_prompt(prompt)
  return prompt
end

def format_line(line)
  line = line.gsub(/ls/, "\033[34mls\033[m")
  return line
end

$parser = ShellParser.new

def redisplay(prompt, line)
  $parser.scan_evaluate(line.dup)
  tokens = $parser.instance_eval { @rex_tokens }
  $stdout.puts line.inspect
  $stdout.puts tokens.inspect

  $stdout.print "\r#{format_prompt(prompt)}: #{format_line(line)}"
  $stdout.flush
end

