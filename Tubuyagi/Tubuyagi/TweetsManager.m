//
//  TweetsManager.m
//  Tubuyagi
//
//  Created by 宮原聡 on 2013/09/24.
//  Copyright (c) 2013年 Genki Ishibashi. All rights reserved.
//

#import "TweetsManager.h"

#import "NSString+SHA.h"
#import "AuthentificationKeys.h"
// AuthentificationKeysはgitの管理外にあります。ほしい人は kan.tan.san @ gmail.com まで

@implementation TweetsManager

NSString * const TYApplicationDomain = @"I.GA.Tsubuyagi";
NSString * const TYApplicationURI = @"https://github.com/miya-s/Tubuyagi";
NSString * const TYApplicationHashTag = @"つぶやぎ";

NS_ENUM(NSInteger, TYTweetQualificationError){
    TYLackingURLInTweet,
    TYLackingUserIDInTweet,
    TYLackingElementsInURL,
    TYLackingTypesOfElementsInURL,
    TYHashDoesntMatch
};

/*
 ツイートの管理を行うクラス
 
 主な機能:
 ・ツイートの取得
 　・学習に食わせる用ツイート
 　・ランキングのツイート
     ・ツイートの判定
 ・ツイートの投稿
 
 
 TODO　クラス関数じゃなくていいよね
 */

#warning    もしかしたら、screen_nameの大文字小文字の違いとかが変な影響を及ぼすかもしれない


/*************************
    ツイート投稿機能関係
 **************************/

/* ハッシュ化
 ハッシュ化する際は、投稿者の情報も必要 bacause ユーザー情報をハッシュの種にしないと、パクツイできてしまう
    ユーザ情報はTwitterのユーザーIDにする because アプリIDだとコピペ予防にならない
    注意！！idは使わない、id_strを使う because idは桁落ちする可能性がある
    TweetにもUserにもid_str属性があるので混同しないように。
 */
NSString *TYMakeHashFromTweet(NSString *tweet, NSString*twitterID){
    NSString *seed=[twitterID stringByAppendingString:tweet];
    NSString *hash =[seed SHAStringForAuth];
    return hash;
}

/*
 URL形式へのエンコード・デコード
 
 参考にしたサイト：
 http://csfun.blog49.fc2.com/blog-entry-126.html
 http://blog.daisukeyamashita.com/post/1686.html
 */
NSString *TYEncodeString(NSString *plainString){
    NSString *encodedText = (__bridge_transfer NSString *)CFURLCreateStringByAddingPercentEscapes(
                                                                                NULL,
                                                                                (__bridge CFStringRef)plainString,
                                                                                NULL,
                                                                                CFSTR("!*'();:@&=+$,/?%#[]"),
                                                                                CFStringConvertNSStringEncodingToEncoding(NSUTF8StringEncoding));
    return encodedText;
}

NSString *TYDecodeString(NSString *encodedString){
    NSString *decodedText = (__bridge_transfer NSString *)CFURLCreateStringByReplacingPercentEscapesUsingEncoding(
                                                                               NULL,
                                                                               (__bridge CFStringRef)encodedString,
                                                                               CFSTR(""),
                                                                               kCFStringEncodingUTF8);
    return decodedText;
}

/*
 　投稿用のツイートを作成する

　ツイートの構成：
 　url, ハッシュタグ, 画像url
 */

NSString *TYMakeTweet(NSString *content){

    NSString *hash = TYMakeHashFromTweet(content, TYMyTwitterID());
    NSString *yagiNameEncoded = TYEncodeString(TYMyYagiName());
    NSString *contentEncoded = TYEncodeString(content);

    NSString *tweet = [NSString stringWithFormat:@"%@?auth=%@&yaginame=%@&content=%@ #%@",
                                                  TYApplicationURI,
                                        hash,
                                        yagiNameEncoded,
                                        contentEncoded,
                                        TYApplicationHashTag];
    return tweet;
}

NSString *TYMyYagiName(void){
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    NSString *yagiName = [ud stringForKey: @"TDYagiName"];
    NSCAssert(yagiName, @"yagi name がTDYaginameに設定されていない");
    return yagiName;
}

NSString *TYMyTwitterID(void){
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    NSString *myId = [ud stringForKey: @"TDUserTwitterID"];
    NSCAssert(myId, @"Twitter IDがTDUserTwitterIDに設定されていない");
    return myId;
}

/*
 そのツイートの|hash|が正規のものかをチェック
 */
BOOL TYCheckHash(NSString *hash, NSString*content, NSString *twitterID){
    NSString *new_hash = TYMakeHashFromTweet(content, twitterID);
    NSCAssert(new_hash, @"ハッシュ生成失敗");
    NSCAssert(hash, @"ハッシュ取得失敗");
    NSCAssert(twitterID, @"twitter ID 取得失敗");
    return [new_hash isEqualToString:hash];
}

