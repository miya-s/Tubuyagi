//
//  AppDelegate.h
//  Tubuyagi
//
//  Created by Genki Ishibashi on 13/09/05.
//  Copyright (c) 2013年 Team IshiHara. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ViewController;

@interface AppDelegate : UIResponder <UIApplicationDelegate>
{
    int kaisuu;
    UIImageView *viewStart;
    UIButton *btnStart, *btnSkip;
    UIView *viewBlack;
    UIScrollView *scrStory, *scrTutorial;
    NSTimer *timer;
}

@property (strong, nonatomic) UIWindow *window;

@property (strong, nonatomic) ViewController *viewController;

@end
