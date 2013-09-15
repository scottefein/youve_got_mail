require 'sinatra'
require 'uri'
require 'twilio-ruby'
require 'puma'

class YouveGotMail < Sinatra::Base
	configure do
	  set :notify_numbers, ENV['NOTIFY_NUMBERS'].split(',')
	  set :twilio_number, ENV['TWILIO_NUMBER']
	  set :twilio_sid, ENV['TWILIO_SID']
	  set :twilio_token, ENV['TWILIO_TOKEN']
	end

	def twilio_auth
		account_sid = settings.twilio_sid
		auth_token = settings.twilio_token
		client = Twilio::REST::Client.new account_sid, auth_token
	end

	def call_with_twilio(number, subject)
		client = twilio_auth
		url_subject = URI.escape(subject)
		client.account.calls.create(
		  :from => "+#{settings.twilio_number}",   # From your Twilio number
		  :to => "+#{number}",     # To any number
		  # Fetch instructions from this URL when the call connects
		  :url => "http://#{request.host}/twilio_speak?subject=#{url_subject}"
		)
	end


	def send_sms_with_twilio(number, subject)
		client = twilio_auth
		client.account.sms.messages.create(
	    :from => "+#{settings.twilio_number}", 
		  :to => "+#{number}", 
	    :body => subject
	  ) 
	end

	def notify(subject)
		login_body = login
		settings.notify_numbers.each do |number|
			send_sms_with_twilio(number, subject)
			call_with_twilio(number, subject)
		end
	end

	post '/new_email_mail' do
		mail = params
		email_subject= mail['subject']
		notify("You've Got an Email. Subject Line: #{email_subject}")
	end

	get '/test' do
		notify("Test Subject")
		"CALLING"
	end

	post '/twilio_speak' do
		Twilio::TwiML::Response.new do |r|
	    r.Say params[:subject]
	  end.text
	end
end

