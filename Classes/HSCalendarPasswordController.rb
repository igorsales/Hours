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
    
    SERVICE = 'HoursCalendarPassword-'
    
    def self.serviceNameForCalendar(calendar)
        service = SERVICE + calendar
    end
    
    def self.passwordForCalendar_username(calendar, username)
        service = serviceNameForCalendar(calendar)

        status, *password = SecKeychainFindGenericPassword(nil, service.length, service, username.length, username)
        
        # Password-related data
        password_length = password.shift
        password_data   = password.shift # OSX::ObjcPtr object
        password        = password_data.bytestr(password_length)
        
        keychain_item = password.shift
    end

    def self.setPassword_forCalendar_username(password, calendar, username)
        service = serviceNameForCalendar(calendar)

        SecKeychainAddGenericPassword(nil, service.length, service, username.length, username, password.length, password.UTF8String, nil)
    end
end
