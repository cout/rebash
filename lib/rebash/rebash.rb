require 'colorizer'

def format_prompt(prompt)
  return prompt
end

def format_line(line)
  colorizer = Colorizer.new(line)
  return colorizer.colorize()
end

def redisplay(prompt, line)
  $stdout.print "\r#{format_prompt(prompt)}: #{format_line(line)}"
  $stdout.flush
end

