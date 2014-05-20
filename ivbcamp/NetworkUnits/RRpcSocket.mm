//
//  RRpcSocket.m
//  ivbcamp
//
//  Created by Octavian Stirbei on 5/20/14.
//  Copyright (c) 2014 Octavian Stirbei. All rights reserved.
//

#import "RRpcSocket.h"

#import "SessionConnection.h"

@implementation RRpcSocket

#pragma mark - Initialization

- (id)init {
    if((self= [super init])) {
    }
    return self;
}

#pragma mark - deallocation

- (void)dealloc {
    [_socket setDelegate:nil];
}

#pragma mark - Public Methods

- (void)connect {
    
    _socket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)];
    SessionConnection *sessionConnection = [SessionConnection sharedInstance];
    __block NSError *preConnectErr = nil;
    if (![_socket connectToHost:[sessionConnection host] onPort:[sessionConnection port] error:&preConnectErr]) {// Asynchronous!
        // If there was an error, it's likely something like "already connected" or "no delegate set"
        NSLog(@"I goofed: %@", preConnectErr);
    }
}

#pragma mark - GCDAsyncSocket delegate methods

- (void)socket:(GCDAsyncSocket *)sender didConnectToHost:(NSString *)host port:(UInt16)port {
    NSLog(@"Am conectat un socket");
    SessionConnection *sessionConnection = [SessionConnection sharedInstance];
    if (_receiver) {
        [[sessionConnection rrpcReceivers] addObject:self];
    }else {
        [[sessionConnection rrpcSenders] addObject:self];
    }
}

- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)error {
}

- (void)socket:(GCDAsyncSocket *)sock didWriteDataWithTag:(long)tag {
}

- (void)socket:(GCDAsyncSocket *)sender didReadData:(NSData *)data withTag:(long)tag {
}


@end
