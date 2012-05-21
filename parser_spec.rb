require './parser'
require './lexer'

describe Parser do
  context '#parse' do
    it "parses arguments" do
      token_list = ["id", :equals, :quote, "bk101", :quote]
      p=Parser.new(token_list)
      t=p.argument
      t.should == {:name => "id", :value => "bk101"}
    end

    it "parses argument lists" do
      token_list = ["id", :equals, :quote, "bk101", :quote, "date", :equals, :quote, "2012-02-02", :quote, :rbracket]
      p=Parser.new(token_list)
      t=p.argument_list
      t.should == [{:name => "id", :value => "bk101"}, {:name => "date", :value => "2012-02-02"}]
    end

    it "parses tagstart" do
      token_list = [:lbracket, "book", "id", :equals, :quote, "bk101", :quote, "date", :equals, :quote, "2012-02-02", :quote, :rbracket]
      p=Parser.new(token_list)
      t=p.tag_start
      t.should == {:name=>"book", :arguments=>[{:name=>"id", :value=>"bk101"}, {:name=>"date", :value=>"2012-02-02"}]}
    end

    it "parses tag with text" do
      token_list = [:lbracket, "book", "id", :equals, :quote, "bk101", :quote, "date", :equals, :quote, "2012-02-02", :quote, :rbracket, "tag text", :lbracket, :slash, "book", :rbracket]
      p=Parser.new(token_list)
      t=p.node
      t.to_s.should =='<book id="bk101" date="2012-02-02">tag text</book>'
    end

    it "parses empty tag" do
      token_list = [:lbracket, "catalog", :rbracket, :lbracket, :slash, "catalog", :rbracket]
      p=Parser.new(token_list)
      t=p.node
      t.to_s.should =='<catalog></catalog>'
    end

    it "parses the closing tag" do
      token_list = [:lbracket, :slash, "book", :rbracket]
      p=Parser.new(token_list)
      t=p.tag_end
      t.to_s.should == '{:name=>"book"}'
    end

    it "finds the end of tag token offset" do
      token_list = [:lbracket, "book", "id", :equals, :quote, "bk101", :quote, "date", :equals, :quote, "2012-02-02", :quote, :rbracket,
                   :lbracket, "nestedtag", :rbracket, "nestedtagtext", :lbracket, :slash, "nestedtag", :rbracket,
                   :lbracket, :slash, "book", :rbracket]
      p=Parser.new(token_list)
      p.next!
      t=p.get_tag_end_offset
      t.should == 21
    end

    it "parses tag inside a tag" do
      token_list = [:lbracket, "book", "id", :equals, :quote, "bk101", :quote, "date", :equals, :quote, "2012-02-02", :quote, :rbracket,
                   :lbracket, "nestedtag", :rbracket, "nestedtagtext", :lbracket, :slash, "nestedtag", :rbracket,
                   :lbracket, :slash, "book", :rbracket]
      p=Parser.new(token_list)
      t=p.node
      t.to_s.should == '<book id="bk101" date="2012-02-02"><nestedtag>nestedtagtext</nestedtag></book>'
    end

    it "parses multiple tags inside a tag" do
      token_list = [
      :lbracket, "book", "id", :equals, :quote, "bk101", :quote, "date", :equals, :quote, "2012-02-02", :quote, :rbracket,
        :lbracket, "nestedtag", :rbracket, "nestedtagtext", :lbracket, :slash, "nestedtag", :rbracket,
        :lbracket, "nestedtag", :rbracket, "second nested tag text", :lbracket, :slash, "nestedtag", :rbracket,
      :lbracket, :slash, "book", :rbracket]

      p=Parser.new(token_list)
      t=p.node
      str = <<-END
<book id="bk101" date="2012-02-02">
  <nestedtag>nestedtagtext</nestedtag>
  <nestedtag>second nested tag text</nestedtag>
</book>
      END
      str.gsub!(/\n\s*/,'')
      t.to_s.should == str
    end

    it "should parse sample token input correctly" do
      token_list = [
          :lbracket, "catalog", :rbracket, 
            :lbracket, "book", "id", :equals, :quote, "bk101", :quote, :rbracket, 
              :lbracket, "author", :rbracket, "Gambardella, Matthew", :lbracket, :slash, "author", :rbracket,
              :lbracket, "title", :rbracket, "XML Developer's Guide", :lbracket, :slash, "title", :rbracket,
              :lbracket, "genre", :rbracket, "Computer", :lbracket, :slash, "genre", :rbracket,
              :lbracket, "price", :rbracket, "44.95", :lbracket, :slash, "price", :rbracket,
              :lbracket, "publish_date", :rbracket, "2000-10-01", :lbracket, :slash, "publish_date", :rbracket,
              :lbracket, "description", :rbracket, "An in-depth look at creating applications with XML.", :lbracket, :slash, "description", :rbracket,
            :lbracket, :slash, "book", :rbracket,
          :lbracket, :slash, "catalog", :rbracket]
      p=Parser.new(token_list)
      t=p.parse
      str = <<-END
<catalog>
  <book id="bk101">
    <author>Gambardella, Matthew</author>
    <title>XML Developer's Guide</title>
    <genre>Computer</genre>
    <price>44.95</price>
    <publish_date>2000-10-01</publish_date>
    <description>An in-depth look at creating applications with XML.</description>
  </book>
