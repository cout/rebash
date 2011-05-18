require 'tokenizer'
require 'term/ansicolor'

class Token
  def colorize
    return self.to_s
  end
end

keyword_tokens = [
  DO, DONE, ELIF, ELSE, ESAC, FI, IF, THEN, UNTIL,
  WHILE, FUNCTION, CASE, SELECT, FOR, COPROC
]

keyword_tokens.each do |token|
  def token.colorize
    return Term::ANSIColor.green { self.to_s }
  end
end

punctuation_tokens = [
  SEMI_SEMI, SEMI_AND, SEMI_SEMI_AND, AND_AND, BANG, BAR_AND, OR_OR,
]

punctuation_tokens.each do |token|
  def token.colorize
    return Term::ANSIColor.cyan { self.to_s }
  end
end

class AssignmentWord < Token
  def colorize
    var, value = self.word.split('=', 2)
    return Term::ANSIColor.brown { var } + '=' + Term::ANSIColor.brown { value }
  end
end

class NumberWord < Token
  def colorize
    return Term::ANSIColor.red { self.number }
  end
end

class Colorizer
  def initialize(s)
    @tokenizer = Tokenizer.new(s)
    @tokens = @tokenizer.tokenize
  end

  def colorize
    s = ''
    @tokens.each do |token|
      s << token.colorize
    end
    return s
  end
end

