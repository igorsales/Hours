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
    
    kvc_accessor :newLocationName

    def init
        initWithWindowNibName('HSLocationsController')
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
    
    def allLocations
        return @arrayController.arrangedObjects if @arrayController
    end

    def presentWindowToAddLocation(sender)
        showWindow(sender)
    end
    
    def add(sender)
        addLocationNameToUserDefaults
        
        window.orderOut(sender)
    end
    
    def cancel(sender)
        window.orderOut(sender)
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
end