Given /^a btc value of "(.*?)"$/ do |btc_value|
  @btc = btc_value
end

When /^I ask for it to be converted to satoshi$/ do
  @satoshi = Mpex::Converter.btc_to_satoshi(@btc)
end

Then /^it should return "(.*?)" satoshi$/ do |satoshi_amount|
  @satoshi.should eq satoshi_amount
end

Given /^a satoshi value of "(.*?)"$/ do |satoshi_amount|
  @satoshi = satoshi_amount
end

When /^I ask for it to be converted to decimal btc$/ do
  @btc = Mpex::Converter.satoshi_to_btc(@satoshi)
end

Then /^it should return "(.*?)" btc$/ do |btc_value|
  @btc.should eq btc_value
end
