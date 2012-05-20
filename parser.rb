require 'ruby-debug'

## GRAMATYKA:

# <xml_document>  ::= <node>
# <node>          ::= <tag_start> <content> <tag_end>
# <content>       ::= epsilon | text | nodelist
# <nodelist>      ::= <node> | <node> <nodelist> | epsilon
# <tag_start>     ::= '<' <tagid> <argument_list> '>'
# <tag_end>       ::= '</' <tagid> '>'
# <argument_list> ::= epsilon | ' ' <arg> <argument_list>
# <argument>      ::= <text> '=' <text>

class Node
  attr_accessor :children, :parent, :name

  def initialize(hash)
    @name      = hash[:name]
    @arguments = hash[:arguments]
    @children = hash[:children].flatten if !hash[:children].nil?
  end

  def to_s
    # text node
    if @name == "Text"
      @children.join('')
    else
      # node with arguments
      if !@arguments.nil?
        arguments = @arguments.map {|arg|
          "#{arg[:name]}=\"#{arg[:value]}\""
        }.join(' ')
        children_str = @children.map{|el| el.to_s}.join('')
        "<#{@name} #{arguments}>#{children_str}</#{@name}>"
      # node with no arguments
      else
        children_str = @children.map{|el| el.to_s}.join('')
        "<#{@name}>#{children_str}</#{@name}>"
      end
    end
  end
end

class Parser
  attr_reader :cursor, :token_list

  def initialize(token_list)
    # remove all whitespace from text
    @token_list = token_list
    @cursor = 0
  end

  def peek
    @token_list[@cursor]
  end

  def next!
    @cursor = @cursor + 1
    self
  end

  def end?
    @cursor == @token_list.length
  end

  def xml_document
    node
  end

  def at(cursor = @cursor)
    @token_list[cursor]
  end

  ##
  # Returns ending tag (wrt the tag we're currently in)
  # lbracket token offset
  def tag_end_offset
    depth = 1
    cursor = @cursor
    while depth != 0 && cursor < @token_list.size
      if at(cursor) == :lbracket && at(cursor+1).is_a?(String)
        depth = depth + 1
      elsif at(cursor) == :lbracket && at(cursor+1) == :slash
        depth = depth - 1
      end
      cursor = cursor + 1
    end

    cursor-1
  end

  def nodelist(tag_end_offset)
    if @cursor >= tag_end_offset
      nil
    else
      car = node
      cdr = nodelist(tag_end_offset)
      # drop last element - it's a nil
      if cdr.nil?
        return [car]
      else
        return [car] << cdr
      end
    end
  end

  def node
    # parse & catch info
    tag_info     = tag_start
    # compute closing tag offset so we know when to stop parsing tokens for tag content
    tag_content  = content(tag_end_offset)
    tag_end_info = tag_end
    if tag_end_info[:name] != tag_info[:name]
      raise 'Closing tag not found'
    end

    # return tree
    t=tag_content
    node = Node.new(tag_info.merge(:children => t))
    node.children.map {|el| el.parent = node }
    node
  end

  def tag_start
    if peek == :lbracket
      next!
      id   = tag_name
      args = argument_list
      if peek == :rbracket
        next!
      end

      {:name => id, :arguments => args}
    end
  end

  def tag_end
    if peek == :lbracket
      next!
      if peek == :slash
        next!
        name = tag_name
        if peek == :rbracket
          next!
          return {:name => name}
        end
      end
    end
  end

  def tag_name
    identifier
  end

  ##
  # Returns: Array of hashes with :name, :value keys
  def argument_list
    if peek == :rbracket
      nil
    else
      arg = argument
      rest = argument_list
      # drop last element
      if rest.nil?  
        return [arg]
      else
        return [arg] << rest
      end
    end
  end

  def argument
    name = peek
    next!
    if peek == :equals
      next!
      if peek == :quote
        next!
        value = peek
        next!
        if peek == :quote
          next!
          {:name => name, :value => value}
        end
      end
    end
  end

  ##
  # Returns: array of elements contained in tag
  def content(tag_end_offset)
    if @cursor == tag_end_offset
      nil
    elsif peek == :lbracket
      nodelist(tag_end_offset)
    else
      [text]
    end
  end

  ##
  # Identifiers are just plain text
  def identifier
    text = peek
    next!
    text
  end

  ##
  # Used for text nested inside of tags
  # Returns: Text node with one element array of children containing text string
  def text
    text_node = Node.new(:name => "Text", :children => [peek])
    next!
    text_node
  end

  # piszemy RD bo najłatwiej
  def parse
    xml_document
  end

end
