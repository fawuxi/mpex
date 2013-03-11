require 'net/yail'
require 'net/http'
require 'timeout'

module Mpex
  # TODO to be improved and to be made configurable!
  class Irc

    ASSBOT = "assbot"
    MPEXBOT = "mpexbot"
    TIMEOUT = 30 # seconds

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

      @irc.hearing_msg do |event|
        @last_message = {:nick => event.nick, :message => event.message}
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
      puts "[IRC] Messaging #{ASSBOT}: !mp  #{dpaste_url}"
      @irc.msg(ASSBOT, "!mp " + dpaste_url)

      status = Timeout::timeout(TIMEOUT) {
        yield wait_for_assbot_message
      }
    end

    def wait_for_assbot_message
      while true
        if @last_message
          answer = handle_assbot_incoming(@last_message[:message])
          if answer
            puts "[IRC] #{ASSBOT} answered: #{@last_message[:message]}"
            @last_message = nil
            return answer
          end
        end
      end
    end

    def handle_assbot_incoming(msg)
      if msg.start_with? "Response: http:"
        resp_url = msg.split[1]
        return Net::HTTP.get(URI.parse(resp_url))
      end
    end

    def vwap(&block)
      puts "[IRC] Messaging #{MPEXBOT}: $vwap"
      @irc.msg MPEXBOT, '$vwap'

      status = Timeout::timeout(TIMEOUT) {
        yield wait_for_mpexbot_message
      }
    end

    def depth(&block)
      puts "[IRC] Messaging #{MPEXBOT}: $depth"
      @irc.msg MPEXBOT, '$depth'

      status = Timeout::timeout(TIMEOUT) {
        yield wait_for_mpexbot_message
      }
    end

    def list_proxies(&block)
      puts "[IRC] Messaging #{MPEXBOT}: $proxies"
      @irc.msg MPEXBOT, '$proxies'

      status = Timeout::timeout(TIMEOUT) {
        yield wait_for_mpexbot_plain_message
      }
    end

    def wait_for_mpexbot_plain_message
      while true
        if @last_message
          answer = @last_message[:message]
          if answer
            puts "[IRC] #{MPEXBOT} answered: #{@last_message[:message]}"
            @last_message = nil
            return answer
          end
        end
      end
    end

    def wait_for_mpexbot_message
      while true
        if @last_message
          answer = handle_mpexbot_incoming(@last_message[:message])
          if answer
            puts "[IRC] #{MPEXBOT} answered: #{@last_message[:message]}"
            @last_message = nil
            return answer
          end
        end
      end
    end

    def handle_mpexbot_incoming(msg)
      if msg.start_with?("http://pastebin.com")
        id = URI.parse(msg).path[1..-1]
        uri = URI.parse("http://pastebin.com/raw.php?i=" + id)
        return Net::HTTP.get(uri)
      end
    end

  end
end