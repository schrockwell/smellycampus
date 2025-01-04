#! /usr/bin/env ruby

require 'fileutils'
require 'json'
require 'liquid'

require_relative 'lib/hbi'
require_relative 'lib/liquid_filters'

# Parameters / constants
template_dir = 'templates'
output_dir = '_site'
input_files = [
  'index.html.liquid',
  'trmnl.html.liquid'
]

# Wipe the output directory and copy assets over
FileUtils.rm_rf(output_dir)
FileUtils.mkdir_p(output_dir)
FileUtils.cp_r('assets/images', output_dir)
FileUtils.cp_r('assets/scripts', output_dir)
FileUtils.cp_r('assets/styles', output_dir)

puts 'Downloading forecasts...'
data = HBI.fetch_forecasts('ijd')
puts "Got #{data['forecasts'].length} forecasts"

input_files.each do |input_file|
  template = Liquid::Template.parse(File.read(File.join(template_dir, input_file)))
  output_file = File.join(output_dir, input_file.gsub('.liquid', ''))

  puts "Rendering #{output_file}..."

  File.open(output_file, 'w') do |f|
    f.write(template.render(data, filters: [LiquidFilters]))
  end
end

File.open(File.join(output_dir, 'trmnl.json'), 'w') do |f|
  f.write(data.to_json)
end

puts 'Done!'