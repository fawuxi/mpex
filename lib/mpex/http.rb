require 'open-uri'
require 'net/http'

module Mpex
  class Http

    def self.post_form(url, params)
      begin
        res = Net::HTTP.post_form(mpex_uri(url), params)
        return res.body.to_s
      rescue Exception => ex
        suggest_proxies
        raise ex
      end
    end

    def self.get(url, url_extension="")
      begin
        uri = mpex_uri(url).merge(url_extension)
        return Net::HTTP.get(uri)
      rescue Exception => ex
        suggest_proxies
        raise ex
      end
    end

    private
    def self.suggest_proxies
      puts "----------"
      say("<%= color('MPEx proxy maybe not reachable.', :red) %>")
      puts "Try a different one or IRC bots.\nType 'irc' to connect to IRC."
      puts "When you're connected you can use mpex via irc bots or find out about alternative proxies via 'proxies'"
      puts "----------"
    end

    def self.mpex_uri(url)
      URI.parse(url).merge("/")
    end

  end
end
