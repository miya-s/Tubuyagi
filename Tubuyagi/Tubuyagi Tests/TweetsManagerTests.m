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

@interface TweetsManager(TYTweetsManagerTest)
NSString *TYEncodeString(NSString *plainString);
NSString *TYDecodeString(NSString *encodedString);
NSString *TYMakeTweet(NSString *content);
BOOL TYCheckHash(NSString *hash, NSString*content, NSString *twitterID);
NSDictionary *TYExtractElementsFromURL(NSString *url, NSError **error);
BOOL TYTweetIsQualified(NSDictionary *tweet, NSError** error);
NSString *TYMakeHashFromTweet(NSString *tweet, NSString*twitterID);
@end

@implementation TweetsManagerTests

- (void)setUp
{
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
    
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    [ud setObject:@"Tubuyagi" forKey:@"TDUserTwitterID"];
    [ud synchronize];
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testEncodeAndDecodeString{
    NSString *string = @"テスト";
    NSString *encodedString = @"%E3%83%86%E3%82%B9%E3%83%88";
    XCTAssertEqualObjects( string, TYDecodeString(TYEncodeString(string)), @"復号されない");
    XCTAssertEqualObjects( encodedString, TYEncodeString(string), @"エンコード結果が間違っている");
    XCTAssertEqualObjects( string, TYDecodeString(encodedString), @"デコード結果が間違っている");
}

/* make tweetまわりは仕様が変わる可能性が大きいので、細かいことは気にしない */
- (void)testMakeTweet{
    NSString *content = @"テスト";
    NSString *tweet = TYMakeTweet(content);
    XCTAssertEqualObjects(tweet, @"https://github.com/miya-s/Tubuyagi?auth=98fcde970c48e8e2172e0cb94890a25d8c56a7a8cde35d17b535855ba065a775&yaginame=%E3%81%A4%E3%81%B6%E3%82%84%E3%81%8E&content=%E3%83%86%E3%82%B9%E3%83%88 #つぶやぎ");
}

-(void) testCheckHash{
    NSString *twitterID = @"yagi";
    NSString *content = @"テスト";
    NSString *hash = TYMakeHashFromTweet(content, twitterID);
    XCTAssertTrue(TYCheckHash(hash, content, twitterID));
    XCTAssertFalse(TYCheckHash(hash, @"テスト2", twitterID));
    XCTAssertFalse(TYCheckHash(hash, content, @"hogehoge"));
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
    NSError *error = nil;
    BOOL result = TYTweetIsQualified(validTweet, &error);
    NSAssert(result, [error description]);
    XCTAssertTrue(TYTweetIsQualified(validTweet, &error));
    for (NSDictionary *invalidTweet in invalidTweets){
        XCTAssertFalse(TYTweetIsQualified(invalidTweet, &error));
    }

}

@end
