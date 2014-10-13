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

  def job_finished(id)
    status = Resque::Plugins::Status::Hash.get(id)
    if status.status == "completed"
      return true
    else
      return false
    end
  end
  
  def jb_city_airport(jb_city)
    if jb_city == "New York Jfk" || jb_city == "New York Lga"
      airport_nyc = jb_city.split(" ").last.upcase
      return  Airport.find_by_faa(airport_nyc).id
    elsif jb_city == "Portland Or"
      return Airport.where("city = ?", "Portland").first.id
    elsif jb_city == "Ft Lauderdale"
      return Airport.find_by_city("Fort Lauderdale").id
    else
      if Airport.where("city = ?", jb_city).count > 0
        return Airport.where("city = ?", jb_city).first.id
      else 
        return 1
      end
    end
  end

  def message_year_check(month, year)
    if month == "12"
      return year.to_i
    else
      return year.to_i + 1
    end
  end

  def city_error_check(city, direction, airline_id, message_id, trip)
    return AirportMapping.where(city: city).first_or_create do |am| 
      am.airline_id = airline_id
      am.note = direction
      am.message_id = message_id
      am.trip_id = trip
    end
  end
  
  def rollbar_error(message_id, city, airline_id, user_id)
    #Rollbar.report_exception(e, rollbar_request_data, rollbar_person_data)
    #Rollbar.report_message("Bad City", "error", :message_id => message_id, :city => city)
    ErrorMailer.uca(user_id, city, message_id, airline_id ).deliver
  end
end