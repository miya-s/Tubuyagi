//
//  YagiView.m
//  YImage
//
//  Created by Genki Ishibashi on 13/09/07.
//  Copyright (c) 2013年 Genki Ishibashi. All rights reserved.
//

#import "YagiView.h"
#import "MarkovTextGenerator.h"

/*
 ViewとControllerが分離できていない
 */

@implementation YagiView{
    int _kaoFlag;
    int _kaisuu;
    BOOL _timerFlag;
    
    // image
    UIImageView *_imgFace, *_imgBody,
    *_imgFrntRightLeg, *_imgFrntLeftLeg,
    *_imgBackRightLeg, *_imgBackLeftLeg,
    *_imgKamikuzu, *_imgTarai;
    
    UIImage *_imgYokoFace,*_imgMaeFace,*_imgGakkariFace,
    *_imgMgmg, *_imgPaku, *_imgKaoTrai;
    
    // timer for movement
    NSTimer *_timer;
    
    //音関連
    SystemSoundID _soundID;
    SystemSoundID _paperSound;
    SystemSoundID _yagiSound;
    SystemSoundID _fail;
    
}

#pragma mark-initializer

- (id)initYagi{
    CGRect yagiRect = CGRectMake(45, 158, 230, 228);
    self = [self initWithFrame:yagiRect];
    if (self) {
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self createImages];
        [self configImages];
        
        //顔のフラグ
        _kaoFlag = 0;
        _kaisuu = 0;
        
        // 効果音準備
        [self prepareSound];
        
        _button = [[UIYagiButton alloc] initWithFrame:frame];
        
        
        //PopTipView準備
        [self preparePopTipView];
        
        [self reset];
    }
    return self;
}

//ヤギを初期状態にもどす
- (void)reset{
    NSLog(@"reset");
    self.lblYagiTweet.frame = CGRectMake(40, 330, 280, 52);
    self.lblYagiTweet.alpha = 0.0;
    self.lblYagiTweet.transform = CGAffineTransformIdentity;
#warning timerFlagという名前はセンスがない
    _timerFlag = YES;
    [self dismissPopTipView];
}

- (void)preparePopTipView{
    CGRect lblRect = CGRectMake(40, 330, 280, 52);
    self.lblYagiTweet = [[UILabel alloc] initWithFrame:lblRect];
    self.lblYagiTweet.text = @"aaaa";
    UIImage *imgPaper = [UIImage imageNamed:@"paper_2.jpg"];
    UIColor *bgColor = [UIColor colorWithPatternImage:imgPaper];
    self.lblYagiTweet.backgroundColor = bgColor;
}

- (void)createImages{
    CGPoint fakePoint = CGPointZero;

    _imgFace = [self yagiImageViewForPart:@"kao"];
    _imgBody = [self yagiImageViewForPart:@"doutai"];
    _imgFrntLeftLeg = [self yagiImageViewForPart:@"maeashi"];
    _imgFrntRightLeg = [self yagiImageViewForPart:@"maeashi2"];
    _imgBackLeftLeg = [self yagiImageViewForPart:@"ushiroashi"];
    _imgBackRightLeg = [self yagiImageViewForPart:@"ushiroashi2"];
    
    _imgTarai = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"tarai.png"]];
    _imgKamikuzu = [[UIImageView alloc] initWithFrame:CGRectMake(fakePoint.x, fakePoint.y, 20, 20)];
    _imgKamikuzu.image = [UIImage imageNamed:@"kamikuzu.png"];
    
    /* 以下のUIImage群は、|_imgFace|の上にのる、ヤギの顔バリエーション */
    _imgYokoFace = [self yagiImageForPart:@"yoko"];
    _imgMaeFace = [self yagiImageForPart:@"kao"];
    _imgGakkariFace = [self yagiImageForPart:@"hukigen"];
    _imgMgmg = [self yagiImageForPart:@"mgmg"];
    _imgPaku = [self yagiImageForPart:@"a"];
    _imgKaoTrai = [self yagiImageForPart:@"tarai"];
}

- (void)configImages{
    CGRect setRect = CGRectMake(0, 0, 29, 113);
    
    _imgFrntRightLeg.frame = setRect;
    _imgFrntLeftLeg.frame = setRect;
    _imgBackRightLeg.frame = setRect;
    _imgBackLeftLeg.frame = setRect;
    
    _imgFace.center = CGPointMake(62, 74);
    _imgBody.center = CGPointMake(144, 120);
    _imgFrntRightLeg.center = CGPointMake(108, 153);
    _imgFrntLeftLeg.center = CGPointMake(130, 157);
    _imgBackRightLeg.center = CGPointMake(170, 154);
    _imgBackLeftLeg.center = CGPointMake(190, 152);
    _imgKamikuzu.center = CGPointMake(200, 150);
    _imgTarai.center = CGPointMake(57.5, -104);
    
    _imgTarai.alpha = 0.0;
    
    //最初にどっちに動かすかの設定
    _imgFrntRightLeg.tag = 1;
    _imgBackRightLeg.tag = 1;
    
    [self addSubview:_imgKamikuzu];
    [self addSubview:_imgBackRightLeg];
    [self addSubview:_imgFrntRightLeg];
    [self addSubview:_imgBody];
    [self addSubview:_imgBackLeftLeg];
    [self addSubview:_imgFrntLeftLeg];
    [self addSubview:_imgFace];
    [self addSubview:_imgTarai];
}

