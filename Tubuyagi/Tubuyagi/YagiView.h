//
//  YagiView.h
//  YImage
//
//  Created by Genki Ishibashi on 13/09/07.
//  Copyright (c) 2013年 Genki Ishibashi. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AudioToolbox/AudioToolbox.h>

@interface YagiView : UIView
{
    int kaoFlag;
    int kaisuu;
    UIImageView *imgFace,*imgBody,
                *imgFrntRightLeg, *imgFrntLeftLeg,
                *imgBackRightLeg, *imgBackLeftLeg,
                *imgKamikuzu, *imgTarai;
    
    UIImage *imgYokoFace,*imgMaeFace,*imgGakkariFace,
            *imgMgmg, *imgPaku, *imgKaoTrai;
    
    NSTimer *timer;
    
    //音関連
    SystemSoundID soudID;
    SystemSoundID paperSound;
    SystemSoundID yagiSound;
    SystemSoundID fail;
}

- (void)stopWalk:(BOOL)hukigen;
- (void)walkRestart;
- (void)eatFood;
- (void)dischargeWord;
- (void)allFoget;
@end

