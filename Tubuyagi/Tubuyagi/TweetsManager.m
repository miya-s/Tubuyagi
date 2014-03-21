//
//  TweetsManager.m
//  Tubuyagi
//
//  Created by 宮原聡 on 2013/09/24.
//  Copyright (c) 2013年 Genki Ishibashi. All rights reserved.
//

#import "TweetsManager.h"

#import "STTwitter.h"
#import <Social/Social.h>
#import <Accounts/Accounts.h>
#import "NSString+SHA.h"
#import "AuthentificationKeys.h"
// !!!: AuthentificationKeysはgitの管理外にあります。ほしい人は kan.tan.san @ gmail.com まで
#import <CoreGraphics/CoreGraphics.h>
#import <QuartzCore/QuartzCore.h>


@implementation TweetsManager
{
@private
    //safariから戻ってきたあとに実行するblock
    void(^_successBlockAfterAuthorized)(NSString *username);
    void(^_errorBlockAfterAuthorized)(NSError *error);
    
    SLComposeViewController *_twitterComposeViewController;
    STTwitterAPI *_twitterAPIClient;
    
    NSString *_OAuthToken;
    NSString *_OAuthTokenSecret;
    
    UIImage *_recentScreenShot;
}

@synthesize username = _username;
@synthesize userID = _userID;
@synthesize twitterAccount = _twitterAccount;

NSString * const TYApplicationScheme = @"tubuyagi";
NSString * const TYApplicationDomain = @"I.GA.Tubuyagi";
NSString * const TYApplicationURI = @"https://github.com/miya-s/Tubuyagi";
NSString * const TYApplicationHashTag = @"つぶやぎ";
NSInteger const TYContentMaxLength = 5;


NSString *TYEncodeString(NSString *plainString);
NSString *TYMakeHashFromTweet(NSString *tweet, NSString*twitterID);
NSString *TYDecodeString(NSString *encodedString);
NSString *TYMyYagiName(void);
UIImage* TYTakeScreenShot(void);
BOOL TYCheckHash(NSString *hash, NSString*content, NSString *twitterID);
NSDictionary *TYExtractElementsFromURL(NSString *url, NSError **error);
BOOL TYTweetIsQualified(NSDictionary *tweet, NSError** error);
NSArray *TYChooseAvailableTweets(NSArray *tweets);
NSArray *TYConvertTweetsToOldStyle(NSArray *tweets);

// TODO: ModelとControllerの分離

- (id) init{
    NSAssert(!singleTweetsManager, @"tweets manager should be single");
    if (self = [super init]) {
        singleTweetsManager = self;
    }
    return self;
}


#pragma mark -Twitter認証

//iOSでログイン
// !!!:simulatorでは常にgrantedがtrueになってしまう
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
    
    [_twitterAPIClient postAccessTokenRequestWithPIN:verifier
                                       successBlock:^(NSString *oauthToken, NSString *oauthTokenSecret, NSString *userID, NSString *screenName) {
                                           
                                           self.userID = userID;
                                           self.OAuthToken = _twitterAPIClient.oauthAccessToken;
                                           self.OAuthTokenSecret = _twitterAPIClient.oauthAccessTokenSecret;
                                           _username = screenName;
                                           _successBlockAfterAuthorized(screenName);
                                           
                                       } errorBlock:_errorBlockAfterAuthorized];
}


//
// キャッシュされたOAuthTokenでAPI
//
- (void)loginTwitterByCachedTokenWithSuccessBlock:(void(^)(NSString *username))successBlock
                                       errorBlock:(void(^)(NSError *error))errorBlock{
    NSAssert(self.OAuthToken, @"OAuth token should be cached!");
    NSAssert(self.OAuthTokenSecret, @"OAuth token secret should be cached!");
    
    _twitterAPIClient = [STTwitterAPI twitterAPIWithOAuthConsumerKey:TYConsumerKey
                                                     consumerSecret:TYConsumerSecret
                                                         oauthToken:self.OAuthToken
                                                   oauthTokenSecret:self.OAuthTokenSecret];
    
    [_twitterAPIClient verifyCredentialsWithSuccessBlock:successBlock
                                             errorBlock:errorBlock];
}

