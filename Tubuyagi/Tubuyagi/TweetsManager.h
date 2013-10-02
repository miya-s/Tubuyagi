//
//  TweetsManager.h
//  Tubuyagi
//
//  Created by 宮原聡 on 2013/09/24.
//  Copyright (c) 2013年 Genki Ishibashi. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "STTwitter.h"
@interface TweetsManager : NSObject
{
    
}

+(NSString *)makeHashFromTweet:(NSString *)tweet tweetOwner:(NSString*)owner ;
+(NSString *)makeTweet:(NSString *)content;
+(BOOL)checkHash:(NSString *)hash tweetContent:(NSString*)content tweetOwner:(NSString *)owner;
+(NSMutableArray *)getAvailableTweets:(NSArray *)tweets;
+(void)postTweet:(NSString *)content twitterAPI:(STTwitterAPI *)twitter successBlock:(void(^)(NSDictionary *status))successBlock errorBlock:(void(^)(NSError *error))error;

@end
