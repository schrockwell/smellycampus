namespace :db do
	desc 'Migrate/create database schema'
	task :migrate => :environment do
		ActiveRecord::Migrator.migrate(File.join(File.dirname(__FILE__), '_db', 'migrate'), ENV["VERSION"] ? ENV["VERSION"].to_i : nil )
	end

	desc 'Drop database'
	task :drop do
		system("rm '#{File.join(File.dirname(__FILE__), '_db', 'site.sqlite3')}'")
	end
end

desc 'Builds the site'
task :build => :environment do
	require 'fileutils'
	require 'stasis'

	begin
		temp = File.join(File.dirname(__FILE__), '_output')
		final = File.join(File.dirname(__FILE__), 'public')

		stasis = Stasis.new(File.dirname(__FILE__), temp)
		stasis.render
		
 		# Weird hack so we don't get dupe dest dirs
		FileUtils.cp_r("#{temp}/.", "#{final}/")
	rescue Exception => ex
		puts "Error during Stasis#render: #{ex.message}"
		puts ex.backtrace.join("\n")
	end
end

task :default => :build

task :environment do
	require_relative '_lib/initialize.rb'
end