require_relative '_lib/initialize'

ignore /(Gemfile|Rakefile|README|LICENSE)/ # "Important" stuff
ignore /\/[._]/ # Dotfiles and files/folders starting with underscores

layout 'partials/_layout.html.erb'

helpers do
	load File.join(File.dirname(__FILE__), '_lib', 'helpers.rb')
end

before 'index.html.erb' do
	# HBI.update_db

	@soundings = []

	valid_at = DateTime.parse("#{HBI::Hour} #{Date.today}")
	(1..HBI::Days).each do |day|
		@soundings << Sounding.where(:valid_at => valid_at).order('run_at desc').first
		valid_at += 1.day
	end
end