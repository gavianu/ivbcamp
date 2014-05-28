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
        _socket = [[GCDTcpSocket alloc] initWithDelegate:self processQueue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)];
        SessionConnection *sessionConnection = [SessionConnection sharedInstance];
        if (![_socket connectToHost:[sessionConnection host] onPort:[sessionConnection port]]) {// Asynchronous!
            // If there was an error, it's likely something like "already connected" or "no delegate set"
            NSLog(@"I goofed:");
        }
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
    if(!_receiver) {
        SessionConnection *sessionConnection = [SessionConnection sharedInstance];
        [[sessionConnection rrpcSenders] removeObject:self];
    }
//    sendTmpBuffer = [[NSJSONSerialization dataWithJSONObject:jsonDictionary options:kNilOptions error:nil] retain];
    [_socket writeData:[NSJSONSerialization dataWithJSONObject:jsonDictionary options:kNilOptions error:nil]];
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

- (void)socket:(GCDTcpSocket *)socket didConnectToHost:(NSString *)host port:(UInt16)port {
    NSLog(@"Am conectat un socket");
    SessionConnection *sessionConnection = [SessionConnection sharedInstance];
    if (_receiver) {
        [self registerChannel];
        [[sessionConnection rrpcReceivers] addObject:self];
    }else {
        [[sessionConnection rrpcSenders] addObject:self];
    }
}

- (void)socketDidDisconnect:(GCDTcpSocket *)sock {
    NSLog(@"S-a deconectat un socket");
    if(_receiver) {
        SessionConnection *sessionConnection = [SessionConnection sharedInstance];
        [[sessionConnection rrpcReceivers] removeObject:self];
        dispatch_queue_t receiversQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
        dispatch_async(receiversQueue, ^(void) {
            RRpcSocket *rrpcSocket = [[RRpcSocket alloc] init];
            rrpcSocket.receiver = YES;
        });
        
    } else {
        dispatch_queue_t senderQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
        dispatch_async(senderQueue, ^(void) {
            RRpcSocket *rrpcSocket = [[RRpcSocket alloc] init];
            rrpcSocket.receiver = NO;
        });
    }
}

- (void)socketDidWriteData:(GCDTcpSocket *)socket {
//    [sendTmpBuffer release];
//    sendTmpBuffer = nil;
}

- (void)socket:(GCDTcpSocket *)socket didReadData:(NSData*)data {
    if(_receiver) {
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
}


@end
