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

@synthesize username = _username;
@synthesize userID = _userID;
@synthesize twitterAccount = _twitterAccount;

NSString * const TYApplicationScheme = @"tubuyagi";
NSString * const TYApplicationDomain = @"I.GA.Tubuyagi";
NSString * const TYApplicationURI = @"https://github.com/miya-s/Tubuyagi";
NSString * const TYApplicationHashTag = @"つぶやぎ";

NSString *TYEncodeString(NSString *plainString);
NSString *TYMakeHashFromTweet(NSString *tweet, NSString*twitterID);
NSString *TYDecodeString(NSString *encodedString);
NSString *TYMyYagiName(void);
UIImage* TYTakeScreenShot(void);
BOOL TYCheckHash(NSString *hash, NSString*content, NSString *twitterID);
NSDictionary *TYExtractElementsFromURL(NSString *url, NSError **error);
BOOL TYTweetIsQualified(NSDictionary *tweet, NSError** error);
NSMutableArray *TYChooseAvailableTweets(NSArray *tweets);

/*
 ツイートの管理を行うクラス
 
 主な機能:
 ・ツイートの取得
 　・学習に食わせる用ツイート
 　・ランキングのツイート
     ・ツイートの判定
 ・ツイートの投稿
 
 TODO ModelとControllerの分離
 */

/*************************
 Twitter API 認証
 ************************/

//iOSでログイン
- (void)checkTwitterAccountsWithSuccessBlock:(void(^)(void))successBlock
                                choicesBlock:(void(^)(NSArray *accounts))choicesblock
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
             _twitterAccounts = accountArray;
             
             //もし、すでにアカウントが設定されていたら
             NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
             NSString *identifier = [ud objectForKey:@"TDSelectedAccountIdentifier"];
             ACAccount *oldAccount = [accountStore accountWithIdentifier:identifier];
             if (oldAccount){
                 self.twitterAccount = oldAccount;
                 successBlock();
                 return;
             }
             if (accountArray.count == 1){
                 self.twitterAccount = [accountArray objectAtIndex:0];
                 successBlock();
                 return;
             }
             self.twitterAccount = [accountArray objectAtIndex:0];
             choicesblock(accountArray);
         }];
    } else {
        //Twitterアクセスが拒否された場合
        NSError *error =[NSError errorWithDomain:TYApplicationDomain
                                            code:TYiOSTwitterAccessDenied
                                        userInfo:@{NSLocalizedDescriptionKey: @"Twitter account access has denied"}];
        errorBlock(error);
    }
}

// OAuthTokenSecretを要求
- (void)OAuthWithOAuthToken:(NSString *)token
              OAuthVerifier:(NSString *)verifier
{
    
    [twitterAPIClient postAccessTokenRequestWithPIN:verifier
                                       successBlock:^(NSString *oauthToken, NSString *oauthTokenSecret, NSString *userID, NSString *screenName) {
                                           
                                           _userID = userID;
                                           self.OAuthToken = twitterAPIClient.oauthAccessToken;
                                           self.OAuthTokenSecret = twitterAPIClient.oauthAccessTokenSecret;
                                           _username = screenName;
                                           successBlockAfterAuthorized(screenName);
                                           
                                       } errorBlock:errorBlockAfterAuthorized];
}


//
// キャッシュされたOAuthTokenでAPI
//
- (void)loginTwitterByCachedTokenWithSuccessBlock:(void(^)(NSString *username))successBlock
                                       errorBlock:(void(^)(NSError *error))errorBlock{
    NSAssert(self.OAuthToken, @"OAuth token should be cached!");
    NSAssert(self.OAuthTokenSecret, @"OAuth token secret should be cached!");
    
    twitterAPIClient = [STTwitterAPI twitterAPIWithOAuthConsumerKey:TYConsumerKey
                                                     consumerSecret:TYConsumerSecret
                                                         oauthToken:self.OAuthToken
                                                   oauthTokenSecret:self.OAuthTokenSecret];
    
    [twitterAPIClient verifyCredentialsWithSuccessBlock:successBlock
                                             errorBlock:errorBlock];
}

