//
//  FoodUIViewController.m
//  Tubuyagi
//
//  Created by Genki Ishibashi on 13/09/05.
//  Copyright (c) 2013年 Genki Ishibashi. All rights reserved.
//

#import "FoodUIViewController.h"

@interface FoodUIViewController ()

@end

@implementation FoodUIViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
//        self.foodTableView.delegate = self;
//        self.foodTableView.dataSource = self;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    //    if (_twitterAccounts.count == 0) return;
    
    NSURL *url = [NSURL URLWithString:@"https://api.twitter.com/1.1/statuses/home_timeline.json"];
    SLRequest *request = [SLRequest requestForServiceType:SLServiceTypeTwitter
                                            requestMethod:SLRequestMethodGET
                                                      URL:url
                                               parameters:nil];
    // Use first twitter account.
    [request setAccount:[_twitterAccounts objectAtIndex:0]];
    [request performRequestWithHandler:^(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            NSUInteger statusCode = urlResponse.statusCode;
            if (200 <= statusCode && statusCode < 300) {
                tweets = [NSJSONSerialization JSONObjectWithData:responseData options:0 error:nil];
                [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
                [self.foodTableView reloadData];
            } else {
                NSDictionary *twitterErrorRoot = [NSJSONSerialization JSONObjectWithData:responseData options:0 error:nil];
                NSArray *twitterErrors = [twitterErrorRoot objectForKey:@"errors"];
                if (twitterErrors.count > 0) {
                    NSLog(@"%@",[[twitterErrors objectAtIndex:0] objectForKey:@"message"]);
                } else {
                    NSLog(@"Failed to get tweets.");
                    
                }
            }
        });
    }];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
#pragma mark - myFunction

- (IBAction)backMainView:(id)sender {
    
    [self dismissViewControllerAnimated:YES completion:nil];
}


#pragma mark - UITableViewDataSource

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    
    if (tweets) {
        return [tweets count];
    }
    return 0;//tweetの数
}

// セルの中身の実装
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
//    CustomCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    UITableViewCell *cell = [self.foodTableView dequeueReusableCellWithIdentifier:CellIdentifier];
    //    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            
            //tweetとユーザー名取得
            NSArray *texts = [tweets valueForKeyPath:@"text"];
            cell.textLabel.text = [texts objectAtIndex:indexPath.row];
            NSArray *users = [[tweets valueForKeyPath:@"user"] valueForKeyPath:@"screen_name"];
            cell.detailTextLabel.text = [users objectAtIndex:indexPath.row];
        }
    }
    return cell;
}

//セルを選択した時の処理
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *selectedCell = [self.foodTableView cellForRowAtIndexPath:indexPath];
    [self.delegate setTweetString:selectedCell.textLabel.text];

    [self dismissViewControllerAnimated:YES completion:nil];
    
}

@end
