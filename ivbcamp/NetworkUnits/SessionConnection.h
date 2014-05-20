//
//  SessionConnection.h
//  ivbcamp
//
//  Created by Octavian Stirbei on 5/20/14.
//  Copyright (c) 2014 Octavian Stirbei. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "GCDAsyncSocket.h"

@interface SessionConnection : NSObject

@property (nonatomic) BOOL  connected;
@property (nonatomic, strong, readonly) GCDAsyncSocket *socket;
@property (nonatomic, strong)   NSString *sessionUUID;
@property (nonatomic, strong)   NSString *clientUUID;
@property (nonatomic, readonly, strong) NSString *host;
@property (nonatomic) uint16_t port;
@property (nonatomic, strong) NSMutableArray *rrpcSenders;
@property (nonatomic, strong) NSMutableArray *rrpcReceivers;



+ (SessionConnection*)sharedInstance;

- (void)connectToHost:(NSString *)host onPort:(uint16_t)port error:(NSError **)errPtr;
- (void)disconnect;
- (void)startAudioSession;

@end
