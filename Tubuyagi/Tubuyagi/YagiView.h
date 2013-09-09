//
//  YagiView.h
//  YImage
//
//  Created by Genki Ishibashi on 13/09/07.
//  Copyright (c) 2013年 Genki Ishibashi. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface YagiView : UIView
{
    int kaoFlag;
    int kaisuu;
    UIImageView *imgFace,*imgBody,
                *imgFrntRightLeg, *imgFrntLeftLeg,
                *imgBackRightLeg, *imgBackLeftLeg;
    
    UIImage *imgYokoFace,*imgMaeFace,*imgGakkariFace,
            *imgMgmg, *imgPaku;
    
    NSTimer *timer;
}

- (void)stopWalk:(BOOL)hukigen;
- (void)walkRestart;
- (void)eatFood;
@end

