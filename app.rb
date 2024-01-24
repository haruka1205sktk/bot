require 'bundler/setup'
Bundler.require
require 'sinatra/reloader' if development?
require './models.rb'
require 'line/bot'
require "openai"
get '/' do
  erb :index
end


def client
        @client ||= Line::Bot::Client.new { |config|
          config.channel_secret = "a9a7928fd25356ca14b0e0aa05b6568c"
          config.channel_token = "uOSv2yphg2AkqPJOKJd6et3jVEA+YTwlKUflGvCikdDW3T81UBiOtsnkfGfmZps4uoaL2HPn4yha2CnidLe8cTHv1xLINVqDAVlBWcUqIof98V/SFHG5ShXxTxrd2/lXhypHaUfMsm2AXeZTtDCWUAdB04t89/1O/w1cDnyilFU="
        }
end
 
post '/callback' do
    p "ok"
    body = request.body.read
    signature = request.env['HTTP_X_LINE_SIGNATURE']
    unless client.validate_signature(body, signature)
      error 400 do 'Bad Request' end
    end
    events = client.parse_events_from(body)

    events.each do |event|
  
      case event
      when Line::Bot::Event::Message
        case event.type
        when Line::Bot::Event::MessageType::Text

          chatgpt = OpenAI::Client.new(access_token: "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")

          response = chatgpt.chat(
              parameters: {
                  model: "gpt-3.5-turbo",
                  messages: [{ role: "user", content: event.message['text'] }],
              })
          
          message = {
            type: 'text',
            text: response.dig("choices", 0, "message", "content")
          }
        end
      end
      client.reply_message(event['replyToken'], message)
    end
    head :ok
end


# LINE Developers登録完了後に作成される環境変数の認証
 

