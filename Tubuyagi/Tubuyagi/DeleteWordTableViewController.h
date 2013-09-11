//
//  DeleteWordTableViewController.h
//  Tubuyagi
//
//  Created by Genki Ishibashi on 13/09/09.
//  Copyright (c) 2013年 Genki Ishibashi. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol DeleteWordTabelViewControllerDelegate;

@interface DeleteWordTableViewController : UIViewController<UITableViewDataSource, UITableViewDelegate,
                    UIAlertViewDelegate>
{
    NSArray *arrDeleteWord;
    UITableViewCell *selectedCell;
}
@property (strong, nonatomic) IBOutlet UITableView *tableView;
@property (nonatomic, retain) id<DeleteWordTabelViewControllerDelegate> delegate;
- (IBAction)backMainView:(id)sender;
@end

@protocol DeleteWordTabelViewControllerDelegate <NSObject>

- (void)wordDelete;

@end
