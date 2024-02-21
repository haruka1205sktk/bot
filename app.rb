require 'bundler/setup'
Bundler.require
require 'sinatra/reloader' if development?
require './models.rb'
require 'line/bot'
require "openai"
require 'dotenv'
require 'json'


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
          config.channel_secret = ENV["CHANNEL_SECRET"]
          config.channel_token = ENV["CHANNEL_TOKEN"]
        }
end
 
post '/callback' do
    request.body.rewind

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
      when Line::Bot::Event::Follow
      # フォローした時にユーザーidを取得して、lineのユーザーidからリンクを作成、そのリンクをユーザーに送る動作をこの中に書く
      when Line::Bot::Event::Message
        case event.type
        when Line::Bot::Event::MessageType::Text
        # ユーザーidを取得して、languageDataにユーザーidと一致するユーザーの言語を持ってくる（言語データとユーザーデータの連携が必要）
        #言語を変更する場合はユーザーの言語を変更
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
                    { role: "system", content: languageData.language + "に" + "翻訳して下さい" + "翻訳した言語の発音をカタカナで教えてください" + "翻訳した結果と発音以外は出力しなくて大丈夫です"},
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
end

# get '/userid/何でも良いよ'do
# 認証ページ作ろう
# 認証ページで名前を登録するよ
# end

# post '/#{userid}/何でも良いよ' do
# データベースにuseridとユーザーの名前を登録
# 送信したら認証完了画面に行くようにしよう
# end

# get '/認証完了' do

# end

# LINE Developers登録完了後に作成される環境変数の認証
 

