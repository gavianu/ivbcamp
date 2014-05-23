//
//  AudioDataProcessor.h
//  ivbcamp
//
//  Created by Octavian Stirbei on 5/20/14.
//  Copyright (c) 2014 Octavian Stirbei. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>

#import "AACELDEncoder.h"
#import "AACELDDecoder.h"


@interface AudioDataProcessor : NSObject {
    AudioBufferList     *rawInputData;
    EncodedAudioBuffer  aacEncodedBuffer;
}

@property (nonatomic, strong) NSMutableArray *audioOutputBuffer;

@property (nonatomic, strong) NSNumber *sendPcksCnt;
@property (nonatomic, strong) NSNumber *lastPckCnt;
@property (nonatomic, strong) NSNumber *dropPckCnt;

+ (AudioDataProcessor*)sharedInstance;
- (void)processRawInputData:(AudioBufferList *)inputDataBuffer;
- (void)processOutput:(AudioBufferList *)outputDataBuffer;

@end
