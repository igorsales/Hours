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
    
    STOP_BUTTON_IMAGE   = 'stop_green_button.png'
    RECORD_BUTTON_IMAGE = 'record_button.png'
    MINUTE_ROUND        = 15
    TIME_FORMAT         = '%H:%M'
    
    ib_outlets :playStopImageView
    ib_action  :statusBarImageClicked
    ib_action  :playStopButtonClicked
    
    attr_accessor :log
    attr_accessor :recording
    attr_accessor :startTime
    attr_accessor :endTime
    
    def startTimeHHMM
        self.startTime.strftime(TIME_FORMAT) if self.startTime
    end
    
    def endTimeHHMM
        self.endTime.strftime(TIME_FORMAT) if self.endTime
    end
    
    def durationHHMM
        return nil if self.startTime.nil? || self.endTime.nil?
        
        duration = self.endTime - self.startTime
        
        duration /= 60 # Get rid of seconds
        minutes   = duration.modulo(60)
        duration /= 60 # Get rid of minutes
        hours     = duration.modulo(60)

        ('%02d' % hours) + ':' + ('%02d' % minutes)
    end

    def init
        @recording = false
        initWithWindowNibName('HSLogViewController')
    end

    def windowDidLoad
        window.setStyleMask(NSBorderlessWindowMask)
        window.alphaValue = 0.95
        window.backgroundColor = NSColor.clearColor
        window.opaque = false
        window.collectionBehavior = NSWindowCollectionBehaviorCanJoinAllSpaces
        window.level = NSStatusWindowLevel
    end

    def playStopButtonClicked(sender)
        if recording
            stopRecording
        else
            startRecording
        end
    end
    
    # It looks like RubyCocoa classes are not fully KVO compliant
    def notifyOfTimeFieldUpdates(updateStart = false)
        willChangeValueForKey(:startTimeHHMM) if updateStart
        didChangeValueForKey(:startTimeHHMM)  if updateStart
        willChangeValueForKey(:endTimeHHMM)
        didChangeValueForKey(:endTimeHHMM)
        willChangeValueForKey(:durationHHMM)
        didChangeValueForKey(:durationHHMM)
    end
    
    def startRecording
        self.recording = true
        @playStopImageView.image = NSImage.imageNamed(STOP_BUTTON_IMAGE)

        self.startTime = Time.new.round_to_nearest(MINUTE_ROUND)
        self.endTime   = Time.at(self.startTime+MINUTE_ROUND*60).round(MINUTE_ROUND)
        
        notifyOfTimeFieldUpdates(true)
        
        # Start update timer
        @durationTimer = NSTimer.scheduledTimerWithTimeInterval_target_selector_userInfo_repeats(15*60,self,:durationTimerFired,nil,true)
    end
    
    def stopRecording
        @playStopImageView.image = NSImage.imageNamed(RECORD_BUTTON_IMAGE)
        self.recording = false
        
        @durationTimer.invalidate
        @durationTimer = nil
    end
    
    def durationTimerFired(timer)
        self.endTime = Time.new.round_to_nearest(MINUTE_ROUND)
        
        notifyOfTimeFieldUpdates
    end
end