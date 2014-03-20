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
#import <CoreGraphics/CoreGraphics.h>
#import <QuartzCore/QuartzCore.h>


@implementation TweetsManager

NSString * const TYApplicationDomain = @"I.GA.Tsubuyagi";
NSString * const TYApplicationURI = @"https://github.com/miya-s/Tubuyagi";
NSString * const TYApplicationHashTag = @"つぶやぎ";

NS_ENUM(NSInteger, TYTweetQualificationError){
    TYLackingURLInTweet,
    TYLackingUserIDInTweet,
    TYLackingElementsInURL,
    TYLackingTypesOfElementsInURL,
    TYHashDoesntMatch,
    TYiOSTwitterAccessDenied,
    TYiOSNoTwitterAccount
};

/*
 ツイートの管理を行うクラス
 
 主な機能:
 ・ツイートの取得
 　・学習に食わせる用ツイート
 　・ランキングのツイート
     ・ツイートの判定
 ・ツイートの投稿
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

NSString *TYMyYagiName(void){
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    NSString *yagiName = [ud stringForKey: @"TDYagiName"];
    NSCAssert(yagiName, @"yagi name がTDYaginameに設定されていない");
    return yagiName;
}

-(NSString *)myTwitterID{
    NSString *myId = [_twitterAccount valueForKeyPath:@"properties.user_id"];
    NSCAssert(myId, @"Twitter IDが設定されていない");
    return myId;
}

/*
 投稿用スクリーンショットを撮る
 TODO ここに書くべきではないかも、ただViewControllerがカオスになってるのでいじりたくない
 参考 : http://www.yoheim.net/blog.php?q=20130706
 */
