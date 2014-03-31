//
//  ViewController.m
//  Tubuyagi
//
//  Created by Genki Ishibashi on 13/09/05.
//  Copyright (c) 2013年 Genki Ishibashi. All rights reserved.
//

#import "ViewController.h"
#import "FoodUIViewController.h"
#import "STTwitter.h"
#import "NSString+SHA.h"
#import "FMDatabase+Tubuyagi.h"

// TODO: 現在のViewContorllerの課題：画面の構成要素をすべてこのファイルに書き込んでしまっている
// TODO: 処理ごとにクラスへ分割するべき

NS_ENUM(NSInteger, TYAlertTags){
    TYAlertStrTweet = 10,
    TYAlertDeleteAllBigramData = 11,
    TYAlertDelegateTextField = 12,
    TYAlertTwitterAccessFailed = 13
};

NS_ENUM(NSInteger, TYActionSheets){
    TYTwitterActionSheet = 20,
    TYForgetActionSheet = 21,
};

@interface ViewController ()
@end

@implementation ViewController

@synthesize availableButtons = _availableButtons;

#pragma mark -initial settings
//初期設定

//ステータスバーの非表示
- (BOOL)prefersStatusBarHidden
{
    return YES;
}

- (BOOL)shouldAutorotate
{
    return NO;
}


- (void)viewDidLoad
{
    NSLog(@"ViewDidLoad");
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    // お気に入られ数の表示
    TweetsManager *tweetsManager = [TweetsManager tweetsManagerFactory];
    self.strWara.text = [NSString stringWithFormat:@"%d", tweetsManager.totalFavoritedCount];
    
    //ヤギの生成
    self.yagiView = [[YagiView alloc] initYagi];
    //ヤギは柵の下に置く
    [self.view insertSubview:self.yagiView belowSubview:self.imgSaku];
    //ヤギ用ボタンの配置
    [self.view addSubview:self.yagiView.button];
    //ボタンイベント登録
    [self.yagiView.button addTarget:self action:@selector(tweetYagi) forControlEvents:UIControlEventTouchUpInside];
    //食べる紙配置
    [self.view addSubview:self.yagiView.lblYagiTweet];

    
    /*
    //木の生成
    self.treeView = [[TreeView alloc] initTreeAsSubView];
    //木はヤギの下に置く
    [self.view insertSubview:self.treeView belowSubview:self.yagiView];
    */
     
    //FoodViewControllerの生成
    fvc = [[FoodUIViewController alloc] initWithNibName:@"FoodUIViewController" bundle:nil];
    fvc.delegate = self;
    fvc.twitterAccounts = self.twitterAccounts;
    
    //twitter情報の取得
    [self performSelector:@selector(getTwitterAccountsInformationiOS)
               withObject:nil
               afterDelay:0.1];
    

    [self prepareStatusBar];

    //設定画面の初期設定
    self.txfYagiName.delegate = self;
    self.txfYagiName.returnKeyType = UIReturnKeyDone;
    
    //ボタン一時利用できないようにする
    self.availableButtons = NO;
}

- (void)prepareStatusBar
{
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    NSString *strOwner = [ud stringForKey:@"TDUserName"];
    NSString *strYagiName = [ud stringForKey:@"TDYagiName"];
    _strStatus.text = [NSString stringWithFormat:@"オーナー:%@\nヤギの名前:%@", strOwner, strYagiName];
}

- (IBAction)closeConfigView:(id)sender {
    
    [_txfYagiName resignFirstResponder];
    [UIView animateWithDuration:0.3 animations:^(void){
        self.configView.transform = CGAffineTransformMakeScale(0.001, 0.001);
    } completion:^(BOOL finished){
        [self.configView removeFromSuperview];
    }];
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
    
    [self.yagiView dismissPopTipView];
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
    
    
#warning ここらへんfvvcのコンストラクタで処理するべきでは？
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
    
    //通知
    fvvc3 = [[FavoriteViewController alloc] initWithNibName:@"FavoriteViewController" bundle:nil];
    fvvc3.delegate = self;
    UIImage *img3 = [UIImage imageNamed:@"bell.png"];
    UITabBarItem *tabItem3 = [[UITabBarItem alloc] initWithTitle:@"通知" image:img3 tag:0];
    fvvc3.tabBarItem = tabItem3;
    
    
    NSArray *views = [NSArray arrayWithObjects:fvvc1, fvvc2, fvvc3, nil];
    [tab setViewControllers:views];

    [self getFavoriteJsondata:fvvc1];
    
    [self presentViewController:tab animated:YES completion:nil];
    
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
//    [self alert];
}


#warning 同じ処理をViewController.mとFavoriteViewController.mで実装してて地獄感ある
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
    } else if (vc == fvvc2){
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
    } else if (vc == fvvc3){
        FMDatabase *database = [FMDatabase databaseFactory];
        fvvc3.activities = [database activityArrayWithCount:30];
        [fvvc3.tableView reloadData];
    }
}

#pragma mark - CMPopTipViewDelegate

