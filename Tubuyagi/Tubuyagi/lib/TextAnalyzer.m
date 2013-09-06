//
//  TextAnalyzer.m
//  Tubuyagi
//
//  Created by 宮原聡 on 2013/09/06.
//  Copyright (c) 2013年 Genki Ishibashi. All rights reserved.
//

#import "TextAnalyzer.h"

@implementation TextAnalyzer

NSString*   sqlAddBigram = @"INSERT INTO bigram VALUES (%@, %@, %d)";
NSString*   sqlSelectBigram = @"SELECT * FROM bigram WHERE pre = %@ AND post = %@;";
NSString*   sqlSelectBigramSet = @"SELECT * FROM bigram WHERE pre = %@";
NSString*   sqlUpdateBigram = @"UPDATE bigram SET count = %d WHERE pre = %@ AND post = %@;";
NSString*   databaseName = @"bi-gram.db";

NSString* escapeDangerousChars(NSString *str){
    //あとでRT後の部分とか消したり
    NSString *result = [str stringByReplacingOccurrencesOfString:@"\n" withString:@""];
    return result;
}

void updateBigramValue(FMDatabase *db, NSString* previous, NSString* current){
    FMResultSet* sqlResult = [db executeQueryWithFormat:sqlSelectBigram, previous, current];
    BOOL isThereTargetBigram = [sqlResult next];
    int value;
    
    if ([previous isEqualToString:@"。"]){
        value = 10;
    } else {
        value = 1;
    }
    if (isThereTargetBigram){
        int count = [sqlResult intForColumn:@"count"];
        [db executeUpdateWithFormat:sqlUpdateBigram, count + value, previous, current];
    } else {
        [db executeUpdateWithFormat:sqlAddBigram, previous, current, value];
    }
}

NSString* generateNextWord(FMDatabase *db, NSString *previous){
    FMResultSet* sqlResult = [db executeQueryWithFormat:sqlSelectBigramSet, previous];
    int sumOfCase = 0;
    while ([sqlResult next]){
        sumOfCase += [sqlResult intForColumn:@"count"];
    }
    sqlResult = [db executeQueryWithFormat:sqlSelectBigramSet, previous];
    
    double k = (double)(arc4random() % 100) / 100;
    while ([sqlResult next]){
        k -= (double)[sqlResult intForColumn:@"count"] / sumOfCase;
        if (k <= 0){
            return [sqlResult stringForColumn:@"post"];
        }
    }
    return @"EOS";
}

NSString* generateSentence(void){
    NSString* previous = @"BOS";
    NSString* result =@"";
    NSArray*    paths = NSSearchPathForDirectoriesInDomains( NSDocumentDirectory, NSUserDomainMask, YES );
    NSString*   dir   = [paths objectAtIndex:0];
    FMDatabase* db    = [FMDatabase databaseWithPath:[dir stringByAppendingPathComponent:databaseName]];
    
    [db open];
    while (true){
        NSString* next = generateNextWord(db, previous);
        if ([next isEqualToString:@"EOS"]){
            break;
        }
        result = [NSString stringWithFormat:@"%@%@",result,next];
        previous = next;
    }
    [db close];
    return result;
}

#define _scheme_ NSLinguisticTagSchemeTokenType

void learnFromText(NSString* morphTargetText){
    
    NSArray *schemes = @[_scheme_];
    
    NSLinguisticTagger *tagger = [[NSLinguisticTagger alloc] initWithTagSchemes:schemes
                                                                        options:0];
    NSString* targetText = escapeDangerousChars(morphTargetText);
    [tagger setString:targetText];
    
    NSArray*    paths = NSSearchPathForDirectoriesInDomains( NSDocumentDirectory, NSUserDomainMask, YES );
    NSString*   dir   = [paths objectAtIndex:0];
    FMDatabase* db    = [FMDatabase databaseWithPath:[dir stringByAppendingPathComponent:databaseName]];
    NSString*   sqlCreateTable = @"CREATE TABLE IF NOT EXISTS bigram (pre TEXT NOT NULL, post TEXT NOT NULL, count INTEGER NOT NULL);";
    
    [db open];
    [db executeUpdate:sqlCreateTable];
    
    __block NSString *previousEntity = @"BOS";
    [tagger enumerateTagsInRange:NSMakeRange(0, targetText.length)
                          scheme:_scheme_
                         options:0
                      usingBlock:
     ^(NSString *tag, NSRange tokenRange, NSRange sentenceRange, BOOL *stop) {
         NSString *currentEntity = [targetText substringWithRange:tokenRange];
         updateBigramValue(db, previousEntity, currentEntity);
         previousEntity = currentEntity;
     }];
    updateBigramValue(db, previousEntity, @"EOS");
    [db close];
}
@end
