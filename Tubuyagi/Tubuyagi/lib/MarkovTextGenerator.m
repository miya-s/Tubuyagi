//
//  TextAnalyzer.m
//  Tubuyagi
//
//  Created by 宮原聡 on 2013/09/06.
//  Copyright (c) 2013年 Genki Ishibashi. All rights reserved.
//

#import "MarkovTextGenerator.h"
#import "FMDatabase+Tubuyagi.h"

@implementation MarkovTextGenerator
{
}

static MarkovTextGenerator *singleMarkovTextGenerator = nil;

+ (MarkovTextGenerator *)markovTextGeneratorFactory{
    if (singleMarkovTextGenerator){
        return singleMarkovTextGenerator;
    }

    singleMarkovTextGenerator = [[MarkovTextGenerator alloc] init];

    return singleMarkovTextGenerator;
}

- (id) init{
    if (self = [super init]) {
        _database = [FMDatabase databaseFactory];
    }
    return self;
}

//
// Tweetにはハッシュタグなどが含まれるので、それを取り除く
//
NSString* deleteNoises(NSString *str){
    NSString *result = [str stringByReplacingOccurrencesOfString:@"\n" withString:@" "];
    NSRegularExpression *regexp;
    NSError *err = NULL;
    regexp = [NSRegularExpression regularExpressionWithPattern:@"　　" options:0 error:&err];
    result = [regexp stringByReplacingMatchesInString:result options:0 range:NSMakeRange(0, [result length]) withTemplate:@"　"];
    regexp = [NSRegularExpression regularExpressionWithPattern:@"(RT @.*?:|#[^ ]*|http(s)?://[/\\w-\\./?%&=]*)" options:0 error:&err];
    result = [regexp stringByReplacingMatchesInString:result options:0 range:NSMakeRange(0, [result length]) withTemplate:@""];
    regexp = [NSRegularExpression regularExpressionWithPattern:@"(@[\\w_0-9]*|RT|\\+|\\=|\\<|\\>|\\.|\\,|\\-|\\*|\\&|\\^|\"|\'|”|“|‘|’|:)" options:0 error:&err];
    result = [regexp stringByReplacingMatchesInString:result options:0 range:NSMakeRange(0, [result length]) withTemplate:@""];
    regexp = [NSRegularExpression regularExpressionWithPattern:@"(）|\\)|」|\\]|】|（|\\(|「|\\[|』|【|『)" options:0 error:&err];
    result = [regexp stringByReplacingMatchesInString:result options:0 range:NSMakeRange(0, [result length]) withTemplate:@""];
    return result;
}


- (NSString*) generateNextWordForPrevious:(NSString *)previous{
    int sum = [self.database sumScoreForPreivousWord: previous];
    NSArray * bigrams = [self.database bigramsForPreviousWord:previous];

    double k = (double)(arc4random() % 100) / 100;

    for (NSDictionary * bigram in bigrams){
        k -= (double)[[bigram objectForKey:@"count"] intValue] / sum;
        if (k <= 0){
            return [bigram objectForKey:@"post"];
        }
    }
    NSAssert(NO, @"理論上ここまでこない");
    return @"EOS";
}

// つぶやぎの文を生成
- (NSString *)generateSentence{
    NSString * previous = @"BOS";
    NSString * sentence =@"";

    int trial = 0;
    while (YES){
        while (YES){
            NSString * nextWord = [self generateNextWordForPrevious:previous];
            if ([nextWord isEqualToString:@"EOS"]){
                break;
            }
            if ([nextWord isEqualToString:@"。"] && [sentence length] > 20){
                sentence = [NSString stringWithFormat:@"%@%@",sentence, nextWord];
                break;
            }
            sentence = [NSString stringWithFormat:@"%@%@",sentence,nextWord];
            previous = nextWord;
        }
        if ([sentence length] < 3 && trial < 4){
            trial += 1;
            continue;
        }
        break;
    }

    if ([sentence length] < 2){
        return @"メェ〜。";
    }
    
    return sentence;
}

#define _scheme_ NSLinguisticTagSchemeTokenType
// 文を分かち書きして、学習
- (void)calcMorphedText:(NSString*)morphTargetText
           learn:(BOOL)learn{
    NSArray *schemes = @[_scheme_];
    
    NSLinguisticTagger *tagger = [[NSLinguisticTagger alloc] initWithTagSchemes:schemes
                                                                        options:0];

    NSString* targetText = deleteNoises(morphTargetText);
    if ([targetText length] < 3){
        return;
    }
    [tagger setString:targetText];
    
    //学習履歴を残す（または消す）
    if (learn){
        [self.database logLearnedText:morphTargetText];
    } else {
        [self.database removeLearnLog:morphTargetText];
    }
    
    //形態素解析して、逐次bigramをDBに追加
    __block NSString *previousEntity = @"BOS";
    __block __weak MarkovTextGenerator * weakself = self;
    [tagger enumerateTagsInRange:NSMakeRange(0, targetText.length)
                          scheme:_scheme_
                         options:0
                      usingBlock:
     ^(NSString *tag, NSRange tokenRange, NSRange sentenceRange, BOOL *stop) {
         NSString *currentEntity = [targetText substringWithRange:tokenRange];
         // TODO: 。もスペースと同じ扱いをする
         if ([previousEntity isEqualToString:@"　"]){
             [weakself.database updateBigramIncrease:learn
                                          previousWord:@"BOS"
                                         followingWord:currentEntity];
         } else if ([currentEntity isEqualToString:@"　"]){
             [weakself.database updateBigramIncrease:learn
                                          previousWord:previousEntity
                                         followingWord:@"EOS"];
         } else {
             [weakself.database updateBigramIncrease:learn
                                          previousWord:previousEntity
                                         followingWord:currentEntity];
         }

         previousEntity = currentEntity;
     }];
    
    if (![previousEntity isEqualToString:@"BOS"]){
        [self.database updateBigramIncrease:learn
                               previousWord:previousEntity
                              followingWord:@"EOS"];
    }
}

- (void)learnText:(NSString *)text{
    [self calcMorphedText:text learn:YES];
}

- (void)forgetText:(NSString *)text{
    [self calcMorphedText:text learn:NO];
}

@end
