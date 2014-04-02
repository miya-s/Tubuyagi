//
//  TreeView.m
//
//  Created by Genki Ishibashi on 13/09/07.
//  Copyright (c) 2013年 Genki Ishibashi. All rights reserved.
//

#import "TreeView.h"

@implementation TreeView
{
    UIImageView *_treeBody;
}

- (id)initTreeAsSubView{
    CGRect treeRect = CGRectMake(180, 100, 130, 200);
    self = [self initWithFrame:treeRect];
    if (self) {
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        //木画像追加
        _treeBody = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"tree.png"]];
        _treeBody.frame = CGRectMake(0, 0, 130, 200);
        [self addSubview:_treeBody];
        
        // !!!:ButtonはTreeと独立して存在するで、絶対座標指定が必要
        //ボタン追加
        _button = [UIButton buttonWithType:UIButtonTypeCustom];
        _button.frame = frame;
    }
    return self;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
