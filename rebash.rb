def format_prompt(prompt)
  return prompt
end

def format_line(line)
  return line
end

def redisplay(prompt, line)
  $stdout.print "\r#{format_prompt(prompt)}: #{format_line(line)}"
  $stdout.flush
end

