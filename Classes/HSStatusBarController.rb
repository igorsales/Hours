####################################
#
#  HSStatusBarController.rb
#
#  Author: Igor Sales.
#  Copyright (c) 2011 Igor Sales. All rights reserved.
#

class HSStatusBarController < NSObject

    TIP_OVER = 4
    
    attr_accessor :statusBarIconView
    attr_accessor :logViewController
    
    attr_accessor :log
    attr_accessor :recording
    attr_accessor :startTime
    attr_accessor :endTime
    
    attr_accessor :active
    attr_accessor :active_image_view
    attr_accessor :inactive_image_view
    
    def awakeFromNib
        @statusBar = NSStatusBar.systemStatusBar

        @statusItem = @statusBar.statusItemWithLength(NSSquareStatusItemLength)
        @statusItem.setView(@statusBarIconView)
        @statusItem.setHighlightMode(true)
        
        self.active = false
    end
    
    def statusBarImageClicked(sender)
        if @logViewController.isWindowLoaded and @logViewController.window.isVisible
            @statusItem.drawStatusBarBackgroundInRect(@statusBarIconView.frame, withHighlight:false)
            @logViewController.window.orderOut(sender)
            @statusBarIconView.needsDisplay = true
        else
            frame          = @statusItem.view.window.frame
            
            centreX        = frame.origin.x + frame.size.width / 2
            
            windowFrame    = @logViewController.window.frame
            frame.origin.x = centreX        - windowFrame.size.width / 2
            frame.origin.y = frame.origin.y - windowFrame.size.height + TIP_OVER
            
            @logViewController.window.setFrameOrigin(frame.origin)
            @logViewController.showWindow(sender)
            
            @statusItem.drawStatusBarBackgroundInRect(@statusBarIconView.frame, withHighlight:true)
            @statusBarIconView.needsDisplay = true
        end
    end
    
    def active=(is_active)
        @active = is_active
        
        active_image_view.hidden = !is_active
        inactive_image_view.hidden = is_active
    end
end