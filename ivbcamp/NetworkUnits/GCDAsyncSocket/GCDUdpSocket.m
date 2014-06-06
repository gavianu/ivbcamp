//
//  GCDUdpSocket.m
//  ivbcamp
//
//  Created by Octavian Stirbei on 5/28/14.
//  Copyright (c) 2014 Octavian Stirbei. All rights reserved.
//

#import "GCDUdpSocket.h"

#include <sys/socket.h>
#include <netinet/in.h>
#include <sys/types.h>
#include <arpa/inet.h>

@implementation GCDUdpSocket



- (id)initWithDelegate:(id)delegate {
    if((self = [super init])) {
        _delegate = delegate;
        _nativeSocket = socket(PF_INET, SOCK_DGRAM, IPPROTO_UDP);
    }
    return self;
}


- (void)writeData:(NSData*)data {
    
    struct sockaddr_in destination;
    unsigned int echolen;
    int broadcast = 1;
    // if that doesn't work, try this
    //char broadcast = '1';
    
    
    /* Construct the server sockaddr_in structure */
    memset(&destination, 0, sizeof(destination));
    
    /* Clear struct */
    destination.sin_family = AF_INET;
    
    /* Internet/IP */
    destination.sin_addr.s_addr = inet_addr("188.25.145.105");
    
    /* IP address */
    destination.sin_port = htons(7827);
    
    /* server port */
    setsockopt(_nativeSocket,
               IPPROTO_IP,
               IP_MULTICAST_IF,
               &destination,
               sizeof(destination));
    
    // this call is what allows broadcast packets to be sent:
    if (setsockopt(_nativeSocket,
                   SOL_SOCKET,
                   SO_BROADCAST,
                   &broadcast,
                   sizeof broadcast) == -1)
    {
        perror("setsockopt (SO_BROADCAST)");
        exit(1);
    }
    
    void *sdata = malloc([data length]);
    memcpy(sdata, [data bytes], [data length]);
    NSUInteger dataLength = [data length];
    
    if (sendto(_nativeSocket,
               sdata,
               dataLength,
               0,
               (struct sockaddr *) &destination,
               sizeof(destination)) != dataLength)
    {
        printf("Mismatch in number of sent bytes\n");
    }
    else
    {
        NSLog(@"s-a trimis cacatul");
    }
}


- (void)listenOnPort:(int)port {
    
    struct sockaddr_in sa;
    __block socklen_t fromlen;
    
    memset(&sa, 0, sizeof sa);
    sa.sin_family = AF_INET;
    sa.sin_addr.s_addr = htonl(INADDR_ANY);
    sa.sin_port = htons(port);
    fromlen = sizeof(sa);
    
    if (-1 == bind(_nativeSocket,(struct sockaddr *)&sa, sizeof(sa))) {
        perror("error bind failed");
        close(_nativeSocket);
        exit(EXIT_FAILURE);
    }
    
    __block id delegate = _delegate;
    __block GCDUdpSocket *weakSelf = self;
    
    dispatch_queue_t listenQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_async(listenQueue, ^(void) {
        char buffer[1024];
        ssize_t recsize;
        __block __strong id theDelegate = delegate;
        __block __strong GCDUdpSocket *strongSelf = weakSelf;
        recsize = recvfrom(strongSelf->_nativeSocket, (void *)buffer, sizeof(buffer), 0, (struct sockaddr *)&sa, &fromlen);
        if (recsize < 0) {
            fprintf(stderr, "%s\n", strerror(errno));
            exit(EXIT_FAILURE);
        }
        if ([theDelegate respondsToSelector:@selector(socket:didReadData:)]) {
            [theDelegate socket:strongSelf didReadData:[NSData dataWithBytes:buffer length:recsize]];
        }
        printf("recsize: %lu\n ", recsize);
        usleep(10);
        printf("datagram: %.*s\n", (int)recsize, buffer);
    });
    
}



@end
