####################################
#
#  HSRequestQueue.rb
#
#  Author: Igor Sales.
#  Copyright (c) 2011 Igor Sales. All rights reserved.
#

require 'osx/cocoa'
require 'digest/sha1'
include OSX

class HSRequestQueue < NSObject
    UPDATE_QUEUE_TIMEOUT = 5*60

    def init
        if super_init
            @updateTimer = NSTimer.scheduledTimerWithTimeInterval_target_selector_userInfo_repeats_(UPDATE_QUEUE_TIMEOUT, self, :updateTimerFired, nil, true)
        end
        
        self
    end

    def queue
        @queue ||= {}
    end
    
    def keyFromData(data)
        Digest::SHA1.hexdigest("#{data[:calendar_name]}-#{data[:start_time]}-#{data[:location]}")
    end
    
    def serializeQueueToUserDefaults
        defaults = NSUserDefaults.standardUserDefaults
        defaults.setValue_forKey(queue, :myUpdateQueue)
        defaults.synchronize
    end
    
    def updateTimerFired(timer)
        queue.each do |key, value|
            updateEventWithData(value)
        end
        
        serializeQueueToUserDefaults
    end
    
    def updateEventWithData(data)
        HSGCalController.updateGCal(data) do |result|
            queue.delete(keyFromData(data)) if result
        end
    end

    def queueCalendarUpdate(data)
        queue[keyFromData(data)] = data
        serializeQueueToUserDefaults

        updateEventWithData(data) # Force an update immediately
    end
end
