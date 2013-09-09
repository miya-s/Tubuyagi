//
//  BasicRequest.m
//  Tubuyagi
//
//  Created by 宮原聡 on 2013/09/09.
//  Copyright (c) 2013年 Genki Ishibashi. All rights reserved.
//

#import "BasicRequest.h"

@implementation BasicRequest

NSString *randStringWithMaxLength(NSInteger max) {
    NSInteger length = randBetween(1, max);
    unichar letter[length];
    for (int i = 0; i < length; i++) {
        letter[i] = randBetween(65,90);
    }
    return [[NSString alloc] initWithCharacters:letter length:length];
}
NSInteger randBetween(NSInteger min, NSInteger max) {
    return (random() % (max - min + 1)) + min;
}

@end
