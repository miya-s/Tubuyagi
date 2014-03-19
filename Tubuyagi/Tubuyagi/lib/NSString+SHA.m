//
//  NSString+SHA.m
//  Tubuyagi
//
//  Created by 宮原聡 on 2013/09/24.
//  Copyright (c) 2013年 Genki Ishibashi. All rights reserved.
//

#import "NSString+SHA.h"
#import <CommonCrypto/CommonDigest.h> // for CC_SHA
#import "AuthentificationKeys.h"
// AuthentificationKeysはgitの管理外にあります。ほしい人は kan.tan.san @ gmail.com まで

@implementation NSString (SHA)
- (NSString *) SHAString
{
    NSData *data = [self dataUsingEncoding:NSUTF8StringEncoding];
    
    uint8_t digest[CC_SHA256_DIGEST_LENGTH];
    
    CC_SHA256(data.bytes, data.length, digest);
    
    NSMutableString *output = [NSMutableString stringWithCapacity:CC_SHA256_DIGEST_LENGTH * 2];

    for(int i = 0; i < CC_SHA256_DIGEST_LENGTH; i++)
        [output appendFormat:@"%02x", digest[i]];
    
    return output;
}

-(NSString*)SHAStringForAuth
{
    NSLog(@"Hashfor%@",self);
    return [[NSString stringWithFormat: @"%@%@", self, TYSHAPassword] SHAString];
}
@end
