WordDescBase = Struct.new(:word, :hasdollar, :quoted, :compassign, :nosplit, :assignment)

class WordDesc < WordDescBase
  def initialize(tokenizer, h)
    super()
    self.word = h[:token]
    self.hasdollar = h[:dollar_present]
    self.quoted = h[:quoted]
    self.compassign = h[:compound_assignment] && h[:token][-1] == ?)

    if is_assignment(h[:token], tokenizer.pst_compassign) then
      self.assignment = true

      # Don't perform word splitting on assignment statements.
      self.nosplit = tokenizer.assignment_acceptable(tokenizer.last_read_token) || tokenizer.pst_compassign

    else
      self.assignment = false
      self.nosplit = false
    end
  end

  # Returns non-nil if the string is an assignment statement.  The
  # returned value is the index of the '=' sign.
  def is_assignment(string, flags)
    # TODO: ARRAY_VARS
    if string =~ /^\w+=/ then
      return string.index('=')
    else
      return nil
    end
  end

  def to_token
    if self.assignment and self.nosplit then
      result = AssignmentWordToken.new(self)
    else
      result = WordToken.new(self)
    end

    return result
  end
end

