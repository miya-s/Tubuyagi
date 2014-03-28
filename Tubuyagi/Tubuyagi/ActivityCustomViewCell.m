//
//  FavoriteCustomViewCell.m
//  Tubuyagi
//
//  Created by Genki Ishibashi on 13/09/10.
//  Copyright (c) 2013年 Genki Ishibashi. All rights reserved.
//

#import "ActivityCustomViewCell.h"
#import "TweetsManager.h"

@implementation ActivityCustomViewCell

@synthesize text = _text;
@synthesize seen = _seen;
@synthesize type = _type;
@synthesize date = _date;

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
    CGRect lblTweetRect = CGRectMake(margin * 2 , margin, self.frame.size.width - (margin * 3), self.bounds.size.height );
    _lblActivity = [[UILabel alloc] initWithFrame:lblTweetRect];
    _lblActivity.font = [UIFont fontWithName:@"Helvetica" size:12];
    _lblActivity.lineBreakMode = NSLineBreakByTruncatingTail;
    _lblActivity.backgroundColor = [UIColor clearColor];
    [_lblActivity setNumberOfLines:0];
    [self addSubview:self.lblActivity];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

#pragma mark-setter and getter
- (NSString *)text{
    return _text;
}

- (void)setText:(NSString *)text{
    self.lblActivity.text = text;
    _text = text;
}


@end
