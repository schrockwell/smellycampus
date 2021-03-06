Storrs Odor Watch
=================

This project stinks. See the live site at [smellycamp.us](http://smellycamp.us/).

Setup
-----

Prerequisites:

* [Ruby](https://www.ruby-lang.org/en/) – 1.9.3 or 2.x
* [RubyGems](https://rubygems.org/pages/download)
* [Bundler](http://bundler.io/) – `gem install bundler --no-ri --no-rdoc`

From the site root:

    bundle install
    rake db:migrate

Site Generation
---------------

From the site root:

    rake

It's that simple. The site is temporarily generated in `/_output/`, then copied over to `/public/` when complete.

This site uses GFS weather model data from the 0:00 UTC and 12:00 UTC runs, so run every 12 hours accordingly – recommended at 6Z and 18Z.

How It Works
------------

1. The `HBI` (Horse Barn Index) class pulls down weather model data into memory.
2. It uses a totally non-scientific heuristic to combine the model data (wind speeds and directions, temperature at different heights of the atmosphere, humidity, etc.) into a single, stinky parameter – the HBI.
3. The results for each model run are stored in a SQLite database. Not every model run will have data for all forecast hours, so old runs have to be cached.
4. The [Stasis](http://stasis.me/) gem does its thing to generate `index.html`.

Development Notes
-----------------

If you are using `stasis -d` to auto-regenerate the site, you may want to comment out `HBI.update_db` in `controller.rb` so that it doesn't pull data every single time.

To-Do
---------

* Support customizable forecast location with a config file

More Info
---------

* See the site – [smellycamp.us](http://smellycamp.us/)
* Stasis gem – [source](https://github.com/winton/stasis), [homepage](http://stasis.me/)
* Author – [Rockwell Schrock](http://rockwellschrock.com/)