require 'date'
require 'net/http'
require 'timeout'
require 'uri'

require_relative 'float'
require_relative 'prediction'
require_relative 'string'

class HBI
	SITE = 'ijd' # Willimantic
	DAY_COUNT = 8
	FORECAST_HOURS = (6..174).step(24).to_a # 18Z for 8 days
	PARAMS = {
		bearing_from: 20 # NNE
	}

	def self.debug=(value)
		@debug = value
	end

	def self.fetch_predictions(site, params = {})
		# Get 12Z GFS BUFKIT data
		text = Net::HTTP.get(URI.parse("http://www.meteo.psu.edu/bufkit/data/GFS/12/gfs3_#{site}.buf"))
		
		lines = text.split("\r\n")

		FORECAST_HOURS.map do |hour|
			Prediction.find(lines, hour, params)
		end
	end

	def self.fetch_forecasts(site)
		hbis = fetch_predictions(site, PARAMS).map do |prediction|
			{
				'time' => prediction.valid_at,
				'hbi' => prediction.hbi,
				'components' => prediction.components
			}
		end

		{
			'today' => hbis[0],
			'forecasts' => hbis,
			'now' => Time.now
		}
	end
end

if __FILE__ == $0
	# HBI.debug = true
	p HBI.fetch_forecasts('ijd')
end