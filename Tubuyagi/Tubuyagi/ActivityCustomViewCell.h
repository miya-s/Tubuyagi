//
//  FavoriteCustomViewCell.h
//  Tubuyagi
//
//  Created by Genki Ishibashi on 13/09/10.
//  Copyright (c) 2013年 Genki Ishibashi. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ActivityCustomViewCell : UITableViewCell
{
    
}

@property (readwrite) NSString *text;
@property (readwrite) BOOL seen;
@property (readwrite) NSInteger type;
@property (readwrite) NSString *date;

@property (nonatomic, retain) UILabel *lblActivity;
- (void)layoutView;

@end