//
// Safari経由でAccessTokenを取得してAPI権限を得る
//
- (void)loginTwitterInSafariWithSuccessBlock:(void(^)(NSString *username))successBlock
                                  errorBlock:(void(^)(NSError *error))errorBlock{
    
    twitterAPIClient = [STTwitterAPI twitterAPIWithOAuthConsumerKey:TYConsumerKey
                                                     consumerSecret:TYConsumerSecret];
    
    [twitterAPIClient
     postTokenRequest: ^(NSURL *url, NSString *oauthToken) {
         //認証成功後の挙動をここで書く
         successBlockAfterAuthorized = successBlock;
         errorBlockAfterAuthorized = errorBlock;
         
         [[UIApplication sharedApplication] openURL:url];
     }
     forceLogin:@(YES)
     screenName:nil
     oauthCallback:[NSString stringWithFormat:@"%@://twitter_access_tokens/", TYApplicationScheme ]
     errorBlock:errorBlock];
}

/*************************
 ツイート取得
 ************************/
//タイムライン取得
//参考: http://qiita.com/paming/items/9a6b51fa56915d1f1d64
- (void)checkTimelineWithSuccessBlock:(void(^)(NSArray *statuses))successBlock
                           errorBlock:(void(^)(NSError *error))errorBlock;
{
    switch (self.authorizeType){
        case TYAuthorizediOS:
            [self checkTimelineiOSWithSuccessBlock:successBlock
                                        errorBlock:errorBlock];
            break;
        case TYAuthorizedSafari:
            [self checkTimelineSafariWithSuccessBlock:successBlock errorBlock:errorBlock];
            break;
        default:
            NSAssert(NO, @"Failed to get timeline");
            break;
    }
}

