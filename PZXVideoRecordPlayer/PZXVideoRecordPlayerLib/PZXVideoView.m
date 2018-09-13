//
//  PZXVideoView.m
//  PZXVideoRecordPlayer
//
//  Created by xrkj on 2018/9/11.
//  Copyright © 2018年 pengzuxin. All rights reserved.
//

#import "PZXVideoView.h"

#import "PZXCircleView.h"


@interface PZXVideoView ()<PZXModelDelegate>

@property (nonatomic, strong) UIView *topView;
@property (nonatomic, strong) UIButton *cancelBtn;
@property (nonatomic, strong) UIView *timeView;
@property (nonatomic, strong) UILabel *timelabel;
@property (nonatomic, strong) UIButton *turnCamera;
@property (nonatomic, strong) UIButton *flashBtn;
@property (nonatomic, strong) PZXCircleView *progressView;//写一个原型进度条
@property (nonatomic, strong) UIButton *recordBtn;
@property (nonatomic, assign) CGFloat recordTime;

@property (nonatomic, strong, readwrite) PZXVideoModel *pzxmodel;

@end
@implementation PZXVideoView


-(instancetype)initWithFMVideoViewType:(PZXVideoViewType)type
{
    
    self = [super initWithFrame:[UIScreen mainScreen].bounds];
    if (self) {
        [self BuildUIWithType:type];
    }
    return self;
}

#pragma mark - view
- (void)BuildUIWithType:(PZXVideoViewType )type
{
    
    self.pzxmodel = [[PZXVideoModel alloc]initWithPZXVideoViewType:type superView:self];
    self.pzxmodel.delegate = self;
    
    self.topView = [[UIView alloc] init];
    self.topView.frame = CGRectMake(0, 0, kScreenHeight, 44);
    self.topView.backgroundColor = [UIColor orangeColor];
    [self addSubview:self.topView];
    
    self.timeView = [[UIView alloc] init];
//    self.timeView.hidden = YES;
    self.timeView.frame = CGRectMake(kScreenWidth/2-50, 16, 100, 34);
    self.timeView.backgroundColor = [UIColor clearColor];
    self.timeView.layer.cornerRadius = 4;
    self.timeView.layer.masksToBounds = YES;
    [self addSubview:self.timeView];
    
    
    UIView *redPoint = [[UIView alloc] init];
    redPoint.frame = CGRectMake(0, 0, 6, 6);
    redPoint.layer.cornerRadius = 3;
    redPoint.layer.masksToBounds = YES;
    redPoint.center = CGPointMake(25, 17);
    redPoint.backgroundColor = [UIColor redColor];
    [self.timeView addSubview:redPoint];
    
    self.timelabel =[[UILabel alloc] init];
    self.timelabel.font = [UIFont systemFontOfSize:13];
    self.timelabel.textColor = [UIColor whiteColor];
    self.timelabel.frame = CGRectMake(40, 8, 40, 28);
    [self.timeView addSubview:self.timelabel];
    
    
    self.cancelBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    self.cancelBtn.frame = CGRectMake(15, 14, 16, 16);
    [self.cancelBtn setImage:[UIImage imageNamed:@"cancel"] forState:UIControlStateNormal];
    [self.cancelBtn addTarget:self action:@selector(dismissVC) forControlEvents:UIControlEventTouchUpInside];
    [self.topView addSubview:self.cancelBtn];
    
    
    self.turnCamera = [UIButton buttonWithType:UIButtonTypeCustom];
    self.turnCamera.frame = CGRectMake(kScreenWidth - 60 - 28, 11, 28, 22);
    [self.turnCamera setImage:[UIImage imageNamed:@"listing_camera_lens"] forState:UIControlStateNormal];
    [self.turnCamera addTarget:self action:@selector(turnCameraAction) forControlEvents:UIControlEventTouchUpInside];
    [self.turnCamera sizeToFit];
    [self.topView addSubview:self.turnCamera];
    
    
    self.flashBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    self.flashBtn.frame = CGRectMake(kScreenWidth - 22 - 15, 11, 22, 22);
    [self.flashBtn setImage:[UIImage imageNamed:@"listing_flash_off"] forState:UIControlStateNormal];
    [self.flashBtn addTarget:self action:@selector(flashAction) forControlEvents:UIControlEventTouchUpInside];
    [self.flashBtn sizeToFit];
    [self.topView addSubview:self.flashBtn];
    
    
    self.progressView = [[PZXCircleView alloc] initWithFrame:CGRectMake((kScreenWidth - 62)/2, kScreenHeight - 32 - 62, 62, 62)];
    self.progressView.backgroundColor = [UIColor clearColor];
    [self addSubview:self.progressView];
    
    self.recordBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.recordBtn addTarget:self action:@selector(startRecord) forControlEvents:UIControlEventTouchUpInside];
    self.recordBtn.frame = CGRectMake(5, 5, 52, 52);
    self.recordBtn.backgroundColor = [UIColor redColor];
    self.recordBtn.layer.cornerRadius = 26;
    self.recordBtn.layer.masksToBounds = YES;
    [self.progressView addSubview:self.recordBtn];
    [self.progressView resetProgress];

}


