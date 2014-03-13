//
//  NSString+SHA.h
//  Tubuyagi
//
//  Created by 宮原聡 on 2013/09/24.
//  Copyright (c) 2013年 Genki Ishibashi. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString(SHA)
- (NSString*) SHAString;
- (NSString*) getSHAForAuth;
@end
