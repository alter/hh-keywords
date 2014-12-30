#!/usr/bin/env ruby
require 'ap'
require 'json'
require 'nokogiri'
require_relative 'hack_http'

@http = HackHTTP.new( 'https://api.hh.ru' )
# https://api.hh.ru/vacancies/8252535
prefix_url = '/vacancies/'
keyword = ARGV.pop || abort( "Usage #$0 'search string'" )
search_url = "#{prefix_url}?text=#{keyword}&only_with_salary=false&area=1"

class String
  def numeric?
    return true if self =~ /^\d+$/
    true if Float(self) rescue false
  end
end  

# input: url, output: json body
def parse_json( url )
  result = @http.get( url )

  begin
    json = JSON.parse( result.body )
  rescue JSON::ParserError => e
    ap "JSON::ParserError: #{e}"
  end

  return json
end

# input: search url, output: array of vacancies' urls
def get_urls( search_url )
  urls = []
  result_json = parse_json( search_url )
  result_json['items'].each do |item|
    urls << item['url']
  end

  return urls
end

# input: array of urls, output: arrays of vacancies' bodies 
def get_vacancies( urls )
  vacancies = []
  urls.each do |url|
    vacancies << parse_json( url )
  end

  return vacancies
end

# input: vacancies array, output: descriptions array
def get_descriptions( vacancies )
  descriptions = []
  vacancies.each do |vacancy|
    descriptions << vacancy['description']
  end

  return descriptions
end

# input: descriptions, output: keywords array
def get_keywords( descriptions )
  keywords = []
  descriptions.each do |description|
    page_text = Nokogiri::HTML(description).text
    keywords.concat( page_text.split(/\W+/) )
  end

  return keywords
end

#input: keywords, output: hash with counted duplicate entries
def count_duplicates( keywords )
  counted_keywords = Hash.new(0)
  keywords.each do |keyword|
    counted_keywords[keyword.downcase] += 1
  end

  return counted_keywords
end

#input: keywords, output: only useful keywords, without trash
def clean_array( keywords )
  keywords.map!{|keyword| keyword.downcase.strip}
  blacklist = %w{ 000 do we from as other like working web data and 00 to you your our on in the of for ru }

  keywords.each do |keyword|
    keywords.delete( keyword ) if keyword.empty?
  end

  keywords.each do |keyword|
    keywords.delete( keyword ) if keyword.numeric?
  end

  keywords.each do |keyword|
    ('a'..'z').to_a.each do |letter|
      keywords.delete( keyword ) if letter == keyword
    end
  end

  keywords.each do |keyword|
    blacklist.each do |badword|
      keywords.delete( keyword ) if keyword == badword
    end
  end

  keywords.each do |k|
    if k == "12"
      ap 'bingo=======================================' if k.numeric?
    end
  end

  return keywords 
end

urls = get_urls( search_url )
vacancies = get_vacancies( urls )
descriptions = get_descriptions( vacancies )
keywords = get_keywords( descriptions )
keywords = clean_array( keywords )
counted_keywords = count_duplicates( keywords )
hash = {}
counted_keywords.sort_by( &:last ).each do |k,v|
  hash[k] = v
end 

ap hash
