//
//  FMDatabase+Tubuyagi.m
//  Tubuyagi
//
//  Created by 宮原聡 on 2014/03/23.
//  Copyright (c) 2014年 Genki Ishibashi. All rights reserved.
//

// !!!:executeQueryとexecuteUpdateを混同しない

#import "FMDatabase+Tubuyagi.h"
#import "NSDate+TimeAgo.h"

@implementation FMDatabase(Tubuyagi)

// DBのファイル名
NSString * const TYDatabaseName = @"tsubuyagi.db";

// singletonパターン用のdatabase
static FMDatabase* _singleDatabase = nil;

#pragma mark-constants

// query
NSString * const TYQueryToAddBigram = @"INSERT INTO bigram VALUES (?, ?, ?);";
NSString * const TYQueryToSelectBigram = @"SELECT * FROM bigram WHERE pre = ? AND post = ?;";
NSString * const TYQueryToDeleteBigram = @"DELETE FROM bigram WHERE pre = ? AND post = ?;";
NSString * const TYQueryToSelectBigramSet = @"SELECT * FROM bigram WHERE pre = ?;";
NSString * const TYQueryToUpdateBigram = @"UPDATE bigram SET count = ? WHERE pre = ? AND post = ?;";

#pragma mark-factory
// FMDBのイニシャライザを書き換えると面倒なことになりそう + singletonパターンにしたい
+ (FMDatabase *)databaseFactory{
    if (_singleDatabase){
        return _singleDatabase;
    }
    NSArray*    paths = NSSearchPathForDirectoriesInDomains( NSDocumentDirectory, NSUserDomainMask, YES );
    NSString*   dir   = [paths objectAtIndex:0];
    FMDatabase* newDatabase    = [FMDatabase databaseWithPath:[dir stringByAppendingPathComponent:TYDatabaseName]];
    [newDatabase execBlock:^(FMDatabase *db) {
        [db open];
        [db executeUpdate:@"CREATE TABLE IF NOT EXISTS learn_log (content TEXT NOT NULL);"];
        [db executeUpdate:@"CREATE TABLE IF NOT EXISTS bigram (pre TEXT NOT NULL, post TEXT NOT NULL, count INTEGER NOT NULL);"];
        [db executeUpdate:@"CREATE TABLE IF NOT EXISTS favorite_log (tweet_id TEXT NOT NULL);"];
        [db executeUpdate:@"CREATE TABLE IF NOT EXISTS tweet_log (tweet_id TEXT NOT NULL, content TEXT NOT NULL, favorited_count INTEGER NOT NULL);"];
        [db executeUpdate:@"CREATE TABLE IF NOT EXISTS activity_log (text TEXT NOT NULL, seen INTEGER NOT NULL, type INTEGER NOT NULL, date REAL NOT NULL);"];
        
        [db close];
    }];
    _singleDatabase = newDatabase;
    return newDatabase;
}

- (void)execBlock:(void(^)(FMDatabase *db))block{
    [self open];
    block(self);
    [self close];
}

#pragma mark -clear
// 学習ログを全消去
- (void) deleteAllLearnedData{
    [self execBlock:^(FMDatabase *db) {
        [db executeUpdateWithFormat:@"DELETE FROM bigram;"];
        [db executeUpdateWithFormat:@"DELETE FROM learn_log;"];
    }];
}

#pragma mark -show

// Tableの中身をarrayとして返す
- (NSArray *)contentsInTable:(NSString *)tableName{
    NSMutableArray *dataToShow = [NSMutableArray array];
    [self execBlock:^(FMDatabase *db) {
        // ???:ここ、select content fromでいいのでは？
        FMResultSet* sqlResults = [db executeQuery:[NSString stringWithFormat: @"SELECT * FROM %@;", tableName]];
        while ([sqlResults next]){
            NSString *log = [sqlResults stringForColumn:@"content"];
            [dataToShow addObject:log];
        }
    }];
    return dataToShow;
}

- (NSArray *)contentsInLearnLog{
    return [self contentsInTable:@"learn_log"];
}

