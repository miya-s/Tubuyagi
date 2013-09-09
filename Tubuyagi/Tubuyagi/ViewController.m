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
#import "STTwitter.h"


@interface ViewController ()

@end

@implementation ViewController
//@synthesize bblView = _bblView;

- (void)viewDidLoad
{
    NSLog(@"ViewDidLoad");
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
    
    //FoodViewControllerの生成
    fvc = [[FoodUIViewController alloc] initWithNibName:@"FoodUIViewController" bundle:nil];
    fvc.delegate = self;
    fvc.twitterAccounts = self.twitterAccounts;
    
    //食べる紙のVIew
    CGRect lblRect = CGRectMake(40, 330, 280, 52);
    lblYagiTweet = [[UILabel alloc] initWithFrame:lblRect];
    lblYagiTweet.text = @"aaaa";
    [self.view addSubview:lblYagiTweet];
    
    //twitter情報の取得
    [self getTwitterAccountInformation];
    
    [self initialize];
    

//    [_yagiView eatFood];
}

//位置設定の初期設定
- (void)initialize
{
    NSLog(@"initialize");
    lblYagiTweet.frame = CGRectMake(40, 330, 280, 52);
    lblYagiTweet.alpha = 0.0;
    timerFlag = YES;
}

- (void)didReceiveMemoryWarning
{
    NSLog(@"memoryWarning");
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)chooseFood:(UIButton *)sender {
    
    [self presentViewController:fvc animated:YES completion:nil];
    fvc.lblTitle.text = userName;
}

- (IBAction)setConfig:(UIButton *)sender {
    NSLog(@"setConfig");
    [self alert];
}


- (void)eatPaper
{
    NSLog(@"eatPaper");
    lblYagiTweet.center = _yagiView.center;
    lblYagiTweet.transform = CGAffineTransformMakeScale(0.01, 0.01);
}

- (void)judgdeWalkRestart
{
    NSLog(@"judgeWalkRestart");
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
    //STTwitter
//    [self.foodTableView reloadData];
    
    STTwitterAPI *twitter = [STTwitterAPI twitterAPIOSWithFirstAccount];
    
    [twitter verifyCredentialsWithSuccessBlock:^(NSString *username) {
        
        //        self.statusLabel.text = [NSString stringWithFormat:@"Fetching timeline for @%@...", username];
        fvc.lblTitle.text = username;
        
        [twitter getHomeTimelineSinceID:nil
                                  count:20
                           successBlock:^(NSArray *statuses) {
                               
                               NSLog(@"-- statuses: %@", statuses);
                               
                               //                               self.statusLabel.text = [NSString stringWithFormat:@"@%@", username];
                               fvc.lblTitle.text = username;
//                               NSLog(@"%@", username);
                               tweets = statuses;
                               fvc.tweets = tweets;
                               [fvc.foodTableView reloadData];
                               userName = [NSString stringWithFormat:@"%@のタイムライン", username];
                               
                           } errorBlock:^(NSError *error) {
                               NSLog(@"%@", [error localizedDescription]);
                           }];
        
    } errorBlock:^(NSError *error) {
        NSLog(@"%@", [error localizedDescription]);
    }];

}


#pragma mark - FoodViewControllerDelegate

- (void)setTweetString:(NSString *)strTweet
{
    [_yagiView eatFood];
    lblYagiTweet.alpha = 1.0;
    //    [UIView beginAnimations:nil context:NULL];
    //    [UIView setAnimationDuration:2.f];
    [UIView animateWithDuration:1.0f animations:^{
        lblYagiTweet.center = CGPointMake(_yagiView.center.x - 52, _yagiView.center.y -15);
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
