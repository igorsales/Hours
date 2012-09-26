//
//  HSCalendarPasswordController.m
//  Hours
//
//  Created by Igor Sales on 12-03-14.
//  Copyright (c) 2012 igorsales.ca. All rights reserved.
//

#import "HSCalendarPasswordController.h"
#import <Security/Security.h>

#define SERVICE  @"HoursCalendarPassword"


@implementation HSCalendarPasswordController


+ (NSString*)serviceName
{
    return SERVICE;
}

+ (NSString*)passwordForUsername:(NSString*)username
{
    NSString* service = self.serviceName;

    UInt32 passwordLength = 0;
    const char* passwordData = nil;
    SecKeychainFindGenericPassword(nil, (UInt32)service.length, [service UTF8String], 
                                        (UInt32)username.length, [username UTF8String],
                                        &passwordLength, (void**)&passwordData, nil);
    
    NSString* password = nil;
    if (passwordData && passwordLength) {
        // It's possible the buffer is not null terminated, so copy it, use it, and throw it away.
        char *buffer = malloc(passwordLength+1);
        memcpy(buffer, passwordData, passwordLength);
        buffer[passwordLength] = 0;
        password = [NSString stringWithCString:buffer encoding:NSUTF8StringEncoding];
        free(buffer);
        
        SecKeychainItemFreeContent(nil, (void*)passwordData);
    }

    return password;
}

+ (void)setPassword:(NSString*)password forUsername:(NSString*)username
{
    NSString* service = self.serviceName;

    SecKeychainAddGenericPassword(nil, (UInt32)service.length, [service UTF8String], 
                                       (UInt32)username.length, [username UTF8String], 
                                       (UInt32)password.length, [password UTF8String], nil);
}

@end