/* urlに記述されたヴァリデーション用の情報などを獲得する */
NSDictionary *TYExtractElementsFromURL(NSString *url, NSError **error){
    NSMutableDictionary *extractedElements = [NSMutableDictionary dictionaryWithDictionary:@{}];

    /*urlの?以降*/
    NSError *metaInfoError = nil;
    NSRegularExpression *regexpForURL = [NSRegularExpression regularExpressionWithPattern:@".*\\?(.*)" options:0 error:&metaInfoError];
    NSTextCheckingResult *matchInURL =[regexpForURL firstMatchInString:url options:0 range:NSMakeRange(0, url.length)];
    if (metaInfoError || matchInURL.numberOfRanges <= 0){
        if (error){
            *error = [NSError errorWithDomain:TYApplicationDomain
                                         code:TYLackingElementsInURL
                                     userInfo:@{NSLocalizedDescriptionKey: @"Lacking Elements in URL Or Invalid Regexp"}];
        }

        return nil;
    }
    
    NSString *metaInfo = [url substringWithRange:[matchInURL rangeAtIndex:1]];
    NSArray *elementsWithKey = [metaInfo componentsSeparatedByString:@"&"];
    if ([elementsWithKey count] <= 2){
        if (error){
            *error = [NSError errorWithDomain:TYApplicationDomain
                                         code:TYLackingElementsInURL
                                     userInfo:@{NSLocalizedDescriptionKey: @"Lacking Elements in URL"}];
        }
        
        return nil;
    }

    for (NSString *element in elementsWithKey){
        NSArray *pairForKeyAndElement = [element componentsSeparatedByString:@"="];
        if ([pairForKeyAndElement count] <= 1){
            if (error){
                *error = [NSError errorWithDomain:TYApplicationDomain
                                             code:TYLackingElementsInURL
                                         userInfo:@{NSLocalizedDescriptionKey: @"lacking elements in URL"}];
            }
            return nil;
        }
        [extractedElements setObject:TYDecodeString(pairForKeyAndElement[1]) forKey:pairForKeyAndElement[0]];
    }
    
    NSArray *requiredKeys = @[@"auth", @"yaginame", @"content"];
    for (NSString *requiredKey in requiredKeys){
        if (![extractedElements objectForKey:requiredKey]){
            if (error){
                *error = [NSError errorWithDomain:TYApplicationDomain
                                             code:TYLackingTypesOfElementsInURL
                                         userInfo:@{NSLocalizedDescriptionKey: @"Lacking Types of Elements in URL"}];
            }
            
            return nil;
        }
        
    }
    return extractedElements;
}

/*適切な情報を含んだ|tweet|かどうかを判定する*/
BOOL TYTweetIsQualified(NSDictionary *tweet, NSError** error){
    /*urlが含まれているか*/
    if ([[[tweet objectForKey:@"entities"] objectForKey:@"urls"] count] <= 0){
        if (error){
            *error = [NSError errorWithDomain:TYApplicationDomain
                                         code:TYLackingURLInTweet
                                     userInfo:@{NSLocalizedDescriptionKey: @"No URL In Tweet"}];
        }
        return NO;
    }
    
    
    NSString *url = [[[[tweet objectForKey:@"entities"] objectForKey:@"urls"] objectAtIndex:0] objectForKey:@"expanded_url"];
    
    /* id_str情報が含まれているか */
    if (![[tweet objectForKey:@"user"] objectForKey:@"id_str"]){
        if (error){
            *error = [NSError errorWithDomain:TYApplicationDomain
                                         code:TYLackingUserIDInTweet
                                     userInfo:@{NSLocalizedDescriptionKey: @"No UserUD In Tweet"}];
        }
        return NO;
    }
    NSString* userID = (NSString *)[[tweet objectForKey:@"user"] objectForKey:@"id_str"];
    
    /* url内にヴァリデーション用の情報が含まれているか */
    NSError *errorForExtraction = nil;
    NSDictionary *elementsInURL = TYExtractElementsFromURL(url, &errorForExtraction);
    if (errorForExtraction){
        *error = errorForExtraction;
        return NO;
    }
    
    /* Hashの整合性チェック */
    BOOL qualifyTweet = TYCheckHash([elementsInURL objectForKey:@"auth"],
                                    [elementsInURL objectForKey:@"content"],
                                    userID);
    if (!qualifyTweet){
        if (error){
            *error = [NSError errorWithDomain:TYApplicationDomain
                                         code:TYHashDoesntMatch
                                     userInfo:@{NSLocalizedDescriptionKey: @"Hash doesn't match"}];
        }
        return NO;
    }
    return YES;
}

/*
    正規のツイートだけ持ってくる
 */
NSMutableArray *TYChooseAvailableTweets(NSArray *tweets){
    NSMutableArray *availableTweets = [NSMutableArray array];
    for (NSDictionary *tweet in tweets){
        NSError *error = nil;
        if(TYTweetIsQualified(tweet, &error)) {
            [availableTweets addObject:tweet];
        }
        NSCAssert(!error, [error localizedDescription]);
    }
    return availableTweets;
}



