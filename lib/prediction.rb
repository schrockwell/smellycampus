class Prediction
	def self.find(lines, forecast_hour, params = {})
		stim_index = lines.find_index { |line| line.starts_with?("STIM = #{forecast_hour}") }
		raise "could not find 'STIM = #{forecast_hour}'" unless stim_index

		slice = lines[(stim_index - 2)..(stim_index + 12)]
		self.new(slice, params)
	end

	def self.get_value(line, key)
		regex = /#{key} = ([^\s]+)/
		match = regex.match(line)
		raise "could not find '#{key}' in #{line.inspect}" unless match
		match[1]
	end

	attr_reader :valid_at, :hbi, :components

	def initialize(lines, params = {})
		# 00 STID = IJD STNM = 725084 TIME = 250110/1800
		# 01 SLAT = 41.73 SLON = -72.18 SELV = 76.00
		# 02 STIM = 174
		# 03 
		# 04 SHOW = 10.63 LIFT = 17.21 SWET = 81.82 KINX = -5.59
		# 05 LCLP = 842.94 PWAT = 5.53 TOTL = 38.96 CAPE = 0.00
		# 06 LCLT = 260.91 CINS = 0.00 EQLV = -9999.00 LFCT = -9999.00
		# 07 BRCH = 0.00
		# 08 
		# 09 PRES TMPC TMWC DWPC THTE DRCT SKNT OMEG
		# 10 HGHT
		# 11 992.80 0.24 -3.00 -10.19 279.10 318.27 9.64 0.20
		# 12 76.00

		raw_time = self.class.get_value(lines[0], 'TIME')
		@valid_at = DateTime.strptime(raw_time, "%y%m%d/%H%M")
		@forecast_hour = self.class.get_value(lines[2], 'STIM').to_i

		@bearing_from = params[:bearing_from] || 0

		# Parameters: http://www.meteo.psu.edu/bufkit/bufkit_parameters.txt
		sfc_row = lines[11].split(' ')
		@pressure = sfc_row[0].to_f
		@temp_c = sfc_row[1].to_f
		@wet_bulb_c = sfc_row[2].to_f
		@dewpoint_c = sfc_row[3].to_f
		@wind_dir = sfc_row[5].to_f
		@wind_speed_kt = sfc_row[6].to_f
		@cinh = self.class.get_value(lines[6], 'CINS').to_f

		calculate_hbi

		# Unused: 
		# @theta_e = sfc_row[4].to_f
		# @omega = sfc_row[7].to_f
		# @cape = self.class.get_value(lines[5], 'CAPE')
	end

	def relative_humidity
		100 * (Math.exp((17.625 * @dewpoint_c) / (243.04 + @dewpoint_c)) / Math.exp((17.625 * @temp_c) / (243.04 + @temp_c)))
	end

	private

	def calculate_hbi
		wind_dir = @wind_dir
			
		# Find the difference in the angle between the wind_dir and the BEARING_FROM
		delta_dir = [(wind_dir - @bearing_from).abs, (360 - (wind_dir - @bearing_from)).abs].min
		
		# Invert this on a new scale, where 90 is a perfect match, 0 is perpendicular, and -90 sucks
		delta_dir_adjusted = 90 - delta_dir
		
		# Scale down various values, sometimes maxxing out at 1.0
		cinh = [@cinh.to_square_normal(0, 500), 1.0].min
		# cap = params[:cap_strength].to_square_normal(0, 6)
		wind = (10.0 - @wind_speed_kt).to_square_normal(0, 10)
		wind_dir = delta_dir_adjusted.abs.to_square_normal(0, 90)
		temp = @temp_c.to_square_normal(14, 20)
		humidity = relative_humidity.to_triangle_normal(0, 85, 100)

		if @debug
			p({
				valid_at: @valid_at,
				relative_humidity: relative_humidity,
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
		@hbi = (raw * 5.0/5.0).clamp(0.0, 5.0).round

		@components = {
			'cinh' => cinh,
			'wind' => wind_raw,
			'temp' => temp,
			'humidity' => humidity,
			'total' => raw
		}
	end
end