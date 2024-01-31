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
  # 最初に、もしLanguageデータベースが０だったら、データを一行作成するコード（カウントに近い、デフォルトは英語にしよう）を書く
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
    p "ok"
    body = request.body.read
    signature = request.env['HTTP_X_LINE_SIGNATURE']
    unless client.validate_signature(body, signature)
      error 400 do 'Bad Request' end
    end
    events = client.parse_events_from(body)

    events.each do |event|
    # 隠しファイルにTOKENを格納、Renderのenvironmentに書いてあげる。
      chatgpt = OpenAI::Client.new(access_token:ENV["OPENAI_ACCESS_TOKEN"])
      case event
      when Line::Bot::Event::Message
        case event.type
        when Line::Bot::Event::MessageType::Text
　　　　# この辺りに、もし送られてきた文字に「に変更」が入っていたらデータベースを書き換える処理をする「〜に変更」という文字を文字列から消して言語を抽出する

          response = chatgpt.chat(
              parameters: {
                  model: "gpt-3.5-turbo",
                  # 英語のところをデータベースに入っている言語に変更
                  messages: [{ role: "user", content: "「英語で送ってください」より後の言葉のみを表示させてください" + event.message['text'] }],
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
 

