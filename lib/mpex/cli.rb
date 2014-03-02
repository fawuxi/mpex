require 'cri'
require 'json'
require 'highline/import'

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

  option "0", :isinteractive, "internal flag set automatically in interactive mode"

  opt :i, :interactive, "Start interactive mode to MPEx.rb. Required for irc. (think: an MPEx shell)" do
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
    mpex.statjson(opts) do |stat|
      puts mpex.format_stat(stat)
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
    mpex.statjson(opts, false) do |answer|
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
    if agree("Send " + args[0] + " to MPEx? [y/n]")
      mpex = Mpex::Mpex.new
      mpex.send_plain(args[0], opts) do |answer|
        puts answer
      end
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
    amount = args[1]
    price = args[2]
    if price.match(/\./)
      puts "Provide price in Satoshis!"
      exit 0
    end
    say "<%= color('Buy #{amount} #{mpsic} @ #{Mpex::Converter.satoshi_to_btc(price.to_i)} BTC = #{Mpex::Converter.satoshi_to_btc(amount.to_i*price.to_i)} total BTC', :bold) %>"
    order_string = "BUY|#{mpsic}|#{amount}|#{price}"
    if agree("Send " + order_string + " to MPEx? [y/n]")
      mpex.send_plain(order_string, opts) do |answer|
        puts answer
      end
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
    amount = args[1]
    price = args[2]
    if price.match(/\./)
      puts "Provide price in Satoshis!"
      exit 0
    end
    say "<%= color('Sell #{amount} #{mpsic} @ #{Mpex::Converter.satoshi_to_btc(price.to_i)} BTC = #{Mpex::Converter.satoshi_to_btc(amount.to_i*price.to_i)} total BTC', :bold) %>"
    order_string = "SELL|#{mpsic}|#{amount}|#{price}"
    if agree("Send " + order_string + " to MPEx? [y/n]")
      mpex.send_plain(order_string, opts) do |answer|
        puts answer
      end
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
    if agree("Send " + order_string + " to MPEx? [y/n]")
      mpex.send_plain(order_string, opts) do |answer|
        puts answer
      end
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
    if agree("Send " + order_string + " to MPEx? [y/n]")
      mpex.send_plain(order_string, opts) do |answer|
        puts answer
      end
    end
  end
end

@cmd.define_command do
  name 'withdraw'
  aliases :WITHDRAW
  usage "withdraw [options] [address] [amount in satoshi]"

  run do |opts, args|
    #puts .run('help'); exit 0 unless args.length == 2
    mpex = Mpex::Mpex.new
    order_string = "WITHDRAW|#{args[0]}|#{args[1]}"
    if agree("Send " + order_string + " to MPEx? [y/n]")
      mpex.send_plain(order_string, opts) do |answer|
        puts answer
      end
    end
  end
end

@cmd.define_command do
  name 'push'
  aliases :PUSH
  usage "push [options] [MPSIC] [40 char key fingerprint] [qty]"

  run do |opts, args|
    #puts .run('help'); exit 0 unless args.length == 2
    mpex = Mpex::Mpex.new
    order_string = "PUSH|#{args[0]}|#{args[1]}|#{args[2]}"
    puts "Read FAQ: 'PUSH|{MPSIC}|{40 char key fingerprint}|{qty}, which allows you to push an asset (including BTC) to another account on MPEx. This is free of charge but it does not check if the keyid exists so please, for the love of all that is holy, make sure you don't send your stocks to limbo.'"
    if agree("Send " + order_string + " to MPEx? [y/n]")
      mpex.send_plain(order_string, opts) do |answer|
        puts answer
      end
    end
  end
end

@cmd.define_command do
  name 'portfolio'
  usage 'portfolio [options]'
  summary ""

  run do |opts, args|
    mpex = Mpex::Mpex.new
    mpex.statjson(opts) do |stat|
      mpex.portfolio(opts, stat) do |portfolio|
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
    if opts[:isinteractive]
      $IRC_LEAK = Mpex::Irc.new
      $IRC_LEAK.connect
    else
      puts "Connecting to IRC works in interactive mode only. Run 'mpex -i' to start MPEx.rb in interactive shell mode."
      exit 0
    end
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
      puts "To use a proxy, edit ~/.mpex/config.yaml and restart mpex -i"
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

