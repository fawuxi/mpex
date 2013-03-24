require 'net/yail'
require 'highline/import'

module Mpex::Interactive

  def self.run
    puts "Welcome to MPEx.rb shell. Type 'help' and 'help [command]' to get a help or 'quit' to exit."
    puts "Donations welcome: 1DrqwLjksrXZHdSzzieaNhQuhrnbNTeiQr"
    puts "Type 'irc' to connect to Freenode to use MPEx IRC bots"
    loop do
      line = ask("mpex>> ") {|q| q.readline = true }

      exit 0 if line =~ /^(exit|quit|q)$/

      args = line.split(" ")

      begin
        Mpex::CLI.command.run(args) unless args.empty?
      rescue Exception => ex
        puts ex
      end
    end
  end

end
