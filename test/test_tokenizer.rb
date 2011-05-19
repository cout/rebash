require 'test/unit'
require 'rebash/tokenizer'
require 'ostruct'

class TokenizerTest < Test::Unit::TestCase
  def self.word(str)
    word = OpenStruct.new(:word => str)
    return WordToken.new(word)
  end

  def self.whitespace(str)
    return WhitespaceToken.new(str)
  end

  TEST_CASES = {
    'ls'     => [ word('ls') ],
    'ls -l'  => [ word('ls'), whitespace(' '), word('-l') ],
    # 'for'    => [ FOR ],
    # 'do'     => [ DO ],
    # '$(foo)' => [ ],
    '"foo"'    => [ word('"foo"')],
    '\'foo\''  => [ word('\'foo\'')],
  }

  TEST_CASES.each do |test_case, expected|
    test_name = test_case.dup
    test_name.tr!(' \t', '__')

    define_method("test_#{test_name}") do
      t = Tokenizer.new(test_case)
      a = t.tokenize
      assert_equal(expected, a)
    end
  end

end

