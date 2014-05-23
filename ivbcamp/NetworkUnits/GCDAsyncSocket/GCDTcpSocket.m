//
//  GCDTcpSocket.m
//  ivbcamp
//
//  Created by Octavian Stirbei on 5/21/14.
//  Copyright (c) 2014 Octavian Stirbei. All rights reserved.
//

#import "GCDTcpSocket.h"

#include <sys/socket.h>
#include <netinet/in.h>
#include <sys/types.h>
#include <arpa/inet.h>

@implementation GCDTcpSocket

-(id)initWithDelegate:(id)delegate processQueue:(dispatch_queue_t)dg {
    if((self = [super init])) {
        _delegate = delegate;
        delegateQueue = dg;
        _nativeSocket = socket(PF_INET, SOCK_STREAM, IPPROTO_TCP);
    }
    return self;
}


-(BOOL)connectToHost:(NSString *)host onPort:(UInt16) port {

    const char *hostAddr =  [host UTF8String];
    
    
    struct sockaddr_in sin;
    memset(&sin, 0, sizeof(sin));
    sin.sin_len = sizeof(sin);
    sin.sin_family = AF_INET; // or AF_INET6 (address family)
    sin.sin_port = htons(port);
    inet_pton(AF_INET, hostAddr, &sin.sin_addr);
 
    NSLog(@"create socket no: %d", _nativeSocket);
    int status = connect(_nativeSocket,  (struct sockaddr *)&sin, sizeof(sin));
    connected = status == 0;
    __block NSString *weakHost = host;
    __block id delegate = _delegate;
    __block GCDTcpSocket *weakSelf = self;
    
    dispatch_queue_t connectQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_async(connectQueue, ^(void) {
        __block __strong id theDelegate = delegate;
        __block __strong GCDTcpSocket *strongSelf = weakSelf;
        __block __strong NSString *strongHost = weakHost;
        if (status == 0 && [theDelegate respondsToSelector:@selector(socket:didConnectToHost:port:)]) {
            [theDelegate socket:strongSelf didConnectToHost:strongHost port:port];
        }
    });
    
    if (status == 0) {
        dispatch_async(delegateQueue, ^(void) {
            __block __strong id theDelegate = delegate;
            __block __strong GCDTcpSocket *strongSelf = weakSelf;
            while (strongSelf->connected) {
                size_t maxDataSize = 512;
                void *data = malloc(maxDataSize);
                ssize_t readBytes = read(strongSelf->_nativeSocket, data, maxDataSize);
                if (readBytes > 0 && [theDelegate respondsToSelector:@selector(socket:didReadData:)]) {
                    [theDelegate socket:strongSelf didReadData:[NSData dataWithBytes:data length:readBytes]];
                }else if (readBytes == 0) {
                    close(_nativeSocket);
                    strongSelf->connected = NO;
                    [theDelegate socketDidDisconnect:strongSelf];
                }
                free(data);
//                usleep(1000);
            }
        });
    }else {
        printf("Oh dear, something went wrong with connect()! %s\n", strerror(errno));
    }

    return status == 0;
}


-(void)disconnect {
    __block id delegate = _delegate;
    __block GCDTcpSocket *weakSelf = self;
    int t = close(_nativeSocket);
    connected = t == 0;
    dispatch_queue_t closeQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_async(closeQueue, ^(void) {
        __block __strong id theDelegate = delegate;
        __block __strong GCDTcpSocket *strongSelf = weakSelf;
        if (t == 0 && [theDelegate respondsToSelector:@selector(socketDidDisconnect:)]) {
            [theDelegate socketDidDisconnect:strongSelf];
        }
    });
}

-(void)writeData:(NSData*)data {
    __block id delegate = _delegate;
    __block GCDTcpSocket *weakSelf = self;
    void *sdata = malloc([data length]);
    memcpy(sdata, [data bytes], [data length]);
    NSUInteger dataLength = [data length];
    
    dispatch_queue_t sendQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_async(sendQueue, ^(void) {
        __block __strong id theDelegate = delegate;
        __block __strong GCDTcpSocket *strongSelf = weakSelf;
        ssize_t sendBytes = write(strongSelf->_nativeSocket, sdata, dataLength);
        if (sendBytes == dataLength && [theDelegate respondsToSelector:@selector(socketDidWriteData:)]) {
            [theDelegate socketDidWriteData:strongSelf];
        }
        free(sdata);
    });
}



@end
