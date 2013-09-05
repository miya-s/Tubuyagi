# -*- coding: utf-8 -*-
require 'MeCab'
require 'twitter'
require 'pp'

def strip(str)
  str.gsub(/(.*)RT @.*/,'\1').gsub(/http[^ ]*/,"").gsub(/@[^ ]*/,'')
end

def rot(bigram,target)
  if bigram[target]
    s = 0
    bigram[target].each do |b,v|
      s += v
    end
    prob = rand
    bigram[target].each do |b,v|
      prob -= v * 1.0/ s
      if prob <= 0
         return b
      end
    end
    return "EOS"
  else
    return "EOS"
  end
end

def blind(str)
  return str.gsub(/(」|「|（|）|\(|\))/,"")
end

def end_mark?(str)
  return true if ["？","！","。"].include? str
  return false
end

def generate(bigram)
  c = "BOS"
  sentence = ""
  while true do
    rotted = rot(bigram,c)
    break if rotted == "EOS"
    sentence = sentence + blind(rotted)

    break if end_mark?(rotted)
    c = rotted
  end
  return sentence
end

class String
  def utf8!
    self.force_encoding("UTF-8")
  end
end

Twitter.configure do |cnf|
  cnf.consumer_key = "fXvo5ihLi3Cq5HV7n2WhHw"
  cnf.consumer_secret = "XQelFQ4ap4zTNRuDF3cR4NMUCZzfdwqNwcbLJlTTeQ"
  cnf.oauth_token = "250459217-qnXCVepIDjpGmR7np7Y378JDRhbFHqNqQqv7qrcS"
  cnf.oauth_token_secret = "3A0xoOPXMadbH70WMlx13pIlVsx85aiLEf3fff3Y2kg"
end

client = Twitter::Client.new

mecab = MeCab::Tagger.new('-Ochasen')

#puts mecab.parse("こんにちは，いい天気ですね！")

bigram = {}

bigram["BOS"] = {}
print "please input the account name\n"
client.user_timeline(gets[0..-2]).each do |t|
  str = t.attrs[:text]
  str.utf8!

  next if str[0..2] == "RT "

  node = mecab.parseToNode(strip(str))
  word_array = []

  if bigram["BOS"][node.next.surface.utf8!]
    bigram["BOS"][node.next.surface.utf8!] += 1
  else
    bigram["BOS"][node.next.surface.utf8!] = 1
  end

  p str.utf8!
  begin
    node = node.next

    if bigram[node.surface.utf8!]
      if bigram[node.surface.utf8!][node.next.surface.utf8!]
        bigram[node.surface.utf8!][node.next.surface.utf8!] += 1
      else
        bigram[node.surface.utf8!][node.next.surface.utf8!] = 1
      end
    else
      bigram[node.surface.utf8!] = {node.next.surface.utf8! => 1}
    end
    if /^名詞,一般/ =~ node.feature.utf8!
      word_array << node.surface.utf8!
    end
  end until node.next.feature.include?("BOS/EOS")

  if bigram[node.surface.utf8!]
    if bigram[node.surface.utf8!]["EOS"]
      bigram[node.surface.utf8!]["EOS"] += 10
    else
      bigram[node.surface.utf8!]["EOS"] = 10
    end
  else
    bigram[node.surface.utf8!] = {"EOS" => 10}
  end
end

p bigram

while true
  gets
  p generate(bigram)
end
