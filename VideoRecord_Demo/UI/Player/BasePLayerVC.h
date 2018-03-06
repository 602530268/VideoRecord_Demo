//
//  BasePLayerVC.h
//  VideoRecord_Demo
//
//  Created by chencheng on 2018/3/1.
//  Copyright © 2018年 double chen. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface BasePLayerVC : UIViewController

# pragma mark - UI
@property(nonatomic,strong) UIView *containerView;
@property(nonatomic,strong) UIButton *playBtn;
@property(nonatomic,strong) UISlider *slider;
@property(nonatomic,strong) UIButton *backBtn;

@property(nonatomic,copy) void(^playEventBlock)(UIButton *btn); //播放
@property(nonatomic,copy) void(^sliderDragBlock)(CGFloat currentProgress); //滑动

@property(nonatomic,strong) NSURL *fileUrl;


@end
