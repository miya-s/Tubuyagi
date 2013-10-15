//
//  TweetsManager.m
//  Tubuyagi
//
//  Created by 宮原聡 on 2013/09/24.
//  Copyright (c) 2013年 Genki Ishibashi. All rights reserved.
//

#import "TweetsManager.h"
#import "NSString+MD5.h"

@implementation TweetsManager


NSString* const applicationURI = @"https://github.com/miya-s/Tubuyagi";
NSString* const applicationHashTag = @"つぶやぎ";


+(NSString *)makeHashFromTweet:(NSString *)tweet tweetOwner:(NSString*)owner{
    NSString *seed=[owner stringByAppendingString:tweet];
    NSString *hash =[seed getMD5ForAuth];
    return hash;
}

//ユーザー情報をハッシュの種にしないと、パクツイできてしまう
//しかしユーザー情報をハッシュの種にすると、ユーザーIDを変更したユーザーが今までのツイートを認証できなくなってしまう
//Twitter APIのユーザーidは、 @hogeの形式ではなく連番？
//注意！！idは使わない、id_strを使う
//TweetにもUserにもid_str属性があるので間違えないように。


+(NSString *)makeTweet:(NSString *)content{
    NSString *hash = [TweetsManager makeHashFromTweet:content tweetOwner:[TweetsManager getMyTwitterID]];
    NSString *tweet = [NSString stringWithFormat:@"%@「%@」%@?auth=%@ #%@", [TweetsManager getMyYagiName], content,  applicationURI, hash, applicationHashTag];
#warning 長さ判定が必要
    return tweet;
}

+(NSString *)getMyYagiName{
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    return [ud stringForKey: @"TDYagiName"];
}

+(NSString *)getMyTwitterID{
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    NSString *myId = [ud stringForKey: @"TDUserTwitterID"];
    return myId;
}

+(BOOL)checkHash:(NSString *)hash tweetContent:(NSString*)content tweetOwner:(NSString *)owner{
    NSString *new_hash = [TweetsManager makeHashFromTweet:content tweetOwner:owner];
    return [new_hash isEqualToString:hash];
}

+(NSMutableArray *)getAvailableTweets:(NSArray *)tweets{
    NSMutableArray *availableTweets = [NSMutableArray array];
    for (NSDictionary *tweet in tweets){
        NSError *error = nil;
        NSRegularExpression *regexp = [NSRegularExpression regularExpressionWithPattern:@".*?「(.*)」.*https.*#つぶやぎ" options:0 error:&error];
        NSRegularExpression *hash_regexp = [NSRegularExpression regularExpressionWithPattern:@".*\?auth=([^&]*)" options:0 error:&error];
        NSString*text = (NSString *)[tweet objectForKey:@"text"];
        NSString*userID = (NSString *)[[tweet objectForKey:@"user"] objectForKey:@"id_str"];
        NSTextCheckingResult *match =[regexp firstMatchInString:text options:0 range:NSMakeRange(0, text.length)];
        if(match.numberOfRanges && [[[tweet objectForKey:@"entities"] objectForKey:@"urls"] count] > 0) {
            NSString *content = [text substringWithRange:[match rangeAtIndex:1]];
            NSString *url = [[[[tweet objectForKey:@"entities"] objectForKey:@"urls"] objectAtIndex:0] objectForKey:@"expanded_url"];
            
            NSTextCheckingResult *hash_match =[hash_regexp firstMatchInString:url options:0 range:NSMakeRange(0, url.length)];
            if (!hash_match.numberOfRanges) continue;
            NSString *hash = [url substringWithRange:[hash_match rangeAtIndex:1]];
            [TweetsManager getMyTwitterID];
            if ([TweetsManager checkHash:hash tweetContent:content tweetOwner:userID]){
                [availableTweets addObject:tweet];
            }
        }
    }
    return availableTweets;
}
+(void)postTweet:(NSString *)content twitterAPI:(STTwitterAPI *)twitter successBlock:(void(^)(NSDictionary *status))successBlock errorBlock:(void(^)(NSError *error))errorBlock{
    NSString *tweetContent = [TweetsManager makeTweet:content];
    [twitter postStatusUpdate:tweetContent inReplyToStatusID:nil latitude:nil longitude:nil placeID:nil displayCoordinates:nil trimUser:nil successBlock:successBlock errorBlock:errorBlock];
}

@end
