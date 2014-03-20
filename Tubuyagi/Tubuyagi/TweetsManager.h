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

@interface TweetsManager : NSObject
{
    @private
    void(^successBlockAfterAuthorized)(NSString *username);
}
//@property(nonatomic, retain) STTwitterAPI *twitterAPIClient;
@property(nonatomic, retain) SLComposeViewController *twitterComposeViewController;
@property(nonatomic, retain, setter = setTwitterAccount:) ACAccount *twitterAccount;
@property(nonatomic, retain) NSArray *twitterAccounts;
/*
 ツイートの管理を行うクラス
 参考: http://blog.himajinworks.net/archives/150
 アカウントページ: https://apps.twitter.com/app/5905926
 */

#warning 将来的にはこれをインターフェイスにするのではなく、Twitter APIからツイートを取ってくる部分も含めた処理をinterfaceに
/*使い物になるツイートだけ収集する*/
//+(NSMutableArray *)availableTweets:(NSArray *)tweets;

/*ツイートを投稿する*/
NSMutableArray *TYChooseAvailableTweets(NSArray *tweets);

- (void)setTwitterAccountsWithSuccessBlock:(void(^)(NSArray *accounts))successBlock
                                errorBlock:(void(^)(NSError *error))errorBlock;

- (void)checkTimelineWithSuccessBlock:(void(^)(NSArray *statuses))successBlock
                           errorBlock:(void(^)(NSError *error))errorBlock;
//- (void)loginTwitterInSafariWithSuccessBlock:(void(^)(NSString *username))successBlock
//                                  errorBlock:(void(^)(NSError *error))errorBlock;
//- (void)setOAuthToken:(NSString *)token
//        oauthVerifier:(NSString *)verifier
//           errorBlock:(void(^)(NSError *error))errorBlock;


@end
