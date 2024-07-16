require 'rack/test'
require_relative '../app.rb'
require 'stringio'

ENV['RACK_ENV'] = 'test'

RSpec.describe 'Film Service' do
    include Rack::Test::Methods
  
    def app
        Sinatra::Application
    end

    before do
        FILM_CACHE.clear
        ACTOR_CACHE.clear
        @log_output = StringIO.new
        LOGGER.instance_variable_set(:@logdev, Logger::LogDevice.new(@log_output))
    end

    def last_log_message
        @log_output.rewind
        logs = @log_output.read.split("\n")
        logs.last
    end
    
    context 'when querying by actor' do
        it 'returns a list of films for a known actor' do
            get '/', actor: 'Matt_Damon'
            expect(last_response).to be_ok
            response = JSON.parse(last_response.body)
            expect(response).to have_key('films')
        end
  
        it 'returns an empty list for an unknown actor' do
            get '/', actor: 'Non_Existent_Actor'
            expect(last_response).to be_ok
            response = JSON.parse(last_response.body)
            expect(response['films']).to be_empty
        end

        it 'returns cached result for repeated actor query' do
            get '/', actor: 'Matt_Damon'
            first_response = JSON.parse(last_response.body)
            expect(last_log_message).to include("Fetched data from DBpedia for actor")
            get '/', actor: 'Matt_Damon'
            second_response = JSON.parse(last_response.body)
            expect(first_response).to eq(second_response)
            expect(last_log_message).to include("Returning cached data for actor")
        end
    end
  
    context 'when querying by film' do
        it 'returns a list of actors for a known film' do
            get '/', film: 'Hellraiser'
            expect(last_response).to be_ok
            response = JSON.parse(last_response.body)
            expect(response).to have_key('actors')
        end
  
        it 'returns an empty list for an unknown film' do
            get '/', film: 'Non_Existent_Film'
            expect(last_response).to be_ok
            response = JSON.parse(last_response.body)
            expect(response['actors']).to be_empty
        end
  
        it 'returns cached result for repeated film query' do
            get '/', film: 'Hellraiser'
            first_response = JSON.parse(last_response.body)
            expect(last_log_message).to include("Fetched data from DBpedia for film")
            get '/', film: 'Hellraiser'
            second_response = JSON.parse(last_response.body)
            expect(first_response).to eq(second_response)
            expect(last_log_message).to include("Returning cached data for film")
        end
    end
  
    context 'when no parameters are provided' do
        it 'returns a 400 error' do
            get '/'
            expect(last_response.status).to eq(400)
            response = JSON.parse(last_response.body)
            expect(response['error']).to eq('Please provide either an actor or a film parameter.')
        end
    end
  
    context 'when invalid parameters are provided' do
        it 'returns a 400 error for unknown parameter' do
            get '/', unknown: 'value'
            expect(last_response.status).to eq(400)
            response = JSON.parse(last_response.body)
            expect(response['error']).to eq('Please provide either an actor or a film parameter.')
        end
    end
end