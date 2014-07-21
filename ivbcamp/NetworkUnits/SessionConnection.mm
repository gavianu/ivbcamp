//
//  SessionConnection.m
//  ivbcamp
//
//  Created by Octavian Stirbei on 5/20/14.
//  Copyright (c) 2014 Octavian Stirbei. All rights reserved.
//

#import "SessionConnection.h"


#import "VBCAudioSession.h"

#define kSenderChannels 10
#define kReceiversChannels 10


@implementation SessionConnection

#pragma mark - initialization

- (id)init {
    if((self = [super init])) {
        _socket = [[GCDAsyncUdpSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
        _rrpcSenders = [[NSMutableArray alloc] init];
        _rrpcReceivers = [[NSMutableArray alloc] init];
        _millis = [NSNumber numberWithDouble:0];
        _recPcksCnt = [NSNumber numberWithLong:0];
    }
    return self;
}

+ (SessionConnection*)sharedInstance {
    static SessionConnection *sharedSessionConnection = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedSessionConnection = [[SessionConnection alloc] init];
        NSLog(@"Singleton has memory address at: %@", sharedSessionConnection);
    });
    return sharedSessionConnection;
}


#pragma mark - deallocation

- (void)dealloc {
    [_socket setDelegate:nil];
//    [_socket release];
//    [_sessionUUID release];
//    [_clientUUID release];
//    [_host release];
//    [_rrpcSenders removeAllObjects];
//    [_rrpcSenders release];
//    [_rrpcReceivers removeAllObjects];
//    [_rrpcReceivers release];
//    if(sendTmpBuffer != nil) {
//        [sendTmpBuffer release];
//        sendTmpBuffer = nil;
//    }
//    [super dealloc];
}


#pragma mark - Methods

- (void)connectToHost:(NSString *)host onPort:(uint16_t)port error:(NSError **)errPtr {
}

- (void)disconnect {
}

- (void)startAudioSession {
    [[VBCAudioSession sharedInstance] startCapture];
}

- (void)sendData:(NSDictionary *)jsonDictionary {
 //   [_socket sendData:<#(NSData *)#> toHost:<#(NSString *)#> port:<#(uint16_t)#> withTimeout:<#(NSTimeInterval)#> tag:<#(long)#>]
}

- (void)initReceivers {
}

#pragma mark - GCDAsyncUdpSocket delegate methods

- (void)udpSocket:(GCDAsyncUdpSocket *)sock didSendDataWithTag:(long)tag {
    
}

- (void)udpSocket:(GCDAsyncUdpSocket *)sock didReceiveData:(NSData *)data
      fromAddress:(NSData *)address
withFilterContext:(id)filterContext {
    
}



@end
