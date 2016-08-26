require 'wit'
require 'json'
require 'rufus-scheduler'

module WitHandler

  SESSIONS = Hash.new({})

  def first_entity_value(entities, entity)
    return nil unless entities.key? entity
    val = entities[entity][0]['value']
    return nil if val.nil?
    val.is_a?(Hash) ? val['value'] : val
  end


  actions = {
    send: ->  (request, response) {
      puts "Executing 'send' action"
      puts "This is request in send action : #{request.to_json}"

      # SESSIONS[request["session_id"]]['context'] = request["context"]
      STDERR.puts "Sending Wit response '#{response['text']}' to '#{request["session_id"]}' in Facebook"
      # request is : {"session_id"=>" ", "context"=>{}, "text"=>" ", "entities"=>{"intent"=>[{"confidence"=> , "value"=>" "}]}}
      # response is : {"text"=>"", "quickreplies"=>nil}
      Bot.deliver(recipient: { id: request["session_id"] }, message: { text: response["text"] })
      puts "this is context in send action : #{request['context']}"
      puts "this is ssessions in send action : #{SESSIONS[request['session_id']]}"


    },
    clear_context: -> (request) {
      puts "Executing 'clear_context' action"
      return {}
    },
    fetch_weather: -> (request) {
      puts "Executing 'fetch_weather' action"

      context = request['context']
      entities = request['entities']

      location = first_entity_value(entities, 'location')
      puts "This is request #{request.to_json}"

      if location
        puts "Entered Location"
        puts "this is location : #{location}"
        response = HTTParty.get('https://query.yahooapis.com/v1/public/yql?q=select * from weather.forecast where woeid in (select woeid from geo.places(1) where text="' + location + '") and u="c"&format=json')
        puts "This is api response #{response.to_json}"
        if response['query']['count'] == 0
          context['wrong_location'] = true
          context.delete('forecast')
          context.delete('missing_location')
        else
          forecast = "It's " + response['query']['results']['channel']['item']['condition']['text'] + " and " + response['query']['results']['channel']['item']['condition']['temp'] + " °C in " + response['query']['results']['channel']['location']['city'] + ", " + response['query']['results']['channel']['location']['country']
          context['forecast'] = forecast
          context.delete('missing_location')
          context.delete('wrong_location')
        end
      else
        context['missing_location'] = true
        context.delete('forecast')
        context.delete('wrong_location')
      end

      return context
    },
    set_reminder: -> (request) {
      puts "Executing 'set_reminder' action"
      puts "this is sessions in set_reminder action : #{SESSIONS[request['session_id']]}"
      SESSIONS[request['session_id']]['entities'] = request['entities'] if SESSIONS[request['session_id']]['entities'].nil?
      entities = SESSIONS[request['session_id']]['entities']
      context = request['context']
      puts "This is request #{request.to_json}"
      if request['entities']['datetime'].nil? && entities['datetime'].nil?
        context['missing_time'] = true
        context.delete('time_set')
        context.delete('reminder_set')
        context.delete('missing_reminder')
        SESSIONS[request['session_id']]['entities']['reminder'] = request['entities']['reminder'] if SESSIONS[request['session_id']]['entities']['reminder'].nil?
      elsif request['entities']['reminder'].nil? && entities['reminder'].nil?
        context['missing_reminder'] = true
        context.delete('time_set')
        context.delete('reminder_set')
        context.delete('missing_time')
        SESSIONS[request['session_id']]['entities']['datetime'] = request['entities']['datetime'] if SESSIONS[request['session_id']]['entities']['datetime'].nil?
      else
        date = first_entity_value(entities, 'datetime') || first_entity_value(request['entities'], 'datetime')
        reminder = first_entity_value(entities, 'reminder') || first_entity_value(request['entities'], 'reminder')
        puts "Setting reminder '#{reminder}' to be at #{date}"

        scheduler = Rufus::Scheduler.new
        scheduler.at date do
          text = "Hey, Just reminding you of " + reminder
          Bot.deliver(recipient: { id: request["session_id"] }, message: { text: text })
        end

        SESSIONS[request['session_id']]['entities'] = nil
        context.delete('missing_time')
        context.delete('missing_reminder')
        context['time_set'] = true
        context['reminder_set'] = true
      end

      puts "this is context in set_reminder action : #{request['context']}"

      return context
    }
  }

  CLIENT = Wit.new(access_token: ENV['WIT_ACCESS_TOKEN'] , actions: actions)
