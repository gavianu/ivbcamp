//
//  GCDTcpSocket.h
//  ivbcamp
//
//  Created by Octavian Stirbei on 5/21/14.
//  Copyright (c) 2014 Octavian Stirbei. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface GCDTcpSocket : NSObject {
    
    __strong dispatch_queue_t delegateQueue;
    int _nativeSocket;
    BOOL connected;
   
}


@property(nonatomic, weak) id delegate;

- (id)initWithDelegate:(id)delegate processQueue:(dispatch_queue_t)dg;
- (BOOL)connectToHost:(NSString *)host onPort:(UInt16) port;
- (void)disconnect;
- (void)writeData:(NSData*)data;


@end


@protocol GCDTcpSocketProtocol
@optional


- (void)socket:(GCDTcpSocket *)socket didConnectToHost:(NSString *)host port:(UInt16)port;

- (void)socketDidDisconnect:(GCDTcpSocket *)sock;

- (void)socketDidWriteData:(GCDTcpSocket *)socket;

- (void)socket:(GCDTcpSocket *)socket didReadData:(NSData*)data;

@end
