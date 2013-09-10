//
//  FavoriteCustomVIewCell.m
//  Tubuyagi
//
//  Created by Genki Ishibashi on 13/09/10.
//  Copyright (c) 2013年 Genki Ishibashi. All rights reserved.
//

#import "FavoriteCustomVIewCell.h"

@implementation FavoriteCustomVIewCell

#define margin 8

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
        self.backgroundColor = [UIColor redColor];


    }

    [self layoutView];

    return self;
}

- (void)layoutView
{
    //ヤギの画像
    // リサイズ例文（サイズを指定する方法）
    UIImage *img_mae = [UIImage imageNamed:@"yagiSample.png"];  // リサイズ前UIImage
    UIImage *img_ato;  // リサイズ後UIImage
    CGFloat width = 50;  // リサイズ後幅のサイズ
    CGFloat height = 50;  // リサイズ後高さのサイズ
    
    UIGraphicsBeginImageContext(CGSizeMake(width, height));
    [img_mae drawInRect:CGRectMake(margin, margin, width, height)];
    img_ato = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    _yagiImageView = [[UIImageView alloc] initWithImage:img_ato];
    [self addSubview:_yagiImageView];
    
    //ヤギの名前
    CGRect lblNameRect = CGRectMake(margin, margin + 50, img_ato.size.width, 10);
    _lblYagiName = [[UILabel alloc] initWithFrame:lblNameRect];
    _lblYagiName.text = @"つぶヤギ";
    _lblYagiName.font = [UIFont systemFontOfSize:[UIFont smallSystemFontSize]];
    [self addSubview:_lblYagiName];
    
    //ヤギの発言
    CGRect lblTweetRect = CGRectMake(margin * 2 + img_ato.size.width , margin, self.frame.size.width - (margin * 3 + img_ato.size.width), self.frame.size.height - margin * 2);
    _lblTweet = [[UILabel alloc] initWithFrame:lblTweetRect];
    _lblTweet.text = @"呪文をいいます。";
    for (int i = 0; i < 100; i++) {
        [_lblTweet.text stringByAppendingString:@"粒ヤギ"];
        NSLog(@"string %@", _lblTweet.text);
    }
    [self addSubview:_lblTweet];
    
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
