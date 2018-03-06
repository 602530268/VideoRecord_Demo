//
//  FiltersView.h
//  Doupai_Demo
//
//  Created by chencheng on 2018/2/26.
//  Copyright © 2018年 double chen. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef void(^ControlsCallback)(id obj);

@interface FiltersView : UIView

@property (weak, nonatomic) IBOutlet UIButton *filterBtn;
@property (weak, nonatomic) IBOutlet UIView *filterContainer;
@property (weak, nonatomic) IBOutlet UIView *beautyContainer;

@property(nonatomic,copy) ControlsCallback filterCallback;
@property(nonatomic,copy) ControlsCallback beautyCallback;

@end
