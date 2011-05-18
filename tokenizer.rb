class Tokenizer
  class Token
    attr_reader :name

    def initialize(name)
      @name = name
    end
  end

  WORD = Object.new

  class WordToken < Token
    attr_reader :word

    def initialize(word)
      super("WORD")
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
      super("ASSIGNMENT_WORD")
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
      super("WORD")
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
      super("COMMAND")
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
      super("NUMBER")
      @number = number
    end

    def ==(rhs)
      return true if rhs == NUMBER
      return false if not rhs.is_a?(NumberToken)
      return self.number == rhs.number
    end
  end

  # Tokens
  ARITH_FOR_EXPRS = Token.new("ARITH_FOR_EXPRS")
  TIME = Token.new("TIME")
  SEMI_SEMI = Token.new("SEMI_SEMI")
  SEMI_AND = Token.new("SEMI_AND")
  SEMI_SEMI_AND = Token.new("SEMI_SEMI_AND")
  AND_AND = Token.new("AND_AND")
  BANG = Token.new("BANG")
  BAR_AND = Token.new("BAR_AND")
  DO = Token.new("DO")
  DONE = Token.new("DONE")
  ELIF = Token.new("ELIF")
  ELSE = Token.new("ELSE")
  ESAC = Token.new("ESAC")
  FI = Token.new("FI")
  IF = Token.new("IF")
  OR_OR = Token.new("OR_OR")
  THEN = Token.new("THEN")
  TIMEOPT = Token.new("TIMEOPT")
  COPROC = Token.new("COPROC")
  UNTIL = Token.new("UNTIL")
  WHILE = Token.new("WHILE")
  FUNCTION = Token.new("FUNCTION")
  CASE = Token.new("CASE")
  SELECT = Token.new("SELECT")
  FOR = Token.new("FOR")
  RE_READ_TOKEN = Token.new("RE_READ_TOKEN")

  WordDesc = Struct.new(:word, :hasdollar, :quoted, :compassign, :nosplit, :assignment)

  SyntabEntryStruct = Struct.new(
      :cword, :cspecl, :cshbrk, :cblank, :cbsdquote, :cglob, :cxglob,
      :cspecvar, :cquote, :cxquote, :cexp, :cbshdoc, :cshmeta, :cshglob,
      :csubstop, :cbackq)
  class SyntabEntry < SyntabEntryStruct
    def initialize(*flags)
      flags.each { |flag| self[flag] = true }
    end
  end

  SH_SYNTAXTAB = Hash.new { |h, c| h[c] = SyntabEntry.new(:cword) }
  SH_SYNTAXTAB[?\001] = SyntabEntry.new(:cspecl)
  SH_SYNTAXTAB[?\t] = SyntabEntry.new(:cshbrk, :cblank)
  SH_SYNTAXTAB[?\n] = SyntabEntry.new(:cshbrk, :cbsdquote)
  SH_SYNTAXTAB[?\s] = SyntabEntry.new(:cshbrk, :cblank)
  SH_SYNTAXTAB[?!] = SyntabEntry.new(:cxglob, :cspecvar)
  SH_SYNTAXTAB[?"] = SyntabEntry.new(:cquote, :cbsdquote, :cxquote)
  SH_SYNTAXTAB[?#] = SyntabEntry.new(:cspecvar)
  SH_SYNTAXTAB[?$] = SyntabEntry.new(:cexp, :cbsdquote, :cbshdoc, :cspecvar)
  SH_SYNTAXTAB[?&] = SyntabEntry.new(:cshmeta, :cshbrk)
  SH_SYNTAXTAB[?'] = SyntabEntry.new(:cquote, :cxquote)
  SH_SYNTAXTAB[?(] = SyntabEntry.new(:cshmeta, :cshbrk)
  SH_SYNTAXTAB[?)] = SyntabEntry.new(:cshmeta, :cshbrk)
  SH_SYNTAXTAB[?*] = SyntabEntry.new(:cglob, :cshglob, :cspecvar)
  SH_SYNTAXTAB[?+] = SyntabEntry.new(:cxglob, :csubstop)
  SH_SYNTAXTAB[?-] = SyntabEntry.new(:cxglob, :csubstop)
  SH_SYNTAXTAB[?;] = SyntabEntry.new(:cshmeta, :cshbrk)
  SH_SYNTAXTAB[?<] = SyntabEntry.new(:cshmeta, :cshbrk, :cexp)
  SH_SYNTAXTAB[?=] = SyntabEntry.new(:csubstop)
  SH_SYNTAXTAB[?>] = SyntabEntry.new(:cshmeta, :cshbrk, :cexp)
  SH_SYNTAXTAB[?@] = SyntabEntry.new(:cxglob, :cspecvar)
  SH_SYNTAXTAB[?[] = SyntabEntry.new(:cglob)
  SH_SYNTAXTAB[?\\] = SyntabEntry.new(:cbsdquote, :cbshdoc, :cxquote)
  SH_SYNTAXTAB[?]] = SyntabEntry.new(:cglob)
  SH_SYNTAXTAB[?`] = SyntabEntry.new(:cbackq, :cquote, :cbsdquote, :cbshdoc, :cxquote)
  SH_SYNTAXTAB[?|] = SyntabEntry.new(:cshmeta, :cshbrk)
  SH_SYNTAXTAB[?\177] = SyntabEntry.new(:cspecl)

  EOF = nil

  CTLESC = ?\001
  CTLNUL = ?\177

  DStack = Struct.new(:delimiters, :delimiter_depth, :delimeter_space)

  def mbtest(expr)
    # TODO: return expr && (@shell_input_line_index > 1) ? shell_input_line_property[shell_input_line_index - 1] : 1
    return expr
  end

  def last_shell_getc_is_singlebyte
    # TODO: return shell_input_line_index > 1 ?
    # shell_input_line_property[shell_input_line_index - 1] : 1
    return true
  end

  # Return true if TOKSYM is a token that after being read would allow a
  # reserved word to be seen, else 0.
  def reserved_word_acceptable(toksym)
    if [ ?\n, ?;, ?(, ?), ?|, ?&, ?{, ?}, AND_AND, BANG, BAR_AND, DO, DONE, ELIF, ELSE, ESAC, FI, IF, OR_OR, SEMI_SEMI, SEMI_AND, SEMI_SEMI_AND, THEN, TIME, TIMEOPT, COPROC, UNTIL, WHILE, ?\000 ].include?(toksym) then
      return true
    else
      if @last_read_token == WORD && @token_before_that == COPROC then
        return true
      else
        return false
      end
    end
  end

  def command_token_position(token)
    return token == ASSIGNMENT_WORD ||
      @pst_redirlist ||
        (token != SEMI_SEMI && token != SEMI_AND && token != SEMI_SEMI_AND && reserved_word_acceptable(token))
  end

  # Handle special cases of token recognition:
  #   IN is recognized if the last token was WORD and the token before
  #   that was FOR or CASE or SELECT.
  #
  #   DO is recognized if the last token was WORD and the token before
  #   that was FOR or SELECT.
  #
  #   ESAC is recognized if the last token caused `esacs_needed_count'
  #   to be set.
  #
  #   `{' is recognized if the last token was WORD and the token before
  #   that was FUNCTION, or if we just parsed an arithmetic `for'
  #   command.
  #
  #   `}' is recognized if there is an unclosed '{' present.
  #
  #   `-p' is recognized as TIMEOPT if the last read token was TIME.
  #
  #   ']]' is returned as COND_END if the parser is currently parsing a
  #   conditional expression ((parser_state & PST_CONDEXPR) != 0)
  #
  #   `time' is returned as TIME if and only if it is immediately
  #   preceded by one of `:', `\n', `||', `&&', or `&'.
  def special_case_tokens(tokstr)
    if (@last_read_token == WORD) &&
       (@token_before_that == FOR || @token_before_that == CASE || @token_before_that == SELECT) &&
       (tokstr == "in") then
      if @token_before_that == CASE
        @pst_casepat = true
        @esacs_needed_count += 1
      end
      return IN
    end

    if (@last_read_token == WORD) &&
          (@token_before_that == FOR || @token_before_that == SELECT) &&
          (tokstr == "do")
      return DO
    end

    # Ditto for ESAC in the CASE case.
    # Specifically, this handles "case word in esac", which is a legal
    # construct, certainly because someone will base an empty arg to the
    # case construct, and we don't want it to barf.  Of course, we
    # should insist that the case construct has at least one pattern in
    # it, but the designers disagree.
    if (@esacs_needed_count > 0) then
      @esacs_needed_count -= 1
      if tokstr == "esac" then
        @pst_casepat = false
        return ESAC
      end
    end

    if @pst_allowopnbrc then
      @pst_allowopnbrc = false
      if tokstr == '{' then
        @open_brace_count += 1
        @function_bstart = @line_number
        return '{'
      end
    end

    # We allow a `do' after a for ((...)) without an intervening
    # list_terminator.
    if @last_read_token == ARITH_FOR_EXPRS && tokstr == "do" then
      return DO
    end

    if @last_read_token == ARITH_FOR_EXPRS && tokstr == '{' then
      @open_brace_count += 1
      return '{'
    end

    if @open_brace_count > 0 && reserved_word_acceptable(@last_read_token) && tokstr == '}' then
      @open_brace_count -= 1
    end

    # Handle -p after `time'.
    if @last_read_token == TIME && tokstr == '-[' then
      return TIMEOPT
    end

    if @pst_condexpr && tokstr == ']]' then
      return COND_END
    end

    return nil
  end

  def shellmeta(c)
    return SH_SYNTAXTAB[c].cshmeta
  end

  def shellblank(c)
    return SH_SYNTAXTAB[c].cblank
  end

  def shellquote(c)
    return SH_SYNTAXTAB[c].cquote
  end

  def shellbreak(c)
    return SH_SYNTAXTAB[c].cshbrk
  end

  def shellexp(c)
    return c == ?$ || c == ?< || c == ?>
  end

  def initialize(s)
    @s = s
    @a = s.bytes.to_a
    @a.reverse!

    @posixly_correct = false

    @token_to_read = nil
    @word_desc_to_read = nil
    @cond_token = nil

    @need_here_doc = false

    @pst_condcmd = false
    @pst_condexpr = false
    @pst_alexpnext = false
    @pst_assignok = false
    @pst_regexp = false
    @pst_dblparen = false
    @pst_casepat = false
    @pst_allowopnbrc = false
    @pst_subshell = false
    @pst_compassign = false
    @pst_comassign = false

    @function_dstart = nil

    @dstack = DStack.new

    # TODO:
    # if @pst_extpat then
    #   @extended_glob = global_extglob
    # end
    @extended_glob = false

    @esacs_needed_count = 0
    @open_brace_count = 0

    @expand_aliases = false
  end

  def shell_getc(remove_quoted_newline)
    c = @a.pop
    debug_log("getc returning #{c ? c.chr : 'nil'}")
    return c 
  end

  def shell_ungetc(c)
    @a.push(c)
  end

  def tokenize
    a = [ ]
    while token = read_token() do
      a.push(token)
    end
    return a
  end

  def debug_log(s)
    puts s
  end

  def current_delimiter(ds)
    return ds.delimiter_depth ? ds.delimiters[ds.delimiter_depth - 1] : 0
  end

  def read_token
    if @token_to_read then
      debug_log "have @token_to_read"
      result = @token_to_read
      if @token_to_read == WORD then
        @token_to_read = nil
        @word_desc_to_read = nil
        return WordToken.new(@word_desc_to_read)
      elsif @token_to_read == ASSIGNMENT_WORD then
        @token_to_read = nil
        @word_desc_to_read = nil
        return AssignmentWordToken.new(@word_desc_to_read)
      else
        @token_to_read = nil
        return result
      end
    end

    if @pst_condcmd and not @pst_condexpr then
      debug_log "@pst_condcmd and not @pst_condexpr"
      @cond_lineno = @line_number
      @pst_condexpr = true
      command = parse_cond_command()
      if @cond_token != COND_END then
        cond_error()
      end
      @token_to_read = COND_END
      @pst_condexpr = false
      @pst_condcmd = false
      return CondCommandToken.new(command)
    end

    while true do
      debug_log("at top of loop")

      # Read a single word from input.  Start by skipping blanks.
      while (character = shell_getc(1)) != EOF and shellblank(character) do
      end

      return EOF if character == EOF

      debug_log("got character '#{character.chr}'")

      if mbtest(character == ?# && (not @interactive or @interactive_comments)) then
        debug_log("comment")
        # A comment.  Discard until EOL or EOF, and then return a newline.
        discard_until(?\n)
        shell_getc(0)
        character = ?\n # this will take the next statement and return.
      end

      if character == ?\n then
        debug_log("newline")
        if @need_here_doc then
          gather_here_documents()
        end

        @pst_alexpnext = false
        @pst_assignok = false

        return character
      end

      if @pst_regexp then
        result = read_token_word(character)
        if result != RE_READ_TOKEN then
          return result
        else
          next
        end
      end

      # Shell meta-characters
      if mbtest(shellmeta(character) && !@pst_dblparen) then
        debug_log("shellmeta and not @pst_dblparen")
        # Turn off alias tokenization iff this character sequence would
        # not leave us ready to read a command.
        if character == ?< or character == ?> then
          @pst_alexpnext = false
        end

        @pst_assignok = false

        peek_char = shell_getc(1)
        debug_log("peek_char is #{peek_char ? peek_char.chr : peek_char.inspect}")
        if character == peek_char then
          case character
          when ?<
            # If '<' then we could be at '<<' or at '<<-'.  We have to
            # look ahead one more character.
            peek_char = shell_getc(1)
            if mbtest(peek_char == '-') then
              return LESS_LESS_MINUS
            elsif mbtest(peek_char == '<') then
              return LESS_LESS_LESS
            else
              shell_ungetc(peek_char)
              return LESS_LESS
            end

          when ?>
            return GREATER_GREATER

          when ?;
            @pst_casepat = true
            @pst_alexpnext = false

            peek_char = shell_getc(1)
            if mbtest(peek_char == '&') then
              return SEMI_SEMI_AND
            else
              shell_ungetc(peek_char)
              return SEMI_SEMI
            end

          when ?&
            return AND_AND

          when ?|
            return OR_OR

          when ?(
            result = parse_dparen(character)
            if result != -2 then
              return result
            end

          end

        elsif mbtest(character == ?< && peek_char == ?&) then
          debug_log("less_and")
          return LESS_AND

        elsif mbtest(character == ?> && peek_char == ?&) then
          debug_log("greater_and")
          return GREATER_AND

        elsif mbtest(character == ?< && peek_char == ?>) then
          debug_log("less_greater")
          return LESS_GREATER

        elsif mbtest(character == ?> && peek_char == ?|) then
          debug_log("greater_bar")
          return GREATER_BAR

        elsif mbtest(character == ?& && peek_char == ?>) then
          debug_log("and_greater")
          peek_char = shell_getc(1)
          if mbtest(peek_char == ?>)
            return AND_GREATER_GREATER
          else
            shell_ungetc(peek_char)
            return AND_GREATER
          end

        elsif mbtest(character == ?| && peek_char == ?&) then
          debug_log("bar_and")
          return BAR_AND

        elsif mbtest(character == ?; && peek_char == ?&) then
          debug_log("semi_and")
          @pst_casepat = true
          @pst_alexpnext = false
          return SEMI_AND

        end

        debug_log("returning peek char")
        shell_ungetc(peek_char)

        # If we look like we are reading the start of a function definition,
        # then let the reader know about it so that we will do the right
        # thing with '{'.
        if mbtest(character == ')' && last_read_token == '(' && token_before_that == WORD) then
          debug_log("close paren on word")
          @pst_allowopnbrc = true
          @pst_alexpnext = false
          @function_dstart = line_number
        end

        # case pattern lists may be preceded by an optional left paren.  If
        # we're not trying to parse a case pattern list, the left paren
        # indicates a subshell.
        if mbtest(character == ?( && !@pst_casepat) then
          debug_log("open paren and not @pst_casepat")
          @pst_subshell = true
        elsif mbtest(@pst_casepat && character == ?)) then
          debug_log("@pst_casepat and close paren")
          @pst_casepat = false
        elsif mbtest(@pst_subshell && character == ?)) then
          debug_log("@pst_subshell and close paren")
          @pst_subshell = false
        end

        # Check for the constructs which introduce process substitution.
        # Shells running in `posix mode' don't do process substitution.
        if mbtest(@posixly_correct || ((character != ?> && character != ?<) || peek_char != '(')) then
          debug_log("posixly_correct or (not > and not <) or '('")
          return character
        end

        # Hack <&- (close stdin) case.  Also <&N- (dup and close).
        if mbtest(character == '-' && (last_read_token == LESS_AND || last_read_token == GREATER_AND)) then
          return character
        end
      end

      # Okay, if we got this far, we have to read a word.  Read one, and
      # then check it against the known ones.
      result = read_token_word(character)
      debug_log("read_token_word returned #{result}")
      if result != RE_READ_TOKEN then
        return result
      else
        debug_log("re-reading")
        next
      end
    end
  end

  # Returns non-nil if the string is an assignment statement.  The
  # returned value is the index of the '=' sign.
  def assignment(string, flags)
    # TODO: ARRAY_VARS
    if string =~ /^\w+=/ then
      return string.index('=')
    else
      return nil
    end
  end

  def digit(character)
    return [?0, ?1, ?2, ?3, ?4, ?5, ?6, ?7, ?8, ?9].include?(character)
  end

  def read_token_word(character)
    debug_log("read_token_word")

    dollar_present = false # becomes true if we see a `$'
    quoted = false         # becomes true if we see one of ("), ('), (`), or (\)
    pass_next_character = false # true means to ignore the value of the next character and just to add it no matter what
    compound_assignment = false # becomes true if we are parsing a compound assignment

    token = ""
    all_digit_token = digit(character)

    next_character = proc {
      if character == ?\n and should_prompt() then
        prompt_again()
      end

      # We want to remove quoted newlines (that is, a \<newline> pair)
      # unless we are within single quotes or pass_next_character is
      # set (the shell equivalent of literal-next).
      cd = current_delimiter(@dstack)
      character = shell_getc(cd != ?' && !pass_next_character)
    }

    got_escaped_character = proc {
      all_digit_token &&= DIGIT(character)
      dollar_present ||= (character == ?$)

      token << character.chr

      next_character.call()
    }

    got_character = proc {
      if character == CTLESC or character == CTLNUL then
        token << CTLESC.chr
      end

      got_escaped_character.call()
    }

    got_token = proc {
      # Check to see what thing we should return.  If the
      # last_read_token is a `<' or a `&', or the character which ended
      # this token is a '>' or '<', then and ONLY then, is this input
      # token a NUMBER.  Otherwise, it is just a word, and should be
      # returned as such.
      if mbtest(all_digit_token && (character == ?< || character == ?> ||
                                     last_read_token == LESS_AND || 
                                     last_read_token == GREATER_AND)) then
        number = parse_number(token)
        return Number.new(number)
      end

      # Check for special case tokens.
      result = last_shell_getc_is_singlebyte ? special_case_tokens(token) : nil
      return result if result

      # Posix.2 does not allow reserved words to be aliased, so check
      # for all of them including special cases, before expanding the
      # current token as an alias.
      if mbtest(@posixly_correct) then
        check_for_reserved_word(token)
      end

      # Aliases are expanded iff EXPAND_ALIASES is non-zero, and quoting
      # inhibits alias expansion.
      if @expand_aliases and quoted == 0 then
        result = alias_expand_token(token)
        if result == RE_READ_TOKEN then
          return RE_READ_TOKEN
        elsif result == NO_EXPANSION then
          @pst_alexpnext = false
        end
      end

      # If not in Posix.2 mode, check for reserved words after alias
      # expansion.
      if mbtest(@posixly_correct == 0) then
        check_for_reserved_word(token)
      end

      the_word = WordDesc.new
      the_word.word = token
      the_word.hasdollar = dollar_present
      the_word.quoted = quoted
      the_word.compassign = (compound_assignment && token[-1] == ?))

      if assignment(token, @pst_compassign) then
        the_word.assignment = true

        # Don't perform word splitting on assignment statements.
        the_word.nosplit = assignment_acceptable(@last_read_token) or @pst_compassign
      else
        the_word.assignment = false
        the_word.nosplit = false
      end

      if command_token_position(@last_read_token) then
        b = builtin_address_internal(token, 0)
        if b.assignment_builtin then
          @pst_assignok = true
        elsif token == "eval" or token == "let" then
          @pst_assignok = true
        end
      end

      word = the_word

      if token[0] == ?{ and token[-1] == ?} and (character == ?< or character == ?>) then
        # can use token; already copied to the_word
        if legal_identifier(token[1..-1]) then
          the_word.word = token[1..-1]
          return REDIR_WORD
        end
      end

      if the_word.assignment and the_word.nosplit then
        result = AssignmentWordToken.new(word)
      else
        result = WordToken.new(word)
      end

      case @last_read_token
      when FUNCTION
        @pst_allowopnbrc = true
        function_dstart = line_number
      when CASE, SELECT, FOR
        if word_top < MAX_CASE_NEST then
          word_top += 1
        end
        word_lineno[word_top] = line_number
      end

      result
    }

    while true do
      debug_log("at top of read token word loop")

      if character == EOF then
        return got_token.call()
      end

      if pass_next_character then
        @pass_next_character = false
        got_escaped_character.call()
        next
      end

      cd = current_delimiter(@dstack)

      # Handle backslashes.  Quote lots of things when not inside of
      # double-quotes, quote some things inside of double-quotes.
      if mbtest(character == ?\\) then
        debug_log("backslash")
        peek_char = shell_getc(0)

        # Backslash-newline is ignored in all cases except when quoted
        # with single quotes.
        if peek_char == ?\n then
          character == ?\n
          next_character.call()
          next
        else
          shell_ungetc(peek_char)

          # If the next character is to be quoted, note it now.
          if cd == ?\000 or cd == ?\` or (cd == ?" and peek_char != nil and (SH_SYNTAXTAB[peek_char].cbsdquote)) then
            pass_next_character += 1
          end

          quoted = true
          got_character.call()
          next
        end
      end

      # Parse a matched pair of quote characters.
      if mbtest(shellquote(character)) then
        debug_log("shellquote")
        push_delimiter(@dstack, character)
        ttok = parse_matched_pair(character, character, character, (character == ?`) ? P_COMMAND : 0)
        token << character.chr
        token << ttok
        all_digit_token = false
        quoted = true
        dollar_present ||= (character == ?" && strchr(ttok, ?$) != 0)
        next_character.call()
        next
      end

      # When parsing a regexp as a single word inside a conditional
      # command, we need to special-case characters special to both
      # the shell and regular expressions.  Right now, that is only
      # '(' and '|'.
      if mbtest(@pst_regexp && (character == ?( || character == ?|)) then
        debug_log("regexp")
        if character == ?| then
          got_character.call()
          next
        end

        push_delimiter(@dstack, character)
        ttok = parse_matched_pair(cd, ?(, ?), 0)
        token << character.chr
        token << ttok
        dollar_present = false
        all_digit_token = false
        next_character.call()
        next
      end

      # Parse a ksh-style extended pattern matching specification.
      if mbtest(@extended_glob && PATTERN_CHAR(character)) then
        debug_log("extended glob")
        peek_char = shell_getc(1)
        if mbtest(peek_char == ?() then
          push_delimiter(@dstack, peek_char)
          ttok = parse_matched_pair(cd, ?(, ?), 0)
          pop_delimiter(@dstack)
          token << character.chr
          token << ttok
          dollar_present = false
          all_digit_token = false
          next_character.call()
          next
        else
          shell_ungetc(peek_char)
        end
      end

      # If the delimiter character is not single quote, parse some of
      # the shell expansions that must be read as a single word.
      if shellexp(character) then
        debug_log("shellexp")
        peek_char = shell_getc(1)
        # $(...), <(...), >(...), $((...)), ${...}, and $[...]
        # constructs
        if mbtest(peek_char == ?( ||
                  ((peek_char == ?{ || peek_char == ?[) && character == ?$)) then
          if peek_char == ?{ then
            ttok = parse_matched_pair(cd, ?{, ?}, P_FIRSTCLOSE)
          elsif peek_char == ?( then
            # XXX - push and pop the `(' as a delimiter for use by the
            # command-oriented-history code.  This way newlines
            # appearing in the $(...) string get added to the history
            # literally rather than causing a possibly-incorrect `;'
            # to be added.
            push_delimiter(@dstack, peek_char)
            ttok = parse_comsub(cd, ?(, ?), P_COMMAND)
            pop_delimiter(@dstack)
          else
            ttok = parse_matched_pair(cd, ?[, ?], 0)
          end

          token << character.chr
          token << peek_char.chr
          token << ttok
          dollar_present = true
          all_digit_token = false
          next_character.call()
          next

        # This handles $'...' and $"..." new-style quoted strings.
        elsif mbtest(character == ?$ && (peek_char == ?' || peek_char == ?")) then
          first_line = line_number
          push_delimiter(@dstack, peek_char)
          ttok = parse_matched_pair(peek_char, peek_char, peek_char, (peek_char == ?') ? P_ALLOWESC : 0)
          pop_delimiter(@dstack)
          if peek_char == ?' then
            ttrans = ansiexpand(ttok, 0)
            ttok = sh_single_quote(ttrans)
            ttrans = ttok
          else
            # Try to locale-expand the converted string.
            ttrans = localeexpand(ttok, 0, first_line)

            # Add the double quotes back
            ttok = sh_mkdoublequoted(ttrans, 0)
            ttrans = ttok
          end

          token << ttrans
          quoted = true
          all_digit_token = false
          next_character()
          next

        # This could eventually be extended to recognize all of the
        # shell's single-character parameter expansions, and set
        # flags.
        elsif mbtest(character == ?$ && peek_char == ?$) then
          token << ttok
          dollar_present = true
          all_digit_token = false
          next_character.call()
          next
        else
          shell_ungetc(peek_char)
        end

      # Identify possible array subscript assignment; match [...]. If
      # @pst_comassign, we need to parse [sub]=words treating `sub' as
      # if it were enclosed in double quotes.
      elsif mbtest(character == ?[ &&
                   ((token.length > 0 && assignment_acceptable(@last_read_token) && token_is_ident(token)) or
                    (token == 0 && @pst_compassign))) then
        debug_log('possible array subscript assignment')
        ttok = parse_matched_pair(cd, ?[, ?], P_ARRAYSUB)
        token << character.chr
        token << ttok
        all_digit_token = false

        # Identify possible compound array variable assignment.
      elsif mbtest(character == ?= && token.length() > 0 && (assignment_acceptable(@last_read_token) || @pst_assignok) && token_is_assignment(token, token_ident)) then
        peek_char = shell_getc(1)
        if mbtest(peek_char == ?() then
          ttok = parse_compound_assignment()
          token << "=(#{ttok})"
          all_digit_token = false
          compound_assignment = true
          next_character.call()
          next
        else
          shell_ungetc(peek_char)
        end
      end

      # When not parsing a multi-character word construct, shell
      # meta-characters break words.
      if mbtest(shellbreak(character)) then
        shell_ungetc(character)
        return got_token.call()
      end

      got_character.call()

      debug_log("end of loop")
    end

    got_token.call()
  end
end

