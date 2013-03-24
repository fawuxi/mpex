require 'cri'
require 'json'

module Mpex::CLI

@cmd = Cri::Command.define do
  name 'mpex'
  usage 'mpex [options] [command] [options]'
  summary 'commandline interface for MPEx trading'
  description <<-DESC
    To change default settings edit ~/.mpex/config.yaml 

  DESC

  flag :h, :help, 'show help for this command' do |value, cmd|
    puts cmd.help
    exit 0
  end

  option :s, :url, 'URL to MPEx (defaults to http://mpex.co)'
  option :u, :keyid, 'key id of your gnupg key to use'
  option :m, :mpexkeyid, 'MPEx public key id (see FAQ#8)'
  option :p, :password, 'passphrase of your private key (unless provided you\'ll be asked for it)'

  opt :i, :interactive, "start alternative interactive mode to mpex, useful for irc" do
    Mpex::Interactive.run
    exit 0
  end

  opt :v, :version, 'show version information and quit' do
    puts Mpex.version_information
    exit 0
  end

end

Mpex::Mpex.new.create_configfile_unless_exists # makes sure config file is present

@cmd.add_command Cri::Command.new_basic_help

@cmd.define_command do
  name 'stat'
  aliases [:STAT, :status]
  usage 'stat [options]'
  summary 'Formatted MPEx STATJSON'

  run do |opts, args|
    mpex = Mpex::Mpex.new
    mpex.send_plain('STATJSON', opts) do |answer|
      puts mpex.format_stat(JSON.parse(answer))
    end
  end
end

@cmd.define_command do
  name 'statjson'
  aliases :STATJSON
  usage 'statjson [options]'
  summary 'STATJSON returns status in json format'

  run do |opts, args|
    mpex = Mpex::Mpex.new
    mpex.send_plain('STATJSON', opts) do |answer|
      puts answer
    end
  end
end

@cmd.define_command do
  name 'plain'
  aliases :p
  usage "plain [options] 'MPX|FOO|BAR'"
  summary "send string as is signed/encrypted to MPEx"

  run do |opts, args|
    mpex = Mpex::Mpex.new
    mpex.send_plain(args[0], opts) do |answer|
      puts answer
    end
  end
end

@cmd.define_command do
  name 'buy'
  aliases :BUY
  usage "buy [options] [MPSIC] [quantity] [price]"

  run do |opts, args|
    mpex = Mpex::Mpex.new
    mpsic = mpex.validate_mpsic(args[0])
    if args[2].match(/\./)
      puts "Provide price in Satoshis!"
      exit 0
    end
    order_string = "BUY|#{mpsic}|#{args[1]}|#{args[2]}"
    mpex.send_plain(order_string, opts) do |answer|
      puts answer
    end
  end
end

@cmd.define_command do
  name 'sell'
  aliases :SELL
  usage "sell [options] [MPSIC] [quantity] [price]"

  run do |opts, args|
    mpex = Mpex::Mpex.new
    mpsic = mpex.validate_mpsic(args[0])
    if args[2].match(/\./)
      puts "Provide price in Satoshis!"
      exit 0
    end
    order_string = "SELL|#{mpsic}|#{args[1]}|#{args[2]}"
    mpex.send_plain(order_string, opts) do |answer|
      puts answer
    end
  end
end

@cmd.define_command do
  name 'cancel'
  aliases :CANCEL
  usage "cancel [options] [order-number]"

  run do |opts, args|
    mpex = Mpex::Mpex.new
    order_string = "CANCEL|#{args[0]}"
    mpex.send_plain(order_string, opts) do |answer|
      puts answer
    end
  end
end

@cmd.define_command do
  name 'deposit'
  aliases :DEPOSIT
  usage "deposit [options] [amount in BTC]"

  run do |opts, args|
    mpex = Mpex::Mpex.new
    order_string = "DEPOSIT|#{args[0]}"
    mpex.send_plain(order_string, opts) do |answer|
      puts answer
    end
  end
end

@cmd.define_command do
  name 'withdraw'
  aliases :WITHDRAW
  usage "withdraw [options] [address] [amount in satoshi]"

  run do |opts, args|
    puts .run('help'); exit 0 unless args.length == 2
    mpex = Mpex::Mpex.new
    order_string = "WITHDRAW|#{args[0]}|#{args[1]}"
    mpex.send_plain(order_string, opts) do |answer|
      puts answer
    end
  end
end

@cmd.define_command do
  name 'portfolio'
  usage 'portfolio [options]'
  summary ""

  run do |opts, args|
    mpex = Mpex::Mpex.new
    mpex.send_plain('STATJSON', opts) do |stat|
      mpex.portfolio(opts, JSON.parse(stat)) do |portfolio|
        puts portfolio
      end if stat
    end
  end
end

@cmd.define_command do
  name 'orderbook'
  usage 'orderbook [options]'
  summary "show MPEx orderbook"

  run do |opts, args|
    mpex = Mpex::Mpex.new
    mpex.fetch_orderbook do |orderbook|
      puts orderbook
    end
  end
end

@cmd.define_command do
  name 'irc'
  usage 'irc [options]'
  summary 'connects an irc bot to freenode to talk to mpex via its bots'

  run do |opts, args|
    $IRC_LEAK = Mpex::Irc.new
    $IRC_LEAK.connect
  end
end

@cmd.define_command do
  name 'proxies'
  usage 'proxies [options]'
  summary 'list active MPEx proxies; only works when connected to IRC'

  run do |opts, args|
    mpex = Mpex::Mpex.new
    mpex.list_proxies do |proxies|
      puts proxies
      puts "To use a proxy, edit ~/.mpex/config.yaml and restart mpex cli"
    end
  end
end

def self.run(args)
  @cmd.run(ARGV)
end

def self.command
  @cmd
end

end

