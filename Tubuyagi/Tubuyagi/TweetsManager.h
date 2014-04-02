//
//  TweetsManager.h
//  Tubuyagi
//
//  Created by 宮原聡 on 2013/09/24.
//  Copyright (c) 2013年 Genki Ishibashi. All rights reserved.
//

#import <Foundation/Foundation.h>


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

@class TweetsManager;
@class SLComposeViewController;
@class STTwitterAPI;
@class ACAccount;

@interface TweetsManager : NSObject

@property(readwrite) ACAccount* twitterAccount;
@property(readonly) NSArray *twitterAccounts;
@property(readonly) NSInteger authorizeType;
@property(readonly) NSString *username;
@property(readonly) NSString *userID;
@property(readonly) BOOL cachedOAuth;
@property(readonly) NSInteger totalFavoritedCount;

/*
 Twitter認証の管理を行うクラス
 参考: http://blog.himajinworks.net/archives/150
 アカウントページ: https://apps.twitter.com/app/5905926
 */

+ (TweetsManager *)tweetsManagerFactory;

#pragma mark 認証エントリ
- (void)checkTwitterAccountsWithSuccessBlock:(void(^)(void))successBlock
                                choicesBlock:(void(^)(NSArray *accounts))choicesBlock
                                  errorBlock:(void(^)(NSError *error))errorBlock;

- (void)loginTwitterInSafariWithSuccessBlock:(void(^)(NSString *username))successBlock
                                  errorBlock:(void(^)(NSError *error))errorBlock;

- (void)loginTwitterByCachedTokenWithSuccessBlock:(void(^)(NSString *username))successBlock
                                       errorBlock:(void(^)(NSError *error))errorBlock;

- (void)OAuthWithOAuthToken:(NSString *)token
              OAuthVerifier:(NSString *)verifier;

#pragma mark 学習用ツイート取得
- (void)checkTweetsToTrainWithSuccessBlock:(void(^)(NSArray *statuses))successBlock
                                errorBlock:(void(^)(NSError *error))errorBlock;

#pragma mark 検索結果取得
- (void)checkSearchResultForRecent:(BOOL)isRecent
                      SuccessBlock:(void(^)(NSArray *statuses))successBlock
                        errorBlock:(void(^)(NSError *error))errorBlock;

#pragma mark お気に入り追加
- (void)addFavoriteToStatusID:(NSString *)statusID
                 successBlock:(void(^)(NSDictionary *status))successBlock
                   errorBlock:(void(^)(NSError *error))errorBlock;


- (void)checkFavoritedWithSuccessBlock:(void(^)(void))successBlock
                            errorBlock:(void(^)(NSError *error))errorBlock;

#pragma mark 投稿

- (void)postTweet:(NSString *)content
       screenshot:(UIImage *)screenshot
     successBlock:(void(^)(NSDictionary *status))successBlock
       errorBlock:(void(^)(NSError *error))errorBlock;


                    

@end
