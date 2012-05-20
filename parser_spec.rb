require './parser'

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
      t.to_s.should == '<book id="bk101" date="2012-02-02">["tag text"]</book>'
    end

    it "parses tag inside a tag" do
      token_list = [:lbracket, "book", "id", :equals, :quote, "bk101", :quote, "date", :equals, :quote, "2012-02-02", :quote, :rbracket,
                   :lbracket, "nestedtag", :rbracket, "nestedtagtext", :lbracket, :slash, :rbracket,
                   :lbracket, :slash, "book", :rbracket]
      p=Parser.new(token_list)
      t=p.node
      t.should == []
    end

    # it "constructs a tree out of nested tags" do
    #   token_list = [:lbracket, "book", :rbracket, :lbracket, "tag", :rbracket, "tagtext",:lbracket, :]
    #   p=Parser.new(token_list)
    #   t=p.tag_start
    #   t.should == {:name=>"book", :arguments=>[{:name=>"id", :value=>"bk101"}, {:name=>"date", :value=>"2012-02-02"}]}
    # end
 #    it "should parse sample token input correctly" do
 #      token_list = [:lbracket, "catalog", :rbracket, :lbracket, "book", "id", :equals, :quote, "bk101", :quote,
 # :rbracket, :lbracket, "author", :rbracket, "Gambardella, Matthew", :lbracket, :slash, "author", :rbracket, :lbracket, "title", :rbracket, "XML Developer's Guide", :lbracket, :slash, "title", :rbracket, :lbracket,
 # "genre", :rbracket, "Computer", :lbracket, :slash, "genre", :rbracket, :lbracket, "price", :rbracket, "44.95", :lbracket, :slash, "price", :rbracket, :lbracket, "publish_date", :rbracket, "2000-10-01", :lbracket,
 # :slash, "publish_date", :rbracket, :lbracket, "description", :rbracket, "An in-depth look at creating applications with XML.", :lbracket, :slash, "description", :rbracket, :lbracket, :slash, "book", :rbracket, :lbracket, 
 # :slash, "catalog", :rbracket]
 #      tree = Parser.new(token_list)
 #    end
  end
end
