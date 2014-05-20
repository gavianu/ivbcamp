//
//  RRpcSocket.h
//  ivbcamp
//
//  Created by Octavian Stirbei on 5/20/14.
//  Copyright (c) 2014 Octavian Stirbei. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "GCDAsyncSocket.h"

@interface RRpcSocket : NSObject

@property(nonatomic) BOOL receiver;
@property (nonatomic, strong, readonly) GCDAsyncSocket *socket;

- (void)connect;

@end
