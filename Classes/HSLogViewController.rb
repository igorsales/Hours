####################################
#
#  HSLogViewController.rb
#
#  Author: Igor Sales.
#  Copyright (c) 2011 Igor Sales. All rights reserved.
#

class Time
    def round(minutes)
        Time.at( (to_f / (minutes*60)).round * (minutes*60) )
    end

    def floor(minutes)
        Time.at( (to_f / (minutes*60)).floor * (minutes*60) )
    end
    
    def round_to_nearest(minutes)
        if (min.to_f / minutes).modulo(1) < 0.5
            floor(minutes)
        else
            round(minutes)
        end
    end
end

class HSLogViewController < NSWindowController
    
    STOP_BUTTON_IMAGE     = 'stop_green_button.png'
    RECORD_BUTTON_IMAGE   = 'record_button.png'
    MINUTE_ROUND          = 15
    UPDATE_TIMER_INTERVAL = 60 #5*60
    TIME_FORMAT           = '%H:%M'
    
    attr_accessor :playStopImageView, :calendarsController, :locationsController, :calendarsPopup, :locationsPopup
    attr_accessor :statusBarController
    attr_accessor :logTextView
    
    attr_accessor :log
    attr_accessor :recording
    attr_accessor :startTime
    attr_accessor :endTime
    attr_accessor :selectedCalendarIndex
    attr_accessor :selectedLocationIndex
    attr_accessor :startTimeHHMM
    attr_accessor :endTimeHHMM
    attr_accessor :durationHHMM

    attr_accessor :needsUpdate
    alias :needsUpdate? :needsUpdate

    alias :recording? :recording
    
    def self.keyPathsForValuesAffectingValueForKey(key)
        keyPaths = super(key)
    
        return keyPaths.setByAddingObjectsFromArray(['startTime']) if key == "startTimeHHMM"
        return keyPaths.setByAddingObjectsFromArray(['endTime']) if key == "endTimeHHMM"
        return keyPaths.setByAddingObjectsFromArray(['startTime', 'endTime']) if key == "durationHHMM"
    end

    def startTimeHHMM
        startTime.strftime(TIME_FORMAT) if startTime
    end
    
    def endTimeHHMM
        endTime.strftime(TIME_FORMAT) if endTime
    end
    
    def durationHHMM
        return nil if startTime.nil? || endTime.nil?
        
        duration = endTime - startTime
        
        duration /= 60 # Get rid of seconds
        minutes   = duration.modulo(60)
        duration /= 60 # Get rid of minutes
        hours     = duration.modulo(60)

        ('%02d' % hours) + ':' + ('%02d' % minutes)
    end

    def requestQueue
        @requestQueue ||= HSRequestQueue.new
    end
    
    def selectedCalendarIndex=(index)
        @oldSelectedCalendarIndex = @selectedCalendarIndex if @selectedCalendarIndex
        
        if @selectedCalendarIndex.nil? or @selectedCalendarIndex != index
            willChangeValueForKey(:selectedCalendarIndex)
            @selectedCalendarIndex = index
            didChangeValueForKey(:selectedCalendarIndex)
        end
    end

    def selectedLocationIndex=(index)
        @oldSelectedLocationIndex = @selectedLocationIndex if @selectedLocationIndex
        
        if @selectedLocationIndex.nil? or @selectedLocationIndex != index
            willChangeValueForKey(:selectedLocationIndex)
            @selectedLocationIndex = index
            didChangeValueForKey(:selectedLocationIndex)
        end
    end

    def init
        if initWithWindowNibName('HSLogViewController')
            self.recording = false
            @selectedCalendarIndex = NSNumber.numberWithInteger(0)
            @selectedLocationIndex = NSNumber.numberWithInteger(0)
        end

        self
    end

    def windowDidLoad
        window.setStyleMask(NSBorderlessWindowMask)
        window.alphaValue = 0.95
        window.backgroundColor = NSColor.clearColor
        window.opaque = false
        window.collectionBehavior = NSWindowCollectionBehaviorCanJoinAllSpaces
        window.level = NSStatusWindowLevel
    end

    def selectedCalendar
        calendars = @calendarsController.allCalendars
        calendars[selectedCalendarIndex.integerValue] if selectedCalendarIndex.integerValue < calendars.length
    end
    
    def selectedLocation
        locations = @locationsController.allLocations
        locations[selectedLocationIndex.integerValue] if selectedLocationIndex.integerValue < locations.length
    end

    def chooseNewCalendar(sender)
        calendars = @calendarsController.allCalendars
        if selectedCalendarIndex && calendars && (calendars.count == 0 || selectedCalendarIndex.integerValue == calendars.count) # Prompt user for new calendar
            @calendarsController.presentWindowToAddCalendar(sender)
            @selectedCalendarIndex = @oldSelectedCalendarIndex
            window.orderOut(sender)
        elsif @selectedCalendarIndex.integerValue < calendars.count
            # User changed the calendar, so wipe out the previous data
            # As long as it was not to edit calendars
            @log = nil
        end
    end

    def chooseNewLocation(sender)
        locations = @locationsController.allLocations
        if selectedLocationIndex && locations && (locations.count == 0 || selectedLocationIndex.integerValue == locations.count) # Prompt user for new location
            @locationsController.presentWindowToAddLocation(sender)
            @selectedLocationIndex = @oldSelectedLocationIndex
            window.orderOut(sender)
        end
    end

    def playStopButtonClicked(sender)
        if recording?
            statusBarController.active = false
            stopRecording
        else
            statusBarController.active = true
            startRecording
        end
    end

    def startRecording
        @recording = true
        @playStopImageView.image = NSImage.imageNamed(STOP_BUTTON_IMAGE)
        @calendarsPopup.enabled = false
        @locationsPopup.enabled = false

        self.startTime = Time.new.round_to_nearest(MINUTE_ROUND)
        self.endTime   = Time.at(startTime+MINUTE_ROUND*60).round(MINUTE_ROUND)
        
        # Start update timer
        @durationTimer = NSTimer.scheduledTimerWithTimeInterval(UPDATE_TIMER_INTERVAL, target: self, selector: "durationTimerFired:", userInfo: nil, repeats:true)
    end
    
    def stopRecording
        @calendarsPopup.enabled = true
        @locationsPopup.enabled = true
        @playStopImageView.image = NSImage.imageNamed(RECORD_BUTTON_IMAGE)
        @recording = false
        
        @durationTimer.invalidate
        @durationTimer = nil
        
        updateEvent
        
        self.startTime = nil
        self.endTime   = nil
    end
    
    def durationTimerFired(timer)
        newEndTime   = Time.new.round_to_nearest(MINUTE_ROUND)
        if endTime < newEndTime
            self.needsUpdate  = true
            self.endTime = newEndTime
        end

        updateEvent if needsUpdate?
        
        self.needsUpdate = false
    end
    
    def subject
        s = NSUserDefaults.standardUserDefaults.stringForKey(:mySubject)
        s ||= ''
    end
    
    def calendarName
        selectedCalendar[:name]
    end
    
    def locationName
        selectedLocation[:name]
    end
    
    def calendarUsername
        selectedCalendar[:username]
    end
    
    def calendarPassword
        HSCalendarPasswordController.passwordForUsername(calendarUsername)
    end
    
    def content
        content = log.string if log
        content ||= ''
    end
    
    def updateEvent

        data = { :calendar_name => calendarName,
                 :username      => calendarUsername,
                 :password      => calendarPassword,
                 :start_time    => Time.at( startTime.to_f ), # Ensure we make a copy
                 :end_time      => Time.at( endTime.to_f ),   # So we don't mess with any of these objects again.
                 :subject       => subject,
                 :location      => locationName,
                 :text          => content }
        
        requestQueue.queueCalendarUpdate(data)
        
        self.needsUpdate = false
    end
    
    #
    # NSWindowController overrides
    #
    def showWindow(sender)
        super(sender)
        window.makeFirstResponder(@logTextView)
    end
    
    #
    # NSTextViewDelegate protocol
    #
    def textDidChange(aNotification)
        if !recording
            startRecording
        end
        
        self.needsUpdate = true
    end
    
    #
    # NSWindowDelegate protocol
    #
    def windowDidResignKey(notification)
        window.orderOut(self)
    end
end