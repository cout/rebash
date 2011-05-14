def redisplay(prompt, line)
  $stdout.print "\r#{prompt}: #{line}"
  $stdout.flush
end

