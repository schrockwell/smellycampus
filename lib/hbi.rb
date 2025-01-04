require 'date'
require 'net/http'
require 'timeout'
require 'uri'

require_relative 'float'
require_relative 'prediction'
require_relative 'string'

class HBI
	SITE = 'ijd' # Willimantic
	BEARING_FROM = 20 # NNE
	DAY_COUNT = 8
	FORECAST_HOURS = (6..174).step(24).to_a # 18Z for 8 days

	def self.debug=(value)
		@debug = value
	end

	def self.calculate(prediction, bearing_from)
		wind_dir = prediction.wind_dir
		
		# Find the difference in the angle between the wind_dir and the bearing_from
		delta_dir = [(wind_dir - bearing_from).abs, (360 - (wind_dir - bearing_from)).abs].min
		
		# Invert this on a new scale, where 90 is a perfect match, 0 is perpendicular, and -90 sucks
		delta_dir_adjusted = 90 - delta_dir
		
		# Scale down various values, sometimes maxxing out at 1.0
		cinh = [prediction.cinh.to_square_normal(0, 500), 1.0].min
		# cap = params[:cap_strength].to_square_normal(0, 6)
		wind = (10.0 - prediction.wind_speed_kt).to_square_normal(0, 10)
		wind_dir = delta_dir_adjusted.abs.to_square_normal(0, 90)
		temp = prediction.temp_c.to_square_normal(14, 20)
		humidity = prediction.relative_humidity.to_triangle_normal(0, 85, 100)

		if @debug
			p({
				valid_at: prediction.valid_at,
				relative_humidity: prediction.relative_humidity,
				cinh: cinh,
				wind: wind,
				wind_dir: wind_dir,
				temp: temp,
				humidity: humidity
			})
		end
		
		# Multiply the wind and wind_dir to get a decent relationship
		# between these two: e.g. low wind speed at a poor direction is still 
		# okay. Multiply by directional sign and double because two vars are 
		# taken into account
		wind_raw = wind * wind_dir * delta_dir_adjusted.sign * 3 # Because there are 2 parameters + fudge factor
		
		raw = cinh + wind_raw + temp + humidity #+ cap
		
		# We want this on a 0-5 scale
		hbi = (raw * 5.0/5.0).clamp(0.0, 5.0).round
	end

	def self.fetch_predictions(site)
		# Get 12Z GFS BUFKIT data
		text = Net::HTTP.get(URI.parse("http://www.meteo.psu.edu/bufkit/data/GFS/12/gfs3_#{site}.buf"))
		
		lines = text.split("\r\n")

		FORECAST_HOURS.map do |hour|
			Prediction.find(lines, hour)
		end
	end

	def self.fetch_forecasts(site)
		hbis = fetch_predictions(site).map do |prediction|
			{
				'time' => prediction.valid_at,
				'hbi' => calculate(prediction, BEARING_FROM)
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