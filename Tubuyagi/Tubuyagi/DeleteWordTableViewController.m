//
//  DeleteWordTableViewController.m
//  Tubuyagi
//
//  Created by Genki Ishibashi on 13/09/09.
//  Copyright (c) 2013年 Genki Ishibashi. All rights reserved.
//

#import "DeleteWordTableViewController.h"
#import "TextAnalyzer.h"

@interface DeleteWordTableViewController ()

@end

@implementation DeleteWordTableViewController

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
        NSSet *aSet = [NSSet setWithArray:showLearnLog()];
        arrDeleteWord = [aSet allObjects];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    NSSet *aSet = [NSSet setWithArray:showLearnLog()];
    arrDeleteWord = [aSet allObjects];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (IBAction)backMainView:(id)sender {
    [self dismissViewControllerAnimated:YES completion:^(void){}];
}

#pragma mark - UITableViewDataSource

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    
    NSLog(@"numberOfRowsInSection");
    if (arrDeleteWord) {
        return [arrDeleteWord count];
    }
    return 0;//tweetの数
}

// セルの中身の実装
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
//    NSLog(@"cellForRowAtIndexPath");
    
    NSString *strCellIdentifier = [NSString stringWithFormat:@"%d", indexPath.row];
    NSString *CellIdentifier = strCellIdentifier;
    
    //    CustomCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    //    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
            //            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            cell.textLabel.font = [UIFont systemFontOfSize:[UIFont systemFontSize]];
            cell.textLabel.numberOfLines = 0;
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            cell.detailTextLabel.font = [UIFont systemFontOfSize:[UIFont systemFontSize]];
            if (arrDeleteWord) {
                cell.textLabel.text = [arrDeleteWord objectAtIndex:indexPath.row];
            }
//            NSLog(@"delete word %@", [showDeletableWords() objectAtIndex:indexPath.row]);
        
        }
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

    
    selectedCell = [self.tableView cellForRowAtIndexPath:indexPath];
    NSString *strAlert = [NSString stringWithFormat:@"「%@」を忘れさせてもいいですか？？", selectedCell.textLabel.text];
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"単語の削除"
                                                    message:strAlert
                                                   delegate:self
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:@"キャンセル", nil];
    [alert show];

    
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    switch (buttonIndex) {
        case 0:

            forgetFromText(selectedCell.textLabel.text);
            [self dismissViewControllerAnimated:YES completion:^(void){}];
            [self.delegate wordDelete];
            break;
            
        default:
            break;
    }
}

//セルの高さ
- (float)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSLog(@"heightForRowAtIndexPath");
    if (arrDeleteWord) {
        
        UITableViewCell *cell = [self tableView:self.tableView cellForRowAtIndexPath:indexPath];
        CGSize bounds = CGSizeMake(self.view.frame.size.width, self.view.frame.size.height);
        UIFont *font = cell.textLabel.font;
        NSLog(@"%@", font);
        //textLabelのサイズ
        CGSize size = [cell.textLabel.text sizeWithFont:cell.textLabel.font
                                      constrainedToSize:bounds
                                          lineBreakMode:NSLineBreakByWordWrapping];
//        NSLog(@"%@", cell.textLabel);
//        NSLog(@"%@", NSStringFromCGSize(size));
        //detailTextLabelのサイズ
//        CGSize detailSize = [[arrDeleteWord objectAtIndex:indexPath.row] sizeWithFont: cell.detailTextLabel.font
//                                                                                       constrainedToSize: bounds
//                                                                                           lineBreakMode: NSLineBreakByWordWrapping];//UILineBreakModeCharacterWrap];
//        NSLog(@"%f",size.height + detailSize.width);
        return size.height + 20;
    }
    return 44;
}

//テーブルの背景

- (void)tableView:(UITableView *)tableView
  willDisplayCell:(UITableViewCell *)cell
forRowAtIndexPath:(NSIndexPath *)indexPath
{
    UIImage *bgImage = [UIImage imageNamed:@"paper_2.jpg"];
    UIColor *bgColor = [[UIColor alloc] initWithPatternImage:bgImage];
    cell.backgroundColor = bgColor;
    
}

@end
