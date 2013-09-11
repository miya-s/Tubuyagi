//
//  BasicRequest.m
//  Tubuyagi
//
//  Created by 宮原聡 on 2013/09/09.
//  Copyright (c) 2013年 Team IshiHara All rights reserved.
//

#import "BasicRequest.h"
#import "TextAnalyzer.h"

@implementation BasicRequest

NSString *randStringWithLength(int length) {
    unichar letter[length];
    for (int i = 0; i < length; i++) {
        letter[i] = randBetween(65,90);
    }
    return [[NSString alloc] initWithCharacters:letter length:length];
}
NSInteger randBetween(NSInteger min, NSInteger max) {
    return (arc4random() % (max - min + 1)) + min;
}

bool addUser(void){
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    NSString *userName = [ud stringForKey: @"TDUserName"];
    NSURL *url = [NSURL URLWithString:@"http://tubu-yagi.appspot.com/api/add_user"];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setHTTPMethod:@"POST"];
    [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    
    NSString *reqBody = [NSString stringWithFormat: @"user_name=%@&random_pass=%@",userName, [ud stringForKey: @"TDRandomPassword"]];
    NSLog(@"reqBody: %@", reqBody);
    
    [request setHTTPBody:[reqBody dataUsingEncoding:NSUTF8StringEncoding]];
    
    
    __block NSString *result;
    __block BOOL outcome;
    [NSURLConnection sendAsynchronousRequest:request
                                       queue:[NSOperationQueue mainQueue]
     
                           completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
                               if (data) {
                                   result = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                                   NSLog(@"result: %@", result);
                                   [ud setBool:true forKey:@"TDSentPassword"];
                                   outcome = true;
                               } else {
                                   NSLog(@"error: %@", error);
                                   outcome = false;
                               }
                           }];
    return outcome;
}

bool addPost(NSString *content){
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    NSURL *url = [NSURL URLWithString:@"http://tubu-yagi.appspot.com/api/add_post"];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setHTTPMethod:@"POST"];
    [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    
    NSString *reqBody = [NSString stringWithFormat: @"user_name=%@&random_pass=%@&yagi_name=%@&content=%@", [ud stringForKey: @"TDUserName"], [ud stringForKey: @"TDRandomPassword"], [ud stringForKey:@"TDYagiName"], content];
    NSLog(@"reqBody: %@", reqBody);
    
    [request setHTTPBody:[reqBody dataUsingEncoding:NSUTF8StringEncoding]];
    
    
    __block NSString *result;
    __block BOOL outcome;
    [NSURLConnection sendAsynchronousRequest:request
                                       queue:[NSOperationQueue mainQueue]
     
                           completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
                               if (data) {
                                   result = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                                   NSLog(@"result: %@", result);
                                   outcome = true;
                               } else {
                                   NSLog(@"error: %@", error);
                                   outcome = false;
                               }
                           }];
    return outcome;
}

NSArray *getJSON(NSString *url){
    NSMutableURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:url]];
    NSData *json_data = [NSURLConnection sendSynchronousRequest:request returningResponse:nil error:nil];
    NSError *error=nil;
    
    
    NSArray *dict = [NSJSONSerialization JSONObjectWithData:json_data options:NSJSONReadingAllowFragments error:&error];
    return dict;
}

bool addWara(long long post_id){
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    NSURL *url = [NSURL URLWithString:@"http://tubu-yagi.appspot.com/api/add_wara"];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setHTTPMethod:@"POST"];
    [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    
    NSString *reqBody = [NSString stringWithFormat: @"user_name=%@&random_pass=%@&post_id=%lld", [ud stringForKey: @"TDUserName"], [ud stringForKey: @"TDRandomPassword"],post_id];
    NSLog(@"reqBody: %@", reqBody);
    
    [request setHTTPBody:[reqBody dataUsingEncoding:NSUTF8StringEncoding]];
    
    
    __block NSString *result;
    __block BOOL outcome;
    [NSURLConnection sendAsynchronousRequest:request
                                       queue:[NSOperationQueue mainQueue]
     
                           completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
                               if (data) {
                                   result = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                                   NSLog(@"result: %@", result);
                                   outcome = true;
                               } else {
                                   NSLog(@"error: %@", error);
                                   outcome = false;
                               }
                           }];
    return outcome;
}


bool addWaraToMyTubuyaki(NSString *content){
    if (isThereWara(content)) return false;
    bool outcome = addPost(content);
    if (outcome){
        addMyWaraLog(content);
    }
    return outcome;
}

bool addWaraToOthersTubuyaki(long long post_id, NSString *content,NSDate *date){
    if (isThereWara(content)) return false;
    addWaraLog(content,date);
    addWara(post_id);
    return true;
}

NSArray *getJSONRecents(int cursor, int num){
    
    return getJSON([NSString stringWithFormat: @"http://tubu-yagi.appspot.com/json/recent?cursor=%d&num=%d", cursor, num]);
}

NSArray *getJSONTops(int cursor, int num){
    return getJSON([NSString stringWithFormat: @"http://tubu-yagi.appspot.com/json/top?cursor=%d&num=%d", cursor, num]);
}

@end
