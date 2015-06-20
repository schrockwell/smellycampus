def hbi_small_date(date)
	if date.to_date == Date.today
		'Today'
	else
		date.strftime('%a, %b %d') # e.g. Mon, Jan 01
	end
end

def sounding_time(time)
	time.utc.strftime('%b %d %HZ')
end

def hbi_description(hbi)
	return 'N/A' if hbi == 'na'
	case hbi.to_i
	when 0; 'none'
	when 1; 'very low'
	when 2; 'low'
	when 3; 'moderate'
	when 4; 'high'
	when 5; 'extreme'
	end
end

def grid(items, titles, options = {}, &block)
	reset_cycle 'grid' 
	options.merge!(:block => block, :titles => titles, :items => items)
	options.merge!(:paginate => true) unless options.has_key?(:paginate)
	options.merge!(:column_classes => nil) unless options.has_key?(:column_classes)
	options.merge!(:empty_message => nil) unless options.has_key?(:empty_message)
	concat(render(:partial => '/partials/grid', :locals => options))
end

def yes_no_format(boolean)
	return boolean ? 'Yes' : 'No'
end