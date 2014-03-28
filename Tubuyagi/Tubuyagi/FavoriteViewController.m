//
//  FavoriteViewController.m
//  Tubuyagi
//
//  Created by Genki Ishibashi on 13/09/10.
//  Copyright (c) 2013年 Genki Ishibashi. All rights reserved.
//

#import "FavoriteViewController.h"
#import "MarkovTextGenerator.h"
#import "TweetsManager.h"
#import "FMDatabase+Tubuyagi.h"

@interface FavoriteViewController ()

@end

@implementation FavoriteViewController

- (BOOL)shouldAutorotate
{
    return NO;
}

//ステータスバーの非表示
- (BOOL)prefersStatusBarHidden
{
    return YES;
}


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

//更新表示を隠す
- (void)_setHeaderViewHidden:(BOOL)hidden animated:(BOOL)animated
{
    CGFloat topOffset = 0.0;
    if (hidden) {
        topOffset = -self.headerView.frame.size.height;
    }
    if (animated) {
        [UIView animateWithDuration:0.2 animations:^{
            self.tableView.contentInset = UIEdgeInsetsMake(topOffset, 0, 0, 0);
        }];
    } else{
        self.tableView.contentInset = UIEdgeInsetsMake(topOffset, 0, 0, 0);
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    
    //HeaderView
    self.tableView.tableHeaderView = self.headerView;
    UIImage *img = [UIImage imageNamed:@"status_bar.png"];
    UIColor *bgColor = [UIColor colorWithPatternImage:img];
    self.headerView.backgroundColor = bgColor;
    [self _setHeaderViewHidden:YES animated:NO];
    [self.headerView setState:HeaderViewStateHidden];
    
    [self.tableView reloadData];

}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidUnload {
    [self setTableView:nil];
    [super viewDidUnload];
}
- (IBAction)backMainView:(id)sender {
    
    [self dismissViewControllerAnimated:YES completion:nil];
    [self.delegate reloadFavCount];
}

#pragma mark - UITableViewDataSource

//要素数
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    if (self.showActivity){
        if (self.activities) {
            return [self.activities count];
        }
        return 0;
    }
    
    if (self.favTweet) {
        return [self.favTweet count];
    }
    return 0;
}

