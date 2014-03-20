//
//  TweetsManager.h
//  Tubuyagi
//
//  Created by 宮原聡 on 2013/09/24.
//  Copyright (c) 2013年 Genki Ishibashi. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "STTwitter.h"
#import <Social/Social.h>
#import <Accounts/Accounts.h>

extern NSString * const TYApplicationScheme;

NS_ENUM(NSInteger, TYAuthorizeType){
    TYNotAuthorized = 0,
    TYAuthorizediOS,
    TYAuthorizedSafari
};

NS_ENUM(NSInteger, TYTweetQualificationError){
    TYLackingURLInTweet,
    TYLackingUserIDInTweet,
    TYLackingElementsInURL,
    TYLackingTypesOfElementsInURL,
    TYHashDoesntMatch,
    TYiOSTwitterAccessDenied,
    TYiOSNoTwitterAccount
};


@interface TweetsManager : NSObject
{
    @private
    //safariから戻ってきたあとに実行するblock
    void(^successBlockAfterAuthorized)(NSString *username);
    void(^errorBlockAfterAuthorized)(NSError *error);
    
    SLComposeViewController *twitterComposeViewController;
    STTwitterAPI *twitterAPIClient;
    
    NSString *OAuthToken;
    NSString *OAuthTokenSecret;
    
    UIImage *recentScreenShot;
}
@property(readwrite) ACAccount* twitterAccount;
@property(readonly) NSArray *twitterAccounts;
@property(readonly) NSInteger authorizeType;
@property(readwrite) NSString *username;
@property(readonly) NSString *userID;
@property(readonly) BOOL cachedOAuth;
/*
 Twitter認証の管理を行うクラス
 参考: http://blog.himajinworks.net/archives/150
 アカウントページ: https://apps.twitter.com/app/5905926
 */

/* 認証エントリ */
- (void)checkTwitterAccountsWithSuccessBlock:(void(^)(void))successBlock
                                choicesBlock:(void(^)(NSArray *accounts))choicesBlock
                                  errorBlock:(void(^)(NSError *error))errorBlock;

- (void)loginTwitterInSafariWithSuccessBlock:(void(^)(NSString *username))successBlock
                                  errorBlock:(void(^)(NSError *error))errorBlock;

- (void)loginTwitterByCachedTokenWithSuccessBlock:(void(^)(NSString *username))successBlock
                                       errorBlock:(void(^)(NSError *error))errorBlock;

- (void)OAuthWithOAuthToken:(NSString *)token
              OAuthVerifier:(NSString *)verifier;

/* タイムライン取得 */
- (void)checkTimelineWithSuccessBlock:(void(^)(NSArray *statuses))successBlock
                           errorBlock:(void(^)(NSError *error))errorBlock;

/* 投稿 */
- (void)openTweetPostWindowFromViewController:(UIViewController *)viewConttoller
                                      content:(NSString *)content;

- (void)postDirectlyTweet:(NSString *)content
             successBlock:(void(^)(NSDictionary *status))successBlock
               errorBlock:(void(^)(NSError *error))errorBlock;

- (void)takeScreenShot;
@end
