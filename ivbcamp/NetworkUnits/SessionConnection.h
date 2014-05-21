//
//  SessionConnection.h
//  ivbcamp
//
//  Created by Octavian Stirbei on 5/20/14.
//  Copyright (c) 2014 Octavian Stirbei. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "GCDAsyncSocket.h"

@interface SessionConnection : NSObject {
    
    NSData  *sendTmpBuffer; //release after write on socket;
    
}

@property (nonatomic) BOOL  connected;
@property (nonatomic, retain, readonly) GCDAsyncSocket *socket;
@property (nonatomic, retain)   NSString *sessionUUID;
@property (nonatomic, retain)   NSString *clientUUID;
@property (nonatomic, readonly, retain) NSString *host;
@property (nonatomic) uint16_t port;
@property (nonatomic, retain) NSMutableArray *rrpcSenders;
@property (nonatomic, retain) NSMutableArray *rrpcReceivers;



+ (SessionConnection*)sharedInstance;

- (void)connectToHost:(NSString *)host onPort:(uint16_t)port error:(NSError **)errPtr;
- (void)disconnect;
- (void)startAudioSession;

@end
