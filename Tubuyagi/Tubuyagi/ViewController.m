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

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    UITapGestureRecognizer *gesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tweetYagi)];
    [self.imgViewYagi addGestureRecognizer:gesture];
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
}

- (void)setTweetString:(NSString *)strTweet
{

    CGRect rect = CGRectMake(0.0, 0.0, 20, 30);
    self.strYagiTweet.text = strTweet;
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:3.f];

    _strYagiTweet.center = CGPointMake(0.0, 0.0);
//    self.strYagiTweet.transform = CGAffineTransformMakeScale(0.01, 0.01);
    [UIView commitAnimations];
//    bubbleView *bblView = [bubbleView alloc]
    
}

- (void)tweetYagi
{
    NSLog(@"tap");
}
@end
