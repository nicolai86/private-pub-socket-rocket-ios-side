//
//  RRAViewController.m
//  PrivatePubSocketRocketExample
//
//  Created by Raphael Randschau on 4/14/12.
//  Copyright (c) 2012 Weluse gmbH. All rights reserved.
//

#import "RRAViewController.h"

@interface RRAViewController ()
  @property (nonatomic, retain) SRWebSocket *websocketClient;
@property (nonatomic, retain) OffersWebSocketClient* websocketDelegate;
@end

@implementation RRAViewController
@synthesize websocketClient = _websocketClient, websocketDelegate = _websocketDelegate;

- (void)viewDidLoad {
  [super viewDidLoad];
  
  NSString *resourceUrl = [NSString stringWithFormat:@"http://localhost:3000/api/websockets/configuration.json?channel=%@", @"/messages/new"];
  NSURL *url = [NSURL URLWithString:resourceUrl];
  NSURLRequest *request = [NSURLRequest requestWithURL:url];

  AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request 
    success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON){
      self.websocketDelegate = [[PrivatePubWebSocketDelegate alloc] initWithPrivatePubTimestamp:[NSString stringWithFormat:@"%@", [JSON valueForKeyPath:@"timestamp"]] andSignature:[NSString stringWithFormat:@"%@", [JSON valueForKeyPath:@"signature"]] andChannel:@"/messages/new"];
  
  NSLog(@"%@", JSON);
  
  NSString *server = [JSON valueForKeyPath:@"server"];
  NSURL *url = [NSURL URLWithString:server];
  NSMutableURLRequest *configurationRequest = [NSMutableURLRequest requestWithURL:url];
    
  self.websocketClient = [[SRWebSocket alloc] initWithURLRequest:configurationRequest];
  self.websocketClient.delegate = self.websocketDelegate;
    
  [self.websocketClient open];
    } 
    failure:^(NSURLRequest* request, NSHTTPURLResponse* response, NSError* error, id JSON) {
      // TODO
      NSLog(@"request was failed: %@", error);
    }
  ];

  [operation start];
	// Do any additional setup after loading the view, typically from a nib.
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
  return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

@end
