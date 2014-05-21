//
//  RRpcSocket.h
//  ivbcamp
//
//  Created by Octavian Stirbei on 5/20/14.
//  Copyright (c) 2014 Octavian Stirbei. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "GCDAsyncSocket.h"

@interface RRpcSocket : NSObject {
    NSData  *sendTmpBuffer; //release after write on socket;    
}

@property(nonatomic) BOOL receiver;
@property (nonatomic, strong, readonly) GCDAsyncSocket *socket;

-(void)send:(NSDictionary *)jsonDictionary;

@end
