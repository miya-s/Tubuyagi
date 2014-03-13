//
//  MarcovTextGenerator.h
//  Tubuyagi
//
//  Created by 宮原聡 on 2013/09/06.
//  Copyright (c) 2013年 Genki Ishibashi. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FMDatabase.h"

@interface MarkovTextGenerator: NSObject

NSString* generateSentence(void);

void learnFromText(NSString* morphTargetText);

void forgetFromText(NSString* text);

void deleteAllBigramData(void);

void deleteAllLearnLog(void);

bool isThereWara(long long post_id);

bool isThereWaraByContent(NSString *str);

NSMutableArray* showLearnLog(void);

NSMutableArray* showWaraLog(void);

void addWaraLog(NSString *content, long long post_id, NSDate *date);

void addMyWaraLog(NSString *content, long long post_id);

void deleteWord(NSString *word);



@end
