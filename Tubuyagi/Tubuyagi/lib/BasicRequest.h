//
//  BasicRequest.h
//  Tubuyagi
//
//  Created by 宮原聡 on 2013/09/09.
//  Copyright (c) 2013年 Team IshiHara. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BasicRequest : NSObject

NSString *randStringWithLength(int length);
bool addUser(void);
bool addPost(NSString *content);
NSArray *getJSONRecents(int cursor, int num);
NSArray *getJSONTops(int cursor, int num);
bool addWara(long long post_id);
bool addWaraToMyTubuyaki(NSString *content);
bool addWaraToOthersTubuyaki(NSString *content,NSDate *date);
@end
