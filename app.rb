require 'sinatra'
require 'sparql/client'
require 'json'
require 'logger'

# Configure the SPARQL client to use the DBpedia endpoint
sparql = SPARQL::Client.new("http://dbpedia.org/sparql")

# Initialize in-memory caches for actors and films
FILM_CACHE = {}
ACTOR_CACHE = {}
LOGGER = Logger.new(STDOUT)

get '/' do
  content_type :json

  # Format the actor and film parameters correctly
  actor = params['actor']&.gsub('_', ' ')
  film = params['film']&.gsub('_', ' ')

  if actor
    # Return cached results for actor if available
    if ACTOR_CACHE.key?(actor)
        LOGGER.info("Returning cached data for actor") # Log use of the cache for testing
        return ACTOR_CACHE[actor].to_json
    end

    # Construct SPARQL query for the actor param
    query = <<-SPARQL
      SELECT ?filmLabel WHERE {
        ?film rdf:type dbo:Film .
        ?film dbo:starring ?actor .
        ?actor rdfs:label "#{actor}"@en .
        ?film rdfs:label ?filmLabel .
        FILTER (lang(?filmLabel) = 'en')
      }
    SPARQL

    results = sparql.query(query) # execute the query and store the results
    films = results.map { |result| result[:filmLabel].to_s } # format the results
    LOGGER.info("Fetched data from DBpedia for actor") # Log use of DBpedia for testing

    if films.empty? 
      status 404
      response = { error: "No films found for the actor '#{actor}'" }
    else
      response = { films: films }
    end

    ACTOR_CACHE[actor] = response # cache the response
    
    response.to_json # return the json formatted response

  elsif film
    # Return cached result if available
    if FILM_CACHE.key?(film)
        LOGGER.info("Returning cached data for film") # Log use of cache for testing
        return FILM_CACHE[film].to_json 
    end

    # Construct SPARQL query for the film parameter
    query = <<-SPARQL
      SELECT ?actorLabel WHERE {
        ?film rdf:type dbo:Film .
        ?film rdfs:label "#{film}"@en .
        ?film dbo:starring ?actor .
        ?actor rdfs:label ?actorLabel .
        FILTER (lang(?actorLabel) = 'en')
      }
    SPARQL

    results = sparql.query(query) # execute the query and store the results
    actors = results.map { |result| result[:actorLabel].to_s } # format the results
    LOGGER.info("Fetched data from DBpedia for film") # Log use of DBpedia for testing
    
    if actors.empty?
      status 404
      response = { error: "No actors found for the film '#{film}'" }
    else
      response = { actors: actors }
    end

    FILM_CACHE[film] = response # cache the response

    response.to_json # return the json formatted response

  else
    # Error message to user if invalid parameters are passed
    status 400
    { error: 'Please provide either an actor or a film parameter.' }.to_json
  end
end

# Start the Sinatra server
set :bind, '0.0.0.0'
set :port, 9292