module Mpex
  class Converter
    
    def self.btc_to_satoshi(btc)
      leftright = btc.to_s.split("\.");
      btcStr = leftright[0];
      satoshiStr = leftright[1];

      while (satoshiStr.length() < 8) do
          satoshiStr = satoshiStr + "0";
      end

      resultstr = btcStr + satoshiStr;
      resultstr.to_i.to_s
    end
    
    def self.satoshi_to_btc(satoshi)
      satoshiStr = satoshi.to_s;
      
      satoshiPart = "";
      btcPart = "0";
      
      denominator = "";

      if (satoshiStr.size > 8)
          btcPart = satoshiStr[0...(satoshiStr.size - 8)];
          satoshiPart = satoshiStr[(satoshiStr.size - 8)..satoshiStr.size];
      else
          if (satoshiStr.start_with?("-"))
              denominator = "-";
              satoshiPart = satoshiStr[1..satoshiStr.size]; # cut denominator
          else
              satoshiPart = satoshiStr;
          end
          while (satoshiPart.size < 8) do
              # prepend zeros
              satoshiPart = "0" + satoshiPart;
          end
      end

      # cut trailing zeros
      while (satoshiPart.end_with?("0")) do
          satoshiPart = satoshiPart.chomp("0");
      end

      return denominator + btcPart + "." + satoshiPart;
    end
    
  end
end