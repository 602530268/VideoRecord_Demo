//
//  FiltersView.m
//  Doupai_Demo
//
//  Created by chencheng on 2018/2/26.
//  Copyright © 2018年 double chen. All rights reserved.
//

#import "FiltersView.h"

@interface FiltersView ()

@property(nonatomic,strong) NSMutableArray *filterBtns;

@end

@implementation FiltersView

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

- (void)awakeFromNib {
    [super awakeFromNib];
    
    _filterBtns = @[].mutableCopy;
    
    [self createUI];
}

# pragma mark - APIs (private)
- (void)createUI {
    [self createFiltersControls];
}

- (void)createFiltersControls {
    NSArray *arr = @[@"美白",@"磨皮",@"素描"];
    CGFloat originX = 0;
    for (int i = 0; i < arr.count; i++) {
        UIButton *btn = [[UIButton alloc] init];
        [btn setTitle:arr[i] forState:UIControlStateNormal];
        [btn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [self.filterContainer addSubview:btn];
        [btn addTarget:self action:@selector(controlsEvent:) forControlEvents:UIControlEventTouchUpInside];
        
        CGFloat width = 50.0f;
        CGFloat space = 10.0f;
        [btn mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(self.filterContainer).offset(originX + space);
            make.top.bottom.equalTo(self.filterContainer);
            make.width.equalTo(@(width));
        }];
        originX += (width + space);
        
        [_filterBtns addObject:btn];
    }
}

- (void)controlsEvent:(UIButton *)sender {
    for (int i = 0; i < _filterBtns.count; i++) {
        UIButton *btn = _filterBtns[i];
        if (btn == sender) {
            [self filterControlsCallback:i];
            return;
        }
    }
}

- (void)filterControlsCallback:(int)index {

    GPUImageOutput<GPUImageInput> *target = nil;
    if (index == 0) {
        GPUImageBrightnessFilter *brightnessFilter = [[GPUImageBrightnessFilter alloc] init];   //美白滤镜
        brightnessFilter.brightness = 0.3f;
        target = brightnessFilter;
    }else if (index == 1) {
        GPUImageBilateralFilter *bilateralFilter = [[GPUImageBilateralFilter alloc] init];  //磨皮滤镜
        target = bilateralFilter;
    }else if (index == 2) {
        GPUImageSketchFilter *sketchFilter = [[GPUImageSketchFilter alloc] init]; //素描滤镜
        target = sketchFilter;
    }
    
    if (self.filterCallback && target) {
        self.filterCallback(target);
    }
}

- (void)beautyControlsCallback:(int)index {
    
}


@end
