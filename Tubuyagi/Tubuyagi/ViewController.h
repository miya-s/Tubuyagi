//
//  ViewController.h
//  Tubuyagi
//
//  Created by Genki Ishibashi on 13/09/05.
//  Copyright (c) 2013年 Genki Ishibashi. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FoodUIViewController.h"
@interface ViewController : UIViewController<FoodViewControllerDelegate>

@property (strong, nonatomic) IBOutlet UILabel *strYagiName;
@property (weak, nonatomic) IBOutlet UILabel *strYagiTweet;
- (IBAction)chooseFood:(UIButton *)sender;
- (IBAction)setConfig:(UIButton *)sender;
@end
