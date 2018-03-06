//
//  CCRecordTool.h
//  Doupai_Demo
//
//  Created by chencheng on 2018/2/27.
//  Copyright © 2018年 double chen. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CCRecordHeader.h"

@interface CCRecordTool : NSObject

+ (CCRecordTool *)shareInstance;

//拼接视频片段
+ (void)videoCompositionWith:(NSArray <NSURL *> *)urls
                   outputUrl:(NSURL *)outputUrl
                     success:(void(^)(NSURL *url))success
                        fail:(void(^)(NSString *error))fail;

//获取指定的视频帧
+ (void)getVideoFrameWith:(NSURL *)fileUrl
                   atTime:(CGFloat)atTime
                    block:(void(^)(UIImage *image))block
                     fail:(void(^)(NSString *error))fail;

//给视频配音
+ (void)dubForVideoWith:(NSURL *)fileUrl
               audioUrl:(NSURL *)audioUrl
              startTime:(CGFloat)startTime
                success:(void(^)(NSURL *url))success
                   fail:(void(^)(NSString *error))fail;

//给视频添加水印
- (void)watermarkForVideoWith:(NSURL *)fileUrl
                    videoRect:(CGRect)videoRect
                watermarkView:(UIView *)watermarkView
         frameProcessingBlock:(void(^)(GPUImageOutput *output, CMTime time))frameProcessingBlock
                      success:(void(^)(NSURL *url))success
                         fail:(void(^)(NSString *error))fail;

//给视频添加滤镜
+ (void)filterForVideoWith:(NSURL *)fileUrl
                   success:(void(^)(NSURL *url))success
                      fail:(void(^)(NSString *error))fail;

@end
