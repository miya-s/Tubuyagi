//
//  AppDelegate.m
//  Tubuyagi
//
//  Created by Genki Ishibashi on 13/09/05.
//  Copyright (c) 2013年 Teaf IshiHara. All rights reserved.
//

#import "AppDelegate.h"
#import "BasicRequest.h"
#import "ViewController.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    //初期値の設定
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];

    NSMutableDictionary *defaults = [NSMutableDictionary dictionary];
    [defaults setObject:@"名無しくん" forKey:@"TDUserName"];
    [defaults setObject:@"つぶやぎ" forKey:@"TDYagiName"];
    [defaults setObject:@"0" forKey:@"TDFirstTime"];
    [defaults setObject:[NSDate date] forKey:@"TDdate"];
    [ud registerDefaults:defaults];

    
    if (![ud objectForKey:@"TDRandomPassword"]){
        [ud setObject:randStringWithLength(20) forKey:@"TDRandomPassword"];
    }

#warning 毎回送る必要はない→名前変更時と、初回起動時と、twitter認証時
    addUser();
    
    // こんな感じにwaraが取れるよって例
//    getJSONWara(^(NSArray *result){
//        NSLog(@"%@", result);
//        NSLog(@"warai : %@", [result objectAtIndex: 0]);
//        NSLog(@"warai : %d", [[[result objectAtIndex: 0] objectForKey:@"wara"] intValue]);
//    });

    
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    // Override point for customization after application launch.
    self.viewController = [[ViewController alloc] initWithNibName:@"ViewController" bundle:nil];
    self.window.rootViewController = self.viewController;
    [self.window makeKeyAndVisible];
    
    //初回起動時の画面作製
    if ([[ud objectForKey:@"TDFirstTime"] isEqualToString:@"0"]) {
        NSLog(@"初回");
        kaisuu = 0;
        [self setStoryView];
        
    }
    
    [self creatStartView];
    

    return YES;
}

- (void)popUpTutorial
{
//    if (kaisuu == 2) {
    

        NSLog(@"popUP");
        scrTutorial = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, self.viewController.view.bounds.size.width, self.viewController.view.bounds.size.height)];
        UIImageView *imgTutorial = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 320, 1099)];
        imgTutorial.image = [UIImage imageNamed:@"tutorial.png"];
        [scrTutorial addSubview:imgTutorial];
        scrTutorial.showsVerticalScrollIndicator = NO;
        scrTutorial.contentSize = imgTutorial.bounds.size;
        //閉じるボタン
        UIButton *btnClose = [UIButton buttonWithType:UIButtonTypeCustom];
        btnClose.frame = CGRectMake(0, 0, 100, 60);
        btnClose.center = CGPointMake(scrTutorial.center.x, scrTutorial.contentSize.height - 30);
        [btnClose addTarget:self action:@selector(endTutorial) forControlEvents:UIControlEventTouchUpInside];
        [scrTutorial addSubview:btnClose];
    
        [self.viewController.view addSubview:scrTutorial];
    
        scrTutorial.transform = CGAffineTransformMakeScale(0.001, 0.001);
        [UIView animateWithDuration:0.3 animations:^(void){
            scrTutorial.transform = CGAffineTransformMakeScale(1.5, 1.5);
        } completion:^(BOOL finished){
            [UIView animateWithDuration:0.2 animations:^(void){
                scrTutorial.transform = CGAffineTransformIdentity;
            }];
        }];
        
//    }
    
}

- (void)setStoryView
{
    NSLog(@"setStryView");
    scrStory = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, self.viewController.view.bounds.size.width, self.viewController.view.bounds.size.height)];
    UIImageView *imgStory = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 320, 740.5)];
    imgStory.image = [UIImage imageNamed:@"story.png"];
    [scrStory addSubview:imgStory];
    CGSize scrollSize = imgStory.bounds.size;
    scrollSize.height += 100;
    scrStory.contentSize = scrollSize;
    scrStory.userInteractionEnabled = NO;
    scrStory.backgroundColor = [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.8];
    scrStory.showsVerticalScrollIndicator = NO;
    scrStory.showsHorizontalScrollIndicator = NO;
    [self.viewController.view addSubview:scrStory];
    viewBlack = [[UIView alloc] initWithFrame:self.window.frame];
    viewBlack.backgroundColor = [UIColor blackColor];
    [self.viewController.view addSubview:viewBlack];
    
    //skipButton
    btnSkip = [UIButton buttonWithType:UIButtonTypeCustom];
    [btnSkip setImage:[UIImage imageNamed:@"scroll.png"] forState:UIControlStateNormal];
    btnSkip.frame = CGRectMake(0, 0, 40, 77.2);
    btnSkip.center = CGPointMake(self.viewController.view.center.x + 120, self.viewController.view.bounds.size.height - 80);
    [btnSkip addTarget:self action:@selector(skipStory) forControlEvents:UIControlEventTouchUpInside];
    [self.viewController.view addSubview:btnSkip];
}

