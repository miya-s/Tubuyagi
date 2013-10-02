//
//  NSString+MD5.h
//  Tubuyagi
//
//  Created by 宮原聡 on 2013/09/24.
//  Copyright (c) 2013年 Genki Ishibashi. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString(MD5)
- (NSString*) MD5String;
- (NSString*) getMD5ForAuth;
@end
