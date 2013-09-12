//
//  ViewController.m
//  Tubuyagi
//
//  Created by Genki Ishibashi on 13/09/05.
//  Copyright (c) 2013年 Genki Ishibashi. All rights reserved.
//

#import "ViewController.h"
#import "FoodUIViewController.h"
#import "TextAnalyzer.h"
#import "STTwitter.h"
#import "BasicRequest.h"

#define alertStrTweet 10
#define alertDeleteAllBigramData 11
@interface ViewController ()

@end

@implementation ViewController
//@synthesize bblView = _bblView;

- (BOOL)shouldAutorotate
{
    return NO;
}

- (void)viewDidLoad
{
    NSLog(@"ViewDidLoad");
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    //ヤギの生成
    CGRect yagiRect = CGRectMake(70, 158, 230, 228);
    _yagiView = [[YagiView alloc] initWithFrame:yagiRect];
    [self.view addSubview:_yagiView];
    
    [self.view insertSubview:_yagiView belowSubview:self.imgSaku];
    
    
    //ヤギを押した時のボタン
    btnYagi = [UIButton buttonWithType:UIButtonTypeCustom];
    yagiRect.size.height -= 30;
    btnYagi.frame = yagiRect;
    [btnYagi addTarget:self action:@selector(tweetYagi) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btnYagi];
    btnYagi.enabled = NO;
    
    //その他ボタン一時利用できないようにする
    self.btnChooseFood.enabled = NO;
//    self.btnShareTweet.enabled = NO;
    self.btnshowFavolite.enabled = NO;
    
    
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
    UIImage *imgPaper = [UIImage imageNamed:@"paper_2.jpg"];
    UIColor *bgColor = [UIColor colorWithPatternImage:imgPaper];
    lblYagiTweet.backgroundColor = bgColor;
    [self.view addSubview:lblYagiTweet];
    
    //twitter情報の取得
    [self performSelector:@selector(getTwitterAccountInformation)
               withObject:nil
               afterDelay:0.1];//getTwitterAccountInformation];
    
    //ヤギのステータス
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    NSString *strOwner = [ud stringForKey:@"TDUserName"];
    NSString *strYagiName = [ud stringForKey:@"TDYagiName"];
    NSLog(@"yagi name %@", [ud objectForKey:@"TDYagiName"]);
    NSLog(@"yagi name 2 %@", [ud stringForKey:@"TDYagiName"]);
    _strStatus.text = [NSString stringWithFormat:@"オーナー:%@\nヤギの名前:%@", strOwner, strYagiName];
    
    [self initialize];
    

//    [_yagiView eatFood];
}

- (void)availableButton
{
    btnYagi.enabled = YES;
    //その他ボタン利用解除
    self.btnChooseFood.enabled = YES;
//    self.btnShareTweet.enabled = YES;
    self.btnshowFavolite.enabled = YES;
}

//位置設定の初期設定
- (void)initialize
{
    NSLog(@"initialize");
    lblYagiTweet.frame = CGRectMake(40, 330, 280, 52);
    lblYagiTweet.alpha = 0.0;
    timerFlag = YES;
    
    [self dismissAllPopTipViews];
}

- (void)didReceiveMemoryWarning
{
    NSLog(@"memoryWarning");
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)chooseFood:(UIButton *)sender {
    
//    UITabBarController *tabc = [[UITabBarController alloc] init];
    
    [self presentViewController:fvc animated:YES completion:nil];
    fvc.lblTitle.text = userName;
    
//    ManualInputViewController *mivc = [[ManualInputViewController alloc] initWithNibName:@"ManualInputViewController" bundle:nil];
//    [self presentViewController:mivc animated:YES completion:nil];
//    NSArray *views = [NSArray arrayWithObjects:fvc, mivc, nil];
//    [tabc setViewControllers:views];
//    
//    [self presentViewController:tabc animated:YES completion:nil];
    
    [self initialize];
}

- (IBAction)setConfig:(UIButton *)sender {
    NSLog(@"setConfig");
    [self alert];
}

