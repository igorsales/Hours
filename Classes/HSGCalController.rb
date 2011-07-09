####################################
#
#  HSGCalController.rb
#
#  Author: Igor Sales.
#  Copyright (c) 2011 Igor Sales. All rights reserved.
#

require 'osx/cocoa'
require 'rubygems'
require 'gcal4ruby'

include OSX
include GCal4Ruby

class HSGCalAgent
    
    attr_accessor :calendar_name
    attr_accessor :username
    attr_accessor :password
    
    def service
        return @service if @service
        
        @service = Service.new
        @service.authenticate(self.username, self.password)
        
        @service
    end
    
    def calendar
        return @calendar if @calendar
        
        calendars = Calendar.find(self.service, { :title => self.calendar_name, :scope => :first})
        
        @calendar = calendars[0]
    end
    
    def calendars
        cals = Calendar.find(self.service, "", { :editable => true })
        
        # For some reason the filter ':editable => true' above isn't working
        cals.select { |c| c.editable }
    end
    
    def eventsBetweenStartTime_endTime(start,endt)
        start_time = start.utc.xmlschema
        end_time   = endt.utc.xmlschema
        
        events = Event.find(service, "",
                            { :calendar     => calendar.id,
                              'start-min'   => start_time,
                              'start-max'   => end_time,
                              'max-results' => 10000
                            }
                           )
        
        events.sort! { |a,b| a.start_time <=> b.start_time }
    end
    
    def updateEvent(event, data)
        event.start_time = data[:start_time] if data[:start_time]
        event.end_time   = data[:end_time]   if data[:end_time]
        event.title      = data[:subject]    if data[:subject]
        event.where      = data[:location]   if data[:location]
        event.content    = data[:text]       if data[:text]
        event.status     = :confirmed
        event.save
    end
    
    def newEventWithData(data)
        event = Event.new(service, {:calendar => self.calendar})
        updateEvent(event, data) if event
        
        event
    end
end

class HSGCalController < NSObject

    def self.mainThreadCallback(data)
        calendars = data[:result]
        block     = data[:block]
    
        block.call(calendars)
    end
    objc_class_method :mainThreadCallback, %w{id id}

    def self.calendars(data, &delegate_block)
        agent = HSGCalAgent.new
        agent.username      = data[:username]
        agent.password      = data[:password]
        
        Thread.start do 
            calendars = agent.calendars
            self.performSelectorOnMainThread_withObject_waitUntilDone('mainThreadCallback:', 
                { :result => calendars,
                  :block  => delegate_block }, false) if block_given?
        end
    end

    def self.updateGCal(data, &delegate_block)
        raise "Invalid argument (username)"       if data[:username].nil?
        raise "Invalid argument (password)"       if data[:password].nil?
        raise "Invalid argument (calendar_name)"  if data[:calendar_name].nil?
        raise "Invalid argument (start_time)"     if data[:start_time].nil?
        raise "Invalid argument (end_time)"       if data[:end_time].nil?

        Thread.start do
            agent = HSGCalAgent.new
            agent.username      = data[:username]
            agent.password      = data[:password]
            agent.calendar_name = data[:calendar_name]
            
            if agent.calendar.nil?
                NSLog("Cannot retrieve calendar #{agent.calendar_name}")
                return
            end
            
            events = agent.eventsBetweenStartTime_endTime(data[:start_time], data[:start_time] + 60)

            if events.nil? or events.length == 0 or events[0].start_time != data[:start_time]
                agent.newEventWithData(data) or NSLog('Cannot create event')
            else
                agent.updateEvent(events[0], data) or NSLog('Cannot update event')
            end
        end
    end
end