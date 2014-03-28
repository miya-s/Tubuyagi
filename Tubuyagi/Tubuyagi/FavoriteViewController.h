//
//  FavoriteViewController.h
//  Tubuyagi
//
//  Created by Genki Ishibashi on 13/09/10.
//  Copyright (c) 2013年 Genki Ishibashi. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FavoriteCustomViewCell.h"
#import "ActivityCustomViewCell.h"
#import "HeaderView.h"

@protocol FavoriteViewControllerDelegate;

@interface FavoriteViewController : UIViewController<UITableViewDataSource,UITableViewDelegate,
                                        UIScrollViewDelegate>
{
    FavoriteCustomViewCell *selectedCell;
}
@property (strong, nonatomic) IBOutlet UITableView *tableView;
@property (nonatomic, retain) NSArray *favTweet;
@property (nonatomic, retain) NSArray *activities;
@property (strong, nonatomic) IBOutlet HeaderView *headerView;
@property (nonatomic, retain) id<FavoriteViewControllerDelegate> delegate;
@property (readonly) BOOL showActivity;

- (IBAction)backMainView:(id)sender;

@end

@protocol FavoriteViewControllerDelegate <NSObject>

- (void)reloadFavCount;

@end