// お気に入られ履歴の配列を得る
- (NSArray *)favoritedArrayWithCount:(NSInteger)count{
    __block NSInteger i = 0;
    __block NSMutableArray *favoritedTweets = [NSMutableArray arrayWithArray:@[]];
    [self execBlock:^(FMDatabase *db) {
        FMResultSet* sqlResults = [db executeQuery:@"SELECT * FROM tweet_log ORDER BY tweet_id DESC"];
        NSError *error = [db lastError];
        if (error) NSLog(@"%@", [error description]);
        while ([sqlResults next]){
            if (i >= count){
                break;
            }
            NSDictionary *tweet = @{@"tweet_id" : [sqlResults stringForColumn:@"tweet_id"],
                                    @"content" : [sqlResults stringForColumn:@"content"],
                                    @"favorited_count" : [NSNumber numberWithInt:[sqlResults intForColumn:@"favorited_count"]]};
            [favoritedTweets addObject:tweet];
            i += 1;
        }
    }];
    return favoritedTweets;
}

// アクティビティの配列を得る
- (NSArray *)activityArrayWithCount:(NSInteger)count{
    __block NSInteger i = 0;
    __block NSMutableArray *activities = [NSMutableArray arrayWithArray:@[]];
    [self execBlock:^(FMDatabase *db) {
        // TODO:ここでソート
        FMResultSet* sqlResults = [db executeQuery:@"SELECT * FROM activity_log"];
        NSError *error = [db lastError];
        if (error) NSLog(@"%@", [error description]);
        while ([sqlResults next]){
            if (i >= count){
                break;
            }
            
#warning dateはTimeAgoメソッドの値を返したいが、エラーが出る
            NSDictionary *activity = @{@"text" : [sqlResults stringForColumn:@"text"],
                                       @"seen" : [NSNumber numberWithBool:[sqlResults boolForColumn:@"seen"]],
                                       @"type" : [NSNumber numberWithInt:[sqlResults intForColumn:@"type"]],
                                       @"date" : [[sqlResults dateForColumn:@"date"] description]};
            [activities addObject:activity];
            i += 1;
        }
    }];
    return activities;
}


#pragma mark -search
// 指定したIDのツイートをすでにふぁぼったか
// Twitterのapiが正しい値を返してくれないのでこれを使う
- (BOOL)findFavoriteByID:(NSString *)tweet_id{
    __block BOOL found;
    [self execBlock:^(FMDatabase *db) {
        FMResultSet* sqlResults = [db executeQuery:@"SELECT * FROM favorite_log WHERE tweet_id = ?", tweet_id];
        found = [sqlResults next];
    }];
    return found;
}

// bigramのスコアを取得
// そもそもBigramが存在しない場合は 0
- (NSInteger)valueForPreviousWord:(NSString*)previous
                    followingWord:(NSString*)following{
    __block int score;
    [self execBlock:^(FMDatabase *db) {
        FMResultSet* queryResult;
        queryResult = [db executeQuery:TYQueryToSelectBigram, previous, following];
        BOOL exist = [queryResult next];
        score = exist ? [queryResult intForColumn:@"count"] : 0;
    }];
    NSAssert(score >= 0, @"score for bigram should be positive");
    return score;
}

// 特定のpreviousを持つbigramのArrayを取得
// 戻り値の形式はDictionaryが入ったArray
- (NSArray *)bigramsForPreviousWord:(NSString *)previous{
    __block NSMutableArray *bigrams = [NSMutableArray arrayWithArray:@[]];
    
    [self execBlock:^(FMDatabase *db){
        FMResultSet* queryResult = [db executeQuery:TYQueryToSelectBigramSet, previous];
        NSLog(@"%@", [db lastErrorMessage]);
        while ([queryResult next]){
            [bigrams addObject:
             @{@"count" : [NSNumber numberWithInt:[queryResult intForColumn:@"count"]],
               @"post" : [queryResult stringForColumn:@"post"]}];
        }
    }];
    return bigrams;
}

#pragma mark -sum
- (NSInteger)sumScoreForPreivousWord:(NSString *)previous{
    __block NSInteger sum;
    [self execBlock:^(FMDatabase *db) {
        FMResultSet* queryResult = [self executeQuery:TYQueryToSelectBigramSet, previous];
        sum = 0;
        while ([queryResult next]){
            sum += [queryResult intForColumn:@"count"];
        }
    }];
    return sum;
}

