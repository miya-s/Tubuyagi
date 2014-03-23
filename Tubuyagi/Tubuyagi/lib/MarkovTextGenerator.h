//
//  MarcovTextGenerator.h
//  Tubuyagi
//
//  Created by 宮原聡 on 2013/09/06.
//  Copyright (c) 2013年 Genki Ishibashi. All rights reserved.


#import <Foundation/Foundation.h>

@class FMDatabase;

@interface MarkovTextGenerator: NSObject

@property(readonly) FMDatabase* database;

+ (MarkovTextGenerator *)markovTextGeneratorFactory;

- (NSString *)generateSentence;

- (void)learnText:(NSString *)text;

- (void)forgetText:(NSString *)text;

@end