- (IBAction)forgetWord:(UIButton *)sender {
    UIActionSheet *as = [[UIActionSheet alloc] initWithTitle:nil
                                                    delegate:self
                                           cancelButtonTitle:@"やめる"
                                      destructiveButtonTitle:nil
                                           otherButtonTitles:@"すべて忘れさせる", @"つぶやきを忘れさせる", nil];
    [as showInView:self.view];
}

- (IBAction)showFavorite:(id)sender {
    
    //UITabBarController生成
    UITabBarController *tab = [[UITabBarController alloc] init];
    tab.delegate = self;
    
//    UITabBarItem *item1 = [[UITabBarItem alloc] initWithTitle:@"新着" image:nil tag:0];
//    UITabBarItem *item2 = [[UITabBarItem alloc] initWithTitle:@"人気" image:nil tag:1];
//    NSArray *items = tab.tabBar.items;//[NSArray arrayWithObjects:item1, item2, nil];


    

    
    //新着順
    fvvc1 = [[FavoriteViewController alloc] initWithNibName:@"FavoriteViewController" bundle:nil];
    fvvc1.title = @"新着";
    //人気順
    fvvc2 = [[FavoriteViewController alloc] initWithNibName:@"FavoriteViewController" bundle:nil];
    fvvc2.title = @"人気";
    NSArray *views = [NSArray arrayWithObjects:fvvc1, fvvc2, nil];
    [tab setViewControllers:views];
//    [tab.tabBar setItems:items];
    
    [self performSelector:@selector(getFavoriteJsondata:)
               withObject:fvvc1
               afterDelay:0.1];
//    NSArray *favTweets = getJSONRecents(0, 20);
//    fvvc.favTweet = favTweets;
    
    [self presentViewController:tab animated:YES completion:nil];
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
//    [self alert];
}

- (void)getFavoriteJsondata:(FavoriteViewController *)vc
{
    NSArray *favTweets;
    if (vc == fvvc1) {
//        favTweets = getJSONRecents(0, 20);
    }else
//        favTweets = getJSONTops(0, 20);

    vc.favTweet = favTweets;
    [vc.tableView reloadData];
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
}




- (IBAction)shareTweet:(UIButton *)sender {
    
    NSString *strShare = [NSString stringWithFormat:@"「%@」のつぶやきを共有しますか？？", strCurrTweet];
    if (!strCurrTweet) {
        strShare = @"つぶやぎをタップして\nしゃべらせよう！";
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"発言の共有"
                                                        message:strShare
                                                       delegate:self
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        alert.tag = 10;
        [alert show];
    }else{
        
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"発言の共有"
                                                    message:strShare
                                                   delegate:self
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:@"キャンセル",nil];
    alert.tag = 10;
    [alert show];
    }
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
    strCurrTweet = [NSString stringWithFormat:@"%@", generateSentence()];
    CMPopTipView *popTipView = [[CMPopTipView alloc] initWithMessage:strCurrTweet];
    popTipView.delegate = self;
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

    
//#warning 直す
//    [_yagiView allFoget];
}


- (void)alert{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"まだできていません" message:@"Coming Soon!" delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
    [alert show];
}

