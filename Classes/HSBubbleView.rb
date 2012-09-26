####################################
#
#  HSBubbleView.rb
#
#  Author: Igor Sales.
#  Copyright (c) 2011 Igor Sales. All rights reserved.
#

class HSBubbleView < NSView
    
    ARROW_HEIGHT = 20
    RADIUS       = 6
    LINE_WIDTH   = 1
    PAD          = LINE_WIDTH/2
    
    def isFlipped
        false
    end
    
    def drawRect(dirtyRect)
        ctx = NSGraphicsContext.currentContext
        
        ctx.saveGraphicsState
        
        context = ctx.graphicsPort
        
        drawBackground(context, frame.size.width, frame.size.height)
        
        ctx.restoreGraphicsState
    end
    
    def backgroundGradient(rectHeight)
        if @rectHeight != rectHeight and @backgroundGradient
            @backgroundGradient = nil
            @rectHeight = rectHeight
        end

        return @backgroundGradient if @backgroundGradient
        
        cs = CGColorSpaceCreateDeviceRGB()
        colour1 = CGColorCreate(cs, [224.0/255, 224.0/255, 224.0/255, 1.0]) # #eee
        colour2 = CGColorCreate(cs, [ 21.0/255,  29.0/255,  49.0/255, 1.0]) # #151d31
        @backgroundGradient = CGGradientCreateWithColors(cs, [colour1, colour2], [0.0, ARROW_HEIGHT * 3 / rectHeight])
        
        @backgroundGradient
    end
    
    def bubblePath(rectWidth, rectHeight, bubbleTipX)
        x_left     = PAD
        y_top      = rectHeight - PAD
        y_top_line = rectHeight - ARROW_HEIGHT - PAD
        x_right    = rectWidth - PAD
        y_bottom   = PAD
        
        bubbleTipX = ARROW_HEIGHT if bubbleTipX < ARROW_HEIGHT
        bubbleTipX = (rectWidth-ARROW_HEIGHT) if bubbleTipX > (rectWidth-ARROW_HEIGHT)
        bubbleTipX = rectWidth/2 if rectWidth < 2*ARROW_HEIGHT

        path = CGPathCreateMutable()
        
        CGPathMoveToPoint(path, nil, x_left + RADIUS, y_top_line)
        
        #     /\
        # ___/  \___
        CGPathAddLineToPoint(path, nil, bubbleTipX - (ARROW_HEIGHT + PAD), y_top_line)
        CGPathAddLineToPoint(path, nil, bubbleTipX,                        y_top)
        CGPathAddLineToPoint(path, nil, bubbleTipX + (ARROW_HEIGHT + PAD), y_top_line)
        
        # ---+ 
        #    |
        CGPathAddLineToPoint(path, nil, x_right - RADIUS, y_top_line)
        CGPathAddArcToPoint(path,  nil, x_right,          y_top_line, x_right, y_top_line - RADIUS, RADIUS)
        
        #    |
        # ---+
        CGPathAddLineToPoint(path, nil, x_right, y_bottom + RADIUS)
        CGPathAddArcToPoint(path,  nil, x_right, y_bottom, x_right - RADIUS, y_bottom, RADIUS)
        
        # |
        # +---
        CGPathAddLineToPoint(path, nil, x_left + RADIUS, y_bottom)
        CGPathAddArcToPoint(path, nil,  x_left,          y_bottom, x_left, y_bottom + RADIUS, RADIUS)
        
        # +---
        # |
        CGPathAddLineToPoint(path, nil, x_left, y_top_line - RADIUS)
        CGPathAddArcToPoint(path, nil,  x_left, y_top_line, x_left + RADIUS, y_top_line, RADIUS)
        
        path
    end
    
    def drawBackground(context, rectWidth, rectHeight)
        
        CGContextSetLineWidth(context, LINE_WIDTH)
        CGContextSetLineJoin(context, KCGLineJoinMiter)
        
        path = bubblePath(rectWidth, rectHeight, rectWidth/2)
        CGContextAddPath(context, path)
        CGContextSaveGState(context)
        CGContextClip(context)
        
        CGContextDrawLinearGradient(context, backgroundGradient(rectHeight), CGPoint.new(rectWidth/2, rectHeight), CGPoint.new(rectWidth/2, 0), 0)
        CGContextRestoreGState(context)
        
        CGContextAddPath(context, path)
        CGContextDrawPath(context, KCGPathStroke)
    end

end