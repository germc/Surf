//
//  Facebook.m
//  Surf
//
//  Created by Sapan Bhuta on 6/18/14.
//  Copyright (c) 2014 SapanBhuta. All rights reserved.
//

#import "Facebook.h"
#import <Social/Social.h>
#import <Accounts/Accounts.h>

@interface Facebook ()
@property NSDictionary *dataSource;
@property NSArray *posts;
@end

@implementation Facebook

- (void)getData
{
    NSLog(@"Facebook");

    ACAccountStore *accountStore = [[ACAccountStore alloc] init];
    ACAccountType *accountTypeFacebook = [accountStore accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierFacebook];
    NSDictionary *options = @{ACFacebookAppIdKey: @"324779421012185",
                              ACFacebookPermissionsKey: @[@"email",@"read_stream"],
                              ACFacebookAudienceKey: ACFacebookAudienceFriends};

    [accountStore requestAccessToAccountsWithType:accountTypeFacebook options:options completion:^(BOOL granted, NSError *error)
     {
         if(granted)
         {
             NSArray *accounts = [accountStore accountsWithAccountType:accountTypeFacebook];
             ACAccount *facebookAccount = accounts.lastObject;
             NSDictionary *parameters = @{@"access_token":facebookAccount.credential.oauthToken};

             NSURL *feedURL = [NSURL URLWithString:@"https://graph.facebook.com/v2.0/me/home"];
             SLRequest *feedRequest = [SLRequest requestForServiceType:SLServiceTypeFacebook
                                                         requestMethod:SLRequestMethodGET
                                                                   URL:feedURL
                                                            parameters:parameters];

             [feedRequest performRequestWithHandler:^(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *error)
              {
                  if (!error)
                  {
                      self.dataSource = [NSJSONSerialization JSONObjectWithData:responseData
                                                                        options:NSJSONReadingMutableLeaves
                                                                          error:&error];
                      if (!error)
                      {
                          self.posts = self.dataSource[@"data"];

                          if (self.posts.count != 0)
                          {
                              dispatch_async(dispatch_get_main_queue(), ^{
                                  [[NSNotificationCenter defaultCenter] postNotificationName:@"Facebook" object:self.posts];
                              });
                          }
                      }
                      else
                      {
                          NSLog(@"Error understanding api data: %@", error);
                      }
                  }
                  else
                  {
                      NSLog(@"Request failed, %@", [urlResponse description]);
                  }
              }];
         }
         else
         {
             NSLog(@"Access Denied");
             NSLog(@"[%@]",[error localizedDescription]);
         }
     }];
}

+ (NSDictionary *)layoutFrom:(NSDictionary *)post
{
    NSLog(@"%@",post);

    NSString *textLabel;
    NSString *detailTextLabel;
    NSNumber *numberOfLines = @0;
    NSString *imgUrlString;

    if (post[@"story"])
    {
        textLabel = post[@"story"];
    }
    else if (post[@"message"])
    {
        textLabel = post[@"message"];
    }
    else
    {
        textLabel = @"facebook";
    }

    if (post[@"from"][@"name"])
    {
        detailTextLabel = post[@"from"][@"name"];
    }
    else
    {
        detailTextLabel = @"facebook";
    }

    if (post[@"picture"])
    {
        imgUrlString = post[@"picture"];
    }
    else
    {
        imgUrlString = @"facebook";
    }

    NSLog(@"textLabel %@", textLabel);
    NSLog(@"detailTextLabel %@",detailTextLabel);
    NSLog(@"imgUrlString %@",imgUrlString);

    return @{@"textLabel":textLabel,
             @"detailTextLabel":detailTextLabel,
             @"numberOfLines":numberOfLines,
             @"imgUrlString":imgUrlString};
}

+ (NSString *)selected:(NSDictionary *)post
{
    return post[@"action"][0][@"link"];
}

+ (CGFloat)height:(NSDictionary *)post
{
    return 120;
}
@end
