//
//  SessionConnection.m
//  ivbcamp
//
//  Created by Octavian Stirbei on 5/20/14.
//  Copyright (c) 2014 Octavian Stirbei. All rights reserved.
//

#import "SessionConnection.h"

#import "RRpcSocket.h"

#define kSenderChannels 10
#define kReceiversChannels 50


@implementation SessionConnection

#pragma mark - initialization

- (id)init {
    if((self = [super init])) {
        _socket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)];
        _rrpcSenders = [[NSMutableArray alloc] init];
        _rrpcReceivers = [[NSMutableArray alloc] init];
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
}


#pragma mark - Methods

- (void)connectToHost:(NSString *)host onPort:(uint16_t)port error:(NSError **)errPtr {
	__block NSError *preConnectErr = nil;
    if (![_socket connectToHost:host onPort:port error:&preConnectErr]) {// Asynchronous!
        *errPtr = preConnectErr;
        // If there was an error, it's likely something like "already connected" or "no delegate set"
        NSLog(@"I goofed: %@", preConnectErr);
    }
}

- (void)disconnect {
    [_socket disconnect];
}

- (void)startAudioSession {
    if (_connected) {
        NSMutableDictionary *requestData = [[NSMutableDictionary alloc] init];
        [requestData setObject:@"createSession" forKey:@"request"];
        [_socket writeData:[NSJSONSerialization dataWithJSONObject:requestData options:kNilOptions error:nil] withTimeout:-1 tag:-1];
        [_socket readDataWithTimeout:-1 tag:2];
    }
}

- (void)initSenders {
    RRpcSocket *rrpcSocket = [[RRpcSocket alloc] init];
    rrpcSocket.receiver = NO;
    __block __weak RRpcSocket *weakRRpcSocket = rrpcSocket;
    dispatch_queue_t connectQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_async(connectQueue, ^(void) {
        __block __strong RRpcSocket *strongRRpcSocket = weakRRpcSocket;
        [strongRRpcSocket connect];
    });
//    [rrpcSocket connect];
}

- (void)initReceivers {
    
}

#pragma mark - GCDAsyncSocket delegate methods

- (void)socket:(GCDAsyncSocket *)sender didConnectToHost:(NSString *)host port:(UInt16)port {
    _connected = YES;
    _host = host;
    _port = port;
    NSLog(@"Cool, I'm connected! That was easy.");
}

- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)error {
    _connected = NO;
    NSLog(@"Cool, I'm disconnected! That was easy.");
}

- (void)socket:(GCDAsyncSocket *)sock didWriteDataWithTag:(long)tag {
    NSLog(@"Cool, I did write! That was easy.");
}

- (void)socket:(GCDAsyncSocket *)sender didReadData:(NSData *)data withTag:(long)tag {
    NSLog(@"Cool, I did read! That was easy.");
    NSDictionary *response = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];
    NSString *request = [response objectForKey:@"request"];
    if ([request isEqualToString:@"createSession"] || [request isEqualToString:@"connectSession"] ) {
        _sessionUUID = [response objectForKey:@"sessionUUID"];
        _clientUUID = [response objectForKey:@"clientUUID"];
        [self initSenders];
        [self initReceivers];
        NSLog(@"New session connection started. Session: %@  Client: %@", _sessionUUID, _clientUUID);
    }
}


@end
