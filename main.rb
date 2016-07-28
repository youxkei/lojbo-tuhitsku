require "open-uri"
require "cgi"

require "dotenv"
require "twitter"

Dotenv.load

source_rest_client = Twitter::REST::Client.new do |config|
  config.consumer_key = ENV["TWITTER_CONSUMER_KEY"]
  config.consumer_secret = ENV["TWITTER_CONSUMER_SECRET"]
  config.access_token = ENV["TWITTER_SOURCE_ACCESS_TOKEN"]
  config.access_token_secret = ENV["TWITTER_SOURCE_ACCESS_TOKEN_SECRET"]
end

source_streaming_client = Twitter::Streaming::Client.new do |config|
  config.consumer_key = ENV["TWITTER_CONSUMER_KEY"]
  config.consumer_secret = ENV["TWITTER_CONSUMER_SECRET"]
  config.access_token = ENV["TWITTER_SOURCE_ACCESS_TOKEN"]
  config.access_token_secret = ENV["TWITTER_SOURCE_ACCESS_TOKEN_SECRET"]
end

target_rest_client = Twitter::REST::Client.new do |config|
  config.consumer_key = ENV["TWITTER_CONSUMER_KEY"]
  config.consumer_secret = ENV["TWITTER_CONSUMER_SECRET"]
  config.access_token = ENV["TWITTER_TARGET_ACCESS_TOKEN"]
  config.access_token_secret = ENV["TWITTER_TARGET_ACCESS_TOKEN_SECRET"]
end

source_user_id = source_rest_client.user.id

def translate_from_japanese_to_english(japanese_text)
  return CGI.unescapeHTML(Net::HTTP.post_form(URI.parse("http://www.excite.co.jp/world/english/"), {
    auto_detect_flg: 1,
    wb_lp: "JAEN",
    before_lang: "JA",
    after_lang: "EN",
    before: japanese_text,
  }).body.match(/<textarea.*?id="after".*?>(.*?)<\/textarea>/)[1])
end

def translate_from_english_to_lojban(english_text)
  return open("http://lojban.lilyx.net/zmifanva/?src=#{URI.encode(english_text.gsub " ", "+")}&dir=en2jb").string.match(/Target Text \(Output\):.*?<textarea.*?>(.*?)<\/textarea/m)[1].strip
end


begin
  source_streaming_client.user do |object|
    if object.is_a?(Twitter::Tweet) &&
        object.user.id == source_user_id &&
        !object.reply?  &&
        !object.retweet?  &&
        !object.quote?
      japanese_text = object.text
      english_text = translate_from_japanese_to_english japanese_text
      lojban_text = translate_from_english_to_lojban english_text

      target_rest_client.update lojban_text[0, 140] if lojban_text.length > 0
    end
  end
rescue
  retry
end
