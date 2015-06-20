namespace :db do
	desc 'Migrate/create database schema'
	task :migrate => :environment do
		ActiveRecord::Migrator.migrate('db/migrate', ENV["VERSION"] ? ENV["VERSION"].to_i : nil )
	end
end

task :environment do
	require_relative 'lib/initialize.rb'
end