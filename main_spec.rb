require './lexer.rb'
require './parser.rb'


describe Parser do

  it "should parse xml" do
      input = <<-END
<catalog>
   <book id="bk101" class="stuff">
   </book>
</catalog>
      END

      token_list = Lexer.new(input).tokenize
      t = Parser.new(token_list).parse
      t.to_s.should == '<"catalog"><"book" "id"=""bk101"" "class"=""stuff""></"book"></"catalog">'
  end
end
