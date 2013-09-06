//
//  ViewController.m
//  Tubuyagi
//
//  Created by Genki Ishibashi on 13/09/05.
//  Copyright (c) 2013年 Genki Ishibashi. All rights reserved.
//

#import "ViewController.h"
#import "FoodUIViewController.h"


@interface ViewController ()

@end

@implementation ViewController
@synthesize bblView = _bblView;

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    UITapGestureRecognizer *gesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tweetYagi)];
    [self.imgViewYagi addGestureRecognizer:gesture];
    self.imgViewYagi.userInteractionEnabled = YES;
    
    //bubbleView生成
    CGRect bblRect = CGRectMake( 60, 100, 200, 115);
    _bblView = [[bubbleView alloc] initWithFrame:bblRect];
    self.bblView.backgroundColor = [UIColor clearColor];
    [self.view addSubview:self.bblView];
    
    //食べる紙のVIew
    CGRect lblRect = CGRectMake(40, 330, 280, 52);
    lblYagiTweet = [[UILabel alloc] initWithFrame:lblRect];
    lblYagiTweet.text = @"aaaa";
    [self.view addSubview:lblYagiTweet];
    
    [self initialize];
}

//位置設定の初期設定
- (void)initialize
{
    lblYagiTweet.frame = CGRectMake(40, 330, 280, 52);
    lblYagiTweet.alpha = 0.0;
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
    [self presentViewController:fvc animated:YES completion:nil];
}

- (IBAction)setConfig:(UIButton *)sender {
    [self alert];
}

- (void)setTweetString:(NSString *)strTweet
{

    lblYagiTweet.alpha = 1.0;
//    [UIView beginAnimations:nil context:NULL];
//    [UIView setAnimationDuration:2.f];
    [UIView animateWithDuration:2.0f animations:^{
        lblYagiTweet.center = self.imgViewYagi.center;
        lblYagiTweet.transform = CGAffineTransformMakeScale(0.01, 0.01);
    } completion:^(BOOL finished){
        lblYagiTweet.transform = CGAffineTransformIdentity;
        [self initialize];
    }];
    lblYagiTweet.text = strTweet;
    
//    [UIView commitAnimations];

    
}

- (void)eatPaper
{
    lblYagiTweet.center = self.imgViewYagi.center;
    lblYagiTweet.transform = CGAffineTransformMakeScale(0.01, 0.01);
}

- (void)tweetYagi
{

    int randomNumber = arc4random() %10000000000000000;
    NSString *strNum = [NSString stringWithFormat:@"あなたの今日のラッキーナンバーは%dだね", randomNumber];
    
    //文字のサイズを取るためのUILabel
    self.bblView.strTweet.text = strNum;
    [self.bblView setNeedsDisplay];
}


- (void)alert{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"まだできていません" message:@"Coming Soon!" delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
    [alert show];
}
@end
