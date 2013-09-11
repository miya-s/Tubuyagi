//
//  FavoriteCustomVIewCell.m
//  Tubuyagi
//
//  Created by Genki Ishibashi on 13/09/10.
//  Copyright (c) 2013年 Genki Ishibashi. All rights reserved.
//

#import "FavoriteCustomVIewCell.h"
#import "BasicRequest.h"

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

- (void)createObjedt
{
    
}


#define favBtnWidth 80
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
//    _lblYagiName.text = @"つぶヤギ";
    _lblYagiName.font = [UIFont systemFontOfSize:[UIFont smallSystemFontSize]];
    [self addSubview:_lblYagiName];
    
    //ヤギの発言
    //発言のサイズ取得
//    CGSize bounds = CGSizeMake(self.frame.size.width - (margin * 3 + img_ato.size.width), 1000 );
//    UIFont *font = [UIFont systemFontOfSize:[UIFont systemFontSize]];
//    //textLabelのサイズ
//    CGSize lblTweetSize = [_lblTweet.text sizeWithFont:font
//                             constrainedToSize:bounds
//                                 lineBreakMode:NSLineBreakByWordWrapping];
    CGRect lblTweetRect = CGRectMake(margin * 2 + img_ato.size.width , margin, self.frame.size.width - (margin * 3 + img_ato.size.width), self.bounds.size.height );
    _lblTweet = [[UILabel alloc] initWithFrame:lblTweetRect];
//    _lblTweet.backgroundColor = [UIColor blueColor];
    _lblTweet.font = [UIFont fontWithName:@"Helvetica" size:12];
//    _lblTweet.text = @"呪文をいいます。";
    _lblTweet.lineBreakMode = NSLineBreakByTruncatingTail;
    [_lblTweet setNumberOfLines:0];
    _lblTweet.font = _lblTweet.font;
    [self addSubview:_lblTweet];
    
    
    //お気に入り・笑いボタン
    CGRect btnFavRect = CGRectMake(lblTweetRect.origin.x + lblTweetRect.size.width - favBtnWidth, lblTweetRect.origin.y + lblTweetRect.size.height + margin, favBtnWidth, 30);
    btnFavorite = [UIButton buttonWithType:UIButtonTypeRoundedRect];

    btnFavorite.frame = btnFavRect;
    [btnFavorite setTitle:@"お気に入り" forState:UIControlStateNormal];
    [self addSubview:btnFavorite];
    [btnFavorite addTarget:self action:@selector(pushButton:) forControlEvents:UIControlEventTouchUpInside];
    
    
}

- (void)pushButton:(UIButton *)btn
{
    NSLog(@"wara");
    addWaraToOthersTubuyaki(self.lblTweet.text, [NSDate date]);
    
    
    
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
