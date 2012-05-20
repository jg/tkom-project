require 'ruby-debug'
require 'set'

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
  attr_accessor :children, :parent, :name, :arguments

  def initialize(hash)
    @name      = hash[:name]
    @arguments = hash[:arguments]
    @children = hash[:children].flatten if !hash[:children].nil?
  end

  ##
  # Arguments are root node and function callback
  # callback is called for each node reachable from root node
  # tree is traversed inorder
  # def inorder(node, depth)
  #   yield(node, depth)
  #   node.children.map do |el|
  #     inorder(el, depth+1)
  #   end
  # end
  def self.inorder(node, callback, depth)
    callback.call(node, depth)
    node.children.map do |el|
      inorder(el, callback, depth+1) unless node.name == "Text"
    end
  end

  def self.node_set(node)
    collection = []

    # callback for inorder HOF
    f = lambda { |node, depth|
      collection[depth] = [] if collection[depth].nil?

      # text node
      if node.name == "Text"
        collection[depth] << ["#{node.name}", node.children.first]
      # node with arguments
      elsif !node.arguments.nil?
        args = node.arguments.map {|h|
          "#{h[:name]}=#{h[:value]}"
        }.sort
        collection[depth] << ["#{node.name} #{args.join(' ')}"]
      else
        collection[depth] << [node.name]
      end
    }

    # collect nodes from tree
    Node.inorder(node,f,0)

    # sort each level of tree
    collection.map {|level| level.sort }
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

  ##
  # Returns a list of nodes which are present in self but not in tree
  def diff(node)
    ns1 = Node.node_set(self)
    ns2 = Node.node_set(node)

    if ns1.length != ns2.length
      warn 'Tree depths do not match'
      return
    end

    warn "\n"
    warn 'tree2-tree1:'
    0.upto(ns1.length-1) do |level|
      ns1[level].each_with_index do |element, i|
        if ns2[level].find_index(element).nil?
          # warn "Element #{element} found at #{level}/#{i}"
          warn "\t#{element} not in tree2 (level #{level})"
        end
      end
    end
    warn '-'*78
    warn 'tree1-tree2'
    0.upto(ns1.length-1) do |level|
      ns2[level].each_with_index do |element, i|
        if ns1[level].find_index(element).nil?
          warn "\t #{element} not in tree1 (level #{level})"
        end
      end
    end
    warn '-'*78
    warn 'in tree1 and tree2:'
    0.upto(ns1.length-1) do |level|
      ns2[level].each_with_index do |element, i|
        if !ns1[level].find_index(element).nil?
          warn "\t #{element} (level: #{level})"
        end
      end
    end
  end

  def ==(other)
    @name == other.name && Set.new(@arguments) == Set.new(other.arguments)
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
        [arg]
      else
        [arg, rest].flatten
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
