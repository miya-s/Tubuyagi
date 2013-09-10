//
//  FavoriteViewController.m
//  Tubuyagi
//
//  Created by Genki Ishibashi on 13/09/10.
//  Copyright (c) 2013年 Genki Ishibashi. All rights reserved.
//

#import "FavoriteViewController.h"

@interface FavoriteViewController ()

@end

@implementation FavoriteViewController

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
    
//    NSLog(@"numberOfRowsInSection");
//    if (arrDeleteWord) {
//        return [arrDeleteWord count];
//    }
    return 10;//tweetの数
}

// セルの中身の実装
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    //    NSLog(@"cellForRowAtIndexPath");
    
    NSString *strCellIdentifier = [NSString stringWithFormat:@"%d", indexPath.row];
    NSString *CellIdentifier = strCellIdentifier;
    
    FavoriteCustomVIewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[FavoriteCustomVIewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];

        
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
//    NSString *strAlert = [NSString stringWithFormat:@"「%@」を忘れさせてもいいですか？？", selectedCell.textLabel.text];
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"単語の削除"
                                                    message:@"おす"
                                                   delegate:self
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:@"キャンセル", nil];
    [alert show];
    
    
}

//セルの高さ
- (float)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
//    NSLog(@"heightForRowAtIndexPath");
//    if (arrDeleteWord) {
//        
//        UITableViewCell *cell = [self tableView:self.tableView cellForRowAtIndexPath:indexPath];
//        CGSize bounds = CGSizeMake(self.view.frame.size.width, self.view.frame.size.height);
//        UIFont *font = cell.textLabel.font;
//        NSLog(@"%@", font);
//        //textLabelのサイズ
//        CGSize size = [cell.textLabel.text sizeWithFont:cell.textLabel.font
//                                      constrainedToSize:bounds
//                                          lineBreakMode:NSLineBreakByWordWrapping];
//        return size.height + 20;
//    }
    return 8*2 + 50 + 22;
}
@end
