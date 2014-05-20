//
//  VBCAudioSession.h
//  ivbcamp
//
//  Created by Octavian Stirbei on 5/20/14.
//  Copyright (c) 2014 Octavian Stirbei. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>

@interface VBCAudioSession : NSObject

@property (readonly) AudioComponentInstance audioSessionInstance;

+ (VBCAudioSession*)sharedInstance;

- (void)startCapture;
- (void)stopCapture;


@end
