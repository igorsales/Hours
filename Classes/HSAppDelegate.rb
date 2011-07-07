####################################
#
#  HSAppDelegate.rb
#
#  Author: Igor Sales.
#  Copyright (c) 2011 Igor Sales. All rights reserved.
#

require 'osx/cocoa'

include OSX

class HSAppDelegate < OSX::NSObject
    
    def initialize
        xformer1 = HSStringArrayForPopupMenuTransformer.new
        xformer1.emptyString = '---'
        xformer1.lastString = 'Edit calendars...'
        
        xformer2 = HSStringArrayForPopupMenuTransformer.new
        xformer2.emptyString = '---'
        xformer2.lastString = 'Edit locations...'
        
        NSValueTransformer.setValueTransformer_forName(xformer1, "HSCalendarArrayStrings")
        NSValueTransformer.setValueTransformer_forName(xformer2, "HSLocationArrayStrings")
    end
end