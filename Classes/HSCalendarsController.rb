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

    ib_outlets :accountsArrayController
    ib_outlets :calendarsArrayController
    ib_outlets :addButton
    
    ib_action :removeAccount
    ib_action :done
    
    ib_action :presentWindowToAddCalendar
    
    kvc_accessor :username
    kvc_accessor :password
    kvc_accessor :errorMessage
    kvc_accessor :busy
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
    
    def setUserDefaultsValue_forKey(value,key)        
        defaults = NSUserDefaults.standardUserDefaults
        defaults.setObject_forKey(value, key)
        defaults.synchronize
    end
    
    def allCalendarsByRemovingCalendars(cals)
        removeIds = cals.collect { |c| c[:displayName] }
        cleanCals = allCalendars.select { |c| removeIds.index(c[:displayName]) == nil }
    end
            
    def addCalendars(cals)
        cals = allCalendarsByRemovingCalendars(cals) + cals
        
        setUserDefaultsValue_forKey(cals, :myCalendars)
    end

    def removeCalendars(cals)
        cals = allCalendarsByRemovingCalendars(cals)
        
        setUserDefaultsValue_forKey(cals, :myCalendars)
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
            
            setUserDefaultsValue_forKey(accts, :myAccounts)
            addCalendars(cals)
            
            HSCalendarPasswordController.setPassword_forUsername(password, username)
            self.busy = NSNumber.numberWithBool(false)
        end
    end

    def removeAccount(sender)
        calsToRemove = @accountsArrayController.selectedObjects
        calsToRemove = calsToRemove.collect { |c| c[:calendars] }
        calsToRemove = calsToRemove.flatten

        @accountsArrayController.remove(sender)
        
        accts = @accountsArrayController.arrangedObjects
        setUserDefaultsValue_forKey(accts, :myAccounts)
        
        removeCalendars(calsToRemove)
    end

    def done(sender)
        window.orderOut(sender)
    end    
end