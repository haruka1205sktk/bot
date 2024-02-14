require 'bundler/setup'
Bundler.require
require 'sinatra/reloader' if development?
require './models.rb'
require 'line/bot'
require "openai"
require 'dotenv'


before do
  p 'before'
    if Language.all.size == 0
      Language.create(language: "英語")
    end
end
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
    request.body.rewind
    data = JSON.parse(request.body.read)
    user_id = data['events'][0]['source']['userId']
    p "ok"
    body = request.body.read
    signature = request.env['HTTP_X_LINE_SIGNATURE']
    unless client.validate_signature(body, signature)
      error 400 do 'Bad Request' end
    end
    events = client.parse_events_from(body)
    events.each do |event|
      chatgpt = OpenAI::Client.new(access_token:ENV["OPENAI_ACCESS_TOKEN"])
      case event
      when Line::Bot::Event::Message
        case event.type
        when Line::Bot::Event::MessageType::Text
          if event.message['text'].end_with?("語に変更")
            languageData = Language.first
            newlanguage = event.message['text'].sub("に変更","")
            languageData.language = newlanguage
            languageData.save
            Language.first.language
            message = {
              type: 'text',
              text: Language.first.language + "に変更しました"
            }
          else
            languageData = Language.first
            response = chatgpt.chat(
              parameters: {
                model: "gpt-3.5-turbo",
                  messages: [
                    { role: "system", content: languageData.language + "に" + "翻訳して下さい" },
                    { role: "user", content: event.message['text'] }
                  ]
              }
            )
            
            message = {
              type: 'text',
              text: response.dig("choices", 0, "message", "content")
            }
          end
        end
      end
      client.reply_message(event['replyToken'], message)
    end
    status 200
    body ''
end


# LINE Developers登録完了後に作成される環境変数の認証
 

