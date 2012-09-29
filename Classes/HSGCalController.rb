####################################
#
#  HSGCalController.rb
#
#  Author: Igor Sales.
#  Copyright (c) 2011 Igor Sales. All rights reserved.
#

ENV['GEM_PATH']=File.expand_path(File.join(File.dirname(__FILE__),'gems'))

require 'rubygems'
require 'gcal4ruby'

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
    
    def eventsBetweenStartTime(start, endTime: endt)
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
        event.attendees  = []
        event.save
    end
    
    def newEventWithData(data)
        event = Event.new(service, {:calendar => self.calendar})
        updateEvent(event, data) if event
    end
end

class HSGCalController

    def self.mainThreadCallback(data)
        result    = data[:result]
        block     = data[:block]
    
        block.call(result)
    end

    def self.calendars(data, &delegate_block)
        agent = HSGCalAgent.new
        agent.username      = data[:username]
        agent.password      = data[:password]
        
        Thread.start do 
            calendars = agent.calendars
            self.performSelectorOnMainThread('mainThreadCallback:', 
                                             withObject: { :result => calendars,
                                             :block  => delegate_block }, waitUntilDone: false) if block_given?
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
                
                self.performSelectorOnMainThread('mainThreadCallback:', 
                                                 withObject: { :result => false, :block  => delegate_block },
                                                 waitUntilDone: false) if block_given?

                return
            end

            events = agent.eventsBetweenStartTime(data[:start_time], endTime: data[:start_time] + 60)

            result = false
            if events.nil? or events.length == 0 or events[0].start_time != data[:start_time]
                result = agent.newEventWithData(data)
                
                NSLog('Cannot create event') if !result
            else
                result = agent.updateEvent(events[0], data)
                
                NSLog('Cannot update event') if !result
            end
            
            self.performSelectorOnMainThread('mainThreadCallback:',
                                             withObject: { :result => result, :block  => delegate_block },
                                             waitUntilDone: false) if block_given?
        end
    end
end