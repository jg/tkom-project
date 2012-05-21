require 'ruby-debug'

## Rozpoznawane tokeny:
# < LBRACKET
# > RBRACKET
# = EQUAL
# " QUOTE
# / SLASH
# TEXT

class Text
  attr_reader :text
  def initialize(text)
    @text = text
  end

  def ==(obj)
    if obj.respond_to?(:text)
      @text == obj.text
    else
      @text == obj
    end
  end

  def to_s
    "#{@text}"
  end
end

##
# Transforms plain text into an array of tokens
# strings are represented as standard ruby strings
class Lexer
  attr_reader :cursor, :text

  def initialize(text)
    # remove all whitespace from text
    @text = remove_whitespace(text)
    @cursor = 0
  end

  def remove_whitespace(s)
    s.gsub!(/\s+/, ' ')
    s.gsub!(/>(\s)</, '><')
    s
  end

  def peek
    @text[@cursor] if @cursor < @text.length
  end

  def peek1
    @text[@cursor+1] if @cursor+1 < @text.length
  end

  def next!
    @previous_cursor = @cursor
    @cursor = @cursor + 1 if @cursor < @text.length
    self
  end

  ##
  # Has the cursor reached the end of text?
  def end?
    @cursor == @text.length
  end

  ##
  # Restore previous cursor
  def back!
    @cursor = @previous_cursor
  end

  ##
  # Moves the @cursor before the next ocurrence of str returns text between 
  # the current cursor and its new value
  # skip_pattern parameter controls whether the cursor stays behind the matched
  # pattern (:before), at the first character of the pattern (:at) or after 
  # the pattern (:after)
  def skip_until!(pattern, cursor_placement = :after)
    @previous_cursor = @cursor
    if pattern.class == String
      if i = @text.index(pattern, @cursor+1)
        ret = @text[@cursor..i-1]
        case cursor_placement
          when :before
            @cursor = i-1
          when :at
            @cursor = i
          when :after
            @cursor = i+pattern.length
        end
        ret
      else
        nil
      end
    elsif pattern.class == Regexp
      if m = @text[@cursor+1..@text.length].match(pattern)
        new_cursor = @text.index(m[0], @cursor+1)
        ret = @text[@cursor..new_cursor-1]
        case cursor_placement
          when :before
            @cursor = new_cursor-1
          when :at
            @cursor = new_cursor
          when :after
            @cursor = new_cursor+m[0].length
        end
        ret
      else
        nil
      end
    end
  end

  ##
  # Returns the index of the first character in text matched by pattern starting 
  # from @cursor
  def index(pattern)
    if pattern.class == String
      if i = @text.index(pattern, @cursor+1)
        return (i+1)
      end
    elsif pattern.class == Regexp
      if m = @text[@cursor+1..@text.length].match(pattern)
        return (@text.index(m[0], @cursor+1)+1)
      end
    end
    nil
  end

  ##
  # Returns a hash of attribute name -> value
  def self.scan_attributes(text)
    parts = text.split('"').map {|el| el.strip }
    h = {}
    parts.each_with_index do |el, i|
        h[parts[i].chop] = parts[i+1] if i % 2 == 0
    end
    h
  end

  def scan_xml_declaration
    attrs = Lexer.scan_attributes(skip_until!('?>'))
    Node.new('xml', attrs)
  end

  ##
  # Assuming the cursor is at '<' this function returns a Node
  # structure from the tag name and its attributes
  def scan_xml_node
    next! # skip initial '<'
    attrs = {}
    inner_text = skip_until!('>', :after)

    if inner_text.include?('=') # tag has attributes
      name_end_index = inner_text.index(' ')
      attrs = Lexer.scan_attributes(inner_text[name_end_index..inner_text.length])
      name = inner_text[0..name_end_index-1]
    else
      name = inner_text
    end

    Node.new(name, attrs)
  end

  def scan_text
    Text.new(skip_until!('<', :at))
  end


  def end_text_capture
    t=Text.new(@tmp_text)
    @tmp_text = ""
    t
  end

  def tokenize
    token_list = []
    @in_text = false
    @in_identifier = false
    @tmp_text = ""

    while not end?
      case peek
        when '<' # new tag or xml declaration
          @in_tag = true
          if @in_text
            @in_text = false
            token_list << end_text_capture
          end

          @in_identifier = true
          token_list << :lbracket
        when '>'
          @in_tag = false
          if @in_identifier
            @in_identifier = false
            token_list << end_text_capture
            # puts '----------------------'
            # puts text
            # puts '----------------------'
            # token_list << 
          end

          if @in_text
            @in_text = false
          end

          token_list << :rbracket
        when '"'
          if @in_text
            @in_text = false
            token_list << end_text_capture
          end

          token_list << :quote
        when '='
          if @in_text
            @in_text = false
            token_list << end_text_capture
          end

          token_list << :equals
        when '?'
          token_list << :question_mark
        when '/'
          @in_identifier = true
          token_list << :slash
        when ' '
          if @in_identifier
            @in_identifier = false
            token_list << end_text_capture
          end

          if @in_text && !@in_tag
            @tmp_text += peek
          end
        else
          @in_text = true
          @tmp_text += peek
      end

      next!

    end

    token_list
  end
end