- (void)creatStartView
{
    NSLog(@"createStartView");
    //スタート画面
    viewStart = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Default.png"]];
    CGPoint viewCenter = self.viewController.view.center;
    viewStart.center = CGPointMake(viewCenter.x, viewCenter.y -30);
    [self.viewController.view addSubview:viewStart];
    UITapGestureRecognizer *gesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(pushStartButton)];
    [self.viewController.view addGestureRecognizer:gesture];
    
    btnStart = [UIButton buttonWithType:UIButtonTypeCustom];
    [btnStart setImage:[UIImage imageNamed:@"startbutton"] forState:UIControlStateNormal];
    [btnStart addTarget:self action:@selector(pushStartButton) forControlEvents:UIControlEventTouchUpInside];
    CGRect btnRect = CGRectMake(0, 0, 200, 50);
    btnStart.frame = btnRect;
    btnStart.tag = 0;//点滅のタグ
    btnStart.center = CGPointMake(self.viewController.view.center.x, self.viewController.view.center.y + 120);
    [self.viewController.view addSubview:btnStart];
    
    timer = [NSTimer scheduledTimerWithTimeInterval:1.0
                                             target:self
                                           selector:@selector(switchStartButton)
                                           userInfo:nil
                                            repeats:YES];

}
             
-(void)switchStartButton
{
    NSLog(@"switchStartVutton");
    switch (btnStart.tag) {
        case 0:
            btnStart.alpha = 0.0;
            btnStart.tag = 1;
            break;
            
        case 1:
            btnStart.alpha = 1.0;
            btnStart.tag = 0;
            
        default:
            break;
    }
    
}
             
             
- (void)pushStartButton
{
    [timer invalidate];
    if (kaisuu == 0) {
        kaisuu++;
    
        NSLog(@"pushStartButton");
        NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
        [UIView animateWithDuration:1 animations:^(void){
            viewStart.alpha = 0.0;
            btnStart.alpha = 0.0;
        } completion:^(BOOL finished){
                [UIView animateWithDuration:3 animations:^(void){
                    viewBlack.alpha = 0.0;
                } completion:^(BOOL finished){
                    [UIView animateWithDuration:15
                                          delay:0
                                        options:UIViewAnimationOptionCurveLinear
                                     animations:^(void){
                                         scrStory.contentOffset = CGPointMake(0, scrStory.contentSize.height - scrStory.bounds.size.height );
                                     } completion:^(BOOL finished){
                                         if ([[ud objectForKey:@"TDFirstTime"] isEqualToString:@"0"]){
                                             [self skipStory];
                                         }
                                     }];
                }];
        }];
        if ([[ud objectForKey:@"TDFirstTime"] isEqualToString:@"1"]) {
            [self.viewController availableButton];
        }
    }
    
    
    
}

- (void)skipStory
{
    if (kaisuu == 1) {
        kaisuu++;
   
    
        NSLog(@"skip");
        [UIView animateWithDuration:5 animations:^(void){
            scrStory.alpha = 0.0;
            btnSkip.alpha = 0.0;
        } completion:^(BOOL finished){

            [self popUpTutorial];
        }];
    }
}

- (void)endTutorial
{
    NSLog(@"endTutorial");
    [UIView animateWithDuration:0.3 animations:^(void){
        scrTutorial.transform = CGAffineTransformMakeScale(0.001, 0.001);
    } completion:^(BOOL finished){
        [scrTutorial removeFromSuperview];
    }];
    
#warning 最後に直す
    [[NSUserDefaults standardUserDefaults] setObject:@"1" forKey:@"TDFirstTime"];
    [self.viewController availableButton];
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
