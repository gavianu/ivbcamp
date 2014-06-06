//
//  GCDUdpSocket.h
//  ivbcamp
//
//  Created by Octavian Stirbei on 5/28/14.
//  Copyright (c) 2014 Octavian Stirbei. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface GCDUdpSocket : NSObject {
    
    int _nativeSocket;
    
}

@property(nonatomic, weak) id delegate;

- (id)initWithDelegate:(id)delegate;


- (void)writeData:(NSData*)data;
- (void)listenOnPort:(int)port;


@end


@protocol GCDUdpSocketProtocol
@optional


- (void)socketDidWriteData:(GCDUdpSocket *)socket;

- (void)socket:(GCDUdpSocket *)socket didReadData:(NSData*)data;


@end