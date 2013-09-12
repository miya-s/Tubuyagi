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

void addUser(void){
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    NSString *userName = [ud stringForKey: @"TDUserName"];
    NSURL *url = [NSURL URLWithString:@"http://tubu-yagi.appspot.com/api/add_user"];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setHTTPMethod:@"POST"];
    [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    
    NSString *reqBody = [NSString stringWithFormat: @"user_name=%@&random_pass=%@",userName, [ud stringForKey: @"TDRandomPassword"]];
    NSLog(@"reqBody: %@", reqBody);
    
    [request setHTTPBody:[reqBody dataUsingEncoding:NSUTF8StringEncoding]];
    
    
    [NSURLConnection sendAsynchronousRequest:request
                                       queue:[NSOperationQueue mainQueue]
     
                           completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {

                                if (data) {
                                    NSString *result;
                                    result = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                                   NSLog(@"result: %@", result);
                                   [ud setBool:true forKey:@"TDSentPassword"];
                               } else {
                                   NSLog(@"error: %@", error);
                               }
                           }];
}

void addPost(NSString *content){
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    NSURL *url = [NSURL URLWithString:@"http://tubu-yagi.appspot.com/api/add_post"];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setHTTPMethod:@"POST"];
    [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    
    NSString *reqBody = [NSString stringWithFormat: @"user_name=%@&random_pass=%@&yagi_name=%@&content=%@", [ud stringForKey: @"TDUserName"], [ud stringForKey: @"TDRandomPassword"], [ud stringForKey:@"TDYagiName"], content];
    NSLog(@"reqBody: %@", reqBody);
    
    [request setHTTPBody:[reqBody dataUsingEncoding:NSUTF8StringEncoding]];
    
    [NSURLConnection sendAsynchronousRequest:request
                                       queue:[NSOperationQueue mainQueue]
     
                           completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
                               if (data) {
                                   NSString *result;
                                   result = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                                   NSLog(@"result: %@", result);
                               } else {
                                   NSLog(@"error: %@", error);
                               }
                           }];
}

void *getJSON(NSString *url, void (^success)(NSArray *result) ){
    NSURL *url1 = [NSURL URLWithString:url];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url1];
    [request setHTTPMethod:@"GET"];
    [NSURLConnection sendAsynchronousRequest:request
                                       queue:[NSOperationQueue mainQueue]
     
                           completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
                               if (data) {
                                   NSArray *result = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:&error];
                                   success(result);
                                    NSLog(@"result: %@", result);
                               } else {
                                   NSLog(@"error: %@", error);
                               }
                           }];
    /*
    NSLog(@"1");
    NSError *error1 = nil;
    NSMutableURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:url]];
    NSLog(@"2");
    //ここでつまる
    NSData *json_data = [NSURLConnection sendSynchronousRequest:request returningResponse:nil error:&error1];
    NSLog(@"error %@", error1);
    
    if (!(error1 == NULL)) {

        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"接続できません"
                                                        message:@"ネットの繋がる場所で再度トライして下さい"
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        [alert show];

        return nil;
    }
    NSError *error=nil;
    NSLog(@"3");
    NSArray *dict = [NSJSONSerialization JSONObjectWithData:json_data options:NSJSONReadingAllowFragments error:&error];
    NSLog(@"%@",dict);
    NSLog(@"%@", error);
    return dict;*/
}

void addWara(long long post_id){
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    NSURL *url = [NSURL URLWithString:@"http://tubu-yagi.appspot.com/api/add_wara"];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setHTTPMethod:@"POST"];
    [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    
    NSString *reqBody = [NSString stringWithFormat: @"user_name=%@&random_pass=%@&post_id=%qi", [ud stringForKey: @"TDUserName"], [ud stringForKey: @"TDRandomPassword"], post_id];
    NSLog(@"reqBody: %@", reqBody);
    
    [request setHTTPBody:[reqBody dataUsingEncoding:NSUTF8StringEncoding]];
    
    [NSURLConnection sendAsynchronousRequest:request
                                       queue:[NSOperationQueue mainQueue]
     
                           completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
                               NSString *result;
                               if (data) {
                                   result = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                                   NSLog(@"result: %@", result);
                               } else {
                                   NSLog(@"error: %@", error);
                               }
                           }];
}


void addWaraToMyTubuyaki(NSString *content){
    if (isThereWaraByContent(content)){
        NSLog(@"you faved the post you have already faved.");
        return;
    }
    addPost(content);
#warning addPostがブロックを取れるようにして、addMyWaraLogは成功時のみ
    addMyWaraLog(content);
}

void addWaraToOthersTubuyaki(long long post_id, NSString *content,NSDate *date){
    if (isThereWara(post_id)){
        NSLog(@"you faved the post you have already faved.");
        return;
    }
    addWaraLog(content, post_id, date);
    addWara(post_id);
}

void *getJSONRecents(int cursor, int num, void (^success)(NSArray *result)){
    getJSON([NSString stringWithFormat: @"http://tubu-yagi.appspot.com/json/recent?cursor=%d&num=%d", cursor, num], success);
}

void *getJSONTops(int cursor, int num, void (^success)(NSArray *result)){
    getJSON([NSString stringWithFormat: @"http://tubu-yagi.appspot.com/json/top?cursor=%d&num=%d", cursor, num], success);
}

@end
