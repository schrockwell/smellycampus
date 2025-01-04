# Storrs Odor Watch

This project stinks. See the live site at [smellycamp.us](http://smellycamp.us/).

## Setup

Prerequisites:

- [Ruby 3.x](https://www.ruby-lang.org/en/)

From the site root:

    bundle

## Site Generation

From the site root:

    bundle exec ./generate.rb

It's that simple. The site is generated in `/_site`.

This site uses GFS weather model data from the 12Z runs, so run it every 24 hours after that.

## How It Works

1. The `HBI` (Horse Barn Index) class pulls down weather model data into memory.
2. It uses a totally non-scientific heuristic to combine the model data (wind speeds and directions, temperature at different heights of the atmosphere, humidity, etc.) into a single, stinky parameter – the HBI.
3. The [Liquid](https://github.com/Shopify/liquid) page template is evaluated and written to disk.

## To-Do

- Support customizable forecast location with a config file

## More Info

- See the site – [smellycamp.us](http://smellycamp.us/)
- Author – [Rockwell Schrock](http://rockwellschrock.com/)
