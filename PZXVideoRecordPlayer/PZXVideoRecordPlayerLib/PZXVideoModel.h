//
//  PZXVideoModel.h
//  PZXVideoRecordPlayer
//
//  Created by xrkj on 2018/9/12.
//  Copyright © 2018年 pengzuxin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>



//录制视频的长宽比必须要
typedef NS_ENUM(NSInteger, PZXVideoViewType) {
    Type1X1 = 0,
    Type4X3,
    TypeFullScreen
};
//闪光灯状态
typedef NS_ENUM(NSInteger, PZXFlashState) {
    PZXFlashClose = 0,
    PZXFlashOpen,
    PZXFlashAuto,
};

//录制状态
typedef NS_ENUM(NSInteger, PZXRecordState) {
    
    PZXRecordStateInit = 0,
    PZXRecordStateRecording,
    PZXRecordStatePause,
    PZXRecordStateFinish,
};

@protocol PZXModelDelegate <NSObject>

- (void)updateFlashState:(PZXFlashState)state;
- (void)updateRecordingProgress:( CGFloat )progress;
- (void)updateRecordState:(PZXRecordState)recordState;

@end

@interface PZXVideoModel : NSObject

@property (nonatomic, weak  ) id<PZXModelDelegate>delegate;
@property (nonatomic, assign) PZXRecordState recordState;
@property (nonatomic, strong, readonly) NSURL *videoUrl;

- (instancetype)initWithPZXVideoViewType:(PZXVideoViewType )type superView:(UIView *)superView;
- (void)turnCameraAction;
- (void)switchflash;
- (void)startRecord;
- (void)stopRecord;
- (void)reset;

@end
