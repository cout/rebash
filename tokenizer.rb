class Tokenizer
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

  def mbtest(expr)
    # return expr && (@shell_input_line_index > 1) ? shell_input_line_property[shell_input_line_index - 1] : 1
    return expr
  end

  def shellmeta(c)
    return SH_SYNTAXTAB[c].cshmeta
  end

  def shellblank(c)
    return SH_SYNTAXTAB[c].cblank
  end

  def initialize(s)
    @s = s
    @a = s.bytes.to_a
    @a.reverse!

    @posixly_correct = false
  end

  def shell_getc(remove_quoted_newline)
    return @a.pop
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
      if @token_to_read == WORD or @token_to_read == ASSIGNMENT_WORD then
        @yylval.word = @word_desc_to_read
        @word_desc_to_read = nil
      end
      @token_to_read = 0
      return result
    end

    if @pst_condcmd and not @pst_condexpr then
      @cond_lineno = @line_number
      @pst_condexpr = true
      @yylval.command = parse_cond_command()
      if @cond_token != COND_END then
        cond_error()
      end
      @token_to_read = COND_END
      @pst_condexpr = false
      @pst_condcmd = false
      return COND_CMD
    end

    while true do
      # Read a single word from input.  Start by skipping blanks.
      while (character = shell_getc(1)) and shellblank(character) do
      end

      return EOF if character == EOF

      if mbtest(character == ?# && (not @interactive or @interactive_comments)) then
        # A comment.  Discard until EOL or EOF, and then return a newline.
        discard_until(?\n)
        shell_getc(0)
        character = ?\n # this will take the next statement and return.
      end

      if character == ?\n then
        if @need_here_doc then
          gather_here_documents()
        end

        @pst_alexpnext = false
        @pst_assignok = false

        return character
      end

      if not @pst_regexp then

        # Shell meta-characters
        if mbtest(shellmeta(character) && !@pst_dblparen) then
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
              if result == -2 then
                break
              else
                return result
              end

            end
          end

        elsif mbtest(character == ?< && peek_char == ?&) then
          return LESS_AND

        elsif mbtest(character == ?> && peek_char == ?&) then
          return GREATER_AND

        elsif mbtest(character == ?< && peek_char == ?>) then
          return LESS_GREATER

        elsif mbtest(character == ?> && peek_char == ?|) then
          return GREATER_BAR

        elsif mbtest(character == ?& && peek_char == ?>) then
          peek_char = shell_getc(1)
          if mbtest(peek_char == ?>)
            return AND_GREATER_GREATER
          else
            shell_ungetc(peek_char)
            return AND_GREATER
          end

        elsif mbtest(character == ?| && peek_char == ?&) then
          return BAR_AND

        elsif mbtest(character == ?; && peek_char == ?&) then
          @pst_casepat = true
          @pst_alexpnext = false
          return SEMI_AND

        end

        shell_ungetc(peek_char)

        # If we look like we are reading the start of a function definition,
        # then let the reader know about it so that we will do the right
        # thing with '{'.
        if mbtest(character == ')' && last_read_token == '(' && token_before_that == WORD) then
          @pst_allowopnbrc = true
          @pst_alexpnext = false
          @function_dstart = line_number
        end

        # case pattern lists may be preceded by an optional left paren.  If
        # we're not trying to parse a case pattern list, the left paren
        # indicates a subshell.
        if mbtest(character == ?( && !@pst_casepat) then
          @pst_subshell = true
        elsif mbtest(@pst_casepat && character == ?)) then
          @pst_casepat = false
        elsif mbtest(@pst_subshell && character == ?)) then
          @pst_subshell = false
        end

        # Check for the constructs which introduce process substitution.
        # Shells running in `posix mode' don't do process substitution.
        if mbtest(@posixly_correct || ((character != ?> && character != ?<) || peek_char != '(')) then
          return character
        end

        # Hack <&- (close stdin) case.  Also <&N- (dup and close).
        if mbtest(character == '-' && (last_read_token == LESS_AND || last_read_token == GREATER_AND)) then
          return character
        end
      end

      result = read_token_word(character)
      if result != RE_READ_TOKEN then
        return result
      end
    end
  end

  def read_token_word(character)
    next_character = proc {
      if character == ?\n and should_prompt() then
        prompt_again()
      end

      # We want to remove quoted newlines (that is, a \<newline> pair)
      # unless we are within single quotes or pass_next_character is
      # set (the shell equivalent of literal-next).
      cd = current_delimiter(dstack)
      character = shell_getc(cd != ?' && !pass_next_character)
    }

    got_escaped_character = proc {
      all_digit_token &&= DIGIT(character)
      dollar_present ||= (character == ?$)

      token[token_index] = character
      token_index += 1

      next_character()
    }

    got_character = proc {
      if character == CTLESC or character == CTLNUL then
        token[token_index] = CTLESC
        token_index += 1
      end

      got_escaped_character()
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
        yylval.number = parse_number(token)
        return NUMBER
      end

      # Check for special case tokens.
      result = last_shell_getc_is_singlebyte ? special_case_tokens(token) : -1
      if result >= 0 then
        return result
      end

      # Posix.2 does not allow reserved words to be aliased, so check
      # for all of them including special cases, before expanding the
      # current token as an alias.
      if mbtest(posixly_correct) then
        check_for_reserved_word(token)
      end

      # Aliases are expanded iff EXPAND_ALIASES is non-zero, and quoting
      # inhibits alias expansion.
      if expand_aliases and quoted == 0 then
        result = alias_expand_token(token)
        if result == RE_READ_TOKEN then
          return RE_READ_TOKEN
        elsif result == NO_EXPANSION then
          @pst_alexpnext = false
        end
      end

      # If not in Posix.2 mode, check for reserved words after alias
      # expansion.
      if mbtest(posixly_correct == 0) then
        check_for_reserved_word(token)
      end

      the_word.word = token
      the_word.hasdollar = dollar_present
      the_word.quoted = quoted
      the_word.compassign = (compound_assignment && token[token_index-1] == ?))

      if assignment(token, @pst_compassign) then
        the_word.assignment = true

        # Don't perform word splitting on assignment statements.
        the_word.nosplit = assignment_acceptable(last_read_token) or @pst_compassign
      else
        the_word.assignment = false
        the_word.nosplit = false
      end

      if command_token_position(last_read_token) then
        b = builtin_address_internal(token, 0)
        if b.assignment_builtin then
          @pst_assignok = true
        elsif token == "eval" or token == "let" then
          @pst_assignok = true
        end
      end

      yylval.word = the_word

      if token[0] == ?{ and token[token_index-1] == ?} and (character == ?< or character == ?>) then
        # can use token; already copied to the_word
        if legal_identifier(token+1) then
          the_word.word = token+1
          return REDIR_WORD
        end
      end

      result = (the_word.w_assignment && the_word.nosplit) ? ASSIGNMENT_WORD : WORD

      case last_read_token
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
        return got_token()
      end

      if pass_next_character then
        @pass_next_character = false
        got_escaped_character()
        continue
      end

      cd = current_delimiter(dstack)

      # Handle backslashes.  Quote lots of things when not inside of
      # double-quotes, quote some things inside of double-quotes.
      if mbtest(character == ?\\) then
        peek_char = shell_getc(0)

        # Backslash-newline is ignored in all cases except when quoted
        # with single quotes.
        if peek_char == ?\n then
          character == ?\n
          next_character()
          continue
        else
          shell_ungetc(peek_char)

          # If the next character is to be quoted, note it now.
          if cd == ?\000 or cd == ?\` or (cd == ?" and peek_char != nil and (SH_SYNTAXTAB[peek_char].cbsdquote)) then
            pass_next_character += 1
          end

          quoted = true
          got_character()
          next
        end

        # Parse a matched pair of quote characters.
        if mbtest(shellquote(character)) then
          push_delimiter(dstack, character)
          ttok = parse_matched_pair(character, character, character, (character == ?`) ? P_COMMAND : 0)
          token << character.chr
          token << ttok
          all_digit_token = false
          quoted = true
          dollar_present ||= (character == ?" && strchr(ttok, ?$) != 0)
          next_character()
          next
        end

        # When parsing a regexp as a single word inside a conditional
        # command, we need to special-case characters special to both
        # the shell and regular expressions.  Right now, that is only
        # '(' and '|'.
        if mbtest(@pst_regexp && (character == ?( || character == ?|)) then
          if character == ?| then
            got_character()
            next
          end

          push_delimiter(dstack, character)
          ttok = parse_matched_pair(cd, ?(, ?), 0)
          token << character.chr
          token << ttok
          dollar_present = false
          all_digit_token = false
          next_character()
          next
        end

        # Parse a ksh-style extended pattern matching specification.
        if mbtest(extended_glob && PATTERN_CHAR(character)) then
          peek_char = shell_getc(1)
          if mbtest(peek_char == ?() then
            push_delimiter(dstack, peek_char)
            ttok = parse_matched_pair(cd, ?(, ?), 0)
            pop_delimiter(dstack)
            token << character.chr
            token << ttok
            dollar_present = false
            all_digit_token = false
            next_character()
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
              push_delimiter(dstack, peek_char)
              ttok = parse_comsub(cd, ?(, ?), P_COMMAND)
              pop_delimiter(dstack)
            else
              ttok = parse_matched_pair(cd, ?[, ?], 0)
            end

            token << character.chr
            token << peek_char.chr
            token << ttok
            dollar_present = true
            all_digit_token = false
            next_character()
            next

          # This handles $'...' and $"..." new-style quoted strings.
          elsif mbtest(character == ?$ && (peek_char == ?' || peek_char == ?")) then
            first_line = line_number
            push_delimiter(dstack, peek_char)
            ttok = parse_matched_pair(peek_char, peek_char, peek_char, (peek_char == ?') ? P_ALLOWESC : 0)
            pop_delimiter(dstack)
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
          end

        # This could eventually be extended to recognize all of the
        # shell's single-character parameter expansions, and set
        # flags.
        elsif mbtest(character == ?$ && peek_char == ?$) then
          token << ttok
          dollar_present = true
          all_digit_token = false
          next_character()
          next
        else
          shell_ungetc(peek_char)
        end

      # Identify possible array subscript assignment; match [...]. If
      # @pst_comassign, we need to parse [sub]=words treating `sub' as
      # if it were enclosed in double quotes.
      elsif mbtest(character == ?[ &&
                   ((token_index > 0 && assignment_acceptable(last_read_token) && token_is_ident(token, token_index)) or
                    (token == 0 && @pst_compassign))) then
        ttok = parse_matched_pair(cd, ?[, ?], P_ARRAYSUB)
        token << character.chr
        token << ttok
        all_digit_token = false

        # Identify possible compound array variable assignment.
      elsif mbtest(character == ?= && token_index > 0 && (assignment_acceptable(last_read_token) || @pst_assignok) && token_is_assignment(token, token_ident)) then
        peek_char = shell_getc(1)
        if mbtest(peek_char == ?() then
          ttok = parse_compound_assignment()
          token << "=(#{ttok})"
          token_index += 1
          all_digit_token = false
          compound_assignment = true
          next_character()
          next
        else
          shell_ungetc(peek_char)
        end

        # When not parsing a multi-character word construct, shell
        # meta-characters break words.
        if mbtest(shellbreak(character)) then
          shell_ungetc(character)
          return got_token()
        end
      end

    end
  end
end
