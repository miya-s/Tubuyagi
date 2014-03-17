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

/*
 ツイートの管理を行うクラス
 */

/*使い物になるツイートだけ収集する*/
+(NSMutableArray *)getAvailableTweets:(NSArray *)tweets;

/*ツイートを投稿する*/
+(void)postTweet:(NSString *)content twitterAPI:(STTwitterAPI *)twitter successBlock:(void(^)(NSDictionary *status))successBlock errorBlock:(void(^)(NSError *error))error;



@end
