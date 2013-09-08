//
//  YagiView.m
//  YImage
//
//  Created by Genki Ishibashi on 13/09/07.
//  Copyright (c) 2013年 Genki Ishibashi. All rights reserved.
//

#import "YagiView.h"

@implementation YagiView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        imgFace = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"_kao.png"]];
        imgBody = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"_doutai.png"]];
        imgFrntLeftLeg = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"maeAshi.png"]];
        imgFrntRightLeg = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"maeAshi.png"]];
        imgBackLeftLeg = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"ushiroAsh.png"]];
        imgBackRightLeg = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"usiroashi_03.png"]];
        imgYokoFace = [UIImage imageNamed:@"yoko_03.png"];
        imgMaeFace = [UIImage imageNamed:@"_kao.png"];
        imgGakkariFace = [UIImage imageNamed:@"yagi_hukigen.png"];
        
        imgFace.image = imgYokoFace;
        
        CGRect setRect = CGRectMake(0, 0, 29, 103);
        imgFrntRightLeg.frame = setRect;
        imgFrntLeftLeg.frame = setRect;
        imgBackLeftLeg.frame = setRect;
        imgBackRightLeg.frame = setRect;
        
        imgFace.center = CGPointMake(62, 74);
        imgBody.center = CGPointMake(144, 120);
        imgFrntRightLeg.center = CGPointMake(108, 153);
        imgFrntLeftLeg.center = CGPointMake(130, 157);
        imgBackRightLeg.center = CGPointMake(170, 154);
        imgBackLeftLeg.center = CGPointMake(190, 152);
        
        //最初にどっちに動かすかの設定
        imgFrntRightLeg.tag = 1;
        imgBackRightLeg.tag = 1;
        
        [self addSubview:imgBackRightLeg];
        [self addSubview:imgBody];
        [self addSubview:imgBackLeftLeg];
        [self addSubview:imgFrntRightLeg];
        [self addSubview:imgFrntLeftLeg];
        [self addSubview:imgFace];
        
        [self walk];
    }
    return self;
}
- (void)walk
{
    [self walkRotation:imgFrntRightLeg];
    [self walkRotation:imgFrntLeftLeg];
    [self walkRotation:imgBackLeftLeg];
    [self walkRotation:imgBackRightLeg];
    
}

- (void)stopWalk:(BOOL)hukigen
{
    imgFrntRightLeg.tag = 2;
    imgFrntLeftLeg.tag = 2;
    imgBackLeftLeg.tag = 2;
    imgBackRightLeg.tag = 2;
    
    if (hukigen == YES) {
        imgFace.image = imgGakkariFace;
    }else{
        imgFace.image = imgMaeFace;
    }
}

- (void)walkRestart
{
    imgFrntRightLeg.tag = 0;
    imgFrntLeftLeg.tag = 1;
    imgBackLeftLeg.tag = 0;
    imgBackRightLeg.tag = 1;
    imgFace.image = imgYokoFace;
    [self walk];
    
}

#define rad M_PI/180
- (void)walkRotation:(UIImageView *)imgView
{
    if (imgView.tag == 0) {
        [UIView animateWithDuration:2
                              delay:0.2
                            options:UIViewAnimationOptionCurveEaseInOut
                         animations:^{
                             imgView.transform = CGAffineTransformMakeRotation(10 * rad);
                         }
                         completion:^(BOOL finished){
                             
                             if (imgView.tag == 2) return ;
                             imgView.tag = 1;
                             [self walkRotation:imgView];
                             
                         }];
    }else if(imgView.tag == 1){
        [UIView animateWithDuration:2
                              delay:0.2
                            options:UIViewAnimationOptionCurveEaseInOut
                         animations:^(void){
                             imgView.transform = CGAffineTransformMakeRotation(-10 * rad);
                         }
                         completion:^(BOOL finished){
                             if (imgView.tag == 2) return ;
                             imgView.tag = 0;
                             [self walkRotation:imgView];
                         }];
    }
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
