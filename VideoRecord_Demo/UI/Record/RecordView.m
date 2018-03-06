//
//  RecordView.m
//  Doupai_Demo
//
//  Created by chencheng on 2018/2/9.
//  Copyright © 2018年 double chen. All rights reserved.
//

#import "RecordView.h"

#define safeCallback(block)\
if (block) {\
block(nil);\
} else {\
\
}

@implementation RecordView
{
    UIView *_progressView;
    NSTimer *_timer;
    CAShapeLayer *_shapeLayer;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

- (void)awakeFromNib {
    [super awakeFromNib];
    
    self.recordBtn.layer.cornerRadius = 40.0f;
    self.recordBtn.layer.borderColor = [UIColor whiteColor].CGColor;
    self.recordBtn.layer.borderWidth = 3.0f;
    
    _progressView = [[UIView alloc] init];
    _progressView.backgroundColor = [UIColor redColor];
    [self addSubview:_progressView];
    _progressView.frame = CGRectMake(0, 0, 0, 0);
    
    _shapeLayer = [CAShapeLayer layer];
    _shapeLayer.strokeColor = [UIColor redColor].CGColor;
    _shapeLayer.fillColor = [UIColor redColor].CGColor;
    [self.layer addSublayer:_shapeLayer];
    
    [self.superview layoutIfNeeded];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        CGFloat width = CGRectGetWidth(self.bounds);
        CGFloat height = CGRectGetHeight(self.bounds) - CGRectGetHeight(self.containerView.bounds);
        _shapeLayer.lineWidth = height;
        UIBezierPath *path = [UIBezierPath bezierPath];
        [path moveToPoint:CGPointMake(0, height/2)];
        [path addLineToPoint:CGPointMake(width, height/2)];
        _shapeLayer.path = path.CGPath;
        
        _shapeLayer.strokeEnd = 0;
    });
    
    _maxRecordTime = 15.0f; //默认15s
}

- (IBAction)btnEvent:(UIButton *)sender {
    
    NSLog(@"%@",sender.titleLabel.text ? sender.titleLabel.text : @"录制");
    
    if (sender == self.closeBtn) {
        safeCallback(self.closeBlock);
    }else if (sender == self.flashBtn) {
        safeCallback(self.flashBlock);
    }else if (sender == self.delayBtn) {
        safeCallback(self.delayBlock);
    }else if (sender == self.cameraBtn) {
        safeCallback(self.cameraBlock);
    }else if (sender == self.photoLibraryBtn) {
        safeCallback(self.photoLibraryBlock);
    }else if (sender == self.seconds15Btn) {
        safeCallback(self.seconds15Block);
    }else if (sender == self.seconds60Btn) {
        safeCallback(self.seconds60Block);
    }else if (sender == self.specialEffectsBtn) {
        safeCallback(self.specialEffectsBlock);
    }else if (sender == self.filterBtn) {
        safeCallback(self.filterBlock);
    }else if (sender == self.recordBtn) {
        safeCallback(self.recordBlock);
    }else if (sender == self.finishBtn) {
        safeCallback(self.finishBlock);
    }else if (sender == self.cancelBtn) {
        safeCallback(self.cancelBlock);
    }
}

- (void)startProgressView {

    [self.containerView bringSubviewToFront:self.timeLbl];
    
    if (_timer) {
        [_timer setFireDate:[NSDate date]];
    }else {
        __block CGFloat time = 0;
        CGFloat animationTime = 0.1f;
        _timer = [NSTimer scheduledTimerWithTimeInterval:animationTime repeats:YES block:^(NSTimer * _Nonnull timer) {
            time += animationTime;
            _shapeLayer.strokeEnd = (time / _maxRecordTime);
            self.timeLbl.text = [NSString stringWithFormat:@"%.1fs",time];
            
            if (time > _maxRecordTime) {
                time = 0;
                [self destoryTimer];
                safeCallback(self.finishBlock);
            }
        }];
    }
}

- (void)pauseProgressView {
    [_timer setFireDate:[NSDate distantFuture]];
}

- (void)cancelProgressView {
    _shapeLayer.strokeEnd = 0;
    [self destoryTimer];
}

- (void)destoryTimer {
    [_timer invalidate];
    _timer = nil;
}



@end
