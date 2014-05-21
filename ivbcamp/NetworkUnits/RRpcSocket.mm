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
        _socket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)];
        SessionConnection *sessionConnection = [SessionConnection sharedInstance];
        __block NSError *preConnectErr = nil;
        if (![_socket connectToHost:[sessionConnection host] onPort:[sessionConnection port] error:&preConnectErr]) {// Asynchronous!
            // If there was an error, it's likely something like "already connected" or "no delegate set"
            NSLog(@"I goofed: %@", preConnectErr);
        }
    }
    return self;
}

#pragma mark - deallocation

- (void)dealloc {
    [_socket setDelegate:nil];
    [_socket release];
    if(sendTmpBuffer != nil) {
        [sendTmpBuffer release];
        sendTmpBuffer = nil;
    }
    [super dealloc];
}

#pragma mark - Public Methods

-(void)send:(NSDictionary *)jsonDictionary {
    if(!_receiver) {
        //        NSLog(@"after send revome from stash");
        SessionConnection *sessionConnection = [SessionConnection sharedInstance];
        [[sessionConnection rrpcSenders] removeObject:self];
    }
    sendTmpBuffer = [[NSJSONSerialization dataWithJSONObject:jsonDictionary options:kNilOptions error:nil] retain];
    [_socket writeData:sendTmpBuffer withTimeout:-1 tag:-1];
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
    [dicData release];
}


#pragma mark - GCDAsyncSocket delegate methods

- (void)socket:(GCDAsyncSocket *)sender didConnectToHost:(NSString *)host port:(UInt16)port {
    NSLog(@"Am conectat un socket");
    SessionConnection *sessionConnection = [SessionConnection sharedInstance];
    if (_receiver) {
        [self registerChannel];
        [[sessionConnection rrpcReceivers] addObject:self];
        [_socket readDataWithTimeout:-1 tag:2];
    }else {
        [[sessionConnection rrpcSenders] addObject:self];
    }
}

- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)error {
    __block __weak RRpcSocket *weakSelf = self;
    if(_receiver) {
        dispatch_queue_t receiversQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0);
        dispatch_async(receiversQueue, ^(void) {
            SessionConnection *sessionConnection = [SessionConnection sharedInstance];
            __block __strong RRpcSocket *blockSelf = weakSelf;
            [[sessionConnection rrpcReceivers] removeObject:blockSelf];
            [blockSelf release];
            RRpcSocket *rrpcSocket = [[RRpcSocket alloc] init];
            rrpcSocket.receiver = YES;
        });
        
    } else {
        
        dispatch_queue_t senderQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0);
        dispatch_async(senderQueue, ^(void) {
            __block __strong RRpcSocket *strongSelf = weakSelf;
            [strongSelf release];
            RRpcSocket *rrpcSocket = [[RRpcSocket alloc] init];
            rrpcSocket.receiver = NO;
        });
    }
}

- (void)socket:(GCDAsyncSocket *)sock didWriteDataWithTag:(long)tag {
    [sendTmpBuffer release];
    sendTmpBuffer = nil;
}

- (void)socket:(GCDAsyncSocket *)sender didReadData:(NSData *)data withTag:(long)tag {
    if(_receiver) {
        NSDictionary *response = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];
        if ([[response objectForKey:@"request"] isEqualToString:@"incomingData"]) {
            NSNumber *dataPckCount = [response objectForKey:@"noPck"];
            AudioDataProcessor *audioDataProcessor = [AudioDataProcessor sharedInstance];
            if (dataPckCount > [audioDataProcessor lastPckCnt]) {
                NSNumber *sendTime = [response objectForKey:@"sendTime"];
                NSTimeInterval seconds = [sendTime doubleValue];
                
                NSDate *date = [NSDate dateWithTimeIntervalSince1970:seconds];
                
                NSLog(@"--- Lag: %f", -[date timeIntervalSinceNow] * 1000);
                
                audioDataProcessor.lastPckCnt = [NSNumber numberWithLong:[dataPckCount longValue]];
                [[audioDataProcessor audioOutputBuffer] addObject:response];
            }else {
                UInt64 dropPckCnt = [[audioDataProcessor dropPckCnt] longValue];
                dropPckCnt += [[audioDataProcessor lastPckCnt] longValue] - [dataPckCount longValue];
                audioDataProcessor.dropPckCnt = [NSNumber numberWithLong:dropPckCnt];
                NSLog(@"drop packet count -----> %lu  ", [[audioDataProcessor dropPckCnt] longValue]);
            }
            
        }
    }
}


@end
