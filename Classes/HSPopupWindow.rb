####################################
#
#  HSPopupWindow.rb
#
#  Author: Igor Sales.
#  Copyright (c) 2011 Igor Sales. All rights reserved.
#

require 'osx/cocoa'
include OSX

# The purpose of this class is
# Just so we can make the popup borderless window become a first responder
# Otherwise, the text view won't get focus.

class HSPopupWindow < NSWindow
    
    def canBecomeKeyWindow
        true
    end

end