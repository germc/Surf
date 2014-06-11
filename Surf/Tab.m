//
//  Tab.m
//  Surf
//
//  Created by Sapan Bhuta on 5/30/14.
//  Copyright (c) 2014 SapanBhuta. All rights reserved.
//

#import "Tab.h"

@implementation Tab

- (id)init
{
    self = [super init];
    self.webView = [UIWebView new];
    self.urls = [NSMutableArray new];
    self.screenshots = [NSMutableArray new];
    [self.urls addObject:@"https://www.google.com"];
    [self.screenshots addObject:[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"back.png"]]];
    self.currentImageIndex = 0;

    return self;
}

@end
