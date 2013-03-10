require 'fileutils'
require 'open-uri'
require 'net/http'
require 'json'
require 'yaml'
require 'highline/import'
require 'gpgme'
require 'digest/md5'
require 'logger'

module Mpex
  class Mpex

    CONFIG_FILE_PATH = File.join(Dir.home, ".mpex", "config.yaml")
    LOGFILE_PATH = File.join(Dir.home, ".mpex", "response.log")

    def initialize
      @crypto = GPGME::Crypto.new(:armor => true)
      unless File.exist?(File.expand_path(LOGFILE_PATH))
        dirname = File.dirname(File.expand_path(LOGFILE_PATH))
        Dir.mkdir(dirname) unless Dir.exist?(dirname)
      end
      @logger = Logger.new(LOGFILE_PATH)
    end

    def sign(msg, opts)
      signed_message = @crypto.sign(msg, :signer => opts[:keyid], :password => opts[:password], :mode => GPGME::SIG_MODE_CLEAR)

      verify(signed_message)
      signed_message.to_s
    end

    def verify(msg)
      @crypto.verify(msg) do |signature|
        if signature.valid?
          say("<%= color('#{signature}', :green) %>")
        else
          say("<%= color('WARNING', :red) %>: Invalid signature! Don't trust!")
          raise "WARNING: Invalid signature! Don't trust!"
        end
      end
    end

    def encrypt(signed_msg, opts)
      @crypto.encrypt(signed_msg, :recipients => opts[:mpexkeyid])
    end

    def decrypt(encrypted_data, opts)
      @crypto.decrypt(encrypted_data, :password => opts[:password]) do |signature|
        raise "Signature could not be verified" unless signature.valid?
      end
    end

    def send_plain(cleartext_command, opts, &block)

      puts "Sending order to MPEX: #{cleartext_command}"

      opts = verify_opts_present(opts, [ :url, :keyid, :mpexkeyid, :password ])

      signed_msg = sign(cleartext_command, opts)
      say("<%= color('Track-ID: #{track_id(signed_msg)}', :blue) %>")
      encrypted_msg = encrypt(signed_msg, opts)

      if $IRC_LEAK && $IRC_LEAK.connected?
        $IRC_LEAK.send_encrypted(encrypted_msg.to_s) do |encr_answer|
          if encr_answer
            yield handle_answer(encr_answer, opts)
          end
        end
      else
        res = Net::HTTP.post_form(mpex_uri(opts[:url]), { 'msg' => "#{encrypted_msg}" })
        yield handle_answer(res.body, opts)
      end
    end

    def handle_answer(encrypted_answer, opts)
      decrypted_response = decrypt(encrypted_answer.to_s, opts)

      @logger.info(decrypted_response.to_s)

      verified_response = verify(decrypted_response)
      verified_response.to_s
    end

    def mpex_uri(url)
      URI.parse(url).merge("/")
    end

    def validate_mpsic(mpsic)
      if mpsic.match(/^\w\./)
        return mpsic
      else
        raise "invalid MPSIC #{mpsic}"
      end
    end

    def track_id(signed_msg)
      md5hex = Digest::MD5.hexdigest(signed_msg)
      md5hex[0..3]
    end

    def orders_sum(stat)
      orders_value = stat["Book"].map do |order|
        order[order.keys.first]["Price"].to_i * order[order.keys.first]["Quantity"].to_i
      end.inject(:+)
      orders_value
    end

    def orders_vwap_sum(stat, vwaps)
      orders_value = stat["Book"].map do |order|
        if order[order.keys.first]["BS"] == "B"
          order[order.keys.first]["Price"].to_i * order[order.keys.first]["Quantity"].to_i
        elsif order[order.keys.first]["BS"] == "S"
          mpsic = order[order.keys.first]["MPSIC"]
          vwaps[mpsic]["1d"]["max"].to_i * order[order.keys.first]["Quantity"].to_i
        else
          0
        end
      end.inject(:+)
      orders_value
    end

    def fetch_mpex_vwaps(url, &block)
      if $IRC_LEAK && $IRC_LEAK.connected?
        $IRC_LEAK.vwap do |resp|
          vwaps = JSON.parse(resp)
        end
      else
        vwap_url = mpex_uri(url).merge("/mpex-vwap.php")
        vwaps = JSON.parse(Net::HTTP.get(vwap_url))
      end
      yield vwaps
    end

    def fetch_orderbook(opts = {}, &block)
      orderbook = []
      if $IRC_LEAK && $IRC_LEAK.connected?
        $IRC_LEAK.depth do |depth|
          orderbook = JSON.parse depth
        end
      else
        opts = verify_opts_present(opts, [ :url ])
        orderbook_url = mpex_uri(opts[:url]).merge("/mpex-mktdepth.php")
        orderbook_res = Net::HTTP.get(orderbook_url)
        orderbook_res = orderbook_res.start_with?("JurovP") ? orderbook_res.match(/JurovP\((.+)\)/)[1] : orderbook_res
        orderbook = JSON.parse(orderbook_res)
      end
      orderbook.each do |s|
        puts s.first
        s.last["S"].sort_by { |price, amount| -price }.each do |o|
          puts "SELL price: #{Converter.satoshi_to_btc(o.first)} amount: #{o.last}"
        end
        s.last["B"].sort_by { |price, amount| price }.each do |o|
          puts "BUY price: #{Converter.satoshi_to_btc(o.first)} amount: #{o.last}"
        end
      end
    end

    def portfolio(opts, stat, &block)

      return unless stat

      opts = verify_opts_present(opts, [ :url, :keyid, :mpexkeyid, :password ])

      fetch_mpex_vwaps(opts[:url]) do |vwaps|
        return unless vwaps
        holdings_value = holdings_avg_value(stat, vwaps)

        optimistic_value = holdings_value + orders_sum(stat)
        vwap_valuation = holdings_value + orders_vwap_sum(stat, vwaps)

        portfolio = <<-PORTFOLIO
          Your optimistic valuation: #{Converter.satoshi_to_btc(optimistic_value)}"
          VWAP valuation: #{Converter.satoshi_to_btc(vwap_valuation)}
        PORTFOLIO
        yield portfolio
      end
    end

    def holdings_avg_value(stat, vwaps)
      # TODO improve!
      holdings_value = stat["Holdings"].map do |h|
        if h["CxBTC"]
          h["CxBTC"].to_i
        elsif h["S.MPOE"]
          h["S.MPOE"].to_i*vwaps["S.MPOE"]["1d"]["avg"].to_i
        elsif h["S.DICE"]
          h["S.DICE"].to_i*vwaps["S.DICE"]["1d"]["avg"].to_i
        else
          0
        end
      end.inject(:+)
    end

    def verify_opts_present(opts, req_opts)
      config_opts = read_config
      req_opts.each do |r_opt|
        unless opts[r_opt]
          if config_opts[r_opt.to_s]
            opts[r_opt] = config_opts[r_opt.to_s]
          elsif r_opt == :password
            opts[:password] = ask("Enter Passphrase: "){|q| q.echo = false}
            puts
          else
            $stderr.puts "--#{r_opt} option is required"
            exit 1
          end
        end
      end
      opts
    end

    def read_config
      begin
        return YAML.load_file(File.expand_path(CONFIG_FILE_PATH))
      rescue
        create_configfile_unless_exists
      end
      return {}
    end

    def create_configfile_unless_exists
      return if File.exist?(File.expand_path(CONFIG_FILE_PATH))
      begin
        current_dir = File.dirname(File.expand_path(__FILE__))

        sample_config_file = File.expand_path(File.join(current_dir, "..", "..", "config.yaml.sample"))
        
        unless File.exist?(File.expand_path(CONFIG_FILE_PATH))
          mpex_dir = File.dirname(File.expand_path(CONFIG_FILE_PATH))
          Dir.mkdir(mpex_dir) unless Dir.exist?(mpex_dir)
        end
        
        FileUtils.cp sample_config_file, File.expand_path(CONFIG_FILE_PATH)
        return YAML.load_file(File.expand_path(CONFIG_FILE_PATH))
      rescue
        puts "WARN: no sample config file found!"
      end
    end

  end
end
