require './lexer'

describe Lexer do
  context '#tokenize' do
    it "should recognize basic tokens" do
      Lexer.new("<").tokenize.should == [:lbracket]
      Lexer.new(">").tokenize.should == [:rbracket]
      Lexer.new("/").tokenize.should == [:slash]
      Lexer.new("=").tokenize.should == [:equals]
      Lexer.new("\"").tokenize.should == [:quote]
      Lexer.new("?").tokenize.should == [:question_mark]
    end

    it "should recognize longer expressions" do
      t=Lexer.new("<stuff>morestuff</stuff>").tokenize
      t.should == [:lbracket, "stuff", :rbracket, "morestuff", :lbracket, :slash, "stuff", :rbracket]
    end

    it "scans xml declaration correctly" do
      t=Lexer.new('<?xml version="1.0"?>').tokenize
      t.should == [:lbracket, :question_mark, "xml", "version", :equals, :quote, "1.0", :quote, :question_mark, :rbracket] 
    end

    it "scans the sample xml input correctly" do
      text = <<-END
<catalog>
   <book id="bk101">
      <author>Gambardella, Matthew</author>
      <title>XML Developer's Guide</title>
      <genre>Computer</genre>
      <price>44.95</price>
      <publish_date>2000-10-01</publish_date>
      <description>An in-depth look at creating applications 
      with XML.</description>
   </book>
</catalog>
      END
      @lexer = Lexer.new(text)
      @tokens = @lexer.tokenize
      @tokens.should == [:lbracket, "catalog", :rbracket, :lbracket, "book", "id", :equals, :quote, "bk101", :quote,
 :rbracket, :lbracket, "author", :rbracket, "Gambardella, Matthew", :lbracket, :slash, "author", :rbracket, :lbracket, "title", :rbracket, "XML Developer's Guide", :lbracket, :slash, "title", :rbracket, :lbracket,
 "genre", :rbracket, "Computer", :lbracket, :slash, "genre", :rbracket, :lbracket, "price", :rbracket, "44.95", :lbracket, :slash, "price", :rbracket, :lbracket, "publish_date", :rbracket, "2000-10-01", :lbracket,
 :slash, "publish_date", :rbracket, :lbracket, "description", :rbracket, "An in-depth look at creating applications with XML.", :lbracket, :slash, "description", :rbracket, :lbracket, :slash, "book", :rbracket, :lbracket, 
 :slash, "catalog", :rbracket]
    end

  end
end
