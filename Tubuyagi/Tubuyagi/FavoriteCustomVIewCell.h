//
//  FavoriteCustomVIewCell.h
//  Tubuyagi
//
//  Created by Genki Ishibashi on 13/09/10.
//  Copyright (c) 2013年 Genki Ishibashi. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FavoriteCustomVIewCell : UITableViewCell
{
    UIButton *btnFavorite;
}


@property (nonatomic, retain) UIImageView *yagiImageView;
@property (nonatomic, retain) UILabel *lblYagiName;
@property (nonatomic, retain) UILabel *lblTweet;

-(void)layoutView;
@end
