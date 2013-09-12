//
//  FavoriteViewController.m
//  Tubuyagi
//
//  Created by Genki Ishibashi on 13/09/10.
//  Copyright (c) 2013年 Genki Ishibashi. All rights reserved.
//

#import "FavoriteViewController.h"
#import "BasicRequest.h"

@interface FavoriteViewController ()

@end

@implementation FavoriteViewController

- (BOOL)shouldAutorotate
{
    return NO;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    
    //データの取得
//    favTweets = getJSONTops(0, 20);
//    NSDictionary *dic = [favTweets objectForKey:@"0"];
//    NSLog(@"dic %@", self.favTweet);
//    NSString *userName = [[self.favTweet objectForKey:@"1"] objectForKey:@"content"];
//    NSLog(@"username %@", userName);
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
}

#pragma mark - UITableViewDataSource

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    
    NSLog(@"numberOfRowsInSection");
    if (self.favTweet) {
        return [self.favTweet count];
    }
    return 0;//tweetの数
}

// セルの中身の実装
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    //    NSLog(@"cellForRowAtIndexPath");
    
//    NSString *strCellIdentifier = [NSString stringWithFormat:@"%d", indexPath.row];
    NSString *CellIdentifier = @"Cell";//strCellIdentifier;
    
    FavoriteCustomVIewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[FavoriteCustomVIewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
//        NSString *num = [NSString stringWithFormat:@"%d", indexPath.row];
        
        
    
//        if (self.favTweet){
//            NSString *tweet = [[self.favTweet objectAtIndex:indexPath.row] objectForKey:@"content"];
//            NSString *strYagiName = [[self.favTweet objectAtIndex:indexPath.row] objectForKey:@"yagi_name"];
//
//
//        }
    }
    if (self.favTweet){
        NSString *tweet = [[self.favTweet objectAtIndex:indexPath.row] objectForKey:@"content"];
        NSString *strYagiName = [[self.favTweet objectAtIndex:indexPath.row] objectForKey:@"yagi_name"];
        
        
        cell.userID = [[self.favTweet objectAtIndex:indexPath.row] objectForKey:@"id"];
        cell.lblTweet.text = tweet;
        cell.lblYagiName.text = strYagiName;
        

    }
    

    return cell;
}

//セルを選択した時の処理
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    //    NSLog(@"didSelectRow");
    //    UITableViewCell *selectedCell = [self.foodTableView cellForRowAtIndexPath:indexPath];
    //    [self.delegate setTweetString:selectedCell.textLabel.text];
    //
    //    learnFromText(selectedCell.textLabel.text);
    
    
//    selectedCell = [self.tableView cellForRowAtIndexPath:indexPath];
//    NSLog(@"click tubuyaki %@", selectedCell.lblTweet);
//    NSString *strAlert = [NSString stringWithFormat:@"「%@」を忘れさせてもいいですか？？", selectedCell.textLabel.text];
//    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"単語の削除"
//                                                    message:@"おす"
//                                                   delegate:self
//                                          cancelButtonTitle:@"OK"
//                                          otherButtonTitles:@"キャンセル", nil];
//    [alert show];
    
    
}

#define margin 8
//セルの高さ
- (float)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSLog(@"heightForRowAtIndexPath");
    if (self.favTweet) {
        
        FavoriteCustomVIewCell *aCell = [[FavoriteCustomVIewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"Cell"];
        CGSize bounds = CGSizeMake(aCell.lblTweet.frame.size.width, 1000);
//        UIFont *font = aCell.textLabel.font;
//        NSLog(@"font desu %@", font);
        //textLabelのサイズ
        CGSize size = [aCell.lblTweet.text sizeWithFont:aCell.lblTweet.font
                                      constrainedToSize:bounds
                                          lineBreakMode:NSLineBreakByWordWrapping];
        return size.height + margin * 3 + 80;
    }
    return 8*2 + 50 + 22 +15;
}
@end