// セルの中身の実装
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.showActivity){
        NSString *CellIdentifier = @"ActivityCell";
        
        ActivityCustomViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        if (cell == nil) {
            cell = [[ActivityCustomViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        }
        if (self.activities){
            
            cell.text = [[self.activities objectAtIndex:indexPath.row] objectForKey:@"text"];
            cell.seen = [[[self.activities objectAtIndex:indexPath.row] objectForKey:@"seen"]boolValue];
            cell.type = [[[self.activities objectAtIndex:indexPath.row] objectForKey:@"type"] integerValue];
            cell.date = [[self.activities objectAtIndex:indexPath.row] objectForKey:@"date"];
        }
        
        
        return cell;
    }
    
    
    
    NSString *CellIdentifier = @"Cell";//strCellIdentifier;
    
    FavoriteCustomViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[FavoriteCustomViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    if (self.favTweet){
        NSString *tweet = [[self.favTweet objectAtIndex:indexPath.row] objectForKey:@"content"];
        NSString *strYagiName = [[self.favTweet objectAtIndex:indexPath.row] objectForKey:@"yagi_name"];

        int i = [[[self.favTweet objectAtIndex:indexPath.row] objectForKey:@"wara"] intValue];

        
#warning ここの設計よくない cellのpropertyとしてtweetなどを設定し、そのプロパティのセッタで変更内容をビューを反映する処理のほうがいい
        cell.userID = [[self.favTweet objectAtIndex:indexPath.row] objectForKey:@"id"];
        cell.lblTweet.text = tweet;
        cell.lblYagiName.text = strYagiName;
        cell.lblFavNumber.text = [NSString stringWithFormat:@"%d",i] ;
        
        // 不正確な値になるので、statusのfavoritedは使用しない
        // 既にふぁぼったものはボタンを無効化
        NSString *tweetID = [[self.favTweet objectAtIndex:indexPath.row] objectForKey:@"id"];
        FMDatabase *database = [FMDatabase databaseFactory];
        BOOL faved = [database findFavoriteByID:tweetID];
        if (faved){
            [cell disabledButton:cell.btnFavorite];
        }
    }
    

    return cell;
}

//セルを選択した時の処理
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{

    
}

#define margin 8
//セルの高さ
- (float)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSLog(@"heightForRowAtIndexPath");
    if (self.favTweet) {
        
        FavoriteCustomViewCell *aCell = [[FavoriteCustomViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"Cell"];
        CGSize bounds = CGSizeMake(aCell.lblTweet.frame.size.width, 1000);

        CGSize size = [aCell.lblTweet.text sizeWithFont:aCell.lblTweet.font
                                      constrainedToSize:bounds
                                          lineBreakMode:NSLineBreakByWordWrapping];
        return size.height + margin * 3 + 80;
    }
    return 8*2 + 50 + 22 +15;
}

#pragma mark - UIScrolViewDelegate

#define PULLDOWN_MARGINE -15.0f

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if (self.headerView.state == HeaderViewStateStopping) {
        return;
    }
    
    CGFloat threshold = self.headerView.frame.size.height;
    
    if ( PULLDOWN_MARGINE <= scrollView.contentOffset.y &&
        scrollView.contentOffset.y < threshold) {
        self.headerView.state = HeaderViewStatePullingDown;
    } else if (scrollView.contentOffset.y < PULLDOWN_MARGINE){
        self.headerView.state = HeaderViewStateOveredThreshold;
    } else{
        self.headerView.state = HeaderViewStateHidden;
    }
    
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    if (self.headerView.state == HeaderViewStateOveredThreshold) {
        self.headerView.state = HeaderViewStateStopping;
        [self _setHeaderViewHidden:NO animated:YES];
        
        [self performSelector:@selector(getFavoriteJsondata) withObject:nil afterDelay:0.1];
    }
}

//データの取得
- (void)getFavoriteJsondata
{
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    __block __weak FavoriteViewController *weakself = self;
    TweetsManager *tweetsManager = [TweetsManager tweetsManagerFactory];
    if ([self.tabBarItem.title isEqualToString:@"新着"]) {
        [tweetsManager checkSearchResultForRecent:YES
                                     SuccessBlock:^(NSArray *statuses) {
                                         weakself.favTweet = statuses;
                                         NSLog(@"status got:%@", statuses);
                                         [weakself taskFinished];
                                         [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
                                     }
                                       errorBlock:^(NSError *error) {
                                           NSAssert(!error, [error localizedDescription]);
                                           [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
                                       }];
    } else if ([self.tabBarItem.title isEqualToString:@"人気"]){
        [tweetsManager checkSearchResultForRecent:NO
                                     SuccessBlock:^(NSArray *statuses) {
                                         weakself.favTweet = statuses;
                                         NSLog(@"status got:%@", statuses);
                                         [weakself taskFinished];
                                         [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
                                     }
                                       errorBlock:^(NSError *error) {
                                           NSAssert(!error, [error localizedDescription]);
                                           [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
                                       }];
    } else if ([self.tabBarItem.title isEqualToString:@"通知"]){
        FMDatabase *database = [FMDatabase databaseFactory];
        self.activities = [database activityArrayWithCount:30];
        [self taskFinished];
    }
}

- (void)taskFinished
{
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    self.headerView.state = HeaderViewStateHidden;
    [self.headerView setUpdatedDate:[NSDate date]];
    [self _setHeaderViewHidden:YES animated:YES];
    [self.tableView reloadData];
}

- (void)tableView:(UITableView *)tableView
  willDisplayCell:(UITableViewCell *)cell
forRowAtIndexPath:(NSIndexPath *)indexPath
{
    UIImage *bgImage = [UIImage imageNamed:@"paper_2.jpg"];
    UIColor *bgColor = [[UIColor alloc] initWithPatternImage:bgImage];
    cell.backgroundColor = bgColor;
    
}

- (BOOL)showActivity{
    return [self.tabBarItem.title isEqualToString:@"通知"];
}
@end
