####################################
#
#  HSCalendarPasswordController.rb
#
#  Author: Igor Sales.
#  Copyright (c) 2011 Igor Sales. All rights reserved.
#

# As found on http://bjeanes.com/2008/04/10/rubycocoa-and-keychain-access

require 'osx/cocoa'
include OSX
require_framework 'Security'

class HSCalendarPasswordController < OSX::NSObject
    
    SERVICE = 'HoursCalendarPassword'
    
    def self.serviceName
        SERVICE
    end
    
    def self.passwordForUsername(username)
        service = serviceName

        status, *password = SecKeychainFindGenericPassword(nil, service.length, service, username.length, username)
        
        # Password-related data
        password_length = password.shift
        password_data   = password.shift # OSX::ObjcPtr object
        password        = password_data.bytestr(password_length)
    end

    def self.setPassword_forUsername(password, username)
        service = serviceName

        SecKeychainAddGenericPassword(nil, service.length, service, username.length, username, password.length, password.UTF8String, nil)
    end
end
