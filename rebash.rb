def format_prompt(prompt)
  return prompt
end

def format_line(line)
  line = line.gsub(/ls/, "\033[34mls\033[m")
  return line
end

def redisplay(prompt, line)
  $stdout.print "\r#{format_prompt(prompt)}: #{format_line(line)}"
  $stdout.flush
end

