//
//  HSStringArrayForPopupMenuTransformer.m
//  Hours
//
//  Created by Igor Sales on 11-07-04.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "HSStringArrayForPopupMenuTransformer.h"

#define kNameKey @"name"

@implementation HSStringArrayForPopupMenuTransformer

@synthesize emptyString;
@synthesize lastString;

- (id)init
{
    self = [super init];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

- (void)dealloc
{
    [super dealloc];
}

- (Class)transformedValueClass { return [NSArray class]; }

- (BOOL)allowsReverseTransformation { return NO; };

- (id)transformedValue:(id)inValue
{
    if(inValue == nil || ![inValue isKindOfClass:[NSArray class]] || [inValue count] == 0) {
        return [NSArray arrayWithObjects:self.emptyString, self.lastString, nil];
    }
    
    NSArray* array = inValue;

    NSMutableArray* newArray = [[NSMutableArray alloc] initWithCapacity:[array count]+1];
    for (id object in array) {
        NSString* name = [object valueForKey:kNameKey];
        if (name == nil || ![name isKindOfClass:[NSString class]]) {
            name = @"???";
        }
        [newArray addObject:name];
    }
    [newArray addObject:self.lastString];
    
    array = [NSArray arrayWithArray:newArray];
    [newArray release];

    return array;
}

@end
