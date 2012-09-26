//
//  HSCalendarPasswordController.h
//  Hours
//
//  Created by Igor Sales on 12-03-14.
//  Copyright (c) 2012 igorsales.ca. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface HSCalendarPasswordController : NSObject {
    
}

+ (NSString*)serviceName;
+ (NSString*)passwordForUsername:(NSString*)username;
+ (void)setPassword:(NSString*)password forUsername:(NSString*)username;

@end
