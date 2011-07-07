####################################
#
#  HSCalendarsController.rb
#
#  Author: Igor Sales.
#  Copyright (c) 2011 Igor Sales. All rights reserved.
#

require 'osx/cocoa'

include OSX

class HSCalendarsController < OSX::NSWindowController

    ib_outlets :arrayController, :popupButton
    
    ib_action :add
    ib_action :done
    
    ib_action :presentWindowToAddCalendar
    ib_action :chooseNewCalendar
    
    attr_accessor :calendarName
    attr_accessor :calendarURL
    attr_accessor :calendarUsername
    attr_accessor :calendarPassword
    attr_accessor :selectedCalendarIndex
    attr_accessor :errorMessage
    
    def init
        initWithWindowNibName('HSCalendarsController')
    end
    
    def awakeFromNib
        # Force the window to be loaded when the object is de-serialized in the main NIB.
        if !isWindowLoaded
            window
        end
    end
    
    def allCalendars
        return @arrayController.arrangedObjects if @arrayController
    end
    
    def urlFromPasteboardIfApplicable
        urlString = NSPasteboard.generalPasteboard.stringForType(NSStringPboardType)
        return if urlString.nil? or !/^http:\/\//.match(urlString)
        
        urlString
    end
    
    def presentWindowToAddCalendar(sender)
        urlString = urlFromPasteboardIfApplicable
        if urlString
            willChangeValueForKey(:calendarURL)
            self.calendarURL = urlString
            didChangeValueForKey(:calendarURL)
        end
        
        showWindow(sender)
        
        willChangeValueForKey(:selectedCalendarIndex)
        self.selectedCalendarIndex = 0
        didChangeValueForKey(:selectedCalendarIndex)
    end
    
    def error(e)
        willChangeValueForKey(:errorMessage)
        self.errorMessage = e
        didChangeValueForKey(:errorMessage)
    end
    
    def validateForm
        ok = false

        if self.calendarName.nil?
            error('Calendar name cannot be empty')
        elsif self.calendarURL.nil?
            error('Calendar URL cannot be empty')
        elsif self.calendarUsername.nil?
            error('Username cannot be empty')
        elsif self.calendarPassword.nil?
            error('Password cannot be empty')
        else
            error('')
            ok = true
        end
        
        ok
    end
    
    def add(sender)
        validateForm or return

        newEntry = { :name => calendarName, :url => calendarURL, :username => calendarUsername }
        
        cals = allCalendars
        if cals.nil?
            cals = [ newEntry ]
        else
            cals = cals + [ newEntry ]
        end

        defaults = NSUserDefaults.standardUserDefaults
        defaults.setObject_forKey(cals, :myCalendars)
        defaults.synchronize
        
        HSCalendarPasswordController.setPassword_forCalendar_username(self.calendarPassword, self.calendarName, self.calendarUsername)
        
        willChangeValueForKey(:selectedCalendarIndex)
        self.selectedCalendarIndex = cals.count-1
        didChangeValueForKey(:selectedCalendarIndex)
        
        window.orderOut(sender)
    end

    def done(sender)
        window.orderOut(sender)
    end

    def chooseNewCalendar(sender)
        calendars = allCalendars
        if selectedCalendarIndex && calendars && (calendars.count == 0 || selectedCalendarIndex == calendars.count) # Prompt user for new location
            presentWindowToAddCalendar(sender)
        end
    end
end