require 'facebook/messenger'
require_relative 'wit_connector'
require 'byebug'

include Facebook::Messenger
include WitHandler

Facebook::Messenger.configure do |config|
  config.access_token = ENV['FB_PAGE_TOKEN']
  config.verify_token = ENV['FB_VERIFY_TOKEN'] || 'verify_token'
  config.app_secret = ENV['FP_APP_SECRET'] 
end

# subscribe the bot to a page
Facebook::Messenger::Subscriptions.subscribe
# setting up the presisting menu
Facebook::Messenger::Thread.set(
  setting_type: 'call_to_actions',
  thread_state: 'existing_thread',
  call_to_actions: [
    {
      type: 'postback',
      title: 'Say Hi',
      payload: 'Hello'
    },
    {
      type: 'postback',
      title: 'Help ( See what i can do )',
      payload: 'BOT_HELP'
    },
    {
      type: 'web_url',
      title: 'View Creator Profile',
      url: 'https://facebook.com/ThisIsKan'
    }
  ]
)
Facebook::Messenger::Thread.set(
  setting_type: 'greeting',
  greeting: {
    text: 'Welcome to your new bot overlord!'
  }
)
def send_help_messages(recipient)
  Bot.deliver(
    recipient: recipient,
    message: {
      text: 'Hello there, i\'m your chatbot assistant and my name is botzy :)'
    }
  )
  Bot.deliver(
    recipient: recipient,
    message: {
      text: 'First of all you can use your menu lcated at the bottom left of your chat box, you can tweak your settings there and get help and much more'
    }
  )
  Bot.deliver(
    recipient: recipient,
    message: {
      text: 'i can help you by providing you with weather statistics about certain city by typing "what is the weather in { city name }"'
    }
  )
  Bot.deliver(
    recipient: recipient,
    message: {
      text: 'i can remind you to do anything in anytime by just typing "remind me of { anything } at { anytime }", and i\'ll be glad to remind you at the time'
    }
  )
end
Bot.on :message do |message|
  STDERR.puts "Recieved #{message.text} from #{message.sender['id']}"
  puts "Sessions before if #{SESSIONS[message.sender['id'].nil?]}"
  if SESSIONS[message.sender['id']].nil?
    puts "Sessions"
    SESSIONS[message.sender['id']] = {}
  end
  case message.text
  when /something humans like/i
    Bot.deliver(
      recipient: message.sender,
      message: {
        text: 'I found something humans seem to like:'
      }
    )

    Bot.deliver(
      recipient: message.sender,
      message: {
        attachment: {
          type: 'image',
          payload: {
            url: 'https://i.imgur.com/iMKrDQc.gif'
          }
        }
      }
    )

    Bot.deliver(
      recipient: message.sender,
      message: {
        attachment: {
          type: 'template',
          payload: {
            template_type: 'button',
            text: 'Did human like it?',
            buttons: [
              { type: 'postback', title: 'Yes', payload: 'HUMAN_LIKED' },
              { type: 'postback', title: 'No', payload: 'HUMAN_DISLIKED' }
            ]
          }
        }
      }
    )
  when /help/i || /botzy/i
    send_help_messages(message.sender)
  else
    puts "Calling actions"
    SESSIONS[message.sender['id']]['context'] = CLIENT.run_actions(message.sender['id'], message.text, SESSIONS[message.sender['id']]['context'] || {})

  end
end

Bot.on :postback do |postback|
  is_predefinded_postback = false
  case postback.payload
  when 'HUMAN_LIKED'
    text = 'That makes bot happy!'
    is_predefinded_postback = true
  when 'HUMAN_DISLIKED'
    text = 'Oh.'
    is_predefinded_postback = true
  when 'BOT_HELP'
    send_help_messages(postback.sender)
  end

  if is_predefinded_postback
    Bot.deliver(
      recipient: postback.sender,
      message: {
        text: text
      }
    )
  else
    SESSIONS[postback.sender['id']]['context'] = CLIENT.run_actions(postback.sender['id'], postback.payload, SESSIONS[postback.sender['id']]['context'], 10)
  end
end

Bot.on :delivery do |delivery|
  puts "Delivered message(s) #{delivery.ids}"
end