//違うタイプのヤギを作りたいときはこれをオーバーライド
- (UIImageView *)yagiImageViewForPart:(NSString *)part{
    NSString *imageName = [NSString stringWithFormat:@"normal_%@.png", part ];
    return [[UIImageView alloc] initWithImage:[UIImage imageNamed:imageName]];
}

- (UIImage *)yagiImageForPart:(NSString *)part{
    NSString *imageName = [NSString stringWithFormat:@"normal_%@.png", part ];
    return [UIImage imageNamed:imageName];
}

- (void)prepareSound{
    NSString *path = [[NSBundle mainBundle] pathForResource:@"tarai" ofType:@"wav"];
    NSURL *url = [NSURL fileURLWithPath:path];
    AudioServicesCreateSystemSoundID((__bridge CFURLRef)url, &_soundID);
    
    NSString *path2 = [[NSBundle mainBundle] pathForResource:@"paper" ofType:@"wav"];
    NSURL *url2 = [NSURL fileURLWithPath:path2];
    AudioServicesCreateSystemSoundID((__bridge CFURLRef)url2, &_paperSound);
    
    NSString *path3 = [[NSBundle mainBundle] pathForResource:@"yagi" ofType:@"wav"];
    NSURL *url3 = [NSURL fileURLWithPath:path3];
    AudioServicesCreateSystemSoundID((__bridge CFURLRef)url3, &_yagiSound);
}

#pragma mark-behavior
- (void)walk
{
    [self walkRotation:_imgFrntRightLeg];
    [self walkRotation:_imgFrntLeftLeg];
    [self walkRotation:_imgBackLeftLeg];
    [self walkRotation:_imgBackRightLeg];
    
}

- (void)stopWalk:(BOOL)hukigen
{
    _imgFrntRightLeg.tag = 2;
    _imgFrntLeftLeg.tag = 2;
    _imgBackLeftLeg.tag = 2;
    _imgBackRightLeg.tag = 2;
    

    AudioServicesPlaySystemSound(_yagiSound);
    if (hukigen == YES) {
        _imgFace.image = _imgGakkariFace;
    }else{
        _imgFace.image = _imgMaeFace;
    }
}

- (void)walkRestart
{
    _imgFrntRightLeg.tag = 0;
    _imgFrntLeftLeg.tag = 1;
    _imgBackLeftLeg.tag = 0;
    _imgBackRightLeg.tag = 1;
    _imgFace.image = _imgYokoFace;
    [self dismissPopTipView];
    [self walk];
    _timerFlag = YES;
}



#pragma mark - 食べる

#define kutiakeruTime 1
#define mogKurikaesi 7
#define mogKankaku 0.5
- (void)eatTweet:(NSString *)tweet
{
    _imgFace.image = _imgPaku;
    [self performSelector:@selector(mogmog) withObject:nil afterDelay:kutiakeruTime];
    AudioServicesPlaySystemSound(_paperSound);
    
    self.lblYagiTweet.alpha = 1.0;
    [UIView animateWithDuration:1.0f animations:^{
        self.lblYagiTweet.center = CGPointMake(self.center.x - 52, self.center.y -15);
        self.lblYagiTweet.transform = CGAffineTransformMakeScale(0.01, 0.01);
    } completion:^(BOOL finished){
        
        //iOS7だとコールバックできないのでタイマー関数で呼ぶ
        [self performSelector:@selector(reset) withObject:Nil afterDelay:1.0f];
        
    }];
    
    self.lblYagiTweet.text = tweet;
    [self.lblYagiTweet sizeThatFits:self.lblYagiTweet.bounds.size];
}

- (void)mogmog
{
    [_timer invalidate];
    _kaisuu = 0;
    _timer = [NSTimer scheduledTimerWithTimeInterval:mogKankaku
                                             target:self
                                           selector:@selector(repeatMog)
                                           userInfo:nil
                                            repeats:YES];
    
    
             
}

- (void)repeatMog
{
    switch (_kaoFlag) {
        case 0:
            _imgFace.image = _imgMgmg;
            _kaoFlag = 1;
            _kaisuu++;
            break;
            
        case 1:
            
            _imgFace.image = _imgMaeFace;
            _kaoFlag = 0;
            _kaisuu++;
            break;
            
        default:
            break;
    }
    
    if (_kaisuu == mogKurikaesi)
    {
        [_timer invalidate];
        _imgFace.image = _imgYokoFace;
        _kaisuu = 0;
    }
    
}


             
#pragma mark -
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

