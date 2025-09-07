require 'openai'

# THIS IS THE LATEST ONE

# CIRCLE=richmond DATE=2024-04-14 CONTACT=auxhall EVENT=ccp SESSION=11 ruby ~/Desktop/transcribe.rb

# Mp3 must be rendered to a file called small.mp3 in path with a very low bitrate

class Transcriber
  attr_reader :text 

  def initialize(path)
  	client = OpenAI::Client.new(access_token: ENV['OPENAI_API_KEY'], request_timeout: 600)

  	response = client.audio.translate(
      parameters: {
          model: "whisper-1",
          file: File.open(path, "rb"),
          prompt: channeling_prompt
      }
    )
    @text = response['text']
  end

private
  def channeling_prompt
		%Q~You are an editor of information received from entities in the 
		Confederation of Planets in Service to the One Infinite Creator. Please 
		review material from High Altitude Receiving Center, and format the sentence
		and paragraph structure like theirs. In addition, pay attention to the name
		of the contact and ensure it's one of these: Q'uo, Hatonn, Laitos, Monka,
		Oorkas, Auxhall. Pay attention also to when the speaker changes if you can
		and make a small note. Finally, break things up into cogent paragraphs that 
		improve readability.~
	end
end

class OswgTranscribe
	ROOT_PATH = '/Users/jeremyweiland/src/akasha/'.freeze

	def initialize(circle:, date:, contact:nil, session:nil, event:nil)
		@circle = circle
		@contact = contact
		@date = date
		@session = session
		@event = event
	end

	def call(echo = false)
		text = Transcriber.new(path_to_mp3).text
		puts text if echo
		File.open(path_to_text, 'w') do |f|
			f << [frontmatter, text].join("\n\n")
		end
	end

	def frontmatter
		<<~DOC
			---
			Date: #{@date}
			Circle: #{@circle}
			Event: #{@event}
			Session: #{@session}
			Contacts: #{contact_formatted}
			Channels:
			Tags: 
			Media: 
			---
		DOC
	end

	def elements
		a = [ ROOT_PATH, @circle, @event, slug ]
		# a << @event if @contact == "quo"
		# a << slug
	end	

	def slug
		# if @contact == "quo"
		# 	"#{@event}_#{@date}_s"
		# else
		# 	[@date, @contact].join("_")
		# end
		sesh = "%03d" % @session.to_i
		[@date, @circle, @event, sesh].join('_')
	end

	def path_to_mp3
		items = elements << "small.mp3"
		path = File.join(*items)
		return path if File.exist? path
		items = elements << "#{slug}.mp3"
		path = File.join(*items)
	end

	def path_to_text
		items = elements << "#{slug}.md"
		File.join(*items)
	end

	def contact_formatted
		case @contact
		when 'quo'
			'Q\'uo'
		else
			@contact.capitalize
		end
	end
end

OswgTranscribe.new(circle: ENV['CIRCLE'], date: ENV['DATE'], contact: ENV['CONTACT'], session: ENV['SESSION'], event: ENV['EVENT']).call(true)