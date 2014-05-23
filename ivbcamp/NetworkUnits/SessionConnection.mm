//
//  SessionConnection.m
//  ivbcamp
//
//  Created by Octavian Stirbei on 5/20/14.
//  Copyright (c) 2014 Octavian Stirbei. All rights reserved.
//

#import "SessionConnection.h"

#import "RRpcSocket.h"

#import "VBCAudioSession.h"

#define kSenderChannels 10
#define kReceiversChannels 10


@implementation SessionConnection

#pragma mark - initialization

- (id)init {
    if((self = [super init])) {
        _socket = [[GCDTcpSocket alloc] initWithDelegate:self processQueue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)];
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
    if (![_socket connectToHost:host onPort:port]) {// Asynchronous!
        // If there was an error, it's likely something like "already connected" or "no delegate set"
        NSLog(@"I goofed: ");
    }
}

- (void)disconnect {
    [_socket disconnect];
}

- (void)startAudioSession {
    if (_connected) {
        NSMutableDictionary *requestData = [[NSMutableDictionary alloc] init];
        [requestData setObject:@"createSession" forKey:@"request"];
        [_socket writeData:[NSJSONSerialization dataWithJSONObject:requestData options:kNilOptions error:nil]];
    }
}

- (void)initSenders {
    for(int i = 0; i < kSenderChannels; i++) {
        dispatch_queue_t createSendersQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0);
        dispatch_async(createSendersQueue, ^(void) {
            RRpcSocket *rrpcSocket = [[RRpcSocket alloc] init];
            rrpcSocket.receiver = NO;
        });
    }
}

- (void)initReceivers {
    for(int i = 0; i < kReceiversChannels; i++) {
        dispatch_queue_t createSendersQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0);
        dispatch_async(createSendersQueue, ^(void) {
            RRpcSocket *rrpcSocket = [[RRpcSocket alloc] init];
            rrpcSocket.receiver = YES;
        });
    }
}

#pragma mark - GCDAsyncSocket delegate methods

- (void)socket:(GCDTcpSocket *)socket didConnectToHost:(NSString *)host port:(UInt16)port {
    _connected = YES;
    _host = host;
    _port = port;
    NSLog(@"Cool, I'm connected! That was easy.");
}

- (void)socketDidDisconnect:(GCDTcpSocket *)sock {
    _connected = NO;
    NSLog(@"Cool, I'm disconnected! That was easy.");
}

- (void)socketDidWriteData:(GCDTcpSocket *)socket {
    NSLog(@"Cool, I did write! That was easy.");
}

- (void)socket:(GCDTcpSocket *)socket didReadData:(NSData*)data {
    NSLog(@"Cool, I did read! That was easy.");
    NSDictionary *response = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];
    NSString *request = [response objectForKey:@"request"];
    if ([request isEqualToString:@"createSession"] || [request isEqualToString:@"connectSession"] ) {
        _sessionUUID = [response objectForKey:@"sessionUUID"];
        _clientUUID = [response objectForKey:@"clientUUID"];
        [self initSenders];
        [self initReceivers];
        [[VBCAudioSession sharedInstance] startCapture];

        NSLog(@"New session connection started. Session: %@  Client: %@", _sessionUUID, _clientUUID);
    }
    
}


@end
