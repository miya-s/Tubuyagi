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

//自分の投稿をお気に入りに追加＆つぶやきを共有
bool addWaraToMyTubuyaki(NSString *content);
//自分のお気に入りに追加
bool addWaraToOthersTubuyaki(NSString *content,NSDate *date);
@end
