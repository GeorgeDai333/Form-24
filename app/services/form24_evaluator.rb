class Form24Evaluator
  # Validate that expression uses exactly the provided numbers (multiset) and evaluates to 24.
  # cards_values: array of integers, e.g. [1,4,7,10]
  # expression: string
  def self.validate_solution(cards_values, expression)
    tokens = tokenize(expression)
    return { ok: false, error: 'Invalid characters in expression' } unless tokens

    begin
      parser = Parser.new(tokens)
      value = parser.parse
    rescue StandardError => e
      return { ok: false, error: "Parse error: #{e.message}" }
    end

    # numbers used
    nums_used = parser.numbers_used
    # compare multisets
    if multiset_equal?(nums_used, cards_values)
      # Use rational comparison to avoid float issues
      if value == Rational(24, 1)
        { ok: true }
      else
        { ok: false, error: "Expression evaluates to #{value.to_f}, not 24" }
      end
    else
      { ok: false, error: 'Expression must use the four card values exactly once' }
    end
  end

  def self.multiset_equal?(a, b)
    a_sorted = a.map(&:to_i).sort
    b_sorted = b.map(&:to_i).sort
    a_sorted == b_sorted
  end

  def self.tokenize(str)
    s = str.strip
    # allow digits, spaces, parentheses, + - * /
    return nil if s.match(%r{[^0-9\s+\-*/()]})

    tokens = []
    i = 0
    while i < s.length
      c = s[i]
      if c =~ /\s/
        i += 1
        next
      elsif c =~ /[0-9]/
        j = i
        j += 1 while j < s.length && s[j] =~ /[0-9]/
        tokens << [:number, s[i...j].to_i]
        i = j
      elsif ['+', '-', '*', '/', '(', ')'].include?(c)
        # Use descriptive symbols for parentheses so they can be compared safely in code
        tokens << if c == '('
                    [:lpar]
                  elsif c == ')'
                    [:rpar]
                  else
                    [c.to_sym]
                  end
        i += 1
      else
        return nil
      end
    end
    tokens
  end

  class Parser
    attr_reader :numbers_used

    def initialize(tokens)
      @tokens = tokens
      @i = 0
      @numbers_used = []
    end

    def peek
      @tokens[@i]
    end

    def next_token
      t = @tokens[@i]
      @i += 1
      t
    end

    # Grammar:
    # expr := term ((+|-) term)*
    # term := factor ((*|/) factor)*
    # factor := number | ( expr )

    def parse
      res = parse_expr
      raise 'Unexpected token after expression' if peek

      res
    end

    def parse_expr
      res = parse_term
      while peek && %i[+ -].include?(peek[0])
        op = next_token[0]
        rhs = parse_term
        res = apply_op(res, op, rhs)
      end
      res
    end

    def parse_term
      res = parse_factor
      while peek && %i[* /].include?(peek[0])
        op = next_token[0]
        rhs = parse_factor
        res = apply_op(res, op, rhs)
      end
      res
    end

    def parse_factor
      t = peek
      raise 'Unexpected end of input' unless t

      if t[0] == :number
        n = next_token[1]
        @numbers_used << n
        Rational(n, 1)
      elsif t[0] == :lpar
        next_token
        res = parse_expr
        raise 'Missing closing parenthesis' unless peek && peek[0] == :rpar

        next_token
        res

      elsif t[0] == :-
        # unary minus
        next_token
        -parse_factor
      else
        raise "Unexpected token #{t.inspect}"
      end
    end

    def apply_op(lhs, op, rhs)
      case op
      when :+
        lhs + rhs
      when :-
        lhs - rhs
      when :*
        lhs * rhs
      when :/
        raise 'Division by zero' if rhs == 0

        lhs / rhs
      else
        raise "Unknown operator #{op}"
      end
    end
  end
end
