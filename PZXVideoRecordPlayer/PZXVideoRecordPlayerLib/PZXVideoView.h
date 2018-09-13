//
//  PZXVideoView.h
//  PZXVideoRecordPlayer
//
//  Created by xrkj on 2018/9/11.
//  Copyright © 2018年 pengzuxin. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PZXVideoModel.h"
@protocol PZXVideoViewDelegate <NSObject>

-(void)dismissVC;
-(void)recordFinishWithvideoUrl:(NSURL *)videoUrl;

@end

@interface PZXVideoView : UIView


@property (nonatomic, weak) id <PZXVideoViewDelegate> delegate;
@property (nonatomic, strong, readonly) PZXVideoModel *pzxmodel;
- (instancetype)initWithFMVideoViewType:(PZXVideoViewType)type;

- (void)reset;


@end