- (void)touchTipPopView
{
    NSString *strShare = [NSString stringWithFormat:@"「%@」のつぶやきを共有しますか？？", self.yagiView.recentTweet];
    if (!self.yagiView.recentTweet) {
        strShare = @"つぶやぎをタップして\nしゃべらせよう！";
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"発言の共有"
                                                        message:strShare
                                                       delegate:self
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        alert.tag = 10;
        [alert show];
    }else{
        [self takeScreenShot];
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

- (void)popTipViewWasDismissedByUser:(CMPopTipView *)popTipView
{
    [self touchTipPopView];
}

/*
 投稿用スクリーンショットを撮る
 参考 : http://www.yoheim.net/blog.php?q=20130706
 */
- (void)takeScreenShot{
    // キャプチャ対象をWindowに
    UIWindow *window = [[UIApplication sharedApplication] keyWindow];
    
    // キャプチャ画像を描画する対象を生成
    UIGraphicsBeginImageContextWithOptions(window.bounds.size, NO, 0.0f);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    // Windowの現在の表示内容を１つずつ描画
    for (UIWindow *aWindow in [[UIApplication sharedApplication] windows]) {
        [aWindow.layer renderInContext:context];
    }
    
    // 描画した内容をUIImageとして受け取る
    UIImage *capturedImage = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    self.yagiView.recentScreenShot = capturedImage;
}

#pragma mark-YagiButton Delegate
- (void)tweetYagi
{
    [self.yagiView tweet];
    self.yagiView.popTipView.delegate = self;
    [self.yagiView.popTipView presentPointingAtView:self.yagiView inView:self.view animated:YES];
    twitterAcountFlag = NO;
    twitterAcountflag2 = NO;
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
    [self prepareStatusBar];
    
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
             alert.tag = TYAlertTwitterAccessFailed;
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
    [self.yagiView eatTweet:strTweet];
}

- (void)foodCancel
{
    [self.yagiView stopWalk:YES];
    [self.yagiView performSelector:@selector(walkRestart) withObject:nil afterDelay:2.4];
    
}

#pragma mark - UIActionSheetDelegate
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    UIAlertView *alert;
    DeleteWordTableViewController *dtvc;
    switch (actionSheet.tag) {
        case TYForgetActionSheet:
            alert = [[UIAlertView alloc] initWithTitle:@"忘却完了" message:@"全ての単語を忘れさせてもいいですか？？" delegate:self cancelButtonTitle:@"OK" otherButtonTitles: @"キャンセル", nil];
            alert.tag = TYAlertDeleteAllBigramData;
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
        case TYAlertStrTweet:
            switch (buttonIndex) {
                case 0:
                    if (!self.yagiView.recentTweet) {
                        break;
                    }
                    
                    [self.tweetsManager postTweet:self.yagiView.recentTweet
                                       screenshot:self.yagiView.recentScreenShot
                                     successBlock:^(NSDictionary *status) {
                                         // TODO:  投稿しました
                                     } errorBlock:^(NSError *error) {
                                         // TODO:　もう一度投稿
                                     }];
                    break;
                    
                default:
                    break;
            }
            break;
            
        case TYAlertDeleteAllBigramData:
            switch (buttonIndex) {
                case 0:
                    database = [FMDatabase databaseFactory];
                    [database deleteAllLearnedData];
                    [self.yagiView allFoget];
                    NSLog(@"全消去");
                    break;
            
                default:
                    break;
            }
            break;
            
        case TYAlertDelegateTextField:
            switch (buttonIndex) {
                case 0:
                    break;
                    
                default:
                    break;
            }
        case TYAlertTwitterAccessFailed:
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
    [self.yagiView dischargeWord];
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

#pragma mark - UITabBarController
- (void)tabBarController:(UITabBarController *)tabBarController didSelectViewController:(UIViewController *)viewController
{
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    if (viewController == fvvc1) {
        if (!fvvc1.favTweet) {
            [self getFavoriteJsondata:fvvc1];
        }
    } else if (viewController == fvvc2){
        if (!fvvc2.favTweet) {
        [self performSelector:@selector(getFavoriteJsondata:)
                   withObject:fvvc2
                   afterDelay:0.1];
        }
    } else if (viewController == fvvc3){
        [self performSelector:@selector(getFavoriteJsondata:)
                   withObject:fvvc3
                   afterDelay:0.1];
    }

    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
}

#pragma mark - UITextFieldDelegate
- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if ([textField.text isEqualToString:@""]) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"名前が設定されていません" message:@"やぎの名前を設定して下さい" delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
        alert.tag = TYAlertDelegateTextField;
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
        [self prepareStatusBar];
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

#pragma mark- getter and setter
- (BOOL)availableButtons{
    return _availableButtons;
}

- (void)setAvailableButtons:(BOOL)availableButtons{
    self.yagiView.button.enabled = availableButtons;
    //self.treeView.button.enabled = availableButtons;
    self.btnChooseFood.enabled = availableButtons;
    self.btnForget.enabled = availableButtons;
    self.btnConfig.enabled = availableButtons;
    self.btnshowFavolite.enabled = availableButtons;
    _availableButtons = availableButtons;
}

@end
