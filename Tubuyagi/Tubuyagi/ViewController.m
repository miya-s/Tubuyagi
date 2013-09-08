//
//  ViewController.m
//  Tubuyagi
//
//  Created by Genki Ishibashi on 13/09/05.
//  Copyright (c) 2013年 Genki Ishibashi. All rights reserved.
//

#import "ViewController.h"
#import "FoodUIViewController.h"
#import "CMPopTipView.h"
#import "TextAnalyzer.h"


@interface ViewController ()

@end

@implementation ViewController
//@synthesize bblView = _bblView;

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    //ヤギの生成
    CGRect yagiRect = CGRectMake(70, 158, 230, 228);
    _yagiView = [[YagiView alloc] initWithFrame:yagiRect];
    [self.view addSubview:_yagiView];
    
    //ヤギを押した時のボタン
    btnYagi = [UIButton buttonWithType:UIButtonTypeCustom];
    btnYagi.frame = yagiRect;
    [btnYagi addTarget:self action:@selector(tweetYagi) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btnYagi];
    
    //PopTipViewの管理
    visiblePopTipViews = [NSMutableArray array];
    
    
//    UITapGestureRecognizer *gesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tweetYagi)];
//    [_yagiView addGestureRecognizer:gesture];
//    .userInteractionEnabled = YES;
    


    
    //bubbleView生成
//    CGRect bblRect = CGRectMake( 60, 100, 200, 115);
//    _bblView = [[bubbleView alloc] initWithFrame:bblRect];
//    self.bblView.backgroundColor = [UIColor clearColor];
//    [self.view addSubview:self.bblView];
    
    //食べる紙のVIew
    CGRect lblRect = CGRectMake(40, 330, 280, 52);
    lblYagiTweet = [[UILabel alloc] initWithFrame:lblRect];
    lblYagiTweet.text = @"aaaa";
    [self.view addSubview:lblYagiTweet];
    
    //twitter情報の取得
    [self getTwitterAccountInformation];
    
    [self initialize];
}

//位置設定の初期設定
- (void)initialize
{
    lblYagiTweet.frame = CGRectMake(40, 330, 280, 52);
    lblYagiTweet.alpha = 0.0;
    timerFlag = YES;
//    lblYagiTweet.transform = CGAffineTransformIdentity;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)chooseFood:(UIButton *)sender {
    
    FoodUIViewController *fvc = [[FoodUIViewController alloc] initWithNibName:@"FoodUIViewController" bundle:nil];
    fvc.delegate = self;
    fvc.twitterAccounts = self.twitterAccounts;
//    for (ACAccount *account in self.twitterAccounts) {

//    }
    NSLog(@"before title is %@", fvc.lblTitle);
    [self presentViewController:fvc animated:YES completion:nil];
    
    for (ACAccount *account in _twitterAccounts) {
        NSString *strTitle = [NSString stringWithFormat:@"%@のタイムライン", account.username];
        fvc.lblTitle.text = strTitle;//account.username;
    }

}

- (IBAction)setConfig:(UIButton *)sender {
    [self alert];
}





- (void)eatPaper
{
    lblYagiTweet.center = _yagiView.center;
    lblYagiTweet.transform = CGAffineTransformMakeScale(0.01, 0.01);
}

- (void)judgdeWalkRestart
{
    [_yagiView walkRestart];
    [self dismissAllPopTipViews];
    timerFlag = YES;
}

- (void)dismissAllPopTipViews {
	while ([visiblePopTipViews count] > 0) {
		CMPopTipView *popTipView = [visiblePopTipViews objectAtIndex:0];
		[popTipView dismissAnimated:YES];
		[visiblePopTipViews removeObjectAtIndex:0];
	}
}

- (void)tweetYagi
{
    [self dismissAllPopTipViews];

    //吹き出し
    CMPopTipView *popTipView = [[CMPopTipView alloc] initWithMessage:generateSentence()];
//    popTipView.delegate = self;
    popTipView.animation = 0;
    popTipView.has3DStyle = 0;
    [popTipView presentPointingAtView:btnYagi inView:self.view animated:YES];
    popTipView.backgroundColor = [UIColor whiteColor];
    popTipView.textColor = [UIColor blackColor];
    [visiblePopTipViews addObject:popTipView];
//    popTipView.center = CGPointMake(self.view.center.x, popTipView.center.y);
    
    //ヤギの動き
    [_yagiView stopWalk:NO];
    
    if (timerFlag == NO) {
        [timer invalidate];
    }
    timer = [NSTimer scheduledTimerWithTimeInterval:3.0f
                                    target:self
                                  selector:@selector(judgdeWalkRestart)
                                  userInfo:nil
                                   repeats:NO];
    timerFlag = NO;

}


- (void)alert{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"まだできていません" message:@"Coming Soon!" delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
    [alert show];
}

- (void)getTwitterAccountInformation
{
    _accountStore = [[ACAccountStore alloc] init];
    
    ACAccountType *accountType = [_accountStore accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierTwitter];
    NSArray *accounts = [_accountStore accountsWithAccountType:accountType];
    if (accounts.count == 0) {
        NSLog(@"Please add twitter account on Settings.");
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Twitterアカウント情報取得失敗" message:@"本体の環境設定からTwitterのアカウントを設定して下さい" delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
        [alert show];
        return;
    }
    NSLog(@"%@", _accountStore);
    [_accountStore requestAccessToAccountsWithType:accountType
                                           options:nil
                                        completion:^(BOOL granted, NSError *error) {
                                            dispatch_async(dispatch_get_main_queue(), ^{
                                                if (granted) {
                                                    //
                                                    // Get twitter accounts.
                                                    //
                                                    _twitterAccounts = [_accountStore accountsWithAccountType:accountType];
                                                    //
                                                    // Display accounts.
                                                    //
                                                    NSMutableString *text = [[NSMutableString alloc] initWithCapacity:200];
                                                    [text appendString:@"Twitter Accounts:\n"];
                                                    for (ACAccount *account in _twitterAccounts) {
                                                        [text appendString:@" > "];
                                                        [text appendString:account.username];
                                                        [text appendString:@"\n"];
                                                    }
                                                    NSLog(@"%@",text);
                                                } else {
                                                    NSLog(@"User denied to access twitter account.");
                                                }
                                            });
                                        }];

}


#pragma mark - FoodViewControllerDelegate

- (void)setTweetString:(NSString *)strTweet
{
    
    lblYagiTweet.alpha = 1.0;
    //    [UIView beginAnimations:nil context:NULL];
    //    [UIView setAnimationDuration:2.f];
    [UIView animateWithDuration:2.0f animations:^{
        lblYagiTweet.center = _yagiView.center;
        lblYagiTweet.transform = CGAffineTransformMakeScale(0.01, 0.01);
    } completion:^(BOOL finished){
        lblYagiTweet.transform = CGAffineTransformIdentity;
        [self initialize];
    }];
    lblYagiTweet.text = strTweet;
    
    //    [UIView commitAnimations];
    
    
}

- (void)foodCancel
{
    [_yagiView stopWalk:YES];
    [self performSelector:@selector(judgdeWalkRestart) withObject:nil afterDelay:2.4];
    
}
@end
