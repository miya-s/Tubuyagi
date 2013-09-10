//
//  BasicRequest.h
//  Tubuyagi
//
//  Created by 宮原聡 on 2013/09/09.
//  Copyright (c) 2013年 Genki Ishibashi. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BasicRequest : NSObject

NSString *randStringWithLength(int length);
bool addUser(void);
bool addPost(NSString *content);

NSDictionary *getJSONRecents(int cursor, int num);
NSDictionary *getJSONTops(int cursor, int num);
@end
