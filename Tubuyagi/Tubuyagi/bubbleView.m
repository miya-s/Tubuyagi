//
//  bubbleView.m
//  BubbleDraw
//
//  Created by 三宅 亮 on 12/08/04.
//  Copyright (c) 2012年 三宅 亮. All rights reserved.
//

#import "bubbleView.h"
#import "TextAnalyzer.h"

@implementation bubbleView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor colorWithRed:1 green:1 blue:0.980 alpha:1];

    }
    self.strTweet = [[UILabel alloc] initWithFrame:CGRectMake(60, 100, 280, 500)];
    //フォント
    UIFont *font = [UIFont fontWithName:@"Helvetica-Bold"size:18];
    self.strTweet.font = font;
    self.strTweet.text = @"タップしてね";
    return self;
}

#define textMarginX 18
#define textMarginY 6
- (void)drawRect:(CGRect)rect
{
    //フォント
    UIFont *font = [UIFont fontWithName:@"Helvetica-Bold"size:18];
    
    //全体のsize取得
    CGSize size = [self.strTweet.text sizeWithFont:font constrainedToSize:self.bounds.size lineBreakMode:NSLineBreakByWordWrapping];
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    //---------
    // フキダシ

    //状態保存
    CGContextSaveGState(context);
    
    //Path作成
//    CGRect bubbleRect = CGRectMake(0, //60.5, 40.5, 170, 70);

    CGRect bubbleRect = CGRectMake(self.bounds.origin.x , self.bounds.origin.y , size.width, size.height );
    CGContextBubblePath(context, bubbleRect);
    CGPathRef bubblePath = CGContextCopyPath(context);
    
    //影
    CGContextSetShadow(context,CGSizeMake(0,1), 3);
    CGContextSetRGBFillColor(context, 1, 1, 1, 1);
    CGContextFillPath(context);
    CGContextSetShadow(context,CGSizeZero,0);
    
    //背景
    CGContextAddPath(context, bubblePath);
    CGContextClip(context);
    CGFloat locations[] = {0.0, 0.2, 0.8, 1.0};
    CGFloat components[] = {
        0.506,0.722,0.990,1.0,
        0.652,0.849,0.996,1.0,
        0.652,0.849,0.996,1.0,
        0.803,0.945,1.000,1.0
    };
    size_t count = sizeof(components) / (sizeof(CGFloat)*4);
    CGPoint startPoint = bubbleRect.origin;
    CGPoint endPoint = startPoint;
    endPoint.y += bubbleRect.size.height;
    CGColorSpaceRef space = CGColorSpaceCreateDeviceRGB();
    CGGradientRef gradient = CGGradientCreateWithColorComponents(space, components, locations, count);
    CGContextDrawLinearGradient(context, gradient, startPoint, endPoint, kCGGradientDrawsBeforeStartLocation);
    CGColorSpaceRelease(space);
    CGGradientRelease(gradient);
    
    //縁取り
    CGContextAddPath(context, bubblePath);
    CGContextSetRGBStrokeColor(context, 0, 0, 0, 0.3);
    CGContextSetLineWidth(context, 1);
    CGContextStrokePath(context);

    //Path解放
    CGPathRelease(bubblePath);
    
    //保存してた状態に戻す
    CGContextRestoreGState(context);
    
    
    //---------
    // 何か書く
    
    CGRect textRect = CGRectMake(self.bounds.origin.x + textMarginX, self.bounds.origin.y + textMarginY, bubbleRect.size.width , bubbleRect.size.height);//75, 45, 150, 60);
    NSString *text = self.strTweet.text;//@"こんにちは。\n吹き出し描いたよ。\nくちばし部分の構造は下の絵を見てね。";
    learnFromText(text);
    NSLog(@"%@",generateSentence());
    
    [[UIColor colorWithWhite:0.1 alpha:1] set];
    [text drawInRect:textRect withFont:[UIFont systemFontOfSize:12]];
//    [self sizeToFit];
    
    //---------
    // 顔Icon
    
    //状態保存
    CGContextSaveGState(context);
    
    //Path作成
    CGRect profRect = CGRectMake(15, 80, 40, 40);
    CGContextRoundRectPath(context, profRect, 4.0);
    CGPathRef profPath = CGContextCopyPath(context);
    
    //画像描画
//    CGContextClip(context);
//    UIImage *profImage = [UIImage imageNamed:@"profile.png"];
//    [profImage drawInRect:profRect];
    
    //縁取り
//    CGContextAddPath(context, profPath);
//    CGContextSetRGBStrokeColor(context, 0, 0, 0, 0.3);
//    CGContextSetLineWidth(context, 1);
//    CGContextStrokePath(context);
    
    //Path解放
    CGPathRelease(profPath);
    
    //保存してた状態に戻す
    CGContextRestoreGState(context);
    
    
    
    
    //---------
    // くちばしの構造
    
    CGRect bubbleRect2 = CGRectMake(50, 150, 600, 290);
    CGContextBubblePathWithScale(context, bubbleRect2, 8);
    CGContextSetRGBStrokeColor(context, 0, 0, 0, 1);
    CGContextSetLineWidth(context, 2);
    CGContextStrokePath(context);
    
    CGContextDrawAdditionalLine(context, bubbleRect2, 8);
}

