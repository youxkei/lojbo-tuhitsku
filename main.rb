require "open-uri"

require "dotenv"
require "twitter"
require "bing_translator"

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

$translator = BingTranslator.new ENV["MICROSOFT_TRANSLATOR_API_CLIENT_ID"], ENV["MICROSOFT_TRANSLATOR_API_CLIENT_SECRET"]

def translate_from_japanese_to_english(japanese_text)
  return $translator.translate japanese_text, from: 'ja', to: 'en'
end

def translate_from_english_to_lojban(english_text)
  return open("http://lojban.lilyx.net/zmifanva/?src=#{english_text.gsub " ", "+"}&dir=en2jb").string.match(/Target Text \(Output\):.*?<textarea.*?>(.*?)<\/textarea/m)[1].strip
end


source_streaming_client.user do |object|
  if object.is_a?(Twitter::Tweet) &&
      object.user.id == source_user_id &&
      !object.reply?  &&
      !object.retweet?  &&
      !object.quote?
    japanese_text = object.text
    english_text = translate_from_japanese_to_english japanese_text
    lojban_text = translate_from_english_to_lojban english_text

    target_rest_client.update lojban_text[0, 140]
  end
end
