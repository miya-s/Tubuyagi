//
//  ViewController.h
//  Tubuyagi
//
//  Created by Genki Ishibashi on 13/09/05.
//  Copyright (c) 2013年 Genki Ishibashi. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Accounts/Accounts.h>
#import <Social/Social.h>
#import "FoodUIViewController.h"
#import "bubbleView.h"
#import "YagiView.h"

@interface ViewController : UIViewController<FoodViewControllerDelegate>
{
    BOOL timerFlag;
    UILabel *lblYagiTweet;
    UIButton *btnYagi;
    NSMutableArray *visiblePopTipViews;
    NSTimer *timer;
//    NSArray *twitterAccounts;
//    NSArray *tweets;
}
@property (strong, nonatomic) IBOutlet UILabel *strYagiName;
//@property (strong, nonatomic) IBOutlet UILabel *strYagiTweet;
@property (strong, nonatomic) bubbleView *bblView;
//@property (weak, nonatomic) IBOutlet UIImageView *imgViewYagi;
@property (nonatomic, retain) ACAccountStore *accountStore;
@property (nonatomic, retain) NSArray *twitterAccounts;
@property (nonatomic, retain) YagiView *yagiView;

- (IBAction)chooseFood:(UIButton *)sender;
- (IBAction)setConfig:(UIButton *)sender;
@end
