//
//  main.m
//  Hours
//
//  Created by Igor Sales on 11-07-02.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <RubyCocoa/RubyCocoa.h>

int main(int argc, const char *argv[])
{
    // RubyCocoa
    //return RBApplicationMain("main.rb", argc, argv);
    
    // MacRuby
    return macruby_main("main.rb", argc, argv);
}
