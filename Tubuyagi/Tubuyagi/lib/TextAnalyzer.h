//
//  TextAnalyzer.h
//  Tubuyagi
//
//  Created by 宮原聡 on 2013/09/06.
//  Copyright (c) 2013年 Genki Ishibashi. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FMDatabase.h"

@interface TextAnalyzer : NSObject
NSString* generateSentence(void);
void learnFromText(NSString* morphTargetText);
void forgetFromText(NSString* text);
void deleteAllBigramData(void);
void deleteAllLearnLog(void);
bool isThereWara(NSString* content);
NSMutableArray* showDeletableWords(void);
NSMutableArray* showLearnLog(void);
NSMutableArray* showWaraLog(void);
void addWaraLog(NSString *content,NSDate *date);
void addMyWaraLog(NSString *content);
void deleteWord(NSString *word);
@end
