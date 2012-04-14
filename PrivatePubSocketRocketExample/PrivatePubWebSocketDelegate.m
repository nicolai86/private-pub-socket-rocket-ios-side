//
//  PrivatePubWebSocketDelegate.m
//  PrivatePubSocketRocketExample
//
//  Created by Raphael Randschau on 4/14/12.
//  Copyright (c) 2012 Weluse gmbH. All rights reserved.
//

#import "PrivatePubWebSocketDelegate.h"

@interface PrivatePubWebSocketDelegate()
  @property (nonatomic) int messageId;
  @property (nonatomic, retain) SRWebSocket *webSocket;
@end

@implementation PrivatePubWebSocketDelegate

@synthesize clientId = _clientId,
            privatePubSignature = _privatePubToken,
            privatePubTimestamp = _privatePubTimestamp,
            channel = _channel,
            messageId = _messageId,
            webSocket = _webSocket;

#pragma mark - Initializers

- (id) init {
  self = [super init];

  if (self) {
    self.messageId = 1;
    self.privatePubSignature = self.privatePubTimestamp = NULL;
  }

  return self;
}

- (id) initWithPrivatePubTimestamp:(NSString*) aTimestamp andSignature:(NSString*)aSignature andChannel:(NSString *)aChannel {
  self = [self init];

  if (self) {
    self.privatePubTimestamp = aTimestamp;
    self.privatePubSignature = aSignature;
    self.channel = aChannel;
  }

  return self;
}

- (void) disconnect {
  assert(self.webSocket != NULL);

  NSDictionary *disconnect = [NSDictionary dictionaryWithObjectsAndKeys:
    @"/meta/disconnect", @"channel",
    self.clientId, @"clientId",
    [NSNumber numberWithInt:self.messageId++], @"id",
    nil];
  [self.webSocket send: [disconnect JSONRepresentation]];
}

#pragma mark - SRWebSocketDelegate Protocol Methods

- (void) webSocket:(SRWebSocket *)webSocket didReceiveMessage:(NSString *)message {
  NSLog(@"base class, nothing happens!");
}

- (void)webSocket:(SRWebSocket *)webSocket didFailWithError:(NSError *)error {
  NSLog(@"WebSocket did fail: %@", error);
}

- (void)webSocket:(SRWebSocket *)webSocket didCloseWithCode:(NSInteger)code reason:(NSString *)reason wasClean:(BOOL)wasClean {
  NSLog(@"WebSocket did close: %@ (%d)", reason, code);
}

- (void)webSocketDidOpen:(SRWebSocket *)webSocket {
  NSLog(@"WebSocket is open");

  NSDictionary *handshake = [NSDictionary dictionaryWithObjectsAndKeys:
    @"/meta/handshake", @"channel",
    [NSNumber numberWithFloat:1.0], @"version",
    [NSArray arrayWithObjects:@"websocket", nil], @"supportedConnectionTypes",
    [NSNumber numberWithInt:self.messageId++], @"id",
    nil];

  isa = [AwaitingHandshakeState class];

  [webSocket send:[handshake JSONRepresentation]];
}

@end  

///
//
///

@implementation AwaitingHandshakeState

  - (void) webSocket:(SRWebSocket *)webSocket didReceiveMessage:(NSString *)message {
    id JSON = [[message JSONValue] objectAtIndex:0];

    NSString *channel = [JSON valueForKeyPath:@"channel"];
    if ([channel isEqualToString:@"/meta/handshake"]) {
      Boolean handshakeWasSuccessful = [[JSON valueForKeyPath:@"successful"] boolValue];

      if (handshakeWasSuccessful) {
        self.clientId = [JSON valueForKeyPath:@"clientId"];
        NSLog(@"handhshake received: set client id to %@", self.clientId);

        self.webSocket = webSocket;

        isa = [SubscriptionState class];

        [(SubscriptionState *)self sendSubscriptions];
      }
    }
  }

@end 

///
//
///

@implementation SubscriptionState

  - (void) sendSubscriptions {
    NSDictionary *ext = [NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:self.privatePubTimestamp, self.privatePubSignature, nil] forKeys:[NSArray arrayWithObjects:@"private_pub_timestamp", @"private_pub_signature", nil]];

    NSDictionary *subscription = [NSDictionary dictionaryWithObjectsAndKeys:
          @"/meta/subscribe", @"channel",
          self.clientId, @"clientId",
          self.channel, @"subscription",
          [NSNumber numberWithInt:self.messageId++], @"id",
          ext, @"ext",
        nil];

    [self.webSocket send:[subscription JSONRepresentation] ];
  }

  - (void) webSocket:(SRWebSocket *)webSocket didReceiveMessage:(NSString *)message {
    id JSON = [[message JSONValue] objectAtIndex:0];
    NSLog(@"recv subscription %@", JSON);

    Boolean subscriptionWasSuccessful = [[JSON valueForKeyPath:@"successful"] boolValue];
    if (subscriptionWasSuccessful) {
      NSLog(@"Now subscribed to %@", self.channel);

      isa = [KeepAliveState class];

      [(KeepAliveState *)self setupKeepAlive];
    }
  }

@end

///
//
///

@interface KeepAliveState()
    @property (nonatomic) int timeout;

    - (void) sendKeepAlive;
@end

@implementation KeepAliveState

  @synthesize timeout = _timeout;

  #pragma mark - Private Methods

  - (void) sendKeepAlive {
    sleep(self.timeout);

    NSLog(@"executing keep alive");

    NSDictionary *keepAlive = [NSDictionary dictionaryWithObjectsAndKeys:
      self.clientId, @"clientId",
      @"/meta/connect", @"channel",
      @"websocket", @"connectionType",
      [NSNumber numberWithInt:self.messageId++], @"id",
      nil];
    [self.webSocket send: [keepAlive JSONRepresentation]];

    [NSThread detachNewThreadSelector:@selector(sendKeepAlive) toTarget:self withObject:nil];
  }

  #pragma mark - Public Methods

  - (void) setupKeepAlive {
    self.timeout = 10;

    // self.timeout = [[JSON valueForKeyPath:@"advice.timeout"] intValue];

    UIDevice* device = [UIDevice currentDevice];
    BOOL backgroundSupported = NO;
    if ([device respondsToSelector:@selector(isMultitaskingSupported)]) {
      backgroundSupported = device.multitaskingSupported;
    }

    if (backgroundSupported) {
      [NSThread detachNewThreadSelector:@selector(sendKeepAlive) toTarget:self withObject:nil];
    }
  }

  #pragma mark - SRWebSocketDelegate Protocol Methods

  - (void) webSocket:(SRWebSocket *)webSocket didReceiveMessage:(NSString *)message {
    NSLog(@"OfferWebSocketClient: %@", message);
  }

@end