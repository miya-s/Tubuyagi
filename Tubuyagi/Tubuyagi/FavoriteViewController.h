//
//  FavoriteViewController.h
//  Tubuyagi
//
//  Created by Genki Ishibashi on 13/09/10.
//  Copyright (c) 2013年 Genki Ishibashi. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FavoriteCustomVIewCell.h"
#import "HeaderView.h"

@protocol FavoriteViewControllerDelegate;

@interface FavoriteViewController : UIViewController<UITableViewDataSource,UITableViewDelegate,
                                        UIScrollViewDelegate>
{
//    NSDictionary *favTweets;
    FavoriteCustomVIewCell *selectedCell;
//    NSString *userID;
}
@property (strong, nonatomic) IBOutlet UITableView *tableView;
@property (nonatomic, retain) NSArray *favTweet;
@property (strong, nonatomic) IBOutlet HeaderView *headerView;
@property (nonatomic, retain) id<FavoriteViewControllerDelegate> delegate;

- (IBAction)backMainView:(id)sender;

@end

@protocol FavoriteViewControllerDelegate <NSObject>

- (void)reloadFavCount;

@end
