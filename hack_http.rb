require 'faraday'
require 'faraday-cookie_jar'

class HackHTTP
  include Faraday

  def initialize(url)
    @conn = Faraday.new(url: url) do |faraday|
      faraday.request  :url_encoded
      faraday.use :cookie_jar
      faraday.adapter Faraday.default_adapter
    end
  end

  def get(url, options=nil)
    @conn.get url, options
  end

  def post(url, options=nil)
    @conn.post url, options 
  end
end
