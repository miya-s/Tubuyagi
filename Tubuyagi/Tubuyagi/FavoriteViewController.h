//
//  FavoriteViewController.h
//  Tubuyagi
//
//  Created by Genki Ishibashi on 13/09/10.
//  Copyright (c) 2013年 Genki Ishibashi. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FavoriteCustomVIewCell.h"

@interface FavoriteViewController : UIViewController<UITableViewDataSource,UITableViewDelegate>
{
//    NSDictionary *favTweets;
}
@property (strong, nonatomic) IBOutlet UITableView *tableView;
@property (nonatomic, retain) NSArray *favTweet;

- (IBAction)backMainView:(id)sender;

@end
