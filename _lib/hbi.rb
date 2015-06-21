require 'net/http'
require 'uri'
require 'timeout'

class Float
	def sign
		return -1 if self < 0
		return 1
	end
	
	def to_square_normal(bottom, top)
		((self.abs - bottom).abs ** 0.5 * ((top - bottom) ** - 0.5)) * (self - bottom).sign
	end
	
	def to_linear_normal(bottom, top)
		(self - bottom) / (top - bottom)
	end
	
	def to_triangle_normal(bottom, mid, top)
	  if self <= mid
      self.to_linear_normal(bottom, mid)
    else
      self.to_linear_normal(top, mid)
	  end
  end
	
	def to_score(bottom, top)
		if self < bottom
			return bottom
		elsif self > top
			return top
		else
			return self.round
		end
	end
end

class String
	def starts_with?(str)
		return false if self.length < str.length
		return self[0..str.length - 1] == str
	end
	
	def ends_with?(str)
		return false if self.length < str.length
		return self[str.length.. - 1] == str
	end
	
	def collapse
		return self.strip unless self.include?('  ')
		return self.gsub('  ', ' ').collapse
	end
	
end

class HBI
	
	def self.debug=(value)
		@debug = value
	end

	def self.calculate(params, bearing_from)
		wind_dir = params[:wind][:sfc][:direction]
		
		# Find the difference in the angle between the wind_dir and the bearing_from
		delta_dir = [(wind_dir - bearing_from).abs, (360 - (wind_dir - bearing_from)).abs].min
		
		# Invert this on a new scale, where 90 is a perfect match, 0 is perpendicular, and -90 sucks
		delta_dir_adjusted = 90 - delta_dir
		
		# Scale down various values, sometimes maxxing out at 1.0
		cinh = [params[:cinh].to_square_normal(0, 500), 1.0].min
		cap = params[:cap_strength].to_square_normal(0, 6)
		wind = (10.0 - params[:wind][:sfc][:speed]).to_square_normal(0, 10)
		wind_dir = delta_dir_adjusted.abs.to_square_normal(0, 90)
		temp = params[:temp][:sfc].to_square_normal(14, 20)
		humidity = params[:humidity][:sfc].to_triangle_normal(0, 85, 100)
		
		# Multiply the wind and wind_dir to get a decent relationship
		# between these two: e.g. low wind speed at a poor direction is still 
		# okay. Multiply by directional sign and double because two vars are 
		# taken into account
		wind_raw = wind * wind_dir * delta_dir_adjusted.sign * 3 # Because there are 2 parameters + fudge factor
		
		raw = cinh + cap + wind_raw + temp + humidity

		if @debug
			print params.inspect
			print "\n[cinh, cap, wind, wind_dir, wind_raw, temp, humidity]\n"
			print [cinh, cap, wind, wind_dir, wind_raw, temp, humidity].inspect + "\n"
			print "raw = #{raw}\n"
		end
		
		# We want this on a 0-5 scale
		hbi = raw * 5.0/6.0
	end
	
	def self.download_data(model, hour, site)
	
		response = Net::HTTP.post_form(URI.parse('http://www.stormchaser.niu.edu/cgi-bin/getmodel2'),
                              {'mo' => model, 'ft'=> hour.to_s, 'stn' => site})
							  
		text_file = /http:\/\/weather.admin.niu.edu\/chaser\/tempgif\/(.*).TXT/.match(response.body)[1]
		
		text = Net::HTTP.get(URI.parse("http://weather.admin.niu.edu/chaser/tempgif/#{text_file}.TXT"))
		
		lines = text.split("\n")
		
		params = {}
		params[:wind] = {}
		params[:wind][:sfc] = {}
		params[:temp] = {}
		params[:dewpoint] = {}
		params[:humidity] = {}
		
		lines.each do |line|
			columns = line.collapse.split
			
			if line.starts_with?('SFC')
				params[:wind][:sfc][:direction] = columns[8].to_f
				params[:wind][:sfc][:speed] = columns[9].to_f
				params[:temp][:sfc] = columns[3].to_f
				params[:dewpoint][:sfc] = columns[4].to_f
				params[:humidity][:sfc] = columns[5].to_f
			end
			
			if line.starts_with?('Cap Strength:')
				params[:cap_strength] = columns[2].to_f
			end
			
			if line.starts_with?('Conv Inhibition')
				params[:cinh] = columns[3].to_f
			end
			if line.starts_with?('Date: ')
				date_string = columns[4..7] * ' ' + " 20#{columns[8]}" # Turn year from 09 to 2009
				if columns[2] == 'analysis' # 0-hour model run
					date_string.gsub!('00Z ', ':00 ') # For some reason, analysis runs list time differently
				else
					date_string.gsub!('Z ', ':00 ') # Replace Z with :00 for parsing
				end
				params[:valid_at] = DateTime.parse(date_string)

				if columns[2] == 'analysis' # Analysis is 0-hour
					params[:run_at] = params[:valid_at]
					params[:hour] = 0
				else
					if columns[2] == 'hour'
						params[:hour] = columns[1].to_i # Hours
					else
						params[:hour] = (columns[1].to_f * 24).to_i # Convert days to hours
					end
					params[:run_at] = params[:valid_at] - params[:hour].hours
				end
			end
		end
		
		return params
	
	end
	Site = 'kijd' # Willimantic
	BearingFrom = 20 # NNE
	GfsHours = [0, 12, 24, 36, 48, 60, 72, 84, 96, 108, 120, 132, 144, 156, 168, 180, 192, 204, 216, 228, 240] # avn
	RucHours = [0, 3, 6, 9, 12] # ruc
	Days = 10
	#Hour = '12:00' # 8 AM
	Hour = '24:00' # 8 PM
	ReadTimeout = 10 # sec
		
	def self.update_db	    
		GfsHours.each do |hour|
			puts "Calculating for hour #{hour}..."

			begin
				Timeout::timeout(ReadTimeout) do
					params = HBI.download_data('avn', hour, Site)
				end
				hbi = HBI.calculate(params, BearingFrom)
			rescue Timeout::Error
				puts "Timeout downloading model data for hour #{hour}; the site is probably down"
				next
			rescue
				puts "Error calculating HBI; most likely the model output isn't available yet"
				next
			end

			sounding = Sounding.where(:run_at => params[:run_at], :valid_at => params[:valid_at]).first
			next if sounding # Don't create duplicates

			# Dump out valid_at and run_at params
			params_saved = params.reject { |k, v| [:run_at, :valid_at, :hour].include?(k) }

			Sounding.create(
				:run_at => params[:run_at], 
				:valid_at => params[:valid_at], 
				:model => 'avn', 
				:index => hbi.to_score(0, 5),
				:params => params_saved.inspect,
				:hour => params[:hour]
			)
		end
	end
end
