//
//  FMDatabase+Tubuyagi.h
//  Tubuyagi
//
//  Created by 宮原聡 on 2014/03/23.
//  Copyright (c) 2014年 Genki Ishibashi. All rights reserved.
//

#import "FMDB.h"

NS_ENUM(NSInteger, TYActivityType){
    TYFavoritedActivity = 0,
    TYSharedActivity
};

#define TYSharedActivityText @"つぶやきを共有しました「%@」"
#define TYFavoritedActivityText @"つぶやきがお気に入りに登録されました「%@」"

@interface FMDatabase(Tubuyagi)

#pragma mark -factory
+ (FMDatabase *)databaseFactory;

#pragma mark -clear
- (void) deleteAllLearnedData;

#pragma mark -show
- (NSArray *)contentsInLearnLog;

- (NSArray *)activityArrayWithCount:(NSInteger)count;

#pragma mark -search

- (BOOL)findFavoriteByID:(NSString *)tweet_id;

- (NSInteger)valueForPreviousWord:(NSString*)previous
                    followingWord:(NSString*)following;

- (NSArray *)bigramsForPreviousWord:(NSString *)previous;

- (NSArray *)favoritedArrayWithCount:(NSInteger)count;

#pragma mark -sum

- (NSInteger)sumScoreForPreivousWord:(NSString *)previous;

- (NSInteger)sumFavoritedCount;

#pragma mark -add
- (void)logLearnedText:(NSString *)text;

- (void)logFavoriteTweet:(NSString *)tweetID;

- (void)logMyTweet:(NSString *)tweetID
           content:(NSString *)content;

- (void)logActivityText:(NSString *)text
                   type:(NSInteger)type;

-(void) updateBigramIncrease:(BOOL)increase
                previousWord:(NSString*)previous
               followingWord:(NSString*)following;

#pragma mark -remove
- (void)removeLearnLog:(NSString *)text;

#pragma mark -update
- (void)updateTweetLogForTweetID:(NSString *)tweetID
                  favoritedCount:(NSInteger)favoritedCount;

@end
