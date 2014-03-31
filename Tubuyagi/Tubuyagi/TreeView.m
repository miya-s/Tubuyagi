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
- (id)initTreeAsSubView{
    CGRect treeRect = CGRectMake(45, 158, 230, 228);
    self = [super initWithFrame:treeRect];
    if (self) {
        //木画像追加
        _treeBody = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"tree.png"]];
        _treeBody.center = CGPointMake(144, 120);
        [self addSubview:_treeBody];
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
