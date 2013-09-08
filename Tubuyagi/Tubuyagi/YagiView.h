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
    UIImageView *imgFace,*imgBody,
                *imgFrntRightLeg, *imgFrntLeftLeg,
                *imgBackRightLeg, *imgBackLeftLeg;
    
    UIImage *imgYokoFace,*imgMaeFace,*imgGakkariFace;
}

- (void)stopWalk:(BOOL)hukigen;
- (void)walkRestart;
@end
