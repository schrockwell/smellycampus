namespace :db do
	desc 'Migrate/create database schema'
	task :migrate => :environment do
		ActiveRecord::Migrator.migrate('db/migrate', ENV["VERSION"] ? ENV["VERSION"].to_i : nil )
	end

	desc 'Drop database'
	task :drop do
		system("rm '#{File.join(File.dirname(__FILE__), 'db', 'site.sqlite3')}'")
	end
end

task :environment do
	require_relative 'lib/initialize.rb'
end