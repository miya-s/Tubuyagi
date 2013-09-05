//
//  FoodUIViewController.h
//  Tubuyagi
//
//  Created by Genki Ishibashi on 13/09/05.
//  Copyright (c) 2013年 Genki Ishibashi. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol FoodViewControllerDelegate;

@interface FoodUIViewController : UIViewController<UITableViewDataSource, UITableViewDelegate>

@property (strong, nonatomic) IBOutlet UITableView *foodTableView;
@property (nonatomic, retain) id<FoodViewControllerDelegate> delegate;

- (IBAction)backMainView:(id)sender;

@end

@protocol FoodViewControllerDelegate <NSObject>

- (void)setTweetString:(NSString *)strTweet;

@end
