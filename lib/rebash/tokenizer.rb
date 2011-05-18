require 'rebash/tokens'
require 'rebash/syntab'
require 'rebash/word'

class Tokenizer
  attr_reader :pst_compassign
  attr_reader :last_read_token

  EOF = nil

  CTLESC = ?\001
  CTLNUL = ?\177

  # Return true if TOKSYM is a token that after being read would allow a
  # reserved word to be seen, else 0.
  def reserved_word_acceptable(toksym)
    if [ ?\n, ?;, ?(, ?), ?|, ?&, ?{, ?}, AND_AND, BANG, BAR_AND, DO, DONE, ELIF, ELSE, ESAC, FI, IF, OR_OR, SEMI_SEMI, SEMI_AND, SEMI_SEMI_AND, THEN, COPROC, UNTIL, WHILE, ?\000 ].include?(toksym) then
      return true
    else
      if @last_read_token == WORD && @token_before_that == COPROC then
        return true
      else
        return false
      end
    end
  end

  def check_for_reserved_word(tok)
    return false; # TODO
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
  #   ']]' is returned as COND_END if the parser is currently parsing a
  #   conditional expression ((parser_state & PST_CONDEXPR) != 0)
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
    @interactive = true # TODO
    @interactive_comments = true # TODO

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

    @dstack = [ ]

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

  def read_token
    if @token_to_read then
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
      @cond_lineno = @line_number
      @pst_condexpr = true
      command = parse_cond_command()
      cond_error() if @cond_token != COND_END
      @token_to_read = COND_END
      @pst_condexpr = false
      @pst_condcmd = false
      return CondCommandToken.new(command)
    end

    while true do
      character = shell_getc(1)
      return EOF if character == EOF

      if shellblank(character) then
        return WhitespaceToken.new(character.chr)
      end

      if character == ?# && (not @interactive or @interactive_comments) then
        # A comment.  Discard until EOL or EOF, and then return a newline.
        comment = ''
        while (character = shell_getc(1)) and character != ?\n and character != EOF do
          comment << character.chr
        end
        shell_ungetc(character)
        return CommentToken.new(comment)
      end

      if character == ?\n then
        gather_here_documents() if @need_here_doc

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
      if shellmeta(character) && !@pst_dblparen then
        result = read_shellmeta(character)
        return result if result
      end

      # Okay, if we got this far, we have to read a word.  Read one, and
      # then check it against the known ones.
      result = read_token_word(character)
      if result != RE_READ_TOKEN then
        return result
      else
        next
      end
    end
  end

  def digit(character)
    return [?0, ?1, ?2, ?3, ?4, ?5, ?6, ?7, ?8, ?9].include?(character)
  end

  def read_token_word(character)
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
      cd = @dstack[-1]
      character = shell_getc(cd != ?' && !pass_next_character)
    }

    got_escaped_character = proc {
      all_digit_token &&= digit(character)
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
      if all_digit_token && (character == ?< || character == ?> ||
                                     @last_read_token == LESS_AND || 
                                     @last_read_token == GREATER_AND) then
        number = parse_number(token)
        return Number.new(number)
      end

      # Check for special case tokens.
      result = special_case_tokens(token)
      return result if result

      # Posix.2 does not allow reserved words to be aliased, so check
      # for all of them including special cases, before expanding the
      # current token as an alias.
      if @posixly_correct then
        check_for_reserved_word(token)
      end

      # Aliases are expanded iff EXPAND_ALIASES is non-zero, and quoting
      # inhibits alias expansion.
      if @expand_aliases and quoted == 0 then
        result = alias_expand_token(token)
        case result
        when RE_READ_TOKEN then return RE_READ_TOKEN
        when NO_EXPANSION then @pst_alexpnext = false
        end
      end

      # If not in Posix.2 mode, check for reserved words after alias
      # expansion.
      if not @posixly_correct then
        check_for_reserved_word(token)
      end

      the_word = WordDesc.new(
          self,
          :token => token,
          :dollar_present => dollar_present,
          :quoted => quoted,
          :compound_assignment => compound_assignment)

      if command_token_position(@last_read_token) then
        b = builtin_address_internal(token, 0)
        if b.assignment_builtin then
          @pst_assignok = true
        elsif token == "eval" or token == "let" then
          @pst_assignok = true
        end
      end

      if token[0] == ?{ and token[-1] == ?} and (character == ?< or character == ?>) then
        # can use token; already copied to the_word
        if legal_identifier(token[1..-1]) then
          the_word.word = token[1..-1]
          return REDIR_WORD
        end
      end

      result = the_word.to_token

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
      if character == EOF then
        return got_token.call()
      end

      if pass_next_character then
        @pass_next_character = false
        got_escaped_character.call()
        next
      end

      cd = @dstack[-1]

      # Handle backslashes.  Quote lots of things when not inside of
      # double-quotes, quote some things inside of double-quotes.
      if character == ?\\ then
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
      if shellquote(character) then
        @dstack.push(character)
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
      if @pst_regexp && (character == ?( || character == ?|) then
        if character == ?| then
          got_character.call()
          next
        end

        @dstack.push(character)
        ttok = parse_matched_pair(cd, ?(, ?), 0)
        token << character.chr
        token << ttok
        dollar_present = false
        all_digit_token = false
        next_character.call()
        next
      end

      # Parse a ksh-style extended pattern matching specification.
      if @extended_glob && PATTERN_CHAR(character) then
        peek_char = shell_getc(1)
        if peek_char == ?( then
          @dstack.push(peek_char)
          ttok = parse_matched_pair(cd, ?(, ?), 0)
          @dstack.pop()
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
        peek_char = shell_getc(1)
        # $(...), <(...), >(...), $((...)), ${...}, and $[...]
        # constructs
        if peek_char == ?( ||
                  ((peek_char == ?{ || peek_char == ?[) && character == ?$) then
          if peek_char == ?{ then
            ttok = parse_matched_pair(cd, ?{, ?}, P_FIRSTCLOSE)
          elsif peek_char == ?( then
            # XXX - push and pop the `(' as a delimiter for use by the
            # command-oriented-history code.  This way newlines
            # appearing in the $(...) string get added to the history
            # literally rather than causing a possibly-incorrect `;'
            # to be added.
            @dstack.push(peek_char)
            ttok = parse_comsub(cd, ?(, ?), P_COMMAND)
            @dstack.pop()
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
        elsif character == ?$ && (peek_char == ?' || peek_char == ?") then
          first_line = line_number
          @dstack.push(peek_char)
          ttok = parse_matched_pair(peek_char, peek_char, peek_char, (peek_char == ?') ? P_ALLOWESC : 0)
          @dstack.pop()
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
        elsif character == ?$ && peek_char == ?$ then
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
      elsif character == ?[ &&
                   ((token.length > 0 && assignment_acceptable(@last_read_token) && token_is_ident(token)) or
                    (token == 0 && @pst_compassign)) then
        ttok = parse_matched_pair(cd, ?[, ?], P_ARRAYSUB)
        token << character.chr
        token << ttok
        all_digit_token = false

        # Identify possible compound array variable assignment.
      elsif character == ?= && token.length() > 0 && (assignment_acceptable(@last_read_token) || @pst_assignok) && token_is_assignment(token, token_ident) then
        peek_char = shell_getc(1)
        if peek_char == ?( then
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
      if shellbreak(character) then
        shell_ungetc(character)
        return got_token.call()
      end

      got_character.call()
    end

    got_token.call()
  end

  def read_shellmeta(character)
    # Turn off alias tokenization iff this character sequence would
    # not leave us ready to read a command.
    if character == ?< or character == ?> then
      @pst_alexpnext = false
    end

    @pst_assignok = false

    peek_char = shell_getc(1)
    if character == peek_char then
      case character
      when ?<
        # If '<' then we could be at '<<' or at '<<-'.  We have to
        # look ahead one more character.
        peek_char = shell_getc(1)
        case peek_char
        when ?- then return LESS_LESS_MINUS
        when ?< then return LESS_LESS_LESS
        else; shell_ungetc(peek_char); return LESS_LESS
        end

      when ?>
        return GREATER_GREATER

      when ?;
        @pst_casepat = true
        @pst_alexpnext = false

        peek_char = shell_getc(1)
        case peek_char
        when ?& then return SEMI_SEMI_AND
        else; return SEMI_SEMI
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

    elsif character == ?< && peek_char == ?& then
      return LESS_AND

    elsif character == ?> && peek_char == ?& then
      return GREATER_AND

    elsif character == ?< && peek_char == ?> then
      return LESS_GREATER

    elsif character == ?> && peek_char == ?| then
      return GREATER_BAR

    elsif character == ?& && peek_char == ?> then
      peek_char = shell_getc(1)
      case peek_char
      when ?> then return AND_GREATER_GREATER
      else; shell_ungetc(peek_char); return AND_GREATER
      end

    elsif character == ?| && peek_char == ?& then
      return BAR_AND

    elsif character == ?; && peek_char == ?& then
      @pst_casepat = true
      @pst_alexpnext = false
      return SEMI_AND

    end

    shell_ungetc(peek_char)

    # If we look like we are reading the start of a function definition,
    # then let the reader know about it so that we will do the right
    # thing with '{'.
    if character == ')' && last_read_token == '(' && token_before_that == WORD then
      @pst_allowopnbrc = true
      @pst_alexpnext = false
      @function_dstart = line_number
    end

    # case pattern lists may be preceded by an optional left paren.  If
    # we're not trying to parse a case pattern list, the left paren
    # indicates a subshell.
    if character == ?( && !@pst_casepat then
      @pst_subshell = true
    elsif @pst_casepat && character == ?) then
      @pst_casepat = false
    elsif @pst_subshell && character == ?) then
      @pst_subshell = false
    end

    # Check for the constructs which introduce process substitution.
    # Shells running in `posix mode' don't do process substitution.
    if @posixly_correct || ((character != ?> && character != ?<) || peek_char != '(') then
      return character
    end

    # Hack <&- (close stdin) case.  Also <&N- (dup and close).
    if character == '-' && (last_read_token == LESS_AND || last_read_token == GREATER_AND) then
      return character
    end

    return nil
  end
end