/***************************
 API インターフェイス
 **************************/

/*ツイート投稿*/
- (void)postTweet:(NSString *)content
    successBlock:(void(^)(NSDictionary *status))successBlock
      errorBlock:(void(^)(NSError *error))errorBlock{
    
    NSString *tweetContent = TYMakeTweet(content);
    
    [_twitterAPIClient postStatusUpdate:tweetContent
                     inReplyToStatusID:nil
                              latitude:nil
                             longitude:nil
                               placeID:nil
                    displayCoordinates:nil
                              trimUser:nil
                          successBlock:successBlock
                            errorBlock:errorBlock];
    
}

/*
 OAuthTokenを前回起動時に取得したか否か
 */
- (BOOL)getOAuthToken:(NSString **)OAuthAccessToken
     OAuthTokenSecret:(NSString **)OAuthAccessTokenSecret
{
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    NSString * existOAuthAccessToken = [ud stringForKey: @"TDOAuthAccessToken"];
    NSString * existOAuthAccessTokenSecret = [ud stringForKey: @"TDOAuthAccessTokenSecret"];
    if (existOAuthAccessToken && existOAuthAccessTokenSecret){
        *OAuthAccessToken = existOAuthAccessToken;
        *OAuthAccessTokenSecret = existOAuthAccessTokenSecret;
        return YES;
    }
    return NO;
}

/*
 OAuthTokenを次回起動時も使えるように保持する
 */
- (void)setOAuthToken:(NSString *)OAuthAccessToken
     OAuthTokenSecret:(NSString *)OAuthAccessTokenSecret
{
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    [ud setObject:OAuthAccessToken forKey: @"TDOAuthAccessToken"];
    [ud setObject:OAuthAccessTokenSecret forKey: @"TDOAuthAccessTokenSecret"];
    [ud synchronize];
}

/*
 Twitterログイン（iOSの一番上に登録されているもの）
 ログインが保証できなくてトラブルの元になることを想定して今回は使用しない
 */
- (void)loginTwitterWithiOSWithSuccessBlock:(void(^)(NSString *username))successBlock
                                 errorBlock:(void(^)(NSError *error))errorBlock{
    
    self.twitterAPIClient = [STTwitterAPI twitterAPIOSWithFirstAccount];
    
    [_twitterAPIClient verifyCredentialsWithSuccessBlock:successBlock
                                             errorBlock:errorBlock];
    
}

/*
 Safari経由でAccessTokenを取得してAPI権限を得る
 */
- (void)loginTwitterInSafariWithSuccessBlock:(void(^)(NSString *username))successBlock
                                  errorBlock:(void(^)(NSError *error))errorBlock{


    NSString *OAuthToken;
    NSString *OAuthTokenSecret;
    if ([self getOAuthToken:&OAuthToken OAuthTokenSecret:&OAuthTokenSecret]){
        /*もしすでにTokenを得ていたら*/
        self.twitterAPIClient = [STTwitterAPI twitterAPIWithOAuthConsumerKey:TYConsumerKey
                                                         consumerSecret:TYConsumerSecret
                                                             oauthToken:OAuthToken
                                                       oauthTokenSecret:OAuthTokenSecret];
        
        [_twitterAPIClient verifyCredentialsWithSuccessBlock:successBlock
                                                 errorBlock:errorBlock];
    
    } else {
        /*まだTokenを得ていなかったら*/
        self.twitterAPIClient = [STTwitterAPI twitterAPIWithOAuthConsumerKey:TYConsumerKey
                                                         consumerSecret:TYConsumerSecret];
        
        [_twitterAPIClient postTokenRequest: ^(NSURL *url, NSString *oauthToken) {
            successBlockAfterAuthorized = successBlock;
            
            [[UIApplication sharedApplication] openURL:url];
        }
                                forceLogin:@(YES)
                                screenName:nil
                             oauthCallback:@"tsubuyagi://twitter_access_tokens/"
                                errorBlock:errorBlock];
    }
}

/*
 もらってきたTokenを保存し、successBlockを実行
 */
- (void)setOAuthToken:(NSString *)token
        oauthVerifier:(NSString *)verifier
           errorBlock:(void(^)(NSError *error))errorBlock
{
    [_twitterAPIClient postAccessTokenRequestWithPIN:verifier
                                       successBlock:^(NSString *oauthToken, NSString *oauthTokenSecret, NSString *userID, NSString *screenName) {

                                           [self setOAuthToken:_twitterAPIClient.oauthAccessToken
                                              OAuthTokenSecret:_twitterAPIClient.oauthAccessTokenSecret];

                                           successBlockAfterAuthorized(screenName);
        
    } errorBlock:errorBlock];
}

@end
