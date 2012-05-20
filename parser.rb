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
  attr_accessor :children

  def initialize(hash)
    @name      = hash[:name]
    @arguments = hash[:arguments]
    if !hash[:text].nil?
      @children  = [hash[:text]]
    elsif !hash[:children].nil?
      @children  = hash[:children].map{|el| Node.new(el)}
    end
  end

  def to_s
    arguments = @arguments.map {|arg|
      "#{arg[:name]}=\"#{arg[:value]}\""
    }.join(' ')
    "<#{@name} #{arguments}>#{@children}</#{@name}>"
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

  def take!
    v=peek
    next!
    v
  end

  def next!
    @cursor = @cursor + 1
  end

  def end?
    @cursor == @token_list.length
  end

  def xml_document
    node
  end

  def nodelist
    if end?
    else
      first = node
      rest = nodelist
      if rest.nil?
        return first
      else
        rest.first(rest.size-1)
        return [first] << rest
      end
    end
  end

  def node
    # parse & catch info
    tag_info    = tag_start
    tag_content = content
    tag_end

    # return tree
    if tag_content.is_a?(String)
      Node.new(tag_info.merge(:text => tag_content))
    else
      Node.new(tag_info.merge(:children => tag_content))
    end
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
    text
  end

  def argument_list
    if peek == :rbracket
      nil
    else
      arg = argument
      rest = argument_list
      # drop last element
      if rest.nil?  
        return arg
      else
        rest.first(rest.size-1)
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

  def content
    if end?
      nil
    elsif peek == :lbracket
      nodelist
    else
      text
    end
  end

  def text
    text = peek
    next!
    text
  end

  # piszemy RD bo najłatwiej
  def parse
  end

end
