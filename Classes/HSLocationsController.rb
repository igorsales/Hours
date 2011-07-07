####################################
#
#  HSLocationsController.rb
#
#  Author: Igor Sales.
#  Copyright (c) 2011 Igor Sales. All rights reserved.
#

require 'osx/cocoa'

include OSX

class HSLocationsController < OSX::NSWindowController
    
    ib_outlets :arrayController, :popupButton
    
    ib_action :add
    ib_action :cancel
    
    ib_action :presentWindowToAddLocation
    ib_action :chooseNewLocation
    
    attr_accessor :newLocationName
    attr_accessor :selectedLocationIndex

    def selectedLocationIndex=(newIndex)
        @oldSelectedLocationIndex = @selectedLocationIndex if @selectedLocationIndex
        @selectedLocationIndex = newIndex
    end

    def init
        initWithWindowNibName('HSLocationsController')
    end
    
    def awakeFromNib
        @oldSelectedLocationIndex = 0

        if !isWindowLoaded
            window
        end

        if @arrayController
            self.selectedLocationIndex = @arrayController.arrangedObjects.count
        end
    end
    
    def allLocations
        return @arrayController.arrangedObjects if @arrayController
    end

    def presentWindowToAddLocation(sender)
        newIndex = @oldSelectedLocationIndex

        if NSApplication.sharedApplication.runModalForWindow(window) != 0
            newIndex = allLocations.count-1
        end
        
        if newIndex >= allLocations.count
            newIndex = 0
        end
        
        # Looks like Cocoa Bindings are not listening to changes in selectedLocationIndex
        # So we must brute force it by using the control directly
        @popupButton.selectItemAtIndex(newIndex) if @popupButton
    end
    
    def add(sender)
        addLocationNameToUserDefaults
        
        window.orderOut(sender)
        NSApplication.sharedApplication.stopModalWithCode(1)
    end
    
    def cancel(sender)
        window.orderOut(sender)
        NSApplication.sharedApplication.stopModalWithCode(0)
    end

    def addLocationNameToUserDefaults
        locations = allLocations
        newEntry = { :name => @newLocationName }
        if locations.nil?
            locations = [ newEntry ]
        else
            locations += [ newEntry ]
        end
        
        defaults = NSUserDefaults.standardUserDefaults
        defaults.setObject_forKey(locations, :myLocations)
        defaults.synchronize
    end
    
    def chooseNewLocation(sender)
        locations = allLocations
        if selectedLocationIndex && locations && (locations.count == 0 || selectedLocationIndex == locations.count) # Prompt user for new location
            presentWindowToAddLocation(sender)
        end
    end
    
    #
    # NSWindow delegate methods
    #
    def windowWillClose(notification)
        NSApplication.sharedApplication.stopModalWithCode(0)
    end
end