module ResHelper
  def get_first_number(full_string)
  	return full_string.match(/\d+/).to_s
  end

  def get_string_from_number_split(full_string, number)
  	return full_string.split(number)[1]
  end

  def split_by_space(full_string)
  	return full_string.strip.split(/\s+/)
  end

  def am_pm_split(full_time)
  	if full_time.scan(/a.m./i).count > 0
  		reg_time = full_time.split(/a.m./i).first
  		hour_min = reg_time.split(":")
  		hour = hour_min[0].to_i
  	elsif full_time.scan(/p.m./i).count > 0
  		reg_time = full_time.split(/p.m./i).first
  		hour_min = reg_time.split(":")
  		hour = hour_min[0].to_i + 12
  	elsif full_time.scan(/pm/i).count > 0
  		reg_time = full_time.split(/pm/i).first
  		hour_min = reg_time.split(":")
  		hour = hour_min[0].to_i  + 12

  	elsif full_time.scan(/am/i).count > 0
  		reg_time = full_time.split(/am/i).first
  		hour_min = reg_time.split(":")
  		hour = hour_min[0].to_i
  	else
  		reg_time = full_time
  		hour_min = reg_time.split(":")
  		hour = hour_min[0].to_i
  	end
  	min = hour_min[1]
  	return {hour: hour, min: min}
  end

  def create_saveable_date(day, month, year, hour)
  	if month.class != Fixnum
	  	if month.length < 4
	  		num_month = Date::ABBR_MONTHNAMES.index(month.capitalize)
	  	else
	  		num_month = month
	  	end
	else
		num_month = month
	end
	
  	new_date = Time.parse("#{year}-#{num_month}-#{day} #{hour}")
  	#string_date = "#{day}/#{num_month}/#{year} #{hour}"
  	#real_date = Chronic.parse(string_date)
  	return new_date
  end
  
  def flight_date_time(day, monthy, year, hour, min)
	month = month_to_number(monthy)
	year_new = year.gsub(/\W+/, '')
	flight_date = DateTime.new(year_new.to_i,month.to_i,day.to_i,hour.to_i,min.to_i, 0, 0)
	
	return flight_date
  end

  def month_to_number(month)
  	if month.class != Fixnum
	  	month = month.gsub(/\W+/, '')
	  	if month.length < 4
	  		num_month = Date::ABBR_MONTHNAMES.index(month.capitalize)
	  	else
	  		num_month = Date::MONTHNAMES.index(month)
	  	end
	else
		num_month = month
	end
	return num_month
  end

  def orbitz_time(string_date)
  	month_name = string_date.split[0]
  	month = Date::MONTHNAMES.index("#{month_name}")
  	day = string_date.split[1]
  	hour = "#{string_date.split[2]} #{string_date[3]}"
  	create_saveable_date(day, month, @year, hour)
  end

  def old_jb_time(date,time)
  	string_date = "#{date} #{time}"
  	return Chronic.parse(string_date)
  end
end