//タイムライン取得(iOS)
- (void)checkTimelineiOSWithSuccessBlock:(void (^)(NSArray *))successBlock errorBlock:(void (^)(NSError *))errorBlock{
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

- (void)checkTimelineSafariWithSuccessBlock:successBlock errorBlock:errorBlock{
    [twitterAPIClient getHomeTimelineSinceID:nil
                                       count:20
                                successBlock:successBlock
                                  errorBlock:errorBlock];
}


/*************************
    ツイート投稿機能関係
 **************************/

//投稿ウィンドウを開く(iOS認証を行った場合のみ)
//引数content: ヤギの発言
// viewのほうに移すべきかも
- (void)openTweetPostWindowFromViewController:(UIViewController *)viewConttoller
                                      content:(NSString *)content{
    NSAssert(self.authorizeType == TYAuthorizediOS, @"This method is only available for iOS Authorization");
    twitterComposeViewController = [SLComposeViewController composeViewControllerForServiceType:SLServiceTypeTwitter];
    
    [twitterComposeViewController setInitialText:@" #つぶやぎ"];
    [twitterComposeViewController addURL:[NSURL URLWithString:[self makeTweetURLWithContent:content]]];
    [twitterComposeViewController addImage:recentScreenShot];
    
    twitterComposeViewController.completionHandler = ^(SLComposeViewControllerResult result){
        if(result == SLComposeViewControllerResultDone){
            //
        }else if(result == SLComposeViewControllerResultCancelled){
            //
        }
        [viewConttoller dismissViewControllerAnimated:YES completion:nil];
    };
    [viewConttoller presentViewController:twitterComposeViewController animated:YES completion:nil];
}


//ツイート投稿（Safari認証では窓を開けないので直接）
- (void)postDirectlyTweet:(NSString *)content
             successBlock:(void(^)(NSDictionary *status))successBlock
               errorBlock:(void(^)(NSError *error))errorBlock{
    NSAssert(self.authorizeType == TYAuthorizedSafari, @"This method is only available for Safari Authorization");
    
    
    NSString *tweetURL = [self makeTweetURLWithContent:content];
    NSString *tweetContent = [NSString stringWithFormat:@"%@のつぶやき：%@… %@ #%@", TYMyYagiName(), [content substringToIndex:5], tweetURL, TYApplicationHashTag];
    
    UIImage *screenShot = recentScreenShot;
    NSData *dataToSend = [[NSData alloc] initWithData:UIImagePNGRepresentation(screenShot)];
    [twitterAPIClient postStatusUpdate:tweetContent
                        mediaDataArray:@[dataToSend]
                     possiblySensitive:nil
                     inReplyToStatusID:nil
                              latitude:nil
                             longitude:nil
                               placeID:nil
                    displayCoordinates:nil
                   uploadProgressBlock:
     ^(NSInteger bytesWritten, NSInteger totalBytesWritten, NSInteger totalBytesExpectedToWrite) {
         
     }
                          successBlock:successBlock
                            errorBlock:errorBlock];
    
}

/*************************
 ツイート作成関連機能
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

// 　投稿ヴァリデーション用のURLを作成する
- (NSString *)makeTweetURLWithContent:(NSString *)content{
    NSString *hash = TYMakeHashFromTweet(content, self.userID);
    NSString *yagiNameEncoded = TYEncodeString(TYMyYagiName());
    NSString *contentEncoded = TYEncodeString(content);
    
    NSString *tweetURL = [NSString stringWithFormat:@"%@?auth=%@&yaginame=%@&content=%@",
                          TYApplicationURI,
                          hash,
                          yagiNameEncoded,
                          contentEncoded];
    return tweetURL;
}

/*
 投稿用スクリーンショットを撮る
 参考 : http://www.yoheim.net/blog.php?q=20130706
 */
- (void)takeScreenShot{
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
    
    recentScreenShot = capturedImage;
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

/**************************
 ツイート正規チェック
 *************************/


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

/*
 getter, setter
 */
//twitterAccountのセッタ。一度設定したアカウントを保持
- (void)setTwitterAccount:(ACAccount *)newTwitterAccount{
    _twitterAccount = newTwitterAccount;
    _username = newTwitterAccount.username;
    _userID = [_twitterAccount valueForKeyPath:@"properties.user_id"];
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    [ud setObject:_twitterAccount.identifier forKey:@"TDSelectedAccountIdentifier"];
    [ud synchronize];
}

- (ACAccount *)twitterAccount{
    return _twitterAccount;
}

- (void)setOAuthToken:(NSString *)newOAuthToken{
    OAuthToken = newOAuthToken;
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    [ud setObject:newOAuthToken forKey: @"TDOAuthToken"];
    [ud synchronize];
}

- (NSString *)OAuthToken{
    if (!OAuthToken){
        NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
        OAuthToken = [ud objectForKey: @"TDOAuthToken"];
    }
    return OAuthToken;
}

- (void)setOAuthTokenSecret:(NSString *)newOAuthTokenSecret{
    OAuthTokenSecret = newOAuthTokenSecret;
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    [ud setObject:newOAuthTokenSecret forKey: @"TDOAuthTokenSecret"];
    [ud synchronize];
}

- (NSString *)OAuthTokenSecret{
    if (!OAuthTokenSecret){
        NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
        OAuthTokenSecret = [ud objectForKey: @"TDOAuthTokenSecret"];
    }
    
    return OAuthTokenSecret;
}

- (NSInteger)authorizeType{
    if (self.twitterAccount){
        return TYAuthorizediOS;
    }
    // TODO もっと正確な判定
    if (self.OAuthToken && self.OAuthTokenSecret){
        return TYAuthorizedSafari;
    }
    return TYNotAuthorized;
}

- (NSString *)username{
    NSAssert(_username, @"nil usename");
    return _username;
}

- (void)setUsername:(NSString *)newUsername{
    _username = newUsername;
}

- (NSString *)userID{
    NSAssert(_username, @"nil userID");
    return _userID;
}

- (BOOL)cachedOAuth{
    BOOL cached = self.OAuthToken && self.OAuthTokenSecret;
    return cached;
}

@end