//
// Safari経由でAccessTokenを取得してAPI権限を得る
//
- (void)loginTwitterInSafariWithSuccessBlock:(void(^)(NSString *username))successBlock
                                  errorBlock:(void(^)(NSError *error))errorBlock{
    
    _twitterAPIClient = [STTwitterAPI twitterAPIWithOAuthConsumerKey:TYConsumerKey
                                                     consumerSecret:TYConsumerSecret];
    
    [_twitterAPIClient
     postTokenRequest: ^(NSURL *url, NSString *oauthToken) {
         //認証成功後の挙動をここで書く
         _successBlockAfterAuthorized = successBlock;
         _errorBlockAfterAuthorized = errorBlock;
         
         [[UIApplication sharedApplication] openURL:url];
     }
     forceLogin:@(YES)
     screenName:nil
     oauthCallback:[NSString stringWithFormat:@"%@://twitter_access_tokens/", TYApplicationScheme ]
     errorBlock:errorBlock];
}

#pragma mark -ツイート取得
//タイムライン取得
//参考: http://qiita.com/paming/items/9a6b51fa56915d1f1d64
- (void)checkTimelineWithSuccessBlock:(void(^)(NSArray *statuses))successBlock
                           errorBlock:(void(^)(NSError *error))errorBlock;
{
    [_twitterAPIClient getHomeTimelineSinceID:NULL
                                       count:20
                                successBlock:successBlock
                                  errorBlock:errorBlock];
}

//検索結果取得
- (void)checkSearchResultForRecent:(BOOL)isRecent
                      SuccessBlock:(void(^)(NSArray *statuses))successBlock
                        errorBlock:(void(^)(NSError *error))errorBlock;
{
    [_twitterAPIClient getSearchTweetsWithQuery:@"#つぶやぎ"
                                       geocode:nil
                                          lang:@"ja"
                                        locale:@"ja"
                                    resultType:isRecent ? @"recent" : @"popular"
                                         count:@"20"
                                         until:nil
                                       sinceID:nil
                                         maxID:nil
                               includeEntities:[[NSNumber alloc] initWithInt:1]
                                      callback:nil
                                  successBlock:^(NSDictionary *searchMetadata, NSArray *  statuses){
                                      NSArray *tweets = TYChooseAvailableTweets(statuses);
                                      NSArray *convertedTweets = TYConvertTweetsToOldStyle(tweets);
                                      successBlock(convertedTweets);
                                  }
     
                                    errorBlock:errorBlock];
}

#pragma mark -ツイート投稿

