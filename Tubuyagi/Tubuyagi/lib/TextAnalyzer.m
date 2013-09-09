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
NSString*   sqlDeleteBigram = @"DELETE FROM bigram WHERE pre = %@ AND post = %@;";
NSString*   sqlDeleteWord = @"DELETE FROM bigram WHERE pre = %@;DELETE * FROM bigram WHERE post = %@;";
NSString*   sqlSelectBigramSet = @"SELECT * FROM bigram WHERE pre = %@";
NSString*   sqlUpdateBigram = @"UPDATE bigram SET count = %d WHERE pre = %@ AND post = %@;";
NSString*   databaseName = @"bi-gram.db";

FMDatabase* getDB(NSString * dbname){
    NSArray*    paths = NSSearchPathForDirectoriesInDomains( NSDocumentDirectory, NSUserDomainMask, YES );
    NSString*   dir   = [paths objectAtIndex:0];
    FMDatabase* db    = [FMDatabase databaseWithPath:[dir stringByAppendingPathComponent:dbname]];
    return db;
}

NSString* deleteNoises(NSString *str){
    NSString *result = [str stringByReplacingOccurrencesOfString:@"\n" withString:@" "];
    NSRegularExpression *regexp;
    NSError *err = NULL;
    regexp = [NSRegularExpression regularExpressionWithPattern:@"(RT @.*?:|#[^ ]*|http(s)?://[/\\w-\\./?%&=]*)" options:0 error:&err];
    result = [regexp stringByReplacingMatchesInString:result options:0 range:NSMakeRange(0, [result length]) withTemplate:@""];
    regexp = [NSRegularExpression regularExpressionWithPattern:@"(@[\\w_0-9]*|RT|\\+|\\=|\\<|\\>|\\.|\\,|\\-|\\*|\\&|\\^|\"|\'|”|“|‘|’|:)" options:0 error:&err];
    result = [regexp stringByReplacingMatchesInString:result options:0 range:NSMakeRange(0, [result length]) withTemplate:@""];
    regexp = [NSRegularExpression regularExpressionWithPattern:@"(）|\\)|」|\\]|】|（|\\(|「|\\[|』|【|『)" options:0 error:&err];
    result = [regexp stringByReplacingMatchesInString:result options:0 range:NSMakeRange(0, [result length]) withTemplate:@"　"];
    return result;
}

void deleteAllData(void){
    FMDatabase* db    = getDB(databaseName);
    [db open];
    [db executeUpdateWithFormat:@"DROP TABLE bigram;"];
    [db close];
}

NSMutableArray* showDeletableWords(void){
    FMDatabase* db    = getDB(databaseName);
    NSMutableArray *result = [NSMutableArray array];
    [db open];
    FMResultSet* sqlResults = [db executeQuery:@"SELECT * FROM bigram ORDER BY count DESC"];
    int i = 0;
    while ([sqlResults next] && i < 20){
        NSString* targetPreWord = [sqlResults stringForColumn:@"pre"];

        if ([result indexOfObject:targetPreWord] != NSNotFound || [targetPreWord length] < 2){
            continue;
        }
        FMResultSet* res = [db executeQuery:@"SELECT COUNT(*) FROM bigram WHERE post = ?",targetPreWord];
        [res next];
        if ([res intForColumn:@"COUNT(*)"] > 1){
            [result addObject:targetPreWord];
            i+=1;
        }
    }
    [db close];
    NSLog(@"deletable : %@",result);
    return result;
}

void deleteWord(NSString* word){
    FMDatabase* db    = getDB(databaseName);
    [db open];
    [db executeQueryWithFormat:sqlDeleteWord, word, word];
    [db close];
}


void updateBigramValue(FMDatabase *db, NSString* previous, NSString* current){
    FMResultSet* sqlResult = [db executeQueryWithFormat:sqlSelectBigram, previous, current];
    BOOL isThereTargetBigram = [sqlResult next];
    int value;
    
    if ([current isEqualToString:@"EOS"]){
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
    FMDatabase* db    = getDB(databaseName);

    [db open];
    int trial = 0;
    while (true){
        while (true){
            NSString* next = generateNextWord(db, previous);
            if ([next isEqualToString:@"EOS"]){
                break;
            }
            if ([next isEqualToString:@"。"] && [result length] > 20){
                result = [NSString stringWithFormat:@"%@%@",result,next];
                break;
            }
            result = [NSString stringWithFormat:@"%@%@",result,next];
            previous = next;
        }
        if ([result length] < 3 && trial < 4){
            trial += 1;
            continue;
        }
        break;
    }
    [db close];
    if ([result length] < 2){
        result = @"メェ〜。";
    }
    showDeletableWords();
    return result;
}

#define _scheme_ NSLinguisticTagSchemeTokenType

void learnFromText(NSString* morphTargetText){
    
    NSArray *schemes = @[_scheme_];
    
    NSLinguisticTagger *tagger = [[NSLinguisticTagger alloc] initWithTagSchemes:schemes
                                                                        options:0];
    NSString* targetText = deleteNoises(morphTargetText);
    if ([targetText length] < 5){
        //短いやつけす
        return;
    }
    [tagger setString:targetText];
    
    FMDatabase* db    = getDB(databaseName);
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
         if ([previousEntity isEqualToString:@"　"]){
             updateBigramValue(db, @"BOS", currentEntity);
         } else if ([currentEntity isEqualToString:@"　"]){
             updateBigramValue(db, previousEntity, @"EOS");
         } else {
             updateBigramValue(db, previousEntity, currentEntity);             
         }

         previousEntity = currentEntity;
     }];
    if (![previousEntity isEqualToString:@"BOS"]){
        updateBigramValue(db, previousEntity, @"EOS");
    }
    [db close];
}
@end
