//
//  NSString+MD5.m
//  Tubuyagi
//
//  Created by 宮原聡 on 2013/09/24.
//  Copyright (c) 2013年 Genki Ishibashi. All rights reserved.
//

#import "NSString+MD5.h"
#import <CommonCrypto/CommonDigest.h> // for CC_MD5

@implementation NSString (MD5)
- (NSString *) MD5String
{
    const char *cStr = [self UTF8String];
    unsigned char result[CC_MD5_DIGEST_LENGTH];
    CC_MD5( cStr, strlen(cStr), result );
    return [NSString stringWithFormat:
            @"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x",
            result[0], result[1], result[2], result[3],
            result[4], result[5], result[6], result[7],
            result[8], result[9], result[10], result[11],
            result[12], result[13], result[14], result[15]
            ];  
}
-(NSString*)getMD5ForAuth
{
#warning AppStore公開直前にpassword変える
    // 総当りで解析できてしまうので、十分に長いpasswordにすること
    NSString *password = @"つぶやぎ　はチーム石原が提供します。";
    NSLog(@"Hashfor%@",self);
    return [[NSString stringWithFormat: @"%@%@", self, password] MD5String];
}
@end