- (void)dischargeWord
{
//    [UIView setAnimationCurve:UIViewAnimationCurveEaseIn];
    [UIView animateWithDuration:0.5 animations:^(void){
        CGPoint fallPoint = _imgKamikuzu.center;
        fallPoint.y += 40;
        _imgKamikuzu.center = fallPoint;
    } completion:^(BOOL finished){
        [UIView animateWithDuration:2.0
                         animations:^(void){
                             CGPoint movePoint = _imgKamikuzu.center;
                             movePoint.x += 100;
                             _imgKamikuzu.center = movePoint;
                         } completion:^(BOOL finished){
                             _imgKamikuzu.center = CGPointMake(200, 150);
                         }];
    }];
}

- (void)allFoget
{
    _imgTarai.alpha = 1.0;
    [UIView animateWithDuration:0.4 animations:^(void){
        _imgTarai.center = CGPointMake(_imgFace.center.x , _imgFace.center.y - 50);
    } completion:^(BOOL finished){
        [UIView animateWithDuration:0.4 animations:^(void){
            AudioServicesPlaySystemSound(_soundID);
            _imgFace.image = _imgKaoTrai;
            CGPoint endPoint = _imgTarai.center;
            endPoint.x += 60;
            endPoint.y -= 20;
            _imgTarai.center = endPoint;
            _imgTarai.transform = CGAffineTransformMakeRotation(45 * M_PI / 180);
            [UIView animateWithDuration:1.0 animations:^(void){
                _imgTarai.alpha = 0.0;
            }completion:^(BOOL finished){                
                _imgTarai.transform = CGAffineTransformIdentity;
                _imgTarai.center = CGPointMake(57.5, -104);
                _imgFace.image = _imgYokoFace;
            }];
        } completion:^(BOOL finished){

        }];
    }];
}


//ヤギがつぶやく
- (void)tweet{
    //まず吹き出しを消す
    [self dismissPopTipView];
    
    //吹き出し
    MarkovTextGenerator *generator = [MarkovTextGenerator markovTextGeneratorFactory];
    _recentTweet = [generator generateSentence];
    self.popTipView = [[CMPopTipView alloc] initWithMessage:_recentTweet];
    self.popTipView.animation = 0;
    self.popTipView.has3DStyle = 0;
    self.popTipView.backgroundColor = [UIColor whiteColor];
    self.popTipView.textColor = [UIColor blackColor];
    self.popTipView.preferredPointDirection = PointDirectionDown;
    self.popTipView.delegate = self;
    
    //ヤギの動き
    [self stopWalk:NO];
    
    if (_timerFlag == NO) {
        [_timer invalidate];
    }
    
    NSUInteger showTime = self.recentTweet.length / 4.0;
    if (showTime < 3) {
        showTime = 3;
    }
    NSLog(@"time is %uld", showTime);
    _timer = [NSTimer scheduledTimerWithTimeInterval:showTime
                                              target:self
                                            selector:@selector(walkRestart)
                                            userInfo:nil
                                             repeats:NO];
    _timerFlag = NO;
}

#pragma mark - CMPopTipViewDelegate

/*
 投稿用スクリーンショットを撮る
 参考 : http://www.yoheim.net/blog.php?q=20130706
 */
- (void)takeScreenShot{
    // キャプチャ対象をWindowに
    UIWindow *window = [[UIApplication sharedApplication] keyWindow];
    
    // キャプチャ画像を描画する対象を生成
    UIGraphicsBeginImageContextWithOptions(window.bounds.size, NO, 0.0f);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    // Windowの現在の表示内容を１つずつ描画
    for (UIWindow *aWindow in [[UIApplication sharedApplication] windows]) {
        [aWindow.layer renderInContext:context];
    }
    
    // 描画した内容をUIImageとして受け取る
    UIImage *capturedImage = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    self.recentScreenShot = capturedImage;
}

- (void)touchTipPopView
{
    NSString *strShare = [NSString stringWithFormat:@"「%@」のつぶやきを共有しますか？？", self.recentTweet];
    if (!self.recentTweet) {
        strShare = @"つぶやぎをタップして\nしゃべらせよう！";
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"発言の共有"
                                                        message:strShare
                                                       delegate:self
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        alert.tag = 10;
        [alert show];
    }else{
        [self takeScreenShot];
        //共有確認ボタンを出す
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"発言の共有"
                                                        message:strShare
                                                       delegate:self
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:@"キャンセル",nil];
        alert.tag = 10;
        [alert show];
    }
}

- (void)popTipViewWasDismissedByUser:(CMPopTipView *)popTipView
{
    [self touchTipPopView];
}


- (void)dismissPopTipView{
    [self.popTipView dismissAnimated:YES];
    self.popTipView = nil;
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

@implementation UIYagiButton

- (id)initWithFrame:(CGRect)frame{
    
    self = [UIButton buttonWithType:UIButtonTypeCustom];
    if (self) {
        frame.size.height -= 30;
        self.frame = frame;
    }
    return self;
}

@end