// 総お気に入られ数を集計する
- (NSInteger)sumFavoritedCount{
    __block NSInteger sum;
    [self execBlock:^(FMDatabase *db) {
        FMResultSet* queryResult = [self executeQuery:@"SELECT * FROM tweet_log;"];
        sum = 0;
        while ([queryResult next]){
            NSInteger favorited_count = [queryResult intForColumn:@"favorited_count"];
            sum += favorited_count;
        }
        NSLog(@"Error%@", [db lastError]);
    }];
    return sum;
}

#pragma mark -update
-(void) updateBigramIncrease:(BOOL)increase
             previousWord:(NSString*)previous
            followingWord:(NSString*)following
{
    
    int oldScore = [self valueForPreviousWord:previous
                                followingWord:following];
    
    // スコア増加分。文末は出やすくする
    int difference = [following isEqualToString:@"EOS"] ? 10 : 1;
    if (!increase){
        difference *= -1;
    }
    
    // すでに登録済みであれば、それに足す
    // 0以下になったら消去
    if (oldScore > 0){
        int finalValue = difference + oldScore;
        if (finalValue > 0){
            [self execBlock:^(FMDatabase *db) {
                [db executeUpdate:TYQueryToUpdateBigram, [NSNumber numberWithInt:finalValue], previous, following];
            }];
            
            return;
        }
        
        //消去
        [self execBlock:^(FMDatabase *db) {
            [db executeUpdate:TYQueryToDeleteBigram, previous, following];
         }];
        return;
    }
    
    // そうでなければ登録
    NSAssert(difference > 0, @"bigram value should be more than 0");
    if (difference > 0){
        [self execBlock:^(FMDatabase *db) {
            [db executeUpdate:TYQueryToAddBigram, previous, following, [NSNumber numberWithInt:difference]];
        }];
    }
}

- (void)logLearnedText:(NSString *)text{
    [self execBlock:^(FMDatabase *db) {
        [db executeUpdate: @"INSERT INTO learn_log VALUES (?)",text];
    }];
}

- (void)removeLearnLog:(NSString *)text{
    [self execBlock:^(FMDatabase *db) {
        [db executeUpdate: @"DELETE FROM learn_log WHERE content = ?",text];
    }];
}

// お気に入り履歴追加
- (void)logFavoriteTweet:(NSString *)tweetID{
    [self execBlock:^(FMDatabase *db) {
        [db executeUpdate: @"INSERT INTO favorite_log VALUES (?)", tweetID];
    }];
}

// 投稿履歴に追加
- (void)logMyTweet:(NSString *)tweetID
           content:(NSString *)content{
    [self execBlock:^(FMDatabase *db) {
        [db executeUpdate: @"INSERT INTO tweet_log VALUES (?, ?, 0)", tweetID, content];
    }];
}

// 投稿履歴に追加
- (void)logActivityText:(NSString *)text
                   type:(NSInteger)type{
    [self execBlock:^(FMDatabase *db) {
        [db executeUpdate: @"INSERT INTO activity_log VALUES (?, 0, ?, ?)", text, [NSNumber numberWithInt:type], [NSDate date]];
    }];
}

// 投稿履歴から、特定tweet_idの履歴がないかチェック
- (void)updateTweetLogForTweetID:(NSString *)tweetID
                  favoritedCount:(NSInteger)favoritedCount
{
    [self execBlock:^(FMDatabase *db) {
        FMResultSet* sqlResults = [db executeQuery:@"SELECT * FROM tweet_log WHERE tweet_id = ?", tweetID];
        [sqlResults next];
        NSInteger oldFavoritedCount = [sqlResults intForColumn:@"favorited_count"];
        if (oldFavoritedCount < favoritedCount){
            [db executeUpdate:@"UPDATE tweet_log SET favorited_count = ? WHERE tweet_id = ?;", [NSNumber numberWithInt: favoritedCount], tweetID];
            NSLog(@"%@", [[db lastError] description]);
        }
    }];
}

@end
