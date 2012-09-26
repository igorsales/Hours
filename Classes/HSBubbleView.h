//
//  HSBubbleView.h
//  Hours
//
//  Created by Igor Sales on 2012-09-26.
//  Copyright (c) 2012 igorsales.ca. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Quartz/Quartz.h>

@interface HSBubbleView : NSView {
    CGFloat _rectHeight;
    CGGradientRef _backgroundGradient;
}

- (void)drawBackgroundWithContext:(CGContextRef)context andSize:(CGSize)size;

@end
