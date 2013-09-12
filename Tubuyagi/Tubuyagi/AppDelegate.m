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
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    // Override point for customization after application launch.
    self.viewController = [[ViewController alloc] initWithNibName:@"ViewController" bundle:nil];
    self.window.rootViewController = self.viewController;
    [self.window makeKeyAndVisible];
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];

    NSMutableDictionary *defaults = [NSMutableDictionary dictionary];
    [defaults setObject:@"サイバーくん" forKey:@"TDUserName"];
    [defaults setObject:@"つぶやぎ" forKey:@"TDYagiName"];
    [ud registerDefaults:defaults];

    if (![ud objectForKey:@"TDRandomPassword"]){
        [ud setObject:randStringWithLength(20) forKey:@"TDRandomPassword"];
    }

#warning 毎回送る必要はない→名前変更時と、初回起動時と、twitter認証時
    addUser();

    [self creatStartView];
    
    
    return YES;
}

- (void)creatStartView
{
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
    [UIView animateWithDuration:1 animations:^(void){
        viewStart.alpha = 0.0;
        btnStart.alpha = 0.0;
    }];
    
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
