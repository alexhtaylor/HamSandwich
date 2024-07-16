# HamSandwich

To download this repository, run `git clone https://github.com/alexhtaylor/HamSandwich.git` in your terminal and navigate to the HamSandwich directory.

Ensure you have Ruby installed by running `ruby -v` in your terminal. 

Run `bundle install` to install the necessary gems.

Run `ruby app.rb` to launch the web service application.

In your browser, visit `http://localhost:9292/` to use the web service. Execute requests in the URL format `http://localhost:9292/?actor=Firstname_Surname` or `http://localhost:9292?film=Film_Name`

Alternatively, open a new tab in your terminal and you may execute requests in the format `curl "http://localhost:9292?actor=Firstname_Surname"` or `curl "http://localhost:9292?film=Film_Name"`
