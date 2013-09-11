//
//  FoodUIViewController.h
//  Tubuyagi
//
//  Created by Genki Ishibashi on 13/09/05.
//  Copyright (c) 2013年 Genki Ishibashi. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Social/Social.h>
#import "HeaderView.h"

@protocol FoodViewControllerDelegate;

@interface FoodUIViewController : UIViewController<UITableViewDataSource, UITableViewDelegate,
                                                        UIScrollViewDelegate>
{
//    NSArray *tweets;
}
@property (strong, nonatomic) IBOutlet UITableView *foodTableView;
@property (nonatomic, retain) id<FoodViewControllerDelegate> delegate;
@property (nonatomic, retain) NSArray *twitterAccounts;
@property (nonatomic, retain) NSArray *tweets;
//@property (nonatomic, retain) NSArray *tweets;
@property (strong, nonatomic) IBOutlet HeaderView *headerView;
@property (strong, nonatomic) IBOutlet UILabel *lblTitle;


- (IBAction)backMainView:(id)sender;

@end

@protocol FoodViewControllerDelegate <NSObject>

- (void)setTweetString:(NSString *)strTweet;
- (void)foodCancel;

@end
