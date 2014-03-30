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

//指定イニシャライザ
- (id)initTreeInSubView{
    CGRect treeRect = CGRectMake(45, 158, 230, 228);
    self = [super initWithFrame:treeRect];
    if (self) {
        //木画像追加
        _treeBody = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"tree.png"]];
        _treeBody.center = CGPointMake(144, 120);
        [self addSubview:_treeBody];
        
        
        _treeButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _treeButton.frame = treeRect;
        [_treeButton addTarget:self action:@selector(moveToTreeView) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:_treeButton];
        _treeButton.enabled = NO;
    }
    return self;

}

- (void)moveToTreeView{
    
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
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
