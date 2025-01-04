module LiquidFilters
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
end