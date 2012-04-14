//
//  PrivatePubWebSocketDelegate.h
//  PrivatePubSocketRocketExample
//
//  Created by Raphael Randschau on 4/14/12.
//  Copyright (c) 2012 Weluse gmbH. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "SRWebSocket.h"
#import "SBJson.h"

@interface PrivatePubWebSocketDelegate : NSObject <SRWebSocketDelegate>

  @property (nonatomic, retain) NSString *clientId;
  @property (nonatomic, retain) NSString *privatePubTimestamp;
  @property (nonatomic, retain) NSString *privatePubSignature;
  @property (nonatomic, retain) NSString *channel;

  - (id) initWithPrivatePubTimestamp:(NSString*) aTimestamp andSignature:(NSString*)aSignature andChannel: (NSString*) aChannel;
  - (id) init;
  - (void) disconnect;

@end 

@interface AwaitingHandshakeState : PrivatePubWebSocketDelegate
@end

@interface SubscriptionState : PrivatePubWebSocketDelegate

  - (void) sendSubscriptions;

@end

@interface KeepAliveState : PrivatePubWebSocketDelegate

  - (void) setupKeepAlive;

@end