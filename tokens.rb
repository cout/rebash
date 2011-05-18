class Token
  attr_reader :name

  def initialize(name, str)
    @name = name
    @str = str
  end

  def to_s
    return @str.to_s
  end
end

class WhitespaceToken < Token
  attr_reader :space

  def initialize(space)
    super("WHITESPACE", space)
    @space = space
  end
end

WORD = Object.new

class WordToken < Token
  attr_reader :word

  def initialize(word)
    super("WORD", word.word)
    @word = word
  end

  def ==(rhs)
    return true if rhs == WORD
    return false if not rhs.is_a?(WordToken)
    return self.word == rhs.word
  end
end

ASSIGNMENT_WORD = Object.new

class AssignmentWordToken < Token
  attr_reader :word

  def initialize(word)
    super("ASSIGNMENT_WORD", word.word)
    @word = word
  end

  def ==(rhs)
    return true if rhs == ASSIGNMENT_WORD
    return false if not rhs.is_a?(AssignmentWordToken)
    return self.word == rhs.word
  end
end

REDIR_WORD = Object.new

class RedirWordToken < Token
  attr_reader :word

  def initialize(word)
    super("WORD", word.word)
    @word = word
  end

  def ==(rhs)
    return true if rhs == REDIR_WORD
    return false if not rhs.is_a?(RedirWordToken)
    return self.word == rhs.word
  end
end

COND_CMD = Object.new

class CondCommandToken < Token
  attr_reader :command

  def initialize(command)
    super("COMMAND", command)
    @command = command
  end

  def ==(rhs)
    return true if rhs == COND_CMD
    return false if not rhs.is_a?(CondCommandToken)
    return self.command == rhs.command
  end
end

NUMBER = Object.new

class NumberToken < Token
  attr_reader :number

  def initialize(number)
    super("NUMBER", number)
    @number = number
  end

  def ==(rhs)
    return true if rhs == NUMBER
    return false if not rhs.is_a?(NumberToken)
    return self.number == rhs.number
  end
end

# Tokens
ARITH_FOR_EXPRS = Token.new("ARITH_FOR_EXPRS", "???")
SEMI_SEMI = Token.new("SEMI_SEMI", ";;")
SEMI_AND = Token.new("SEMI_AND", ";&")
SEMI_SEMI_AND = Token.new("SEMI_SEMI_AND", ";;&")
AND_AND = Token.new("AND_AND", "&&")
BANG = Token.new("BANG", "!")
BAR_AND = Token.new("BAR_AND", "|&")
DO = Token.new("DO", "do")
DONE = Token.new("DONE", "done")
ELIF = Token.new("ELIF", "elif")
ELSE = Token.new("ELSE", "else")
ESAC = Token.new("ESAC", "esac")
FI = Token.new("FI", "fi")
IF = Token.new("IF", "if")
OR_OR = Token.new("OR_OR", "||")
THEN = Token.new("THEN", "then")
COPROC = Token.new("COPROC", "coproc")
UNTIL = Token.new("UNTIL", "until")
WHILE = Token.new("WHILE", "while")
FUNCTION = Token.new("FUNCTION", "function")
CASE = Token.new("CASE", "case")
SELECT = Token.new("SELECT", "select")
FOR = Token.new("FOR", "for")
RE_READ_TOKEN = Token.new("RE_READ_TOKEN", "RE_READ_TOKEN")