//角度→ラジアン変換
#if !defined(RADIANS)
#define RADIANS(D) (D * M_PI / 180)
#endif

//吹き出しを描く
void CGContextBubblePath(CGContextRef context, CGRect rect)
{
    CGFloat rad = 10;  //角の半径
    CGFloat qx = 10; // くちばしの長さ
    CGFloat qy = 20; // くちばしの高さ
    CGFloat cqy = 4; // 上くちばしカーブの基準点の高さ
    CGFloat lx = CGRectGetMinX(rect)+qx; //左
    CGFloat rx = CGRectGetMaxX(rect); //右
    CGFloat ty = CGRectGetMinY(rect); //上
    CGFloat by = CGRectGetMaxY(rect); //下
    
    CGContextBeginPath(context);
    
    CGContextMoveToPoint(context, lx, ty+rad); //左上
    CGContextAddArc(context, lx+rad, ty+rad, rad, RADIANS(180), RADIANS(270), 0); //左上のカーブ
    CGContextAddArc(context, rx-rad, ty+rad, rad, RADIANS(270), RADIANS(360), 0); //右上のカーブ
    CGContextAddArc(context, rx-rad, by-rad, rad, RADIANS(0), RADIANS(90), 0); //右下のカーブ
    CGContextAddArc(context, lx+rad, by-rad, rad, RADIANS(90), RADIANS(125), 0); //くちばしの付け根(下の凹み)
    CGContextAddQuadCurveToPoint(context, lx, by, lx-qx, by); //くちばしの先端
    CGContextAddQuadCurveToPoint(context, lx, by-cqy, lx, by-qy); //くちばしの付け根(上)
    
    CGContextClosePath(context); //左上の点まで閉じる
}

//角丸の図形を描く
void CGContextRoundRectPath(CGContextRef context, CGRect rect, CGFloat radius)
{
    CGFloat lx = CGRectGetMinX(rect);
    CGFloat rx = CGRectGetMaxX(rect);
    CGFloat ty = CGRectGetMinY(rect);
    CGFloat by = CGRectGetMaxY(rect);
    
    CGContextBeginPath(context);
    
    CGContextMoveToPoint(context, lx+radius, by);
    CGContextAddArcToPoint(context, lx, by, lx, by-radius, radius);
    CGContextAddArcToPoint(context, lx, ty, lx+radius, ty, radius);
    CGContextAddArcToPoint(context, rx, ty, rx, ty+radius, radius);
    CGContextAddArcToPoint(context, rx, by, rx-radius, by, radius);
    
    CGContextClosePath(context);
}




