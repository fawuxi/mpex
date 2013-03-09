require 'net/yail'
require 'net/http'

module Mpex
  # TODO to be improved and to be made configurable!
  class Irc

    ASSBOT = "assbot"
    MPEXBOT = "mpexbot"

    def initialize
      @irc = Net::YAIL.new(
        :address    => 'irc.freenode.net',
        :username   => 'mp_rb_client',
        :realname   => 'mpex ruby irc client',
        :nicknames  => ["mp_rb_client#{Random.rand(42..4096)}", "mp_rb_client#{Random.rand(42..4096)}"]
      )
      log = Logger.new(STDOUT)
      log.level = Logger::WARN
      @irc.log = log
    end

    def connect
      @irc.on_welcome do |event|
        puts "\nConnected to IRC."
        @connected = true
      end

      puts "Connecting. Please wait."

      @irc.start_listening
    end

    def disconnect
      @irc.stop_listening
    end

    def connected?
      @connected
    end

    def send_encrypted(message, &block)
      res = Net::HTTP.post_form(URI.parse("http://dpaste.com/api/v1/"), { 'content' => "#{message}" })
      dpaste_url = res['Location']
      @irc.msg(ASSBOT, "!mp " + dpaste_url)

      @irc.hearing_msg do |event|
        resp_url = parse_message(event.message)
        mpex_res = Net::HTTP.get(URI.parse(resp_url)) if resp_url
        yield mpex_res
      end
    end

    def parse_message(msg)
      if msg.start_with? "Response: http:"
        return msg.split[1]
      end
    end

    def vwap(&block)
      @irc.msg MPEXBOT, '$vwap'
      
      @irc.hearing_msg do |event|
        mpexbot_res = Net::HTTP.get(URI.parse(event.message)) if event.message.start_with?("http:")
        yield mpexbot_res.to_s if mpexbot_res
      end
    end

    def depth(&block)
      @irc.msg MPEXBOT, '$depth'
      
      @irc.hearing_msg do |event|
        if event.message.start_with?("http:")
          uri = URI.parse(event.message);
          id = uri.path[1..-1]
          uri = URI.parse("http://pastebin.com/raw.php?i=" + id)
          mpexbot_res = Net::HTTP.get(uri)
        end
        yield mpexbot_res.to_s if mpexbot_res
      end
    end

  end
end