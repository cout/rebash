require 'rebash/colorizer'

def format_prompt(prompt)
  # TODO: These characters indicate that contained between them is a
  # non-printable sequence.  What should we do with them?
  prompt.gsub!(/\001/, '')
  prompt.gsub!(/\002/, '')

  return prompt
end

def format_line(line)
  colorizer = Colorizer.new(line)
  return colorizer.colorize()
end

def redisplay(prompt, line)
  $stdout.print "\r#{format_prompt(prompt)}#{format_line(line)}"
  $stdout.flush
end

