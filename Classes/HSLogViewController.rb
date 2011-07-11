####################################
#
#  HSLogViewController.rb
#
#  Author: Igor Sales.
#  Copyright (c) 2011 Igor Sales. All rights reserved.
#

require 'osx/cocoa'

include OSX

class Time
    def round(minutes)
        Time.at( (self.to_f / (minutes*60)).round * (minutes*60) )
    end

    def floor(minutes)
        Time.at( (self.to_f / (minutes*60)).floor * (minutes*60) )
    end
    
    def round_to_nearest(minutes)
        if (self.min.to_f / minutes).modulo(1) < 0.5
            floor(minutes)
        else
            round(minutes)
        end
    end
end

class HSLogViewController < OSX::NSWindowController
    
    STOP_BUTTON_IMAGE     = 'stop_green_button.png'
    RECORD_BUTTON_IMAGE   = 'record_button.png'
    MINUTE_ROUND          = 15
    UPDATE_TIMER_INTERVAL = 5*60
    TIME_FORMAT           = '%H:%M'
    
    ib_outlets :playStopImageView, :calendarsController, :locationsController, :calendarsPopup, :locationsPopup
    ib_action  :statusBarImageClicked
    ib_action  :playStopButtonClicked
    ib_action  :chooseNewCalendar
    ib_action  :chooseNewLocation
    
    kvc_accessor :log
    kvc_accessor :recording
    kvc_accessor :startTime
    kvc_accessor :endTime
    kvc_accessor :selectedCalendarIndex
    kvc_accessor :selectedLocationIndex

    alias :recording? :recording
    
    kvc_depends_on([:startTime],           :startTimeHHMM)
    kvc_depends_on([:endTime],             :endTimeHHMM)
    kvc_depends_on([:startTime, :endTime], :durationHHMM)
    
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
            @recording = false
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
            self.selectedCalendarIndex = @oldSelectedCalendarIndex
            window.orderOut(sender)
        elsif @selectedCalendarIndex.integerValue < calendars.count
            # User changed the calendar, so wipe out the previous data
            # As long as it was not to edit calendars
            self.log = nil
        end
    end

    def chooseNewLocation(sender)
        locations = @locationsController.allLocations
        if selectedLocationIndex && locations && (locations.count == 0 || selectedLocationIndex.integerValue == locations.count) # Prompt user for new location
            @locationsController.presentWindowToAddLocation(sender)
            self.selectedLocationIndex = @oldSelectedLocationIndex
            window.orderOut(sender)
        end
    end

    def playStopButtonClicked(sender)
        if recording?
            stopRecording
        else
            startRecording
        end
    end

    def startRecording
        self.recording = true
        @playStopImageView.image = NSImage.imageNamed(STOP_BUTTON_IMAGE)
        @calendarsPopup.enabled = false
        @locationsPopup.enabled = false

        self.startTime = Time.new.round_to_nearest(MINUTE_ROUND)
        self.endTime   = Time.at(startTime+MINUTE_ROUND*60).round(MINUTE_ROUND)
        
        # Start update timer
        @durationTimer = NSTimer.scheduledTimerWithTimeInterval_target_selector_userInfo_repeats(UPDATE_TIMER_INTERVAL,self,:durationTimerFired,nil,true)
    end
    
    def stopRecording
        @calendarsPopup.enabled = true
        @locationsPopup.enabled = true
        @playStopImageView.image = NSImage.imageNamed(RECORD_BUTTON_IMAGE)
        self.recording = false
        
        @durationTimer.invalidate
        @durationTimer = nil
        
        updateEvent
    end
    
    def durationTimerFired(timer)
        self.endTime = Time.new.round_to_nearest(MINUTE_ROUND)
        updateEvent
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
        content = self.log.string if self.log
        content ||= ''
    end
    
    def updateEvent

        HSGCalController.updateGCal(
                                    { :calendar_name => self.calendarName,
                                      :username      => self.calendarUsername,
                                      :password      => self.calendarPassword,
                                      :start_time    => self.startTime,
                                      :end_time      => self.endTime,
                                      :subject       => self.subject,
                                      :location      => self.locationName,
                                      :text          => self.content })
    end
    
    #
    # NSTextViewDelegate protocol
    #
    def textDidChange(aNotification)
        if !recording
            startRecording
        end
    end
end