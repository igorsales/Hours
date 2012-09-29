####################################
#
#  HSRequestQueue.rb
#
#  Author: Igor Sales.
#  Copyright (c) 2011 Igor Sales. All rights reserved.
#

require 'digest/sha1'

class HSRequestQueue < NSObject
    UPDATE_QUEUE_TIMEOUT = 5*60

    def init
        if super
            @updateTimer = NSTimer.scheduledTimerWithTimeInterval_target_selector_userInfo_repeats_(UPDATE_QUEUE_TIMEOUT, self, :updateTimerFired, nil, true)
        end
        
        self
    end

    def queue
        @queue ||= {}
    end
    
    def keyFromData(data)
        Digest::SHA1.hexdigest("#{data[:calendar_name]}-#{data[:start_time].utc.xmlschema}-#{data[:location]}")
    end
    
    def serializeQueueToUserDefaults
        defaults = NSUserDefaults.standardUserDefaults
        defaults.setValue(queue, forKey: :myUpdateQueue)
        defaults.synchronize
    end
    
    def updateTimerFired(timer)
        queue.each do |key, data|
            username = data[:username]
            password = HSCalendarPasswordController.passwordForUsername(username) if username
            if username and password
                eventData = data.dup
                eventData[:password] = password
                updateEventWithData(eventData)
            end
        end
        
        serializeQueueToUserDefaults
    end
    
    def updateEventWithData(data)
        HSGCalController.updateGCal(data) do |result|
            queue.delete(keyFromData(data)) if result
        end
    end

    def queueCalendarUpdate(data)
        storedData = data.dup
        storedData.delete(:password)
        
        queue[keyFromData(data)] = storedData
        serializeQueueToUserDefaults

        updateEventWithData(data) # Force an update immediately
    end
end
