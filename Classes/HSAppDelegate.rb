####################################
#
#  HSAppDelegate.rb
#
#  Author: Igor Sales.
#  Copyright (c) 2011 Igor Sales. All rights reserved.
#

class HSAppDelegate < NSObject
    
    def init
        if super
            xformer1 = HSStringArrayForPopupMenuTransformer.new
            xformer1.emptyString = '---'
            xformer1.lastString = 'Edit calendars...'
            
            xformer2 = HSStringArrayForPopupMenuTransformer.new
            xformer2.emptyString = '---'
            xformer2.lastString = 'Edit locations...'
            
            NSValueTransformer.setValueTransformer(xformer1, forName:"HSCalendarArrayStrings")
            NSValueTransformer.setValueTransformer(xformer2, forName:"HSLocationArrayStrings")
        end
        
        self
    end
end