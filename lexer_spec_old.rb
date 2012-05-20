require './lexer'

describe Lexer do
  context '#peek' do
    before do
      text = '<'
      @lexer = Lexer.new(text)
    end

    it 'should return the character under index' do
      @lexer.peek.should == '<'
    end

    it 'should return nil if at the end of text' do
      @lexer.next!.peek.should be_nil
    end
  end

  context '#index' do
    it 'should return the position of the first character matched by pattern in text' do
      text = '<genre>Fantasy</genre>'
      lexer = Lexer.new(text)
      lexer.index('Fantasy').should == 8
      lexer.index('Stuff').should == nil
      lexer.index(/[fF]antasy/).should == 8
    end
  end


  context '#peek1' do
    it 'should return the next character under index' do
      text = '<?xml version="1.0"?>'
      lexer = Lexer.new(text).peek1.should == '?'
    end
  end

  context '#next!' do
    it 'should move the text pointer one character forward' do
      text = '<?xml version="1.0"?>'
      lexer = Lexer.new(text)
      lexer.peek.should == '<'
      lexer.next!
      lexer.peek.should == '?'
    end
  end

  context '#skip_until!' do
    before do
      text = '<?xml version="1.0"?>'
      @lexer = Lexer.new(text)
      @lexer.next!.next!
    end

    it 'should move the text pointer after the pattern found' do
      @lexer.skip_until!('?')
      @lexer.peek.should == '>'

      @lexer.skip_until!(/\?/)
      @lexer.peek.should == '>'
    end

    it 'should move the text pointer before if :before parameter given' do
      @lexer.skip_until!('?', :before)
      @lexer.peek.should == '"'

      @lexer.skip_until!(/\?/, :before)
      @lexer.peek.should == '"'
    end

    it 'should move the text pointer properly if :at parameter given' do
      @lexer.skip_until!('?', :at)
      @lexer.peek.should == '?'

      @lexer.skip_until!(/\?/, :at)
      @lexer.peek.should == '?'
    end

    it 'returns text between old pointer position and start of match' do
      @lexer.skip_until!('?').should == "xml version=\"1.0\""
    end

    it 'should recognize regexps' do
      @lexer.skip_until!(/[?]>/).should == "xml version=\"1.0\""
    end

    it 'should recognize regexps' do
      @lexer.skip_until!(/[?]/).should == "xml version=\"1.0\""
    end

  end

  context '#scan_attributes' do
    it 'should return a hash of attributes from attribute string' do
      text = 'price="5.94" title="oberon"'
      attrs = Lexer.scan_attributes(text)
      attrs.class.should == Hash
      attrs.should include("price" => "5.94", "title" => "oberon")

    end
  end

  context '#scan_xml_node' do
    it 'should parse tag names and attributes properly' do
      text = '<book attr="stuff">stuff</book>'
      lexer = Lexer.new(text)
      r = lexer.scan_xml_node
      r.class.should == Node
      r.name.should == 'book'
      r.attributes.should include("attr" => 'stuff')
      lexer.peek.should == 's'
    end

    it 'should handle tags without attributes properly' do
      text = '<book>stuff</book>'
      lexer = Lexer.new(text)
      r = lexer.scan_xml_node
      r.name.should == 'book'
      r.attributes.count.should == 0
    end

    it 'should handle closing tags properly' do
      text = '<book attr="stuff">stuff</book>s'
      lexer = Lexer.new(text)
      lexer.scan_xml_node
      lexer.scan_text
      r = lexer.scan_xml_node
      r.name.should == '/book'
      lexer.peek.should == 's'
    end
  end

  context '#scan_text' do
    it 'should parse text inside of tag' do
      text = '<book attr="value">stuff</book>'
      lexer = Lexer.new(text)
      lexer.scan_xml_node
      lexer.peek.should == 's'
      r = lexer.scan_text
      r.text.should == 'stuff'
      lexer.peek.should == '<'

      text = '<book>stuff</book>'
      lexer = Lexer.new(text)
      lexer.scan_xml_node
      r = lexer.scan_text
      r.text.should == 'stuff'
      lexer.peek.should == '<'
    end
  end


  context '#tokenize' do
    before do

      text = <<-END
<?xml version="1.0"?>
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
    end

    it 'should return a list of tokens' do
      @tokens.should_not be_nil

      str = <<-END
[xml, ' ', catalog, ' ', book, ' ', author, 'Gambardella, Matthew', /author, ' ', title, 'XML Developer's Guide', /title, ' ', genre, 'Computer', /genre, ' ', price, '44.95', /price, ' ', publish_date, '2000-10-01', /publish_date, ' ', description, 'An in-depth look at creating applications with XML.', /description, ' ', /book, ' ', /catalog]
      END

      @tokens.to_s.should == str.chop
    end
  end

end
