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


#define favBtnWidth 30
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
    CGRect lblNameRect = CGRectMake(margin, margin + 50, img_ato.size.width+15, 10);
    _lblYagiName = [[UILabel alloc] initWithFrame:lblNameRect];
    _lblYagiName.backgroundColor = [UIColor clearColor];
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
    _lblTweet.backgroundColor = [UIColor clearColor];
    [_lblTweet setNumberOfLines:0];
    _lblTweet.font = _lblTweet.font;
    [self addSubview:_lblTweet];
    
    
    //お気に入り・笑いボタン
    CGRect btnFavRect = CGRectMake(lblTweetRect.origin.x + lblTweetRect.size.width - favBtnWidth - 10, lblTweetRect.origin.y + lblTweetRect.size.height + margin, favBtnWidth, 30);
    self.btnFavorite = [UIButton buttonWithType:UIButtonTypeCustom];

    self.btnFavorite.frame = btnFavRect;
    [self.btnFavorite setImage:[UIImage imageNamed:@"vocant-heart.png"] forState:UIControlStateNormal];
    [self addSubview:self.btnFavorite];
    [self.btnFavorite addTarget:self action:@selector(pushButton:) forControlEvents:UIControlEventTouchUpInside];
    
    //お気に入りの数
    UIImageView *imgHeart = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"total-heart.png"]];
    CGPoint heartPoint = self.btnFavorite.center;
    heartPoint.x -= 180;
    imgHeart.center = heartPoint;
    [self addSubview:imgHeart];
    
    
    _lblFavNumber = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 60, 20)];
    _lblFavNumber.text = @"1";
    _lblFavNumber.backgroundColor =[UIColor clearColor];
    CGPoint lblPoint = imgHeart.center;
    lblPoint.x += 60;
    self.lblFavNumber.center = lblPoint;
    [self addSubview:self.lblFavNumber];
    
    
}

- (void)pushButton:(UIButton *)btn
{
    NSLog(@"wara");

    long long userId = [self.userID longLongValue];
    addWaraToOthersTubuyaki(userId, self.lblTweet.text, [NSDate date]);
    NSLog(@"userID = %lld, text = %@, date = %@", userId, self.lblTweet.text, [NSDate date]);
    
    //お気に入りの数字を増やす
    int i = [_lblFavNumber.text intValue];
    i++;
    _lblFavNumber.text = [NSString stringWithFormat:@"%d", i];

    [self disabledButton:btn];
    
//    btn setTitle:<#(NSString *)#> forState:<#(UIControlState)#>
    
    
}

- (void)disabledButton:(UIButton *)btn
{
    //ボタン無効化
    [self.btnFavorite setImage:[UIImage imageNamed:@"heart.png"] forState:UIControlStateNormal];//setTitle:@"お気に入り済" forState:UIControlStateNormal];
    self.btnFavorite.enabled = NO;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
