//
//  AudioDataProcessor.m
//  ivbcamp
//
//  Created by Octavian Stirbei on 5/20/14.
//  Copyright (c) 2014 Octavian Stirbei. All rights reserved.
//

#import "AudioDataProcessor.h"

#ifndef max
#define max( a, b ) ( ((a) > (b)) ? (a) : (b) )
#endif

#ifndef min
#define min( a, b ) ( ((a) < (b)) ? (a) : (b) )
#endif

#pragma mark - AAC static declaration

static AACELDEncoder         *g_encoder        = NULL;
static AACELDDecoder         *g_decoder        = NULL;
static MagicCookie            g_cookie;


#pragma mark - AAC config methods

/* Initialize the AAC-ELD encoder and decoder */
void InitAACELD() {
    EncoderProperties p;
    p.samplingRate = 44100.0;
    p.inChannels   = 1;
    p.outChannels  = 1;
    p.frameSize    = 512;
    p.bitrate      = 32000;
    
    g_encoder = CreateAACELDEncoder();
    InitAACELDEncoder(g_encoder, p, &g_cookie);
    
    DecoderProperties dp;
    dp.samplingRate = 44100.0;
    dp.inChannels   = 1;
    dp.outChannels  = 1;
    dp.frameSize    = p.frameSize;
    
    g_decoder = CreateAACELDDecoder();
    InitAACELDDecoder(g_decoder, dp, &g_cookie);
}

/* Cleanup */
void DestroyAACELD() {
    DestroyAACELDEncoder(g_encoder, &g_cookie);
    DestroyAACELDDecoder(g_decoder);
}

@implementation AudioDataProcessor

#pragma mark - Initialization

- (id)init {
    if((self = [super init])) {
        rawInputData = nil;
        InitAACELD();
        _audioOutputBuffer = [[NSMutableArray alloc] init];
        _sendPcksCnt = [NSNumber numberWithLong:0];
        _lastPckCnt = [NSNumber numberWithLong:0];
        _dropPckCnt = [NSNumber numberWithLong:0];
    }
    return self;
}

+ (AudioDataProcessor*)sharedInstance {
    static AudioDataProcessor *sharedAudioDataProcessor = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedAudioDataProcessor = [[AudioDataProcessor alloc] init];
        NSLog(@"Singleton has memory address at: %@", sharedAudioDataProcessor);
    });
    return sharedAudioDataProcessor;
}

#pragma mark - Deallocation

- (void)dealloc {
    DestroyAACELD();
}

#pragma mark - Audio IO callbacks

- (void)processRawInputData:(AudioBufferList *)inputDataBuffer {
}

- (void)processOutput:(AudioBufferList *)outputDataBuffer {
}



@end
