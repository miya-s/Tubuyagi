//
//  YagiView.h
//  YImage
//
//  Created by Genki Ishibashi on 13/09/07.
//  Copyright (c) 2013年 Genki Ishibashi. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AudioToolbox/AudioToolbox.h>
#import "ViewController.h"
#import "CMPopTipView.h"

@class UIYagiButton;

@interface YagiView : UIView<CMPopTipViewDelegate>

// ヤギをタッチした時の動作を管理
@property(readwrite) UIYagiButton *button;

// ヤギの発言が表示されるpopup
@property(readwrite) CMPopTipView *popTipView;

// 食べた発言が表示されるLabel
@property(readwrite) UILabel *lblYagiTweet;

// 一番最近生成した発言
@property(readonly) NSString *recentTweet;

// 一番最近撮影したスクリーンショット
@property(readwrite) UIImage *recentScreenShot;

- (id)initYagi;

- (void)reset;

- (void)stopWalk:(BOOL)hukigen;

- (void)walkRestart;

- (void)eatTweet:(NSString *)tweet;

- (void)dischargeWord;

- (void)allFoget;

- (void)tweet;

- (void)dismissPopTipView;

@end

@interface UIYagiButton : UIButton

@end

