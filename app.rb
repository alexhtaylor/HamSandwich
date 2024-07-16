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

  # Format the actor and film params correctly
  actor = params['actor']&.gsub('_', ' ')
  film = params['film']&.gsub('_', ' ')

  if actor
    # Return cached result if available
    if ACTOR_CACHE.key?(actor)
        LOGGER.info("Returning cached data for actor") # Log use of the cache
        return ACTOR_CACHE[actor].to_json
    end
    query = <<-SPARQL
      SELECT ?filmLabel WHERE {
        ?film rdf:type dbo:Film .
        ?film dbo:starring ?actor .
        ?actor rdfs:label "#{actor}"@en .
        ?film rdfs:label ?filmLabel .
        FILTER (lang(?filmLabel) = 'en')
      }
    SPARQL

    results = sparql.query(query)
    films = results.map { |result| result[:filmLabel].to_s }
    LOGGER.info("Fetched data from DBpedia for actor") # Log use of DBpedia
    response = { films: films }
    ACTOR_CACHE[actor] = response

    response.to_json

  elsif film
    # Return cached result if available
    if FILM_CACHE.key?(film)
        LOGGER.info("Returning cached data for film") # Log use of cache
        return FILM_CACHE[film].to_json 
    end

    query = <<-SPARQL
      SELECT ?actorLabel WHERE {
        ?film rdf:type dbo:Film .
        ?film rdfs:label "#{film}"@en .
        ?film dbo:starring ?actor .
        ?actor rdfs:label ?actorLabel .
        FILTER (lang(?actorLabel) = 'en')
      }
    SPARQL

    results = sparql.query(query)
    actors = results.map { |result| result[:actorLabel].to_s }
    LOGGER.info("Fetched data from DBpedia for film") # Log use of DBpedia
    response = { actors: actors }
    FILM_CACHE[film] = response

    response.to_json

  else
    status 400
    { error: 'Please provide either an actor or a film parameter.' }.to_json
  end
end

# Start the Sinatra server
set :bind, '0.0.0.0'
set :port, 9292