#pragma mark - action

- (void)dismissVC
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(dismissVC)]) {
        
        [self.delegate dismissVC];
    
    }
}

- (void)turnCameraAction
{
    
    NSLog(@"turnCameraAction");
    [self.pzxmodel turnCameraAction];
}

- (void)flashAction
{
    
    NSLog(@"flashAction");

    [self.pzxmodel switchflash];
}

- (void)startRecord
{
    if (self.pzxmodel.recordState == PZXRecordStateInit) {
        [self.pzxmodel startRecord];
    } else if (self.pzxmodel.recordState == PZXRecordStateRecording) {
        [self.pzxmodel stopRecord];
    } else if (self.pzxmodel.recordState == PZXRecordStatePause) {

    }
    NSLog(@"startRecord");

}


- (void)updateRecordingProgress:(CGFloat)progress
{
    [self.progressView updateProgressWithValue:progress];
    self.timelabel.text = [self changeToVideotime:progress * RECORD_MAX_TIME];
    [self.timelabel sizeToFit];

}
- (NSString *)changeToVideotime:(CGFloat)videocurrent {
    
    return [NSString stringWithFormat:@"%02li:%02li",lround(floor(videocurrent/60.f)),lround(floor(videocurrent/1.f))%60];
    
}

#pragma mark - PZXModelDelegate
- (void)updateFlashState:(PZXFlashState)state
{
    if (state == PZXFlashOpen) {
        [self.flashBtn setImage:[UIImage imageNamed:@"listing_flash_on"] forState:UIControlStateNormal];
    }
    if (state == PZXFlashClose) {
        [self.flashBtn setImage:[UIImage imageNamed:@"listing_flash_off"] forState:UIControlStateNormal];
    }
    if (state == PZXFlashAuto) {
        [self.flashBtn setImage:[UIImage imageNamed:@"listing_flash_auto"] forState:UIControlStateNormal];
    }
}


- (void)updateRecordState:(PZXRecordState)recordState
{
    if (recordState == PZXRecordStateInit) {
        [self updateViewWithStop];
        [self.progressView resetProgress];
    } else if (recordState == PZXRecordStateRecording) {
        [self updateViewWithRecording];
    } else if (recordState == PZXRecordStatePause) {
        [self updateViewWithStop];
    } else  if (recordState == PZXRecordStateFinish) {
        [self updateViewWithStop];
        if (self.delegate && [self.delegate respondsToSelector:@selector(recordFinishWithvideoUrl:)]) {
            [self.delegate recordFinishWithvideoUrl:self.pzxmodel.videoUrl];
        }
    }
}

- (void)updateViewWithRecording
{
    self.timeView.hidden = NO;
    self.topView.hidden = YES;
    [self changeToRecordStyle];
}

- (void)updateViewWithStop
{
    self.timeView.hidden = YES;
    self.topView.hidden = NO;
    [self changeToStopStyle];
}

- (void)changeToRecordStyle
{
    [UIView animateWithDuration:0.2 animations:^{
        CGPoint center = self.recordBtn.center;
        CGRect rect = self.recordBtn.frame;
        rect.size = CGSizeMake(28, 28);
        self.recordBtn.frame = rect;
        self.recordBtn.layer.cornerRadius = 4;
        self.recordBtn.center = center;
    }];
}

- (void)changeToStopStyle
{
    [UIView animateWithDuration:0.2 animations:^{
        CGPoint center = self.recordBtn.center;
        CGRect rect = self.recordBtn.frame;
        rect.size = CGSizeMake(52, 52);
        self.recordBtn.frame = rect;
        self.recordBtn.layer.cornerRadius = 26;
        self.recordBtn.center = center;
    }];
}
@end
