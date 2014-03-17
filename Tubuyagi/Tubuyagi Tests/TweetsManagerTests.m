//
//  TweetsManagerTests.m
//  Tubuyagi
//
//  Created by 宮原聡 on 2014/03/14.
//  Copyright (c) 2014年 Genki Ishibashi. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "TweetsManager.h"
@interface TweetsManagerTests : XCTestCase

@end

@interface TweetsManager(Test)
+(NSString *)encodeString:(NSString *)plainString;
+(NSString *)decodeString:(NSString *)encodedString;
+(NSString *)makeTweet:(NSString *)content;
+(BOOL)isValidTubuyaki:(NSDictionary *)tweet;
@end

@implementation TweetsManager(Test2)
/*getMyTwitterIDは、認証関連で面倒だったりするので、テスト時には無視*/
#warning TwitterIDはScreen_nameではなくなんか数字の羅列
+(NSString *)getMyTwitterID{
    return @"Tubuyagi";
}
@end

@implementation TweetsManagerTests

- (void)setUp
{
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testEncodeAndDecodeString{
    NSString *string = @"テスト";
    NSString *encodedString = @"%E3%83%86%E3%82%B9%E3%83%88";
    XCTAssertEqualObjects( string, [TweetsManager decodeString:[TweetsManager encodeString:string]], @"復号されない");
    XCTAssertEqualObjects( encodedString, [TweetsManager encodeString:string], @"エンコード結果が間違っている");
    XCTAssertEqualObjects( string, [TweetsManager decodeString:encodedString], @"デコード結果が間違っている");
}

/* make tweetまわりは仕様が変わる可能性が大きいので、細かいことは気にしない */
- (void)testMakeTweet{
    NSString *content = @"テスト";
    NSString *tweet = [TweetsManager makeTweet:content];
    XCTAssertEqualObjects(tweet, @"https://github.com/miya-s/Tubuyagi?auth=98fcde970c48e8e2172e0cb94890a25d8c56a7a8cde35d17b535855ba065a775&yaginame=%E3%81%A4%E3%81%B6%E3%82%84%E3%81%8E&content=%E3%83%86%E3%82%B9%E3%83%88 #つぶやぎ");
}

-(void) testCheckHash{
    NSString *twitterID = @"yagi";
    NSString *content = @"テスト";
    NSString *hash = [TweetsManager makeHashFromTweet:content twitterID:twitterID];
    XCTAssertTrue([TweetsManager checkHash:hash tweetContent:content twitterID:twitterID]);
    XCTAssertFalse([TweetsManager checkHash:hash tweetContent:@"テスト2" twitterID:twitterID]);
    XCTAssertFalse([TweetsManager checkHash:hash tweetContent:content twitterID:@"hogehoge"]);
}

-(void)testIsValidTubuyaki{
    NSDictionary *validTweet = @{@"text" : @"これオモシロすぎるだろｗｗｗｗｗ https://hoge.com #つぶやぎ",
                            @"entities" : @{@"urls" : @[@{@"expanded_url" : @"https://github.com/miya-s/Tubuyagi?auth=98fcde970c48e8e2172e0cb94890a25d8c56a7a8cde35d17b535855ba065a775&yaginame=%E3%81%A4%E3%81%B6%E3%82%84%E3%81%8E&content=%E3%83%86%E3%82%B9%E3%83%88"}]},
                            @"user" : @{@"id_str" : @"Tubuyagi"}};
    NSArray *invalidTweets = @[@{@"text" : @"これオモシロすぎるだろｗｗｗｗｗ https://hoge.com #つぶやぎ",
                                 @"entities" : @{@"urls" : @[@{@"expanded_url" : @"https://github.com/miya-s/Tubuyagi?auth=98fcde970c48e8e2172e0db94890a25d8c56a7a8cde35d17b535855ba065a775&yaginame=%E3%81%A4%E3%81%B6%E3%82%84%E3%81%8E&content=%E3%83%86%E3%82%B9%E3%83%88"}]},
                                 @"user" : @{@"id_str" : @"Tubuyagi"}},
                                    
                                    @{@"text" : @"これオモシロすぎるだろｗｗｗｗｗ https://hoge.com #つぶやぎ",
                                      @"entities" : @{@"urls" : @[@{@"expanded_url" : @"https://github.com/miya-s/Tubuyagi?auth=98fcde970c48e8e2172e0cb94890a25d8c56a7a8cde35d17b535855ba065a775&yaginame=%E3%81%A4%E3%81%B6%E3%82%84%E3%81%8E&content=%E3%83%86%E3%82%B9%E3%83%88"}]},
                                      @"user" : @{@"id_str" : @"HugaHuga"}},
                                    ];
    
    XCTAssertTrue([TweetsManager isValidTubuyaki:validTweet]);
    for (NSDictionary *tweet in invalidTweets){
        XCTAssertFalse([TweetsManager isValidTubuyaki:tweet]);
    }

}

@end
