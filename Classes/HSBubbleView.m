//
//  HSBubbleView.m
//  Hours
//
//  Created by Igor Sales on 2012-09-26.
//  Copyright (c) 2012 igorsales.ca. All rights reserved.
//

#import "HSBubbleView.h"

const static CGFloat ARROW_HEIGHT = 20;
const static CGFloat RADIUS       = 6;
const static CGFloat LINE_WIDTH   = 1;
const static CGFloat PAD          = LINE_WIDTH/2;


@implementation HSBubbleView

- (BOOL)isFlipped
{
    return NO;
}

- (void)drawRect:(CGRect)dirtyRect
{
    NSGraphicsContext* ctx = [NSGraphicsContext currentContext];

    [ctx saveGraphicsState];

    CGContextRef context = [ctx graphicsPort];

    [self drawBackgroundWithContext:context andSize:self.frame.size];

    [ctx restoreGraphicsState];
}

- (CGGradientRef)backgroundGradientForHeight:(CGFloat)rectHeight
{
    if (_rectHeight != _rectHeight && _backgroundGradient) {
        _backgroundGradient = nil;
        _rectHeight = rectHeight;
    }

    if (_backgroundGradient) {
        return _backgroundGradient;
    }

    CGColorSpaceRef cs = CGColorSpaceCreateDeviceRGB();
    CGColorRef colour1 = CGColorCreateGenericRGB( 224.0/255, 224.0/255, 224.0/255, 1.0); // #eee
    CGColorRef colour2 = CGColorCreateGenericRGB( 21.0/255,  29.0/255,  49.0/255, 1.0); // #151d31
    
    CGFloat locations[] = {  0.0, (ARROW_HEIGHT * 3 / rectHeight) };
    _backgroundGradient = CGGradientCreateWithColors(cs, (CFArrayRef)@[(id)colour1, (id)colour2], locations);

    return _backgroundGradient;
}

- (CGPathRef)bubblePathWithWidth:(CGFloat)rectWidth height:(CGFloat)rectHeight tip:(CGFloat)bubbleTipX
{
    CGFloat x_left     = PAD;
    CGFloat y_top      = rectHeight - PAD;
    CGFloat y_top_line = rectHeight - ARROW_HEIGHT - PAD;
    CGFloat x_right    = rectWidth - PAD;
    CGFloat y_bottom   = PAD;

    if (bubbleTipX < ARROW_HEIGHT) {
        bubbleTipX = ARROW_HEIGHT;
    }
    
    if (bubbleTipX > (rectWidth-ARROW_HEIGHT)) {
        bubbleTipX = (rectWidth-ARROW_HEIGHT);
    }

    if (rectWidth < 2*ARROW_HEIGHT) {
        bubbleTipX = rectWidth/2;
    }

    CGMutablePathRef path = CGPathCreateMutable();

    CGPathMoveToPoint(path, nil, x_left + RADIUS, y_top_line);

    //     /\
    // ___/  \___
    CGPathAddLineToPoint(path, nil, bubbleTipX - (ARROW_HEIGHT + PAD), y_top_line);
    CGPathAddLineToPoint(path, nil, bubbleTipX,                        y_top);
    CGPathAddLineToPoint(path, nil, bubbleTipX + (ARROW_HEIGHT + PAD), y_top_line);

    // ---+
    //    |
    CGPathAddLineToPoint(path, nil, x_right - RADIUS, y_top_line);
    CGPathAddArcToPoint(path,  nil, x_right,          y_top_line, x_right, y_top_line - RADIUS, RADIUS);

    //    |
    // ---+
    CGPathAddLineToPoint(path, nil, x_right, y_bottom + RADIUS);
    CGPathAddArcToPoint(path,  nil, x_right, y_bottom, x_right - RADIUS, y_bottom, RADIUS);

    // |
    // +---
    CGPathAddLineToPoint(path, nil, x_left + RADIUS, y_bottom);
    CGPathAddArcToPoint(path, nil,  x_left,          y_bottom, x_left, y_bottom + RADIUS, RADIUS);

    // +---
    // |
    CGPathAddLineToPoint(path, nil, x_left, y_top_line - RADIUS);
    CGPathAddArcToPoint(path, nil,  x_left, y_top_line, x_left + RADIUS, y_top_line, RADIUS);

    return path;
}

- (void)drawBackgroundWithContext:(CGContextRef)context andSize:(CGSize)size
{
    CGContextSetLineWidth(context, LINE_WIDTH);
    CGContextSetLineJoin(context, kCGLineJoinMiter);

    CGPathRef path = [self bubblePathWithWidth:size.width height:size.height tip:size.width/2];
    CGContextAddPath(context, path);
    CGContextSaveGState(context);
    CGContextClip(context);

    CGContextDrawLinearGradient(context,
                                [self backgroundGradientForHeight:size.height],
                                CGPointMake(size.width/2, size.height), CGPointMake(size.width/2, 0), 0);
    CGContextRestoreGState(context);

    CGContextAddPath(context, path);
    CGContextDrawPath(context, kCGPathStroke);
}


@end
