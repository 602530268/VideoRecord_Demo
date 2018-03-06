//
//  CCSystemCamera.m
//  CCKit_Demo
//
//  Created by chencheng on 2018/1/22.
//  Copyright © 2018年 double. All rights reserved.
//

#import "CCSystemCamera.h"

@interface CCSystemCamera ()<UINavigationControllerDelegate, UIImagePickerControllerDelegate>
{
    UIViewController *_target;
    void (^_photoCallback)(id obj);
    void (^_cancel)(void);
}

@property(nonatomic,strong) UIImagePickerController *imagePickerController;

@end

@implementation CCSystemCamera

+ (CCSystemCamera *)shareInstance {
    static CCSystemCamera *manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[CCSystemCamera alloc] init];
    });
    return manager;
}

//打开系统相机
- (void)showCameraWith:(UIViewController *)target photo:(void(^)(id obj))photo cancel:(void(^)(void))cancel {
    _target = target;
    _photoCallback = photo;
    _cancel = cancel;
    self.imagePickerController.sourceType = UIImagePickerControllerSourceTypeCamera;
    [_target presentViewController:self.imagePickerController animated:YES completion:nil];
}

//打开系统相册
- (void)showPhotoLibraryWith:(UIViewController *)target photo:(void(^)(id obj))photo cancel:(void(^)(void))cancel {
    _target = target;
    _photoCallback = photo;
    _cancel = cancel;
    
    self.imagePickerController.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    [target presentViewController:self.imagePickerController animated:YES completion:nil];
}

- (void)setMediaTypes:(NSArray *)mediaTypes {
    _mediaTypes = mediaTypes;
    self.imagePickerController.mediaTypes = mediaTypes;
}

#pragma mark UIImagePickerControllerDelegate
//保存图片到相册
- (void)image:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo {
    NSString *msg = nil;
    if (!error) {
        msg = @"图片保存成功";
    }
    else {
        msg = @"图片保存失败";
    }
}

//点击使用按钮
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info{
    
//    UIImage *image = nil;
//    if (picker.sourceType == UIImagePickerControllerSourceTypeCamera) { //相机拍照的照片
//        image = info[@"UIImagePickerControllerOriginalImage"];  //取出image
//        if (self.savePhotoToLibrary) {
//            UIImageWriteToSavedPhotosAlbum(image, self, @selector(image:didFinishSavingWithError:contextInfo:), NULL);  //保存到相册
//        }
//    }
//    else if (picker.sourceType == UIImagePickerControllerSourceTypePhotoLibrary) {  //相册选中的照片
//        image = info[@"UIImagePickerControllerOriginalImage"];
//    }
    if (_photoCallback) {
        _photoCallback(info);
    }
    [_target dismissViewControllerAnimated:YES completion:nil];
}

//点击返回按钮
- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    if (_cancel) {
        _cancel();
    }
    [self.imagePickerController dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Lazy load
- (UIImagePickerController *)imagePickerController {
    
    if (!_imagePickerController) {
        _imagePickerController = [[UIImagePickerController alloc] init];
        _imagePickerController.delegate = self;
        _imagePickerController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
        _imagePickerController.videoQuality = UIImagePickerControllerQualityTypeHigh;
    }
    return _imagePickerController;
}

@end

