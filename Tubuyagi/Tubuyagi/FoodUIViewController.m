//
//  FoodUIViewController.m
//  Tubuyagi
//
//  Created by Genki Ishibashi on 13/09/05.
//  Copyright (c) 2013年 Genki Ishibashi. All rights reserved.
//

#import "FoodUIViewController.h"
#import "TextAnalyzer.h"

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
//                [self performSelector:@selector(reloadData) withObject:self.foodTableView afterDelay:1.0];
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

- (NSArray *)getTextOrUserName:(NSString *)key{
    //tweetとユーザー名取得
    if ([key isEqualToString:@"text"]) {//本文の配列を返す
        NSArray *texts = [tweets valueForKeyPath:@"text"];
        return texts;
    } else if ([key isEqualToString:@"user"]){//ユーザー名の配列を返す
        NSArray *users = [[tweets valueForKeyPath:@"user"] valueForKeyPath:@"screen_name"];
        return users;
    } else
        return nil;
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
    NSString *strCellIdentifier = [NSString stringWithFormat:@"%d", indexPath.row];
    NSString *CellIdentifier = strCellIdentifier;
    
//    CustomCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    UITableViewCell *cell = [self.foodTableView dequeueReusableCellWithIdentifier:CellIdentifier];
    //    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
//            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
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
    UITableViewCell *selectedCell = [self.foodTableView cellForRowAtIndexPath:indexPath];
    [self.delegate setTweetString:selectedCell.textLabel.text];
    
    learnFromText(selectedCell.textLabel.text);
    

    [self dismissViewControllerAnimated:YES completion:nil];
    
}

//セルの高さ
- (float)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (tweets) {
        
        UITableViewCell *cell = [self tableView:self.foodTableView cellForRowAtIndexPath:indexPath];
        CGSize bounds = CGSizeMake(self.foodTableView.frame.size.width, self.foodTableView.frame.size.height);
        UIFont *font = cell.textLabel.font;
        NSLog(@"%@", font);
        //textLabelのサイズ
        CGSize size = [cell.textLabel.text sizeWithFont:cell.textLabel.font
                                    constrainedToSize:bounds
                                        lineBreakMode:NSLineBreakByClipping];
        NSLog(@"%@", cell.textLabel);
        NSLog(@"%@", NSStringFromCGSize(size));
        //detailTextLabelのサイズ
        CGSize detailSize = [[[self getTextOrUserName:@"user"] objectAtIndex:indexPath.row] sizeWithFont: cell.detailTextLabel.font
                                                constrainedToSize: bounds
                                                    lineBreakMode: NSLineBreakByWordWrapping];//UILineBreakModeCharacterWrap];
        NSLog(@"%f",size.height + detailSize.width);
        return size.height + detailSize.height;
    }
    return 44;
}

@end