</catalog>
      END
      str.gsub!(/\n\s*/,'')
      t.to_s.should == str
    end

    it "should return valid tag offset" do
str = <<-END
<catalog>
   <book>
      <author id="bk101">Gambardella, Matthew</author>
      <title>XML Developer's Guide</title>
   </book>
</catalog>
END
      str.gsub!(/\n\s*/,'')

      tokens = Lexer.new(str).tokenize
      Parser.new(tokens).get_tag_end_offset.should == 34
    end


    it "should parse big xml sample" do
str = <<-END
<catalog>
   <book>
      <author id="bk101">Gambardella, Matthew</author>
      <title>XML Developer's Guide</title>
   </book>
</catalog>
END
      str.gsub!(/\n\s*/,'')

      tokens = Lexer.new(str).tokenize
      t = Parser.new(tokens).parse
      t.to_s.should == '<catalog><book><author id="bk101">Gambardella, Matthew</author><title>XML Developer\'s Guide</title></book></catalog>'
    end

    # it "constructs a tree out of nested tags" do
    #   token_list = [
    #       :lbracket, "catalog", :rbracket, 
    #         :lbracket, "book", "id", :equals, :quote, "bk101", :quote, "date", :equals, :quote, "2012/02/03", :quote, :rbracket,
    #           :lbracket, "author", :rbracket, "Gambardella, Matthew", :lbracket, :slash, "author", :rbracket,
    #           :lbracket, "title", :rbracket,
    #             :lbracket, "nested", :rbracket, "text", :lbracket, :slash, "nested", :rbracket,
    #           :lbracket, :slash, "title", :rbracket,
    #           :lbracket, "genre", :rbracket, "Computer", :lbracket, :slash, "genre", :rbracket,
    #           :lbracket, "price", :rbracket, "44.95", :lbracket, :slash, "price", :rbracket,
    #           :lbracket, "publish_date", :rbracket, "2000-10-01", :lbracket, :slash, "publish_date", :rbracket,
    #           :lbracket, "description", :rbracket, "An in-depth look at creating applications with XML.", :lbracket, :slash, "description", :rbracket,
    #         :lbracket, :slash, "book", :rbracket,
    #       :lbracket, :slash, "catalog", :rbracket]
    #   p=Parser.new(token_list)
    #   t=p.parse
      # it = t.inorder_iterator(t, 0)
      # it.call Proc.new {|node, depth|
      #   if node.name != nil
      #     warn "\t"*depth + "#{node.name}" 
      #   end
      # }
      # t.inorder(t,0) {|node,depth|
        # if node.name != nil
        #   warn "\t"*depth + "#{node.name}" 
      # }

      # Node.node_set(t).each_with_index do |el, index|
      #   warn "#{index}: #{el}"
      # end
    # end

    # it "diffs the trees" do
    #   token_list1 = [
    #       :lbracket, "catalog", :rbracket, 
    #         :lbracket, "book", "id", :equals, :quote, "bk101", :quote, "date", :equals, :quote, "2012/02/03", :quote, :rbracket,
    #           :lbracket, "author", :rbracket, "Gambardella, Matthew", :lbracket, :slash, "author", :rbracket,
    #           :lbracket, "title", :rbracket,
    #             :lbracket, "nested", :rbracket, "text", :lbracket, :slash, "nested", :rbracket,
    #           :lbracket, :slash, "title", :rbracket,
    #           :lbracket, "genre", :rbracket, "Computer", :lbracket, :slash, "genre", :rbracket,
    #           :lbracket, "price", :rbracket, "44.95", :lbracket, :slash, "price", :rbracket,
    #           :lbracket, "publish_date", :rbracket, "2000-10-01", :lbracket, :slash, "publish_date", :rbracket,
    #           :lbracket, "description", :rbracket, "An in-depth look at creating applications with XML.", :lbracket, :slash, "description", :rbracket,
    #         :lbracket, :slash, "book", :rbracket,
    #       :lbracket, :slash, "catalog", :rbracket]
    #   token_list2 = [
    #       :lbracket, "catalog", :rbracket, 
    #         :lbracket, "book", "id", :equals, :quote, "bk101", :quote, "date", :equals, :quote, "2012/02/03", :quote, :rbracket,
    #           :lbracket, "author", :rbracket, "Gambardella, Matthew", :lbracket, :slash, "author", :rbracket,
    #           :lbracket, "title", :rbracket,
    #             :lbracket, "nested", :rbracket, "text", :lbracket, :slash, "nested", :rbracket,
    #           :lbracket, :slash, "title", :rbracket,
    #           :lbracket, "price", :rbracket, "44.95", :lbracket, :slash, "price", :rbracket,
    #           :lbracket, "publish_date", :rbracket, "2000-10-01", :lbracket, :slash, "publish_date", :rbracket,
    #           :lbracket, "description", :rbracket, "An in-depth look at creating applications with XML.", :lbracket, :slash, "description", :rbracket,
    #         :lbracket, :slash, "book", :rbracket,
    #       :lbracket, :slash, "catalog", :rbracket]
    #   t1=Parser.new(token_list1).parse
    #   t2=Parser.new(token_list2).parse
    #   t1.diff(t2)
    # end
  end
end
