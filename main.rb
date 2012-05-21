#!/usr/bin/env ruby
#encoding: utf-8
require './lexer'
require './parser'
# 
# if ARGV.size < 2
#   puts 'Podaj dwa argumenty będące nazwami plików wejściowych'
#   exit
# end

d1 = File.open(ARGV[0]).read
d2 = File.open(ARGV[1]).read

l1 = Lexer.new(d1).tokenize
# puts l1.to_s
l2 = Lexer.new(d2).tokenize

t1 = Parser.new(l1).parse
t2 = Parser.new(l2).parse

t1.diff(t2)
