####################################
#
#  HSCalendarsController.rb
#
#  Author: Igor Sales.
#  Copyright (c) 2011 Igor Sales. All rights reserved.
#

class HSCalendarsController < NSWindowController

    attr_accessor :accountsArrayController
    attr_accessor :calendarsArrayController
    attr_accessor :addButton

    attr_accessor :username
    attr_accessor :password
    attr_accessor :errorMessage
    attr_accessor :busy
    alias :busy? :busy
    
    def init
        if initWithWindowNibName('HSCalendarsController')
            @busy = NSNumber.numberWithBool(false)
        end
        
        self
    end
    
    def awakeFromNib
        if !isWindowLoaded
            # Force window to be loaded when it's awaken in the first NIB
            window
        end
    end
    
    def windowDidLoad
        window.collectionBehavior = NSWindowCollectionBehaviorCanJoinAllSpaces
    end
    
    def allCalendars
        @calendarsArrayController.arrangedObjects if @calendarsArrayController
    end
    
    def allAccounts
        @accountsArrayController.arrangedObjects if @accountsArrayController
    end
    
    def presentWindowToAddCalendar(sender)
        showWindow(sender)
    end
    
    def error(e)
        errorMessage = e
    end
    
    def validateForm
        ok = false

        if username.nil?
            error('Username cannot be empty')
        elsif password.nil?
            error('Password cannot be empty')
        else
            error('')
            ok = true
        end
        
        ok
    end
    
    def setUserDefaultsValue(value, forKey: key)        
        defaults = NSUserDefaults.standardUserDefaults
        defaults.setObject(value, forKey:key)
        defaults.synchronize
    end
    
    def allCalendarsByRemovingCalendars(cals)
        removeIds = cals.collect { |c| c[:displayName] }
        cleanCals = allCalendars.select { |c| removeIds.index(c[:displayName]) == nil }
    end
            
    def addCalendars(cals)
        cals = allCalendarsByRemovingCalendars(cals) + cals
        
        setUserDefaultsValue(cals, forKey: :myCalendars)
    end

    def removeCalendars(cals)
        cals = allCalendarsByRemovingCalendars(cals)
        
        setUserDefaultsValue(cals, forKey: :myCalendars)
    end
    
    def addAccount(sender)
        validateForm or return
        
        self.busy = NSNumber.numberWithBool(true)

        HSGCalController.calendars( { :username => username, :password => password } ) do |calendars|
            cals = calendars.collect { |c| { :id => c.id, :name => c.title, :displayName => "#{c.title} (#{username})", :username => username } }
            
            newEntry = { :username => username, :calendars => cals }
            
            accts = allAccounts
            if accts.nil?
                accts = [ newEntry ]
                else
                accts = accts.select { |a| a[:username] != username }
                accts = accts + [ newEntry ]
            end
            
            setUserDefaultsValue(accts, forKey: :myAccounts)
            addCalendars(cals)
            
            HSCalendarPasswordController.setPassword(password, forUsername: username)
            self.busy = NSNumber.numberWithBool(false)
        end
    end

    def removeAccount(sender)
        calsToRemove = @accountsArrayController.selectedObjects
        calsToRemove = calsToRemove.collect { |c| c[:calendars] }
        calsToRemove = calsToRemove.flatten

        @accountsArrayController.remove(sender)
        
        accts = @accountsArrayController.arrangedObjects
        setUserDefaultsValue(accts, forKey: :myAccounts)
        
        removeCalendars(calsToRemove)
    end

    def done(sender)
        window.orderOut(sender)
    end

    #
    # NSWindowDelegate protocol
    #
    def windowDidResignKey(notification)
        window.orderOut(self)
    end
end