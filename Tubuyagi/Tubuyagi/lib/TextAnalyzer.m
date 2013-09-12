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
NSString*   sqlSelectBigramSet = @"SELECT * FROM bigram WHERE pre = %@";
NSString*   sqlUpdateBigram = @"UPDATE bigram SET count = %d WHERE pre = %@ AND post = %@;";
NSString*   bigramDatabaseName = @"bi-gram.db";
NSString*   learnLogDatabaseName = @"tweet-log.db";
NSString*   waraLogDatabaseName = @"wara-logv2.db";

FMDatabase* getDB(NSString * dbname){
    NSArray*    paths = NSSearchPathForDirectoriesInDomains( NSDocumentDirectory, NSUserDomainMask, YES );
    NSString*   dir   = [paths objectAtIndex:0];
    FMDatabase* db    = [FMDatabase databaseWithPath:[dir stringByAppendingPathComponent:dbname]];
    return db;
}

FMDatabase* getBigramDB(void){
    return getDB(bigramDatabaseName);
}

FMDatabase* getLearnLogDB(void){
    return getDB(learnLogDatabaseName);
}

FMDatabase* getWaraLogDB(void){
    return getDB(waraLogDatabaseName);
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

void deleteAllBigramData(void){
    FMDatabase* db    = getBigramDB();
    [db open];
    [db executeUpdateWithFormat:@"DROP TABLE bigram;"];
    [db close];
    deleteAllLearnLog();
}

void deleteAllLearnLog(void){
    FMDatabase* db    = getLearnLogDB();
    [db open];
    [db executeUpdateWithFormat:@"DROP TABLE learn_log;"];
    [db close];
}


NSMutableArray* showDeletableWords(void){
    FMDatabase* db    = getBigramDB();
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
    return result;
}

NSMutableArray* showDBContents(FMDatabase* db, NSString *db_name){
    NSMutableArray *result = [NSMutableArray array];
    [db open];
    FMResultSet* sqlResults = [db executeQuery:[NSString stringWithFormat: @"SELECT * FROM %@;", db_name]];
    while ([sqlResults next]){
        NSString *log = [sqlResults stringForColumn:@"content"];
        [result addObject:log];
    }
    [db close];
    
    return result;
}

NSMutableArray* showLearnLog(void){
    FMDatabase *db = getLearnLogDB();
    return showDBContents(db, @"learn_log");
}

NSMutableArray* showWaraLog(void){
    FMDatabase *db = getWaraLogDB();
    return showDBContents(db, @"wara_log");
}

bool isThereWara(long long post_id){
    FMDatabase* db    = getWaraLogDB();
    [db open];
    FMResultSet* sqlResults = [db executeQuery:@"SELECT * FROM wara_log WHERE post_id = ?",[NSNumber numberWithLongLong:post_id]];
    bool res = [sqlResults next];
    [db close];
    return res;
}

void deleteWord(NSString* word){
    FMDatabase* db    = getBigramDB();
    [db open];

    [db executeQueryWithFormat:@"DELETE FROM bigram WHERE pre = %@", word];
    [db executeQueryWithFormat:@"DELETE FROM bigram WHERE post = %@", word];
    NSLog(@"%@", [db lastError]);
    NSLog(@"%@", word);
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

void reduceBigramValue(FMDatabase *db, NSString* previous, NSString* current){
    FMResultSet* sqlResult = [db executeQueryWithFormat:sqlSelectBigram, previous, current];
    BOOL isThereTargetBigram = [sqlResult next];
    int value;
    
    if ([current isEqualToString:@"EOS"]){
        value = -10;
    } else {
        value = -1;
    }
    if (isThereTargetBigram){
        int count = [sqlResult intForColumn:@"count"];
        if (count + value <= 0){
            [db executeUpdateWithFormat:sqlDeleteBigram, previous, current];
        } else {
            [db executeUpdateWithFormat:sqlUpdateBigram, count + value, previous, current];
        }
    } else {
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
    FMDatabase* db    = getBigramDB();

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
        return @"メェ〜。";
    }
    
    return result;
}

#define _scheme_ NSLinguisticTagSchemeTokenType

void learnFromText(NSString* morphTargetText){
    NSArray *schemes = @[_scheme_];
    
    NSLinguisticTagger *tagger = [[NSLinguisticTagger alloc] initWithTagSchemes:schemes
                                                                        options:0];

    
    
    NSString* targetText = deleteNoises(morphTargetText);
    if ([targetText length] < 3){
        return;
    }
    [tagger setString:targetText];
    
    
    FMDatabase* learnLogDb    = getLearnLogDB();
    [learnLogDb open];
    [learnLogDb executeUpdate:@"CREATE TABLE IF NOT EXISTS learn_log (content TEXT NOT NULL);"];
    [learnLogDb executeUpdateWithFormat: @"INSERT INTO learn_log VALUES (%@)",morphTargetText];
    [learnLogDb close];
    
    FMDatabase* db    = getBigramDB();
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


#warning miyahara learnFromTextを変えたらこっちも変える必要あり。うまく関数にわけると解決可能
void forgetFromText(NSString* text){
    NSArray *schemes = @[_scheme_];
    
    NSLinguisticTagger *tagger = [[NSLinguisticTagger alloc] initWithTagSchemes:schemes
                                                                        options:0];
    NSString* targetText = deleteNoises(text);
    if ([targetText length] < 3){
        return;
    }
    [tagger setString:targetText];
    
    FMDatabase* learnLogDb    = getLearnLogDB();
    [learnLogDb open];
    [learnLogDb executeUpdateWithFormat: @"DELETE FROM learn_log WHERE content = %@",text];
    [learnLogDb close];
    
    FMDatabase* db    = getBigramDB();
    [db open];
    __block NSString *previousEntity = @"BOS";
    [tagger enumerateTagsInRange:NSMakeRange(0, targetText.length)
                          scheme:_scheme_
                         options:0
                      usingBlock:
     ^(NSString *tag, NSRange tokenRange, NSRange sentenceRange, BOOL *stop) {
         NSString *currentEntity = [targetText substringWithRange:tokenRange];
         if ([previousEntity isEqualToString:@"　"]){
             reduceBigramValue(db, @"BOS", currentEntity);
         } else if ([currentEntity isEqualToString:@"　"]){
             reduceBigramValue(db, previousEntity, @"EOS");
         } else {
             reduceBigramValue(db, previousEntity, currentEntity);
         }
         
         previousEntity = currentEntity;
     }];
    if (![previousEntity isEqualToString:@"BOS"]){
        reduceBigramValue(db, previousEntity, @"EOS");
    }
    [db close];
}

void addWaraLog(NSString *content, long long post_id, NSDate *date){
    FMDatabase* waraLogDb    = getWaraLogDB();
    [waraLogDb open];
    [waraLogDb executeUpdate:@"CREATE TABLE IF NOT EXISTS wara_log (content TEXT NOT NULL, wara INTEGER, post_id INTEGER, date TEXT);"];
#warning  miyahara ここの設計要検討
    [waraLogDb executeUpdateWithFormat: @"INSERT INTO wara_log VALUES (%@, 0, %qi, %@)",content, post_id,date];
    [waraLogDb close];
}

void addMyWaraLog(NSString *content){
    addWaraLog(content, 0, [NSDate date]);
}
@end
