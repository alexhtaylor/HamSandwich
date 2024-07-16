# HamSandwich

To run this app, download the repository and navigate to the film_web_service directory in your terminal.

Ensure you have Ruby installed by running `ruby -v` in your terminal. 

Run `bundle install` to install the necessary gems.

Run `ruby app.rb` to launch the web service application.

In your browser, visit `http://localhost:9292/` to use the web service. Execute requests in the URL format `http://localhost:9292/?actor=Firstname_Surname` or `http://localhost:9292?film=Film_Name`

Alternatively, open a new tab in your terminal and you may execute requests in the format `curl "http://localhost:9292?actor=Firstname_Surname"` or `curl "http://localhost:9292?film=Film_Name"`
