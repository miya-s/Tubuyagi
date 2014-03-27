//
//  ViewController.m
//  Tubuyagi
//
//  Created by Genki Ishibashi on 13/09/05.
//  Copyright (c) 2013年 Genki Ishibashi. All rights reserved.
//

#import "ViewController.h"
#import "FoodUIViewController.h"
#import "MarkovTextGenerator.h"
#import "STTwitter.h"
#import "NSString+SHA.h"
#import "FMDatabase+Tubuyagi.h"

NS_ENUM(NSInteger, TYAlertTags){
    alertStrTweet = 10,
    alertDeleteAllBigramData = 11,
    alertDelegateTextField = 12,
    alertTwitterAccessFailed = 13
};

NS_ENUM(NSInteger, TYActionSheets){
    TYTwitterActionSheet = 20,
    TYForgetActionSheet = 21,
};

@interface ViewController ()
@end

@implementation ViewController
//@synthesize bblView = _bblView;

- (BOOL)shouldAutorotate
{
    
    return NO;
}



//ステータスバーの非表示
- (BOOL)prefersStatusBarHidden
{
    return YES;
}

- (void)viewDidLoad
{
    NSLog(@"ViewDidLoad");
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    //ヤギの生成
    CGRect yagiRect = CGRectMake(45, 158, 230, 228);
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
    self.btnConfig.enabled = NO;
    self.btnForget.enabled = NO;
    self.btnshowFavolite.enabled = NO;
    btnYagi.enabled = NO;
    
    
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
    [self performSelector:@selector(getTwitterAccountsInformationiOS)
               withObject:nil
               afterDelay:0.1];//getTwitterAccountInformation];
    
    //ヤギのステータス
    [self setYagiName];
    
    //ヤギの食べるエサの配置
    [self initialize];
    

    //自分のお気に入り数を生成
    //[self performSelector:@selector(getWaraCount) withObject:nil afterDelay:3];

    //設定画面の初期設定
    self.txfYagiName.delegate = self;
    self.txfYagiName.returnKeyType = UIReturnKeyDone;
}

- (void)setYagiName
{
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    NSString *strOwner = [ud stringForKey:@"TDUserName"];
    NSString *strYagiName = [ud stringForKey:@"TDYagiName"];
    NSLog(@"yagi name %@", [ud objectForKey:@"TDYagiName"]);
    NSLog(@"yagi name 2 %@", [ud stringForKey:@"TDYagiName"]);
    _strStatus.text = [NSString stringWithFormat:@"オーナー:%@\nヤギの名前:%@", strOwner, strYagiName];
}

- (void)availableButton
{
    btnYagi.enabled = YES;
    //その他ボタン利用解除
    self.btnChooseFood.enabled = YES;
    self.btnForget.enabled = YES;
    self.btnConfig.enabled = YES;
    self.btnshowFavolite.enabled = YES;
}

- (IBAction)closeConfigView:(id)sender {
    
    [_txfYagiName resignFirstResponder];
    [UIView animateWithDuration:0.3 animations:^(void){
        self.configView.transform = CGAffineTransformMakeScale(0.001, 0.001);
    } completion:^(BOOL finished){
        [self.configView removeFromSuperview];
    }];
}

//ヤギのエサの位置設定
- (void)initialize
{
    NSLog(@"initialize");
    lblYagiTweet.frame = CGRectMake(40, 330, 280, 52);
    lblYagiTweet.alpha = 0.0;
   lblYagiTweet.transform = CGAffineTransformIdentity;
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
    
    [self presentViewController:fvc animated:YES completion:nil];
    fvc.lblTitle.text = userName;
    
    
    [self initialize];
}

- (IBAction)setConfig:(UIButton *)sender {
    NSLog(@"setConfig");
    
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    self.strYagiName.text =  [ud objectForKey:@"TDYagiName"];
    self.txfYagiName.placeholder = @"新しいやぎの名前をいれてね";
    self.strOwnerName.text = [ud objectForKey:@"TDUserName"];
    
    [self.view addSubview:self.configView];
    
    self.configView.transform = CGAffineTransformMakeScale(0.001, 0.001);
    [UIView animateWithDuration:0.3 animations:^(void){
        self.configView.transform = CGAffineTransformMakeScale(1.5, 1.5);
    } completion:^(BOOL finished){
        [UIView animateWithDuration:0.2 animations:^(void){
            self.configView.transform = CGAffineTransformIdentity;
        }];
    }];
    
    [self.txfYagiName becomeFirstResponder];
//    [self alert];
}

