//
//  RRpcSocket.m
//  ivbcamp
//
//  Created by Octavian Stirbei on 5/20/14.
//  Copyright (c) 2014 Octavian Stirbei. All rights reserved.
//

#import "RRpcSocket.h"

#import "SessionConnection.h"
#import "AudioDataProcessor.h"

@implementation RRpcSocket

#pragma mark - Initialization

- (id)init {
    if((self= [super init])) {
        _socket = [[GCDUdpSocket alloc] initWithDelegate:self];
    }
    return self;
}

#pragma mark - deallocation

- (void)dealloc {
    [_socket setDelegate:nil];
//    [_socket release];
//    if(sendTmpBuffer != nil) {
//        [sendTmpBuffer release];
//        sendTmpBuffer = nil;
//    }
//    [super dealloc];
}

#pragma mark - Public Methods

-(void)send:(NSDictionary *)jsonDictionary {
//    sendTmpBuffer = [[NSJSONSerialization dataWithJSONObject:jsonDictionary options:kNilOptions error:nil] retain];
    [_socket writeData:[NSJSONSerialization dataWithJSONObject:jsonDictionary options:kNilOptions error:nil]];
}

-(void)listenOnPort:(int)port {
    [_socket listenOnPort:port];
}

#pragma mark - Private methods

- (void)registerChannel {
    SessionConnection *sessionConnection = [SessionConnection sharedInstance];
    NSMutableDictionary *dicData = [[NSMutableDictionary alloc] init];
    [dicData setObject:@"rpc" forKey:@"request"];
    [dicData setObject:@"registerChannel" forKey:@"method"];
    NSMutableArray *params = [[NSMutableArray alloc] init];
    [params addObject:[sessionConnection sessionUUID]];
    [params addObject:[sessionConnection clientUUID]];
    [dicData setObject:params forKey:@"params"];
    [self send:dicData];
//    [dicData release];
}


#pragma mark - GCDAsyncSocket delegate methods


- (void)socket:(GCDUdpSocket *)socket didReadData:(NSData*)data {
    NSDictionary *response = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];
    SessionConnection *sessionConnection = [SessionConnection sharedInstance];
    if ([[response objectForKey:@"request"] isEqualToString:@"incomingData"]) {
        NSNumber *dataPckCount = [response objectForKey:@"noPck"];
        AudioDataProcessor *audioDataProcessor = [AudioDataProcessor sharedInstance];
        if (dataPckCount > [audioDataProcessor lastPckCnt]) {
            NSNumber *sendTime = [response objectForKey:@"sendTime"];
            NSTimeInterval seconds = [sendTime doubleValue];
            
            NSDate *date = [NSDate dateWithTimeIntervalSince1970:seconds];
            
            double tmpMilis = [[sessionConnection millis] doubleValue];
            tmpMilis += -[date timeIntervalSinceNow]*1000;
            [sessionConnection setMillis:[NSNumber numberWithDouble:tmpMilis]];
            long tmpCnt = [[sessionConnection recPcksCnt] longValue];
            [sessionConnection setRecPcksCnt:[NSNumber numberWithLong:++tmpCnt]];
            NSLog(@"--- Lag: %f Jitter: %f , total packets:  %lu ", -[date timeIntervalSinceNow] * 1000, tmpMilis/tmpCnt, tmpCnt);
            
            
            audioDataProcessor.lastPckCnt = [NSNumber numberWithLong:[dataPckCount longValue]];
            [[audioDataProcessor audioOutputBuffer] addObject:response];
        }else {
            long dropPckCnt = [[audioDataProcessor dropPckCnt] longValue];
            dropPckCnt += [[audioDataProcessor lastPckCnt] longValue] - [dataPckCount longValue];
            long tmpCnt = [[sessionConnection recPcksCnt] longValue];
            [sessionConnection setRecPcksCnt:[NSNumber numberWithLong:++tmpCnt]];
            audioDataProcessor.dropPckCnt = [NSNumber numberWithLong:dropPckCnt];
            NSLog(@"drop packet count -----> %lu total packets: %lu, loosage: %f ", dropPckCnt, tmpCnt, ((double)dropPckCnt / (double)tmpCnt) * 100);
        }
    }
}


@end
