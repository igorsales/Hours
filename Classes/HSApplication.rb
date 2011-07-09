####################################
#
#  HSAppDelegate.rb
#
#  Author: Igor Sales.
#  Copyright (c) 2011 Igor Sales. All rights reserved.
#

require 'osx/cocoa'

include OSX

class HSApplication < OSX::NSApplication
    def sendEvent(event)
        if event.oc_type == NSKeyDown and
           event.modifierFlags & NSDeviceIndependentModifierFlagsMask == NSCommandKeyMask
            
            return if event.charactersIgnoringModifiers.isEqualToString:"x" and sendAction_to_from('cut:',       nil, self)
            return if event.charactersIgnoringModifiers.isEqualToString:"c" and sendAction_to_from('copy:',      nil, self)
            return if event.charactersIgnoringModifiers.isEqualToString:"v" and sendAction_to_from('paste:',     nil, self)
            return if event.charactersIgnoringModifiers.isEqualToString:"z" and sendAction_to_from('undo:',      nil, self)
            return if event.charactersIgnoringModifiers.isEqualToString:"a" and sendAction_to_from('selectAll:', nil, self)
        end
            
        super_sendEvent(event)
    end
end