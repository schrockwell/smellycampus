module LiquidFilters
  def hbi_small_date(date)
    if date.is_a?(String)
      date = Date.parse(date)
    else
      date = date.to_date
    end
    
    if date == Date.today
      'Today'
    else
      date.strftime('%a, %b %-d') # e.g. Mon, Jan 1
    end
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

  def pct(value)
    "#{(value * 100).to_i.round}%"
  end

  def hbi_bg_trmnl_class(hbi)
    case hbi
    when 0; 'bg-gray-7'
    when 1; 'bg-gray-6'
    when 2; 'bg-gray-5'
    when 3; 'bg-gray-4'
    when 4; 'bg-gray-2'
    when 5; 'bg-black'
    else; 'bg-gray-7'
    end
  end

  def hbi_text_trmnl_class(hbi)
    case hbi
    when 4, 5; 'text--white'
    else; ''
    end
  end
end