- (IBAction)forgetWord:(UIButton *)sender {
    UIActionSheet *as = [[UIActionSheet alloc] initWithTitle:nil
                                                    delegate:self
                                           cancelButtonTitle:@"やめる"
                                      destructiveButtonTitle:nil
                                           otherButtonTitles:@"すべて忘れさせる", @"つぶやきを忘れさせる", nil];
    as.tag = TYForgetActionSheet;
    [as showInView:self.view];
}

- (IBAction)showFavorite:(id)sender {
    
    //UITabBarController生成
    UITabBarController *tab = [[UITabBarController alloc] init];
    tab.delegate = self;
    

    [[tab.tabBar.items objectAtIndex:0] setBackgroundImage:[UIImage imageNamed:@"clock.png"]];
    
    //新着順
    fvvc1 = [[FavoriteViewController alloc] initWithNibName:@"FavoriteViewController" bundle:nil];
    fvvc1.delegate = self;
    UIImage *img1 = [UIImage imageNamed:@"clock.png"];
    UITabBarItem *tabItem1 = [[UITabBarItem alloc] initWithTitle:@"新着" image:img1 tag:0];
    fvvc1.tabBarItem = tabItem1;
//    [[fvvc1.tabBarController.tabBar.items objectAtIndex:0] setFinishedSelectedImage:nil withFinishedUnselectedImage:[UIImage imageNamed:@"clock.png"]];
    //人気順
    fvvc2 = [[FavoriteViewController alloc] initWithNibName:@"FavoriteViewController" bundle:nil];
    fvvc2.delegate = self;
    UIImage *img2 = [UIImage imageNamed:@"crown.png"];
    UITabBarItem *tabItem2 = [[UITabBarItem alloc] initWithTitle:@"人気" image:img2 tag:0];
    fvvc2.tabBarItem = tabItem2;
    NSArray *views = [NSArray arrayWithObjects:fvvc1, fvvc2, nil];
    [tab setViewControllers:views];

    [self getFavoriteJsondata:fvvc1];
    
    [self presentViewController:tab animated:YES completion:nil];
    
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
//    [self alert];
}

