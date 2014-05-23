//
//  AudioDataProcessor.m
//  ivbcamp
//
//  Created by Octavian Stirbei on 5/20/14.
//  Copyright (c) 2014 Octavian Stirbei. All rights reserved.
//

#import "AudioDataProcessor.h"

#import "SessionConnection.h"
#import "RRpcSocket.h"
#import "NSData+Base64.h"


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
//    [_audioOutputBuffer removeAllObjects];
//    [_audioOutputBuffer release];
//    [_sendPcksCnt release];
//    [_lastPckCnt release];
//    [_dropPckCnt release];
//    
//    free(rawInputData->mBuffers[0].mData);
//    free(aacEncodedBuffer.data);
//    
//    [super dealloc];
}

#pragma mark - Audio IO callbacks

- (void)processRawInputData:(AudioBufferList *)inputDataBuffer {
    NSLog(@"trimit date ");
    SessionConnection *sessionConnection = [SessionConnection sharedInstance];
    if ([[sessionConnection rrpcSenders] count] <= 0) {
        return;
    }
    EncodeAACELD(g_encoder, &inputDataBuffer->mBuffers[0], &aacEncodedBuffer);
    long value = [_sendPcksCnt longValue];
    _sendPcksCnt = [NSNumber numberWithLong:++value];
    NSMutableDictionary *dataPacket = [[NSMutableDictionary alloc] init];
    [dataPacket setObject:@"incomingData" forKey:@"request"];
    [dataPacket setObject:[sessionConnection sessionUUID] forKey:@"sessionUUID"];
    [dataPacket setObject:[sessionConnection clientUUID] forKey:@"clientUUID"];
    [dataPacket setObject:_sendPcksCnt forKey:@"noPck"];
    NSNumber *sendTime = [NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970]];
    [dataPacket setObject:sendTime forKey:@"sendTime"];

    NSData *audioData = [[NSData alloc] initWithBytes:aacEncodedBuffer.data length:aacEncodedBuffer.mDataBytesSize];
    NSString* newStr = [audioData base64EncodedString];
//    [audioData release];
    [dataPacket setObject:newStr forKey:@"audioData"];
//    NSLog(@"trimit date ");
    [[[sessionConnection rrpcSenders] firstObject] send:dataPacket];
////    [dataPacket release];
    
}

- (void)processOutput:(AudioBufferList *)outputDataBuffer {
    if ([_audioOutputBuffer count] > 0) {
        NSDictionary *audioDic = [_audioOutputBuffer objectAtIndex:0];
        NSString *serializeData = [audioDic objectForKey:@"audioData"];
        NSData *audioData = [NSData dataFromBase64String:serializeData];
        
        EncodedAudioBuffer encodedAB;
        encodedAB.mChannels = 1;
        encodedAB.mDataBytesSize = (UInt32)[audioData length];
        encodedAB.data = malloc(sizeof(unsigned char) * (encodedAB.mDataBytesSize));
        memcpy(encodedAB.data, [audioData bytes], encodedAB.mDataBytesSize);
        
//        [audioData release];
        
        AudioBuffer sourceBuffer;
        
        sourceBuffer.mNumberChannels = 1;
        sourceBuffer.mDataByteSize = 512 * sizeof(AudioSampleType);
        sourceBuffer.mData = malloc(sizeof(unsigned char)* sourceBuffer.mDataByteSize);
        memset(sourceBuffer.mData, 0, sourceBuffer.mDataByteSize);
        
        DecodeAACELD(g_decoder, &encodedAB, &sourceBuffer);
        
        for (int i=0; i < outputDataBuffer->mNumberBuffers; i++) { // in practice we will only ever have 1 buffer, since audio format is mono
            AudioBuffer audioBuffer = outputDataBuffer->mBuffers[i];
            UInt32 size = min(audioBuffer.mDataByteSize, sourceBuffer.mDataByteSize); // dont copy more data then we have, or then fits
            
            memcpy(audioBuffer.mData, sourceBuffer.mData, size);
            audioBuffer.mDataByteSize = size; // indicate how much data we wrote in the buffer
            
        }
        
        free(encodedAB.data);
        free(sourceBuffer.mData);
        
        [_audioOutputBuffer removeObject:audioDic];
        
    }
}



@end
