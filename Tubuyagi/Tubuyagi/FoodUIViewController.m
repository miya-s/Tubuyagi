//
//  FoodUIViewController.m
//  Tubuyagi
//
//  Created by Genki Ishibashi on 13/09/05.
//  Copyright (c) 2013年 Genki Ishibashi. All rights reserved.
//

#import "FoodUIViewController.h"
#import "TextAnalyzer.h"
#import "STTwitter.h"
#import "DeleteWordTableViewController.h"

@interface FoodUIViewController ()

@end

@implementation FoodUIViewController

- (BOOL)shouldAutorotate
{
    return NO;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
//        self.foodTableView.delegate = self;
//        self.foodTableView.dataSource = self;
        
    }
    self.view.backgroundColor = [UIColor redColor];
    NSLog(@"init");
    return self;
}

- (void)_setHeaderViewHidden:(BOOL)hidden animated:(BOOL)animated
{
    CGFloat topOffset = 0.0;
    if (hidden) {
        topOffset = -self.headerView.frame.size.height;
    }
    if (animated) {
        [UIView animateWithDuration:0.2 animations:^{
            self.foodTableView.contentInset = UIEdgeInsetsMake(topOffset, 0, 0, 0);
        }];
    } else{
        self.foodTableView.contentInset = UIEdgeInsetsMake(topOffset, 0, 0, 0);
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    NSLog(@"ViewDidLoad");
    
    self.lblTitle.text = @"";
    
    //HeaderView
    self.foodTableView.tableHeaderView = self.headerView;
    [self _setHeaderViewHidden:YES animated:NO];
    [self.headerView setState:HeaderViewStateHidden];
    
    //twtterデータの取得
//    [self getTwitterInformation];
    
    //紙の背景の生成
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
#pragma mark - myFunction

- (IBAction)backMainView:(id)sender {
    
    [self.delegate foodCancel];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (NSArray *)getTextOrUserName:(NSString *)key{
    
    NSLog(@"getTextOrUserName");
    //tweetとユーザー名取得
    if ([key isEqualToString:@"text"]) {//本文の配列を返す
        NSArray *texts = [self.tweets valueForKeyPath:@"text"];
        return texts;
    } else if ([key isEqualToString:@"user"]){//ユーザー名の配列を返す
        NSArray *users = [[self.tweets valueForKeyPath:@"user"] valueForKeyPath:@"screen_name"];
        return users;
    } else
        return nil;
}

- (void)getTwitterInformation
{
//    self.statuses = @[];
//    self.statusLabel.text = @"";
//    [self.foodTableView reloadData];
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    STTwitterAPI *twitter = [STTwitterAPI twitterAPIOSWithFirstAccount];
    
    [twitter verifyCredentialsWithSuccessBlock:^(NSString *username) {
        
//        self.statusLabel.text = [NSString stringWithFormat:@"Fetching timeline for @%@...", username];
        
        [twitter getHomeTimelineSinceID:nil
                                  count:20
                           successBlock:^(NSArray *statuses) {
                               
                               NSLog(@"-- statuses: %@", statuses);
                               
//                               self.statusLabel.text = [NSString stringWithFormat:@"@%@", username];
                               
                               self.tweets = statuses;
                               [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
                               self.headerView.state = HeaderViewStateHidden;
                               [self.headerView setUpdatedDate:[NSDate date]];
                               [self _setHeaderViewHidden:YES animated:YES];
                               [self.foodTableView reloadData];
                               
                               
                           } errorBlock:^(NSError *error) {
                               NSLog(@"%@", [error localizedDescription]);
                           }];
        
    } errorBlock:^(NSError *error) {
        NSLog(@"%@", [error localizedDescription]);
    }];
}


#pragma mark - UITableViewDataSource

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    
    NSLog(@"numberOfRowsInSection");
    if (self.tweets) {
        return [self.tweets count];
    }
    return 0;//tweetの数
}

// セルの中身の実装
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSLog(@"cellForRowAtIndexPath");
    
    NSString *strCellIdentifier = [NSString stringWithFormat:@"%d", indexPath.row];
    NSString *CellIdentifier = strCellIdentifier;
    
//    CustomCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    UITableViewCell *cell = [self.foodTableView dequeueReusableCellWithIdentifier:CellIdentifier];
    //    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
            cell.textLabel.font = [UIFont systemFontOfSize:[UIFont systemFontSize]];
            cell.textLabel.numberOfLines = 0;
            cell.detailTextLabel.font = [UIFont systemFontOfSize:[UIFont systemFontSize]];

            
            
            //tweetとユーザー名取得
            cell.textLabel.text = [[self getTextOrUserName:@"text"] objectAtIndex:indexPath.row];//[texts objectAtIndex:indexPath.row];
            cell.detailTextLabel.text = [[self getTextOrUserName:@"user"] objectAtIndex:indexPath.row];
        }
    }
    
    
    return cell;
}

//セルを選択した時の処理
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSLog(@"didSelectRow");
    UITableViewCell *selectedCell = [self.foodTableView cellForRowAtIndexPath:indexPath];
    [self.delegate setTweetString:selectedCell.textLabel.text];
    
    learnFromText(selectedCell.textLabel.text);
    

    [self dismissViewControllerAnimated:YES completion:^(void){
        [self.foodTableView deselectRowAtIndexPath:indexPath animated:NO];
    }];
    
}

//セルの高さ
- (float)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSLog(@"heightForRowAtIndexPath");
    if (self.tweets) {
        
        UITableViewCell *cell = [self tableView:self.foodTableView cellForRowAtIndexPath:indexPath];
        CGSize bounds = CGSizeMake(self.view.frame.size.width, self.view.frame.size.height);
        UIFont *font = cell.textLabel.font;
        NSLog(@"%@", font);
        //textLabelのサイズ
        CGSize size = [cell.textLabel.text sizeWithFont:cell.textLabel.font
                                    constrainedToSize:bounds
                                        lineBreakMode:NSLineBreakByWordWrapping];
        NSLog(@"%@", cell.textLabel);
        NSLog(@"%@", NSStringFromCGSize(size));
        //detailTextLabelのサイズ
        CGSize detailSize = [[[self getTextOrUserName:@"user"] objectAtIndex:indexPath.row] sizeWithFont: cell.detailTextLabel.font
                                                constrainedToSize: bounds
                                                    lineBreakMode: NSLineBreakByWordWrapping];//UILineBreakModeCharacterWrap];
//        NSLog(@"detail size %@", NSStringFromCGSize(detailSize));
        NSLog(@"%f",size.height + detailSize.width);
        return size.height + detailSize.height + 20;
    }
    return 44;
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
        
        [self performSelector:@selector(getTwitterInformation) withObject:nil afterDelay:0.1];
        //        [self.delegate refleshMainView];
    }
}

//テーブルの背景

- (void)tableView:(UITableView *)tableView
  willDisplayCell:(UITableViewCell *)cell
forRowAtIndexPath:(NSIndexPath *)indexPath
{
//    UIImage *bgImage = [UIImage imageNamed:@"paper.png"];
//    UIColor *bgColor = [[UIColor alloc] initWithPatternImage:bgImage];
//    cell.backgroundColor = bgColor;
//    // For even
//    if (indexPath.row % 2 == 0) {
//        cell.backgroundColor = [UIColor whiteColor];
//    }
//    // For odd
//    else {
//        cell.backgroundColor = [UIColor colorWithHue:0.61
//                                          saturation:0.09
//                                          brightness:0.99
//                                               alpha:1.0];
//    }
}


@end