end



def jokes
    jokes = {
      'logic' => [
        'There are only 10 types of people in the world: those that understand binary and those that don’t.',
        'Computers make very fast, very accurate mistakes.',
        'Be nice to the nerds, for all you know they might be the next Bill Gates!',
        'Artificial intelligence usually beats real stupidity.',
        'To err is human – and to blame it on a computer is even more so.',
        'CAPS LOCK – Preventing Login Since 1980.'
      ],

      'the web' => [
        'The truth is out there. Anybody got the URL?',
        'The Internet: where men are men, women are men, and children are FBI agents.',
        'Some things Man was never meant to know. For everything else, there’s Google.'
      ],

      'operating systems' => [
        'The box said ‘Requires Windows Vista or better’. So I installed LINUX.',
        'UNIX is basically a simple operating system, but you have to be a genius to understand the simplicity.',
        'In a world without fences and walls, who needs Gates and Windows?',
        'C://dos, C://dos.run, run.dos.run',
        'Bugs come in through open Windows.',
        'Penguins love cold, they wont survive the sun.',
        'Unix is user friendly. It’s just selective about who its friends are.',
        'Failure is not an option. It comes bundled with your Microsoft product.',
        'NT is the only OS that has caused me to beat a piece of hardware to death with my bare hands.',
        'My daily Unix command list: unzip; strip; touch; finger; mount; fsck; more; yes; unmount; sleep.',
        'Microsoft: “You’ve got questions. We’ve got dancing paperclips.”',
        'Erik Naggum: “Microsoft is not the answer. Microsoft is the question. NO is the answer.”',
        'Windows isn’t a virus, viruses do something.',
        'Computers are like air conditioners: they stop working when you open Windows.',
        'Mac users swear by their Mac, PC users swear at their PC.'
      ],

      'development' => [
        'If at first you don’t succeed; call it version 1.0.',
        'My software never has bugs. It just develops random features.',
        'I would love to change the world, but they won’t give me the source code.',
        'The code that is the hardest to debug is the code that you know cannot possibly be wrong.',
        'Beware of programmers that carry screwdrivers.',
        'Programming today is a race between software engineers striving to build bigger and better idiot-proof programs, and the Universe trying to produce bigger and better idiots. So far, the Universe is winning.',
        'The beginning of the programmer’s wisdom is understanding the difference between getting program to run and having a runnable program.',
        'I’m not anti-social; I’m just not user friendly.',
        'Hey! It compiles! Ship it!',
        'If Ruby is not and Perl is the answer, you don’t understand the question.',
        'The more I C, the less I see.',
        'COBOL programmers understand why women hate periods.',
        'Michael Sinz: “Programming is like sex, one mistake and you have to support it for the rest of your life.”',
        'If you give someone a program, you will frustrate them for a day; if you teach them how to program, you will frustrate them for a lifetime.',
        'Programmers are tools for converting caffeine into code.',
        'My attitude isn’t bad. It’s in beta.',
        'Get the Beta joke on a T-Shirt from the MakeUseOf T-Shirt store.'
      ],

      'computations' => [
        'There are three kinds of people: those who can count and those who can’t.',
        'Latest survey shows that 3 out of 4 people make up 75% of the world’s population.',
        'Hand over the calculator, friends don’t let friends derive drunk.',
        'An infinite crowd of mathematicians enters a bar. The first one orders a pint, the second one a half pint, the third one a quarter pint… “I understand”, says the bartender – and pours two pints.',
        '1f u c4n r34d th1s u r34lly n33d t0 g37 l41d.'
      ],

      'computing' => [
        'Enter any 11-digit prime number to continue.',
        'E-mail returned to sender, insufficient voltage.',
        'All wiyht. Rho sritched mg kegtops awound?',
        'Black holes are where God divided by zero.',
        'If I wanted a warm fuzzy feeling, I’d antialias my graphics!',
        'If brute force doesn’t solve your problems, then you aren’t using enough.',
        'SUPERCOMPUTER: what it sounded like before you bought it.',
        'Evolution is God’s way of issuing upgrades.',
        'Linus Torvalds: “Real men don’t use backups, they post their stuff on a public ftp server and let the rest of the world make copies.”',
        'Hacking is like sex. You get in, you get out, and hope that you didn’t leave something that can be traced back to you.'
      ]
    }
  end
