require 'rack/test'
require_relative '../app.rb'
require 'stringio'

# to run tests: bundle exec rspec

ENV['RACK_ENV'] = 'test'

RSpec.describe 'Film Service' do
    include Rack::Test::Methods
  
    def app
        Sinatra::Application
    end

    before do
        # Reset the caches before each test to ensure queries are tested correctly
        FILM_CACHE.clear 
        ACTOR_CACHE.clear
        # initialise logger to track cache use
        @log_output = StringIO.new
        LOGGER.instance_variable_set(:@logdev, Logger::LogDevice.new(@log_output))
    end

    # Method to return most recent log message for cache testing
    def last_log_message
        @log_output.rewind
        logs = @log_output.read.split("\n")
        logs.last
    end
    

    context 'when querying by actor' do
        # Testing response format for known actor parameter
        it 'returns a list of films for a known actor' do
            get '/', actor: 'Matt_Damon'
            expect(last_response).to be_ok
            response = JSON.parse(last_response.body)
            expect(response).to have_key('films')
        end

        # Testing response format for unknown actor parameter
        it 'returns an informative error message for an unknown actor' do
            get '/', actor: 'Non_Existent_Actor'
            expect(last_response.status).to eq(404)
            expect(last_response.body).to include('No films found for the actor')
        end

        # Testing caching of repeated identical actor queries
        it 'returns cached result for repeated actor query' do
            get '/', actor: 'Matt_Damon'
            first_response = JSON.parse(last_response.body)
            # Checking DBpedia is queried for initial request
            expect(last_log_message).to include("Fetched data from DBpedia for actor")

            # Repeat the same request to test cache functionality
            get '/', actor: 'Matt_Damon'
            second_response = JSON.parse(last_response.body)
            expect(first_response).to eq(second_response)
            # Checking cache is queried for repeated request
            expect(last_log_message).to include("Returning cached data for actor")
        end
    end
  
    context 'when querying by film' do
        # Testing response format for known film parameter
        it 'returns a list of actors for a known film' do
            get '/', film: 'Hellraiser'
            expect(last_response).to be_ok
            response = JSON.parse(last_response.body)
            expect(response).to have_key('actors')
        end

        # Testing response format for unknown film parameter
        it 'returns an informative error message for an unknown film' do
            get '/', film: 'Non_Existent_Film'
            expect(last_response.status).to eq(404)
            expect(last_response.body).to include('No actors found for the film')
        end

        # Testing caching of repeated identical film queries
        it 'returns cached result for repeated film query' do
            get '/', film: 'Hellraiser'
            first_response = JSON.parse(last_response.body)
            # Checking DBpedia is queried for initial request
            expect(last_log_message).to include("Fetched data from DBpedia for film")

            # Repeat the same request to test cache functionality
            get '/', film: 'Hellraiser'
            second_response = JSON.parse(last_response.body)
            expect(first_response).to eq(second_response)
            # Checking cache is queried for repeated request
            expect(last_log_message).to include("Returning cached data for film")
        end
    end
  
    # Testing error handling for missing parameters
    context 'when no parameters are provided' do
        it 'returns a 400 error' do
            get '/'
            expect(last_response.status).to eq(400)
            response = JSON.parse(last_response.body)
            expect(response['error']).to eq('Please provide either an actor or a film parameter.')
        end
    end
  
    # Testing error handling for invalid parameters
    context 'when invalid parameters are provided' do
        it 'returns a 400 error for unknown parameter' do
            get '/', unknown: 'value'
            expect(last_response.status).to eq(400)
            response = JSON.parse(last_response.body)
            expect(response['error']).to eq('Please provide either an actor or a film parameter.')
        end
    end
end