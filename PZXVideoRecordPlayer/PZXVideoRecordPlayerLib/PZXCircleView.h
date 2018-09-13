//
//  PZXCircleView.h
//  PZXVideoRecordPlayer
//
//  Created by xrkj on 2018/9/12.
//  Copyright © 2018年 pengzuxin. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PZXCircleView : UIView

- (instancetype)initWithFrame:(CGRect)frame;
-(void)updateProgressWithValue:(CGFloat)progress;
-(void)resetProgress;

@end