- (void)getFavoriteJsondata:(FavoriteViewController *)vc
{

    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    if (vc == fvvc1) {
        [self.tweetsManager checkSearchResultForRecent:YES
                                          SuccessBlock:^(NSArray *statuses) {
                                              fvvc1.favTweet = statuses;
                                              NSLog(@"status got:%@", statuses);
                                              [fvvc1.tableView reloadData];
                                              [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
                                          }
                                            errorBlock:^(NSError *error) {
                                                NSAssert(!error, [error localizedDescription]);
                                                [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
                                            }];
    }else if (vc == fvvc2){
        [self.tweetsManager checkSearchResultForRecent:NO
                                          SuccessBlock:^(NSArray *statuses) {
                                              fvvc2.favTweet = statuses;
                                              NSLog(@"status got:%@", statuses);
                                              [fvvc2.tableView reloadData];
                                              [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
                                          }
                                            errorBlock:^(NSError *error) {
                                                NSAssert(!error, [error localizedDescription]);
                                                [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
                                            }];
    }
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
        [self.tweetsManager takeScreenShot];
        //共有確認ボタンを出す
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
    MarkovTextGenerator *generator = [MarkovTextGenerator markovTextGeneratorFactory];
    strCurrTweet = [NSString stringWithFormat:@"%@", [generator generateSentence]];
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
    
    NSUInteger showTime = strCurrTweet.length / 4.0;
    if (showTime < 3) {
        showTime = 3;
    }
    NSLog(@"time is %uld", showTime);
    timer = [NSTimer scheduledTimerWithTimeInterval:showTime
                                    target:self
                                  selector:@selector(judgdeWalkRestart)
                                  userInfo:nil
                                   repeats:NO];
    timerFlag = NO;
    twitterAcountFlag = NO;
    twitterAcountflag2 = NO;

    
//#warning 直す
//    [_yagiView dischargeWord];
}


- (void)alert{
    if (twitterAcountFlag) {
        
    
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Twitterの情報を取得できませんでした" message:@"電波のいいところで再起動、もしくは本体に登録されているTwitterアカウントを確認して下さい" delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
        [alert show];
    }else if (twitterAcountflag2)
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Twitterの情報を取得できませんでした" message:@"本体に登録されているTwitterアカウントを確認して下さい" delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
        [alert show];
    }
}
- (void)loadTimeLine:(NSArray *)statuses{
    //取得内容の保存
    tweets = statuses;
    fvc.tweets = statuses;
    
    //データ取得したら更新
    [fvc.foodTableView reloadData];
    
    //ステータスの更新
    [self setYagiName];
    
    //読みこみの表示の解除
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    
    //お気に入られ数もついでに更新
    [self reloadFavCount];
    
}

//認証完了後に呼ぶ：基本情報の取得
- (void)loadTwitterUserInfo{
    NSString *newUserName = self.tweetsManager.username;
    fvc.lblTitle.text = newUserName;
    NSUserDefaults *df = [NSUserDefaults standardUserDefaults];
    [df setObject:newUserName forKey:@"TDUserName"];
    userName = [NSString stringWithFormat:@"%@のタイムライン", newUserName];
    
    [self.tweetsManager checkTimelineWithSuccessBlock:^(NSArray *statuses) {
        [self performSelectorOnMainThread:@selector(loadTimeLine:)
                               withObject:statuses
                            waitUntilDone:YES];
    } errorBlock:^(NSError *error) {
        NSLog(@"%@", [error localizedDescription]);
        NSLog(@"通信失敗1");
        twitterAcountFlag = YES;
    }];
}

- (void)showActionSheetForAccounts:(NSArray *)accounts{
    dispatch_async(dispatch_get_main_queue(), ^{
        UIActionSheet *actionSheet = [[UIActionSheet alloc]
                                       
                                       initWithTitle: @"使用するTwitterアカウントを選んでください"
                                       delegate: self
                                       cancelButtonTitle:nil
                                       destructiveButtonTitle: nil
                                       otherButtonTitles:nil];
        actionSheet.tag = TYTwitterActionSheet;
        for (ACAccount *account in accounts){
            [actionSheet addButtonWithTitle:account.username];
        }
        [actionSheet showInView:[[[[UIApplication sharedApplication] keyWindow] subviews] lastObject]];
    });
}

- (void)getTwitterAccountsInformationiOS
{
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    __block __weak ViewController *weakSelf = self;
    
    //まず最初に、iOSに設定されたアカウントでのtwitter認証を試みる
    self.tweetsManager = [TweetsManager tweetsManagerFactory];
    [self.tweetsManager checkTwitterAccountsWithSuccessBlock:
     ^(void) {
         [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
         [weakSelf performSelectorOnMainThread:@selector(loadTwitterUserInfo)
                                    withObject:nil
                                 waitUntilDone:YES];
     } choicesBlock: ^(NSArray *accounts) {
         [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
         [self showActionSheetForAccounts:accounts];
     } errorBlock:^(NSError *error) {
         NSLog(@"Error : %@", [error localizedDescription]);
         [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;

         //無理だったら、まずキャッシュされたAccessTokenがないか確認
         if (weakSelf.tweetsManager.cachedOAuth){
             [weakSelf.tweetsManager loginTwitterByCachedTokenWithSuccessBlock:
              ^(NSString *username) {
                  [weakSelf performSelectorOnMainThread:@selector(loadTwitterUserInfo)
                                             withObject:nil
                                          waitUntilDone:YES];
             } errorBlock:^(NSError *error) {
                 //TODO キャッシュログイン失敗時はsafari認証
                 NSAssert(!error, [error localizedDescription]);
             }];
             return;
         }

         //それすらなかったらSafariで認証
         dispatch_async(dispatch_get_main_queue(), ^{
             UIAlertView *alert =
             [[UIAlertView alloc] initWithTitle:@"Twitterの情報を取得できませんでした"
                                        message:@"本体に登録されているTwitterアカウントを確認して下さい"
                                       delegate:weakSelf
                              cancelButtonTitle:@"設定方法"
                              otherButtonTitles:@"Safariで認証", nil];
             alert.tag = alertTwitterAccessFailed;
             [alert show];
         });
         
         //twitterAcountflag2 = YES;
     }
     ];
}

//Safariで認証
- (void)getTwitterAccountsInformationSafari
{
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    self.tweetsManager = [TweetsManager tweetsManagerFactory];
    
    [self.tweetsManager
     loginTwitterInSafariWithSuccessBlock:
     ^(NSString *username){
         // 認証成功
         [self loadTwitterUserInfo];
         [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
     }
     errorBlock:
     ^(NSError *error) {
         // 認証失敗
         NSAssert(!error, [error description]);
         [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
         twitterAcountflag2 = YES;
     }];
}

#pragma mark - FoodViewControllerDelegate

- (void)setTweetString:(NSString *)strTweet
{
    [_yagiView eatFood];
    lblYagiTweet.alpha = 1.0;
    [UIView animateWithDuration:1.0f animations:^{
        lblYagiTweet.center = CGPointMake(_yagiView.center.x - 52, _yagiView.center.y -15);
        lblYagiTweet.transform = CGAffineTransformMakeScale(0.01, 0.01);
    } completion:^(BOOL finished){
        
        //iOS7だとコールバックできないのでタイマー関数で呼ぶ
        [self performSelector:@selector(initialize) withObject:Nil afterDelay:1.0f];
        
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
    UIAlertView *alert;
    DeleteWordTableViewController *dtvc;
    switch (actionSheet.tag) {
        case TYForgetActionSheet:
            alert = [[UIAlertView alloc] initWithTitle:@"忘却完了" message:@"全ての単語を忘れさせてもいいですか？？" delegate:self cancelButtonTitle:@"OK" otherButtonTitles: @"キャンセル", nil];
            alert.tag = alertDeleteAllBigramData;
            dtvc = [[DeleteWordTableViewController alloc] initWithNibName:@"DeleteWordTableViewController" bundle:nil];
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
            break;
        case TYTwitterActionSheet:
            self.tweetsManager.twitterAccount = [self.tweetsManager.twitterAccounts objectAtIndex:buttonIndex];
            [self loadTwitterUserInfo];
            break;
        default:
            break;
    }
}

#pragma mark - UIAlertViewDelegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    NSURL *twSettingURL;
    FMDatabase *database;
    
    switch (alertView.tag) {
        case alertStrTweet:
            switch (buttonIndex) {
                case 0:
                    if (!strCurrTweet) {
                        break;
                    }
                    
                    [self.tweetsManager postTweet:strCurrTweet
                                             successBlock:^(NSDictionary *status) {
                                                 // TODO  投稿しました
                                             } errorBlock:^(NSError *error) {
                                                 // TODO　もう一度投稿
                                             }];
                    break;
                    
                default:
                    break;
            }
            break;
            
        case alertDeleteAllBigramData:
            switch (buttonIndex) {
                case 0:
                    database = [FMDatabase databaseFactory];
                    [database deleteAllLearnedData];
                    [_yagiView allFoget];
                    NSLog(@"全消去");
                    break;
            
                default:
                    break;
            }
            break;
            
        case alertDelegateTextField:
            switch (buttonIndex) {
                case 0:
                    break;
                    
                default:
                    break;
            }
        case alertTwitterAccessFailed:
            switch (buttonIndex) {
                //設定方法参照
                case 0:
                    twSettingURL = [NSURL URLWithString:@"http://support.apple.com/kb/HT5500?viewlocale=ja_JP"];
                    [[UIApplication sharedApplication] openURL:twSettingURL];
                    break;
                //Safariで認証
                default:
                    [self getTwitterAccountsInformationSafari];
                    break;
            }
            
            
            break;
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
    [self setBtnConfig:nil];
    [self setBtnForget:nil];
    [self setStrWara:nil];
    [self setStrOwnerName:nil];
    [self setStrYagiName:nil];
    [self setTxfYagiName:nil];
    [self setConfigView:nil];
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

#pragma mark - UITextFieldDelegate
- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if ([textField.text isEqualToString:@""]) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"名前が設定されていません" message:@"やぎの名前を設定して下さい" delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
        alert.tag = alertDelegateTextField;
        [alert show];
    }else{
    
        [textField resignFirstResponder];
        [UIView animateWithDuration:0.3 animations:^(void){
            self.configView.transform = CGAffineTransformMakeScale(0.001, 0.001);
        } completion:^(BOOL finished){
            [self.configView removeFromSuperview];
        }];
    
        NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
        [ud setValue:textField.text forKey:@"TDYagiName"];
        [self setYagiName];
    }
    

    return YES;
}

#pragma mark - FavoriteVieDelegate
// お気に入られ数の表示
- (void)reloadFavCount{
    TweetsManager *tweetsManager = [TweetsManager tweetsManagerFactory];
    self.strWara.text = [NSString stringWithFormat:@"%d", tweetsManager.totalFavoritedCount];
    [tweetsManager checkFavoritedWithSuccessBlock:^() {
        self.strWara.text = [NSString stringWithFormat:@"%d", tweetsManager.totalFavoritedCount];
    } errorBlock:^(NSError *error) {
        NSAssert(!error, [error localizedDescription]);
    }];
}
@end