//投稿ウィンドウを開く(iOS認証を行った場合のみ)
//引数content: ヤギの発言
// TODO: ウィンドウを開くような処理はViewに移す
- (void)openTweetPostWindowFromViewController:(UIViewController *)viewConttoller
                                      content:(NSString *)content{
    NSAssert(self.authorizeType == TYAuthorizediOS, @"This method is only available for iOS Authorization");
    _twitterComposeViewController = [SLComposeViewController composeViewControllerForServiceType:SLServiceTypeTwitter];
    
    [_twitterComposeViewController setInitialText:@" #つぶやぎ"];
    [_twitterComposeViewController addURL:[NSURL URLWithString:[self makeTweetURLWithContent:content]]];
    [_twitterComposeViewController addImage:_recentScreenShot];
    
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


//ツイート投稿（Safari認証では窓を開けないので直接）
- (void)postDirectlyTweet:(NSString *)content
             successBlock:(void(^)(NSDictionary *status))successBlock
               errorBlock:(void(^)(NSError *error))errorBlock{
    NSAssert(self.authorizeType == TYAuthorizedSafari, @"This method is only available for Safari Authorization");
    
    
    NSString *tweetURL = [self makeTweetURLWithContent:content];
    NSString *shortenContent = content;
    if (content.length > TYContentMaxLength){
        content = [NSString stringWithFormat:@"%@…" , [content substringFromIndex:TYContentMaxLength]];
    }
    NSString *tweetContent = [NSString stringWithFormat:@"%@：%@ %@ #%@", TYMyYagiName(), shortenContent, tweetURL, TYApplicationHashTag];
    
    UIImage *screenShot = _recentScreenShot;
    NSData *dataToSend = [[NSData alloc] initWithData:UIImagePNGRepresentation(screenShot)];
    [_twitterAPIClient postStatusUpdate:tweetContent
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

#pragma mark -ツイート作成

/* ハッシュ化
 ハッシュ化する際は、投稿者の情報も必要 bacause ユーザー情報をハッシュの種にしないと、パクツイできてしまう
    ユーザ情報はTwitterのユーザーIDにする because アプリIDだとコピペ予防にならない
    注意！！idは使わない、id_strを使う because idは桁落ちする可能性がある
    TweetにもUserにもid_str属性があるので混同しないように。
 */
// !!!:idは使わない、id_strを使う
// !!!:tweetのidとuserのidを混同しない
NSString *TYMakeHashFromTweet(NSString *tweet, NSString*twitterID){
    NSString *seed=[twitterID stringByAppendingString:tweet];
    NSString *hash =[seed SHAStringForAuth];
    return hash;
}

// 　投稿用のURLを作成する
- (NSString *)makeTweetURLWithContent:(NSString *)content{
    NSString *hash = TYMakeHashFromTweet(content, self.userID);
    NSString *yagiNameEncoded = TYEncodeString(TYMyYagiName());
    NSString *contentEncoded = TYEncodeString(content);
    NSAssert(hash, @"null hash");
    NSAssert(yagiNameEncoded, @"null yaginame");
    NSAssert(contentEncoded, @"null content");
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
    
    _recentScreenShot = capturedImage;
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

#pragma mark -正規のツイートかチェック
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

NSDictionary *TYExtractElementsFromTweet(NSDictionary *tweet, NSError **error){
    if ([[[tweet objectForKey:@"entities"] objectForKey:@"urls"] count] <= 0){
        if (error){
            *error = [NSError errorWithDomain:TYApplicationDomain
                                         code:TYLackingURLInTweet
                                     userInfo:@{NSLocalizedDescriptionKey: @"No URL In Tweet"}];
        }
        return nil;
    }
    NSString *url = [[[[tweet objectForKey:@"entities"] objectForKey:@"urls"] objectAtIndex:0] objectForKey:@"expanded_url"];
    NSDictionary *extractedElements = TYExtractElementsFromURL(url, error);
    return extractedElements;
}


/*適切な情報を含んだ|tweet|かeどうかを判定する*/
BOOL TYTweetIsQualified(NSDictionary *tweet, NSError** error){
    /*urlが含まれているか*/
    NSDictionary *elementsInURL = TYExtractElementsFromTweet(tweet, error);
    if (!elementsInURL){
        return NO;
    }
    
    /* id_str情報が含まれているか */
    if (![[tweet objectForKey:@"user"] objectForKey:@"id_str"]){
        if (error){
            *error = [NSError errorWithDomain:TYApplicationDomain
                                         code:TYLackingUserIDInTweet
                                     userInfo:@{NSLocalizedDescriptionKey: @"No UserUD In Tweet"}];
        }
        return NO;
    }
    NSString* userIDForTweet = (NSString *)[[tweet objectForKey:@"user"] objectForKey:@"id_str"];
    
    /* Hashの整合性チェック */
    BOOL qualifyTweet = TYCheckHash([elementsInURL objectForKey:@"auth"],
                                    [elementsInURL objectForKey:@"content"],
                                    userIDForTweet);
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
NSArray *TYChooseAvailableTweets(NSArray *tweets){
    NSMutableArray *availableTweets = [NSMutableArray array];
    for (NSDictionary *tweet in tweets){
        NSError *error = nil;
        if(TYTweetIsQualified(tweet, &error)) {
            [availableTweets addObject:tweet];
        }
        if (error){
            NSLog(@"erorr in TYChooseAvailableTweets: %@ ", [error localizedDescription]);
        }
            //NSCAssert(!error, [error localizedDescription]);
    }
    return availableTweets;
}

/*
 モックプランで作成したサーバーのレスポンスと同じ形式に変換する（to be depricated）
 */
NSDictionary *TYConvertTweetToOldStyle(NSDictionary *oldTweet){
    NSError *error;
    NSDictionary *elementsInTweet = TYExtractElementsFromTweet(oldTweet, &error);
    NSCAssert(!error, [error localizedDescription]); // chooseしたあとなので、ここでエラーは起きないはず
    NSString * yagi_name = [elementsInTweet objectForKey:@"yaginame"];
    NSString * content =  [elementsInTweet objectForKey:@"content"];
    NSString * wara = [oldTweet objectForKey:@"favorite_count"];
    NSString * date = [oldTweet objectForKey:@"created_at"];
#warning created_atをもっとわかりやすいけいしきに, 少なくともソートで使えるように
    NSString * user_name = [[oldTweet objectForKey:@"user"] objectForKey:@"screen_name"];
    NSString * id_str = [oldTweet objectForKey:@"id_str"];
    NSCAssert(yagi_name, @"convert error");
    NSCAssert(content, @"convert error");
    NSCAssert(wara, @"convert error");
    NSCAssert(date, @"convert error");
    NSCAssert(user_name, @"convert error");
    NSCAssert(id_str, @"convert error");
    NSDictionary *newTweet = @{@"yagi_name" : yagi_name,
                               @"content" : content,
                               @"wara" : wara,
                               @"date" : date,
                               @"user_name" : user_name,
                               @"id" : id_str};
    return newTweet;
}


NSArray *TYConvertTweetsToOldStyle(NSArray *tweets){
    NSMutableArray *newTweets = [NSMutableArray array];
    for (NSDictionary *tweet in tweets){
        [newTweets addObject:TYConvertTweetToOldStyle(tweet)];
    }
    return newTweets;
}

#pragma mark -getter and setter

#define TYGetUDIfNil(key, object) \
if (!object){\
NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];\
object = [ud objectForKey: key ];\
}

#define TYSetUD(key, object) \
NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];\
[ud setObject: object forKey: key ];\
[ud synchronize]

//twitterAccountのセッタ
- (void)setTwitterAccount:(ACAccount *)newTwitterAccount{
    _twitterAccount = newTwitterAccount;
    self.username = newTwitterAccount.username;
    self.userID = [_twitterAccount valueForKeyPath:@"properties.user_id"];

    //一度設定したアカウントを保持
    TYSetUD(@"TDSelectedAccountIdentifier", _twitterAccount.identifier);
    
    //APIClientを切り替え
    _twitterAPIClient = [STTwitterAPI twitterAPIOSWithAccount:newTwitterAccount];
}

- (ACAccount *)twitterAccount{
    return _twitterAccount;
}

void TYSetUserDefault(NSString* key, id object){
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    [ud setObject:object forKey: key];
    [ud synchronize];
}

- (void)setOAuthToken:(NSString *)newOAuthToken{
    _OAuthToken = newOAuthToken;
    TYSetUD(@"TDOAuthToken", _OAuthToken);
}

- (NSString *)OAuthToken{
    TYGetUDIfNil(@"TDOAuthToken", _OAuthToken);
    return _OAuthToken;
}

- (void)setOAuthTokenSecret:(NSString *)newOAuthTokenSecret{
    _OAuthTokenSecret = newOAuthTokenSecret;
    TYSetUD(@"TDOAuthTokenSecret", _OAuthTokenSecret);
}

- (NSString *)OAuthTokenSecret{
    TYGetUDIfNil(@"TDOAuthTokenSecret", _OAuthTokenSecret);
    return _OAuthTokenSecret;
}

- (NSInteger)authorizeType{
    if (self.twitterAccount){
        return TYAuthorizediOS;
    }
    // TODO: もっと正確な判定
    if (self.OAuthToken && self.OAuthTokenSecret){
        return TYAuthorizedSafari;
    }
    return TYNotAuthorized;
}

- (NSString *)username{
    TYGetUDIfNil(@"TDUserName", _username);
    NSAssert(_username, @"nil usename");
    return _username;
}

- (void)setUsername:(NSString *)newUsername{
    _username = newUsername;
    TYSetUD(@"TDUserName", _username);
}

- (NSString *)userID{
    TYGetUDIfNil(@"TDUserID", _userID);
    NSAssert(_userID, @"nil userID");
    return _userID;
}

- (void)setUserID:(NSString *)newUserID{
    _userID = newUserID;
    TYSetUD(@"TDUserID", _userID);
}


- (BOOL)cachedOAuth{
    BOOL cached = self.OAuthToken && self.OAuthTokenSecret;
    return cached;
}

@end
