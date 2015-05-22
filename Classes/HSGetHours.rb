#!/usr/bin/ruby

####################################
#
#  HSGetHours.rb
#
#  Author: Igor Sales.
#  Copyright (c) 2011 Igor Sales. All rights reserved.
#

require 'rubygems'
require 'digest/sha1'
require 'optparse'
require 'google/api_client'
require 'google/api_client/auth/file_storage'
require 'google/api_client/auth/installed_app'
require 'json'

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
    opts = OptionParser.new do |opts|
      opts.banner = "Usage: get_hours.rb [options]"
  
      opts.on("-u", "--username USERNAME", "Username:") do |v|
        options[:username] = v
      end
      opts.on("-c", "--calendar CALENDAR", "Calendar name") do |v|
        options[:calendar] = v
      end
      opts.on("-x", "--comments", "Print comments instead of hours") do |v|
        options[:comments] = true
      end

      opts.on("-h", "--help", "Display this cruft") do  |v|
        puts opts
        exit
      end
    end
    opts.parse!

    @start_time_str = ARGV[0]
    @end_time_str   = ARGV[1]

    @username       = options[:username]
    @password       = options[:password]
    @calendar_name  = options[:calendar]
    @comments_only  = options[:comments]
    
    if @username.nil? or @calendar_name.nil?
      puts opts.help
      puts "\nPlease specify the calendar and the username"
      exit
    end
  end

  def gapi_client
    @gapi_client ||= Google::APIClient.new(
      :application_name => 'Hours Command Line',
      :application_version => '1.0.0'
    )
  end

  def gcal_api
    @gcal_api ||= gapi_client.discovered_api('calendar', 'v3')
  end

  def gapi_secrets
    @gapi_secrets ||= begin
      secrets_file = File.join(hours_storage_dir,"client_secrets.json")
      Google::APIClient::ClientSecrets.load(secrets_file)
    end
  end

  def hours_storage_dir
    @hours_storage_dir ||= begin
      dir = File.join(ENV['HOME'],'.hours')
      Dir.mkdir(dir) unless File.exists?(dir) && File.directory?(dir)
      dir
    end
  end

  def gcal_file_storage
    @gcal_file_storage ||= begin
      store_file = File.join(hours_storage_dir,"#{Digest::SHA1.hexdigest(@username)}-oauth2.json")
      Google::APIClient::FileStorage.new(store_file)
    end
  end

  def gapi_installed_app_flow
    @gapi_installed_app_flow ||= begin
      Google::APIClient::InstalledAppFlow.new(
        :client_id => gapi_secrets.client_id, 
        :client_secret => gapi_secrets.client_secret,
        :scope => ['https://www.googleapis.com/auth/calendar']
      )
    end
  end

  def gapi_authorize
    if gcal_file_storage.authorization
      gapi_client.authorization = gcal_file_storage.authorization
    else
      gapi_client.authorization = gapi_installed_app_flow.authorize(gcal_file_storage)
    end
  end

  def fetch_events(start_time_str, end_time_str)
    if start_time_str and end_time_str.nil?
      tmp_time = Time.parse(start_time_str)
      # Is it the first of the month?
      if tmp_time.day == 1 and tmp_time.hour == 0 and tmp_time.min == 0
        year = tmp_time.year
        month = tmp_time.month+1
        if month == 13
          year = year + 1
          month = 1
        end
        tmp_time = Time.local(year, month, tmp_time.day, 0, 0, 0)
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
    start_time = start_time.xmlschema
    end_time   = end_time.xmlschema

    result = gapi_client.execute(
      :api_method => gcal_api.calendar_list.list
    )

    calendars = JSON.parse(result.data.to_json)['items']
    calendars = calendars.
        select  { |c| c['summary'] == @calendar_name }.
        collect { |c| c['id'] }

    raise "Calendar #{@calendar_name} not found" unless calendars.size > 0

    calendar_id = calendars.first

    result = gapi_client.execute(
      :api_method => gcal_api.events.list, 
      :parameters => {
        'calendarId' => calendar_id, 
        'timeMin' => start_time,
        'timeMax' => end_time,
        'maxResults' => 10000
      }
    )

    result.data.items
  end

  def print_summary(events)
    total_elapsed = 0
    total_day     = 0
    total_perday  = 0
    prev_date = Time.parse(events[0].start.dateTime.to_s)
    puts "#{prev_date.strftime(DAY_FORMAT)}"
    puts ('=' * 80) if @comments_only
    events.each do |e|
      next unless e.start && e.end
      e_start = Time.parse(e.start.dateTime.to_s)
      e_end   = Time.parse(e.end.dateTime.to_s)

      this_date = e_start
      end_date  = e_end
      if prev_date.day != this_date.day
        puts "#{total_day} hours\n\n#{this_date.strftime(DAY_FORMAT)}"
        puts ('=' * 80) if @comments_only
        total_perday += total_day
        total_day = 0
      end
  
      elapsed = (e_end - e_start) / ONE_HOUR_IN_SECONDS # time in hours
      total_elapsed += elapsed
      total_day     += elapsed
  
      if !@comments_only
        puts "#{this_date.strftime(TIME_FORMAT)} to #{end_date.strftime(TIME_FORMAT)} = #{elapsed}h \t(#{formatted_hours(elapsed)})" 
      else
        puts "#{e.description}"
      end
  
      prev_date = Time.at(e_start)
    end
    puts ('=' * 80) if @comments_only
    puts "#{prev_date.strftime(DAY_FORMAT)}: #{total_day} hours\n\n"
    total_perday += total_day
    total_day = 0
  
    puts "Total hours: #{total_elapsed}  \t(#{formatted_hours(total_elapsed)})" # cross_check=(#{total_perday})"
  end

  def run
    parse_cmd_line_args
    gapi_authorize
    events = fetch_events(@start_time_str, @end_time_str)
    if events and events.size > 0
      print_summary(events)
    else
      puts "No events retrieved. Did you forget to specify the dates?"
    end
  end
end

HSGetHours.new.run
