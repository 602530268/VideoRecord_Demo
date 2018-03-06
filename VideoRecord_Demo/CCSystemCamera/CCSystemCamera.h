//
//  CCSystemCamera.h
//  CCKit_Demo
//
//  Created by chencheng on 2018/1/22.
//  Copyright © 2018年 double. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <MobileCoreServices/MobileCoreServices.h>   //mediaTypes需要

@interface CCSystemCamera : NSObject

+ (CCSystemCamera *)shareInstance;

@property(nonatomic,assign) BOOL savePhotoToLibrary;    //保存照片到相库
@property(nonatomic,strong) NSArray *mediaTypes;    //媒体资源类型

//打开系统相机
- (void)showCameraWith:(UIViewController *)target photo:(void(^)(id obj))photo cancel:(void(^)(void))cancel;

//打开系统相册
- (void)showPhotoLibraryWith:(UIViewController *)target photo:(void(^)(id obj))photo cancel:(void(^)(void))cancel;


@end


