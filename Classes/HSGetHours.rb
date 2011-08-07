#!/usr/bin/ruby
####################################
#
#  HSGetHours.rb
#
#  Author: Igor Sales.
#  Copyright (c) 2011 Igor Sales. All rights reserved.
#

require 'rubygems'
require 'gcal4ruby'
require 'optparse'
require 'HSCalendarPasswordController'

include GCal4Ruby


class HSGetHours
  DAY_FORMAT            = '%a %b %d, %Y'
  TIME_FORMAT           = '%H:%M'
  ONE_DAY_IN_SECONDS    = 24*60*60
  ONE_HOUR_IN_SECONDS   = 60*60
  ONE_MINUTE_IN_SECONDS = 60
  ONE_HOUR_IN_MINUTES   = 60
  
  def formatted_hours(t)
    h = t.to_i
    m = t - h
  
    m = m * ONE_HOUR_IN_MINUTES
  
    ("%d:" % h) + ("%02d" % m)
  end
  
  def parse_cmd_line_args
    options = {}
    OptionParser.new do |opts|
      opts.banner = "Usage: get_hours.rb [options]"
  
      opts.on("-u", "--username USERNAME", "Username:") do |v|
        options[:username] = v
      end
      opts.on("-p", "--password PASSWORD", "Password:") do |v|
        options[:password] = v
      end
      opts.on("-c", "--calendar CALENDAR", "Calendar name") do |v|
        options[:calendar] = v
      end
    end.parse!

    @start_time_str = ARGV[0]
    @end_time_str   = ARGV[1]

    @username       = options[:username]
    @password       = options[:password]
    @calendar_name  = options[:calendar]
    
    raise "Please specify the username and calendar" if @username.nil? or @calendar_name.nil?
  end

  def handle_password
    # If password wasn't specified, try to get it from KeyChain
    if @password.nil?
      @password = HSCalendarPasswordController.passwordForUsername(@username)
      if @password.nil? # Still nil? We couldn't get it, so error out
        raise "Cannot find password for username #{@username}"
      end
    else
      # User specified a password, so store it
      HSCalendarPasswordController.setPassword_forUsername(@password, @username)
    end
  end

  def fetch_events(start_time_str, end_time_str)
    if start_time_str and end_time_str.nil?
      tmp_time = Time.parse(start_time_str)
      # Is it the first of the month?
      if tmp_time.day == 1 and tmp_time.hour == 0 and tmp_time.min == 0
        tmp_time = Time.local(tmp_time.year, tmp_time.month+1, tmp_time.day, 0, 0, 0)
        end_time_str = tmp_time.to_s
      end
    end
    
    start_time = Time.parse(start_time_str) if start_time_str
    end_time   = Time.parse(end_time_str) if end_time_str
    
    # Today
    right_now = Time.new
    zero_hour = right_now.to_i - right_now.to_i % ONE_DAY_IN_SECONDS
    midnight  = zero_hour + ONE_DAY_IN_SECONDS
    
    start_time ||= Time.at( zero_hour )
    end_time   ||= Time.at( midnight )
    
    # Now convert to the desired API format
    start_time = start_time.utc.xmlschema
    end_time   = end_time.utc.xmlschema
    
    service = Service.new
    service.authenticate(@username, @password)
    
    calendars = Calendar.find(service, 
                             @calendar_name,
                             {:scope => :first})
    
    if calendars and calendars.length > 0
      calendar = calendars[0]
    
      events = Event.find(service, "",
          { 'start-min' => start_time,
            'start-max' => end_time, 
            'max-results' => 10000,
            :calendar => calendar.id }
      )
    
      events.sort! { |a,b| a.start_time <=> b.start_time } 
      return events
    end
    nil
  end

  def print_summary(events)
    total_elapsed = 0
    total_day     = 0
    total_perday  = 0
    prev_date = Time.at(events[0].start_time)
    puts "#{prev_date}"
    events.each do |e|
      this_date = Time.at(e.start_time)
      end_date  = Time.at(e.end_time)
      if prev_date.day != this_date.day
        puts "#{total_day} hours\n\n#{this_date.strftime(DAY_FORMAT)}"
        total_perday += total_day
        total_day = 0
      end
  
      elapsed = (e.end_time - e.start_time) / ONE_HOUR_IN_SECONDS # time in hours
      total_elapsed += elapsed
      total_day     += elapsed
  
      puts "#{this_date.strftime(TIME_FORMAT)} to #{end_date.strftime(TIME_FORMAT)} = #{elapsed}h \t(#{formatted_hours(elapsed)})" 
  
      prev_date = Time.at(e.start_time)
    end
    puts "#{prev_date.strftime(DAY_FORMAT)}: #{total_day} hours\n\n"
    total_perday += total_day
    total_day = 0
  
    puts "Total hours: #{total_elapsed}  \t(#{formatted_hours(total_elapsed)}) cross_check=(#{total_perday})"
  end

  def run
    parse_cmd_line_args
    handle_password
    events = fetch_events(@start_time_str, @end_time_str)
    print_summary(events) if events
  end
end

HSGetHours.new.run
