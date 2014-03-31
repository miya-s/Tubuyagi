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
#import "DeleteWordTableViewController.h"
//#import "ManualInputViewController.h"
#import "FavoriteViewController.h"
#import "bubbleView.h"
#import "TreeView.h"
#import "TweetsManager.h"
#import "YagiView.h"
#import "CMPopTipView.h"

@class YagiView;

@interface ViewController : UIViewController<FoodViewControllerDelegate, UIActionSheetDelegate,
                                                CMPopTipViewDelegate, UIAlertViewDelegate, DeleteWordTabelViewControllerDelegate,
                                                UITabBarControllerDelegate,UITextFieldDelegate,
                                                FavoriteViewControllerDelegate>
{
    BOOL twitterAcountFlag;//本体にアカウントが設定されてないフラグ
    BOOL twitterAcountflag2;//電波が通じないフラグ
    NSArray *tweets;
    NSString *userName;
    FoodUIViewController *fvc;
    
    FavoriteViewController *fvvc1, *fvvc2, *fvvc3;
}
@property (nonatomic, retain) ACAccountStore *accountStore;
@property (nonatomic, retain) NSArray *twitterAccounts;
@property (nonatomic, retain) YagiView *yagiView;
@property (nonatomic, retain) TreeView *treeView;
@property (nonatomic, retain) TweetsManager *tweetsManager;
@property (strong, nonatomic) IBOutlet UIButton *btnChooseFood;
@property (strong, nonatomic) IBOutlet UIButton *btnshowFavolite;
@property (strong, nonatomic) IBOutlet UIImageView *imgSaku;
@property (strong, nonatomic) IBOutlet UILabel *strStatus;
@property (strong, nonatomic) IBOutlet UIButton *btnConfig;
@property (strong, nonatomic) IBOutlet UIButton *btnForget;
@property (strong, nonatomic) IBOutlet UILabel *strWara;
@property (strong, nonatomic) IBOutlet UILabel *strOwnerName;
@property (strong, nonatomic) IBOutlet UILabel *strYagiName;
@property (strong, nonatomic) IBOutlet UITextField *txfYagiName;
@property (strong, nonatomic) IBOutlet UIView *configView;
@property (readwrite) BOOL availableButtons;

- (IBAction)chooseFood:(UIButton *)sender;
- (IBAction)setConfig:(UIButton *)sender;
- (IBAction)forgetWord:(UIButton *)sender;
- (IBAction)showFavorite:(id)sender;
- (IBAction)closeConfigView:(id)sender;
- (void)alert;


@end
