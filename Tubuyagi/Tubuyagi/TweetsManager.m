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

@implementation TweetsManager


static NSString* const applicationURI = @"https://github.com/miya-s/Tubuyagi";
static NSString* const applicationHashTag = @"つぶやぎ";

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
+(NSString *)makeHashFromTweet:(NSString *)tweet twitterID:(NSString*)twitterID{
    NSString *seed=[twitterID stringByAppendingString:tweet];
    NSString *hash =[seed getSHAForAuth];
    return hash;
}

/*
 URL形式へのエンコード・デコード
 
 参考にしたサイト：
 http://csfun.blog49.fc2.com/blog-entry-126.html
 http://blog.daisukeyamashita.com/post/1686.html
 */
+(NSString *)encodeString:(NSString *)plainString{
    NSString *encodedText = (__bridge_transfer NSString *)CFURLCreateStringByAddingPercentEscapes(
                                                                                NULL,
                                                                                (__bridge CFStringRef)plainString,
                                                                                NULL,
                                                                                CFSTR("!*'();:@&=+$,/?%#[]"),
                                                                                CFStringConvertNSStringEncodingToEncoding(NSUTF8StringEncoding));
    return encodedText;
}

+(NSString *)decodeString:(NSString *)encodedString{
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

+(NSString *)makeTweet:(NSString *)content{
    NSString *hash = [TweetsManager makeHashFromTweet:content twitterID:[TweetsManager getMyTwitterID]];
    NSString *yagiNameEncoded = [TweetsManager encodeString:[TweetsManager getMyYagiName]];
    NSString *contentEncoded = [TweetsManager encodeString:content];
    NSString *tweet = [NSString stringWithFormat:@"%@?auth=%@&yaginame=%@&content=%@ #%@",
                                                  applicationURI,
                                        hash,
                                        yagiNameEncoded,
                                        contentEncoded,
                                        applicationHashTag];
    return tweet;
}

+(NSString *)getMyYagiName{
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    return [ud stringForKey: @"TDYagiName"];
}

+(NSString *)getMyTwitterID{
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    NSString *myId = [ud stringForKey: @"TDUserTwitterID"];
    if (!myId){
        @throw @"Runtime Error: Twitter IDがTDUserTwitterIDに設定されていない";
    }
    return myId;
}

/*
 そのツイートのHashが正規のものかをチェック
 */
+(BOOL)checkHash:(NSString *)hash tweetContent:(NSString*)content twitterID:(NSString *)twitterID{
    NSString *new_hash = [TweetsManager makeHashFromTweet:content twitterID:twitterID];
    return [new_hash isEqualToString:hash];
}

/*正規のつぶやきかどうかを判定する*/
+(BOOL)isValidTubuyaki:(NSDictionary *)tweet{
    NSError *error = nil;
    NSString*text = (NSString *)[tweet objectForKey:@"text"];

    /*ハッシュタグが適切に含まれているか*/
    //TODO ここの「#つぶやぎ」をapplicationHashTagにしたい
    NSRegularExpression *validationChecker = [NSRegularExpression regularExpressionWithPattern:@".*https.*#つぶやぎ" options:0 error:&error];
    NSTextCheckingResult *match =[validationChecker firstMatchInString:text options:0 range:NSMakeRange(0, text.length)];
    if (!match.numberOfRanges){
        return false;
    }

    /*urlが含まれているか*/
    if ([[[tweet objectForKey:@"entities"] objectForKey:@"urls"] count] <= 0){
        return false;
    }


    NSString *url = [[[[tweet objectForKey:@"entities"] objectForKey:@"urls"] objectAtIndex:0] objectForKey:@"expanded_url"];
    NSMutableDictionary *elementsInURL = [TweetsManager getElementsFromURL:url];
    NSString* userID = (NSString *)[[tweet objectForKey:@"user"] objectForKey:@"id_str"];
    /* url内にヴァリデーション用の情報が含まれているか */
    if ([elementsInURL count] <= 0){
        return false;
    }
    /* Hashの整合性チェック */
    return [TweetsManager checkHash:[elementsInURL objectForKey:@"hash"]
                       tweetContent:[elementsInURL objectForKey:@"content"]
                          twitterID:userID];
}


/* urlに記述されたヴァリデーション用の情報などを獲得する */
+(NSMutableDictionary *)getElementsFromURL:(NSString *)url{
    NSMutableDictionary *extractedElements = [NSMutableDictionary dictionaryWithDictionary:@{}];
    NSError *error = nil;
    NSRegularExpression *regexpForURL = [NSRegularExpression regularExpressionWithPattern:@".*\?auth=([^&]*)&yaginame=([^&]*)&content=([^&]*)" options:0 error:&error];
    NSTextCheckingResult *matchInURL =[regexpForURL firstMatchInString:url options:0 range:NSMakeRange(0, url.length)];

    /*マッチすべき情報が含まれていなかったら離脱*/
    if (matchInURL.numberOfRanges <= 2){
        return extractedElements;
    }
    [extractedElements setObject:[TweetsManager decodeString:[url substringWithRange:[matchInURL rangeAtIndex:1]]] forKey:@"hash"];
    [extractedElements setObject:[TweetsManager decodeString:[url substringWithRange:[matchInURL rangeAtIndex:2]]] forKey:@"yaginame"];
    [extractedElements setObject:[TweetsManager decodeString:[url substringWithRange:[matchInURL rangeAtIndex:3]]] forKey:@"content"];
    return extractedElements;
}

/*
    正規のツイートだけ持ってくる
 */
+(NSMutableArray *)getAvailableTweets:(NSArray *)tweets{
    NSMutableArray *availableTweets = [NSMutableArray array];
    for (NSDictionary *tweet in tweets){
        if( [TweetsManager isValidTubuyaki:tweet]) {
            [availableTweets addObject:tweet];
        }
    }
    return availableTweets;
}



/***************************
 API インターフェイス
 **************************/

/*ツイート投稿*/
+(void)postTweet:(NSString *)content twitterAPI:(STTwitterAPI *)twitter successBlock:(void(^)(NSDictionary *status))successBlock errorBlock:(void(^)(NSError *error))errorBlock{
    
    NSString *tweetContent = [TweetsManager makeTweet:content];
    
    [twitter postStatusUpdate:tweetContent inReplyToStatusID:nil latitude:nil longitude:nil placeID:nil displayCoordinates:nil trimUser:nil successBlock:successBlock errorBlock:errorBlock];
    
}


@end