- (void)getTwitterAccountInformation
{
    //STTwitter
//    [self.foodTableView reloadData];
    
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    STTwitterAPI *twitter = [STTwitterAPI twitterAPIOSWithFirstAccount];
    
    [twitter verifyCredentialsWithSuccessBlock:^(NSString *username) {
        
        //        self.statusLabel.text = [NSString stringWithFormat:@"Fetching timeline for @%@...", username];
        fvc.lblTitle.text = username;
        
        [twitter getHomeTimelineSinceID:nil
                                  count:20
                           successBlock:^(NSArray *statuses) {
                               
//                               NSLog(@"-- statuses: %@", statuses);
                               
                               //取得内容の保存
                               tweets = statuses;
                               fvc.tweets = tweets;
                               
                               //データ取得したら更新
                               [fvc.foodTableView reloadData];
                               
                               //ユーザー名の保存
                               NSUserDefaults *df = [NSUserDefaults standardUserDefaults];
                               [df setObject:username forKey:@"TDUserName"];
                               userName = [NSString stringWithFormat:@"%@のタイムライン", username];
                               
                               //読みこみの表示の解除
                               [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
                               
                           } errorBlock:^(NSError *error) {
                               NSLog(@"%@", [error localizedDescription]);
                               NSLog(@"通信失敗1");
                           }];
        
    } errorBlock:^(NSError *error) {
        NSLog(@"%@", [error localizedDescription]);
        NSLog(@"通信失敗２");
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
    [lblYagiTweet sizeThatFits:lblYagiTweet.bounds.size];
    
    //    [UIView commitAnimations];
    
    
}

- (void)foodCancel
{
    [_yagiView stopWalk:YES];
    [self performSelector:@selector(judgdeWalkRestart) withObject:nil afterDelay:2.4];
    
}

#pragma mark - UIActionSheetDelegate
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"忘却完了" message:@"全ての単語を忘れさせてもいいですか？？" delegate:self cancelButtonTitle:@"OK" otherButtonTitles: @"キャンセル", nil];
    alert.tag = alertDeleteAllBigramData;
    DeleteWordTableViewController *dtvc = [[DeleteWordTableViewController alloc] initWithNibName:@"DeleteWordTableViewController" bundle:nil];
    dtvc.delegate = self;
    switch (buttonIndex) {
        case 0:
//            deleteAllData();
            [alert show];
            break;
            
        case 1:
            [self presentViewController:dtvc animated:YES completion:^(void){}];
            break;
        
        default:
            break;
    }
}

#pragma mark - UIAlertViewDelegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    switch (alertView.tag) {
        case alertStrTweet:
            switch (buttonIndex) {
                case 0:
                    if (![ud objectForKey:@"TDSentPassword"]) {
                        addUser();
                    }
                    if (!strCurrTweet) {
                        break;
                    }
                    addWaraToMyTubuyaki(strCurrTweet);
                    break;
                    
                default:
                    break;
            }
            break;
            
        case alertDeleteAllBigramData:
            switch (buttonIndex) {
                case 0:
                    deleteAllBigramData();
                    [_yagiView allFoget];
                    NSLog(@"全消去");
                    break;
            
                default:
                    break;
            }
            default:
            break;
    }
}

- (void)tableView:(UITableView *)tableView
  willDisplayCell:(UITableViewCell *)cell
forRowAtIndexPath:(NSIndexPath *)indexPath
{
    // For even
    if (indexPath.row % 2 == 0) {
        cell.backgroundColor = [UIColor whiteColor];
    }
    // For odd
    else {
        cell.backgroundColor = [UIColor colorWithHue:0.61
                                          saturation:0.09
                                          brightness:0.99
                                               alpha:1.0];
    }
}

#pragma mark - DeleteWordTabeleViewControllerDelegate
- (void)wordDelete
{
    [_yagiView dischargeWord];
}
- (void)viewDidUnload {
    [self setBtnChooseFood:nil];
//    [self setBtnShareTweet:nil];
    [self setBtnshowFavolite:nil];
    [self setImgSaku:nil];
    [self setStrStatus:nil];
    [super viewDidUnload];
}

#pragma mark - CMPopTipViewDelegate
- (void)touchTipPopView
{
    [self shareTweet:nil];
}

- (void)popTipViewWasDismissedByUser:(CMPopTipView *)popTipView
{
    
}

#pragma mark - UITabBarController
- (void)tabBarController:(UITabBarController *)tabBarController didSelectViewController:(UIViewController *)viewController
{
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    if (viewController == fvvc1) {
        if (!fvvc1.favTweet) {
            [self getFavoriteJsondata:fvvc1];
        }
    }else if (viewController == fvvc2){
        if (!fvvc2.favTweet) {
        [self performSelector:@selector(getFavoriteJsondata:)
                   withObject:fvvc2
                   afterDelay:0.1];
        }
    }
    
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
}
@end
