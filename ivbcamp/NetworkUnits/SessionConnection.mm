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
    [_socket release];
    [_sessionUUID release];
    [_clientUUID release];
    [_host release];
    [_rrpcSenders removeAllObjects];
    [_rrpcSenders release];
    [_rrpcReceivers removeAllObjects];
    [_rrpcReceivers release];
    if(sendTmpBuffer != nil) {
        [sendTmpBuffer release];
        sendTmpBuffer = nil;
    }
    [super dealloc];
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
        sendTmpBuffer = [[NSJSONSerialization dataWithJSONObject:requestData options:kNilOptions error:nil] retain];
        [_socket writeData:sendTmpBuffer withTimeout:-1 tag:-1];
        [_socket readDataWithTimeout:-1 tag:2];
    }
}

- (void)initSenders {
    dispatch_queue_t createSendersQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0);
    dispatch_async(createSendersQueue, ^(void) {
        for(int i = 0; i < kSenderChannels; i++) {
            RRpcSocket *rrpcSocket = [[RRpcSocket alloc] init];
            rrpcSocket.receiver = NO;
        }
    });
}

- (void)initReceivers {
    dispatch_queue_t createSendersQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0);
    dispatch_async(createSendersQueue, ^(void) {
        for(int i = 0; i < kReceiversChannels; i++) {
            RRpcSocket *rrpcSocket = [[RRpcSocket alloc] init];
            rrpcSocket.receiver = YES;
        }
    });
}

#pragma mark - GCDAsyncSocket delegate methods

- (void)socket:(GCDAsyncSocket *)sender didConnectToHost:(NSString *)host port:(UInt16)port {
    _connected = YES;
    _host = [host retain];
    _port = port;
    NSLog(@"Cool, I'm connected! That was easy.");
}

- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)error {
    _connected = NO;
    NSLog(@"Cool, I'm disconnected! That was easy.");
}

- (void)socket:(GCDAsyncSocket *)sock didWriteDataWithTag:(long)tag {
    NSLog(@"Cool, I did write! That was easy.");
    [sendTmpBuffer release];
    sendTmpBuffer = nil;
}

- (void)socket:(GCDAsyncSocket *)sender didReadData:(NSData *)data withTag:(long)tag {
    NSLog(@"Cool, I did read! That was easy.");
    NSDictionary *response = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];
    NSString *request = [response objectForKey:@"request"];
    if ([request isEqualToString:@"createSession"] || [request isEqualToString:@"connectSession"] ) {
        _sessionUUID = [[response objectForKey:@"sessionUUID"] retain];
        _clientUUID = [[response objectForKey:@"clientUUID"] retain];
        [self initSenders];
        [self initReceivers];
        [[VBCAudioSession sharedInstance] startCapture];

        NSLog(@"New session connection started. Session: %@  Client: %@", _sessionUUID, _clientUUID);
    }
    
}


@end