void CGContextBubblePathWithScale(CGContextRef context, CGRect rect, CGFloat scale)
{
    CGFloat rad = 10*scale;  //角の半径
    CGFloat qx = 10*scale; // くちばしの長さ
    CGFloat qy = 20*scale; // くちばしの高さ
    CGFloat cqy = 4*scale; // 上くちばしカーブの基準点の高さ
    CGFloat lx = CGRectGetMinX(rect)+qx; //左
    CGFloat rx = CGRectGetMaxX(rect); //右
    CGFloat ty = CGRectGetMinY(rect); //上
    CGFloat by = CGRectGetMaxY(rect); //下
    
    CGContextBeginPath(context);
    
    CGContextMoveToPoint(context, lx, ty+rad); //左上
    CGContextAddArc(context, lx+rad, ty+rad, rad, RADIANS(180), RADIANS(270), 0); //左上のカーブ
    CGContextAddArc(context, rx-rad, ty+rad, rad, RADIANS(270), RADIANS(360), 0); //右上のカーブ
    CGContextAddArc(context, rx-rad, by-rad, rad, RADIANS(0), RADIANS(90), 0); //右下のカーブ
    CGContextAddArc(context, lx+rad, by-rad, rad, RADIANS(90), RADIANS(125), 0); //くちばしの付け根(下の凹み)
    CGContextAddQuadCurveToPoint(context, lx, by, lx-qx, by); //くちばしの先端
    CGContextAddQuadCurveToPoint(context, lx, by-cqy, lx, by-qy); //くちばしの付け根(上)
    
    CGContextClosePath(context); //左上の点まで閉じる
}

void CGContextDrawAdditionalLine(CGContextRef context, CGRect rect, CGFloat scale)
{
    CGFloat rad = 10*scale;  //角の半径
    CGFloat qx = 10*scale; // くちばしの長さ
    CGFloat qy = 20*scale; // くちばしの高さ
    //CGFloat cqy = 4*scale; // 上くちばしカーブの基準点の高さ
    CGFloat lx = CGRectGetMinX(rect)+qx; //左
    CGFloat rx = CGRectGetMaxX(rect); //右
    CGFloat ty = CGRectGetMinY(rect); //上
    CGFloat by = CGRectGetMaxY(rect); //下
    
    CGContextSetRGBStrokeColor(context, 0, 1, 0, 0.7);
    CGContextSetLineWidth(context, 1.5);
    
    CGContextBeginPath(context);
    
    CGContextMoveToPoint(context, lx, ty+rad);
    CGContextAddArc(context, lx+rad, ty+rad, rad, RADIANS(180), RADIANS(-180), 0);
    CGContextStrokePath(context);
    
    CGContextMoveToPoint(context, rx, ty+rad);
    CGContextAddArc(context, rx-rad, ty+rad, rad, RADIANS(0), RADIANS(360), 0);
    CGContextStrokePath(context);
    
    CGContextMoveToPoint(context, rx, by-rad);
    CGContextAddArc(context, rx-rad, by-rad, rad, RADIANS(0), RADIANS(360), 0);
    CGContextStrokePath(context);
    
    CGContextMoveToPoint(context, lx, by-rad);
    CGContextAddArc(context, lx+rad, by-rad, rad, RADIANS(180), RADIANS(-180), 0);
    CGContextStrokePath(context);
    
    CGContextSetRGBStrokeColor(context, 1, 0, 0, 0.7);
    CGContextMoveToPoint(context, lx+4.3*scale, by-1.8*scale);
    //CGContextAddLineToPoint(context, lx, by);
    CGContextAddLineToPoint(context, lx-qx, by);
    CGContextStrokePath(context);
    
    CGContextSetRGBStrokeColor(context, 0, 0, 1, 0.0);
    CGContextMoveToPoint(context, lx-qx, by);
    //CGContextAddLineToPoint(context, lx, by-cqy);
    CGContextAddLineToPoint(context, lx, by-qy);
    CGContextStrokePath(context);
}

@end
