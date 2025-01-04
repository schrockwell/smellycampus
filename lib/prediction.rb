class Prediction
	def self.find(lines, forecast_hour)
		stim_index = lines.find_index { |line| line.starts_with?("STIM = #{forecast_hour}") }
		raise "could not find 'STIM = #{forecast_hour}'" unless stim_index

		slice = lines[(stim_index - 2)..(stim_index + 12)]
		self.new(slice)
	end

	def self.get_value(line, key)
		regex = /#{key} = ([^\s]+)/
		match = regex.match(line)
		raise "could not find '#{key}' in #{line.inspect}" unless match
		match[1]
	end

	attr_reader :valid_at,
		:forecast_hour,
		:temp_c,
		:dewpoint_c,
		:wind_dir,
		:wind_speed_kt,
		:cinh

	def initialize(lines)
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

		# Parameters: http://www.meteo.psu.edu/bufkit/bufkit_parameters.txt
		sfc_row = lines[11].split(' ')
		@pressure = sfc_row[0].to_f
		@temp_c = sfc_row[1].to_f
		@wet_bulb_c = sfc_row[2].to_f
		@dewpoint_c = sfc_row[3].to_f
		@wind_dir = sfc_row[5].to_f
		@wind_speed_kt = sfc_row[6].to_f
		@cinh = self.class.get_value(lines[6], 'CINS').to_f

		# Unused: 
		# @theta_e = sfc_row[4].to_f
		# @omega = sfc_row[7].to_f
		# @cape = self.class.get_value(lines[5], 'CAPE')
	end

	def relative_humidity
		100 * (Math.exp((17.625 * @dewpoint_c) / (243.04 + @dewpoint_c)) / Math.exp((17.625 * @temp_c) / (243.04 + @temp_c)))
	end
end