UIImage* TYTakeScreenShot(void){
    // キャプチャ対象をWindowに
    UIWindow *window = [[UIApplication sharedApplication] keyWindow];
    
    // キャプチャ画像を描画する対象を生成
    UIGraphicsBeginImageContextWithOptions(window.bounds.size, NO, 0.0f);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    // Windowの現在の表示内容を１つずつ描画
    for (UIWindow *aWindow in [[UIApplication sharedApplication] windows]) {
        [aWindow.layer renderInContext:context];
    }
    
    // 描画した内容をUIImageとして受け取る
    UIImage *capturedImage = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    return capturedImage;
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
        [extractedElements setObject:TYDecodeString([pairForKeyAndElement objectAtIndex:1])
                              forKey:[pairForKeyAndElement objectAtIndex:0]];
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


/*************************
     Twitter API 認証
 ************************/
- (void)setTwitterAccountsWithSuccessBlock:(void(^)(NSArray *accounts))successBlock
                                errorBlock:(void(^)(NSError *error))errorBlock{
	ACAccountStore *accountStore = [[ACAccountStore alloc] init];
    
    if ([SLComposeViewController isAvailableForServiceType:SLServiceTypeTwitter]) {
        //Twitterアカウントにアクセスできた場合
        ACAccountType *accountType;
        accountType = [accountStore accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierTwitter];
        //アカウント一覧を取得
        [accountStore
         requestAccessToAccountsWithType:accountType
         options:nil
         completion:^(BOOL granted, NSError *error) {
             if (error){
                 errorBlock(error);
                 return;
             }

             NSArray *accountArray = [accountStore accountsWithAccountType:accountType];
             if (!granted || accountArray.count == 0){
                 //注意！simulatorでは常にgrantedがtrueになってしまう
                 //Twitterアクセスが拒否された場合
                 NSError *error =[NSError errorWithDomain:TYApplicationDomain
                                                     code:TYiOSNoTwitterAccount
                                                 userInfo:@{NSLocalizedDescriptionKey: @"Twitter account is not set in iOS"}];
                 errorBlock(error);
                 return;
             }
             self.twitterAccounts = accountArray;

             //もし、すでにアカウントが設定されていたら
             NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
             NSString *identifier = [ud objectForKey:@"TDSelectedAccountIdentifier"];
             ACAccount *oldAccount = [accountStore accountWithIdentifier:identifier];
             if (oldAccount){
                 self.twitterAccount = oldAccount;
             } else {
                 //そうでなければ、一番上のアカウントで決め打ち
                 self.twitterAccount = [accountArray objectAtIndex:0];
             }
             successBlock(accountArray);
         }];
    } else {
        //Twitterアクセスが拒否された場合
        SLComposeViewController *ctrl = [[SLComposeViewController alloc] init];
        if ([ctrl respondsToSelector:@selector(alertView:clickedButtonAtIndex:)]) {
            // Manually invoke the alert view button handler
            [(id <UIAlertViewDelegate>)ctrl alertView:nil
                                 clickedButtonAtIndex:0];
        }
        NSError *error =[NSError errorWithDomain:TYApplicationDomain
                                            code:TYiOSTwitterAccessDenied
                                        userInfo:@{NSLocalizedDescriptionKey: @"Twitter account access has denied"}];
        errorBlock(error);
    }
}

//twitterAccountのセッタ。一度設定したアカウントを保持
- (void)setTwitterAccount:(ACAccount *)twitterAccount{
    _twitterAccount = twitterAccount;
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    [ud setObject:twitterAccount.identifier forKey:@"TDSelectedAccountIdentifier"];
    [ud synchronize];
}

//タイムライン取得
//参考: http://qiita.com/paming/items/9a6b51fa56915d1f1d64
- (void)checkTimelineWithSuccessBlock:(void(^)(NSArray *statuses))successBlock
                           errorBlock:(void(^)(NSError *error))errorBlock;
{
    // make request
    NSURL *url = [NSURL URLWithString:@"https://api.twitter.com/1.1/statuses/home_timeline.json"];
    NSDictionary *params = @{@"exclude_replies" : @"1",
                             @"trim_user" : @"0",
                             @"include_entities" : @"0",
                             @"contributor_details" : @"0",
                             @"count" : @"20"};
    SLRequest *request =
        [SLRequest requestForServiceType:SLServiceTypeTwitter
                           requestMethod:SLRequestMethodGET
                                     URL:url
                              parameters:params];
    
    //  Attach an account to the request
    [request setAccount:self.twitterAccount];
    
    //  Execute the request
    [request performRequestWithHandler:^(NSData *responseData,
                                         NSHTTPURLResponse *urlResponse,
                                         NSError *error) {
        if (responseData) {
            if (urlResponse.statusCode >= 200 && urlResponse.statusCode < 300) {
                NSError *jsonError;
                NSArray *timelineData =
                    [NSJSONSerialization
                     JSONObjectWithData:responseData
                     options:NSJSONReadingAllowFragments error:&jsonError];
                if (timelineData) {
                    successBlock(timelineData);
                } else {
                    // Our JSON deserialization went awry
                    NSLog(@"JSON Error: %@", [jsonError localizedDescription]);
                    errorBlock(jsonError);
                }
            } else {
                // The server did not respond successfully... were we rate-limited?
                NSLog(@"The response status code is %d", urlResponse.statusCode);
                errorBlock(error);
            }
        }
    }];
}

// 　投稿ヴァリデーション用のURLを作成する
- (NSString *)makeTweetURLWithContent:(NSString *)content{
    NSString *hash = TYMakeHashFromTweet(content, [self myTwitterID]);
    NSString *yagiNameEncoded = TYEncodeString(TYMyYagiName());
    NSString *contentEncoded = TYEncodeString(content);
    
    NSString *tweetURL = [NSString stringWithFormat:@"%@?auth=%@&yaginame=%@&content=%@",
                          TYApplicationURI,
                          hash,
                          yagiNameEncoded,
                          contentEncoded];
    return tweetURL;
}

//投稿ウィンドウを開く
//引数content: ヤギの発言
- (void)openTweetPostWindowFromViewController:(UIViewController *)viewConttoller
                                      content:(NSString *)content{
    self.twitterComposeViewController = [SLComposeViewController composeViewControllerForServiceType:SLServiceTypeTwitter];
    
    [_twitterComposeViewController setInitialText:@" #つぶやぎ"];
    [_twitterComposeViewController addURL:[NSURL URLWithString:[self makeTweetURLWithContent:content]]];
    [_twitterComposeViewController addImage:TYTakeScreenShot()];

    _twitterComposeViewController.completionHandler = ^(SLComposeViewControllerResult result){
        if(result == SLComposeViewControllerResultDone){
            //
        }else if(result == SLComposeViewControllerResultCancelled){
            //
        }
        [viewConttoller dismissViewControllerAnimated:YES completion:nil];
    };
    [viewConttoller presentViewController:_twitterComposeViewController animated:YES completion:nil];
}

/*
 以下、Social.frameworkを使わない場合の実装
 
 //ツイート投稿
- (void)postTweet:(NSString *)content
    successBlock:(void(^)(NSDictionary *status))successBlock
      errorBlock:(void(^)(NSError *error))errorBlock{
    
    NSString *tweetContent = TYMakeTweet(content);
    
    NSData *screenShot = TYTakeScreenShot();
    [_twitterAPIClient postStatusUpdate:tweetContent
                         mediaDataArray:@[screenShot]
                      possiblySensitive:nil
                      inReplyToStatusID:nil
                               latitude:nil
                              longitude:nil
                                placeID:nil
                     displayCoordinates:nil
                    uploadProgressBlock:
     ^(NSInteger bytesWritten, NSInteger totalBytesWritten, NSInteger totalBytesExpectedToWrite) {
         
     } successBlock:^(NSDictionary *status) {
         
     } errorBlock:^(NSError *error) {
         
     }];
    
}

// OAuthTokenを前回起動時に取得したか否か
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

// OAuthTokenを次回起動時も使えるように保持する
- (void)setOAuthToken:(NSString *)OAuthAccessToken
     OAuthTokenSecret:(NSString *)OAuthAccessTokenSecret
{
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    [ud setObject:OAuthAccessToken forKey: @"TDOAuthAccessToken"];
    [ud setObject:OAuthAccessTokenSecret forKey: @"TDOAuthAccessTokenSecret"];
    [ud synchronize];
}

//
// Safari経由でAccessTokenを取得してAPI権限を得る
//
- (void)loginTwitterInSafariWithSuccessBlock:(void(^)(NSString *username))successBlock
                                  errorBlock:(void(^)(NSError *error))errorBlock{


    NSString *OAuthToken;
    NSString *OAuthTokenSecret;
    if ([self getOAuthToken:&OAuthToken OAuthTokenSecret:&OAuthTokenSecret]){
        //もしすでにTokenを得ていたら
        self.twitterAPIClient = [STTwitterAPI twitterAPIWithOAuthConsumerKey:TYConsumerKey
                                                         consumerSecret:TYConsumerSecret
                                                             oauthToken:OAuthToken
                                                       oauthTokenSecret:OAuthTokenSecret];
        
        [_twitterAPIClient verifyCredentialsWithSuccessBlock:successBlock
                                                 errorBlock:errorBlock];
    
    } else {
        //まだTokenを得ていなかったら
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


// もらってきたTokenを保存し、successBlockを実行

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
*/

@end
