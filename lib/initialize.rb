require 'active_record'
require_relative 'hbi'
require_relative 'sounding'
require_relative 'helpers'

ActiveRecord::Base.establish_connection(:adapter => 'sqlite3', :database => File.join(File.dirname(__FILE__), '..', 'db', 'site.sqlite3'))