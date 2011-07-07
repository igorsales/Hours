//
//  HSStringArrayForPopupMenuTransformer.h
//  Hours
//
//  Created by Igor Sales on 11-07-04.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

// NOTE: This class has to be in Objective-C because the runtime environment won't recognize NSValueTransformer subclasses
//       in Ruby. Don't know why.

@interface HSStringArrayForPopupMenuTransformer : NSValueTransformer {
@private
    NSString* emptyString;
    NSString* lastString;
}

@property (nonatomic, copy) NSString* emptyString;
@property (nonatomic, copy) NSString* lastString;

@end
