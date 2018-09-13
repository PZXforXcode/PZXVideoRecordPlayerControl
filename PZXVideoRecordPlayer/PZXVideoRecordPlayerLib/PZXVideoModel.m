//
//  PZXVideoModel.m
//  PZXVideoRecordPlayer
//
//  Created by xrkj on 2018/9/12.
//  Copyright © 2018年 pengzuxin. All rights reserved.
//

#import "PZXVideoModel.h"
#import <AVFoundation/AVFoundation.h>
#import <AssetsLibrary/AssetsLibrary.h>
#define IS_IPHONE_4 (fabs((double)[[UIScreen mainScreen]bounds].size.height - (double)480) < DBL_EPSILON)

@interface PZXVideoModel ()<AVCaptureFileOutputRecordingDelegate>

@property (nonatomic, weak) UIView *superView;

@property (nonatomic, strong) AVCaptureSession *session;
@property (nonatomic, strong) AVCaptureVideoPreviewLayer *previewlayer;
@property (nonatomic, strong) AVCaptureDeviceInput *videoInput;
@property (nonatomic, strong) AVCaptureDeviceInput *audioInput;
@property (nonatomic, strong) AVCaptureMovieFileOutput *FileOutput;

@property (strong,nonatomic)  UIImageView *focusCursor; //聚焦光标

@property (nonatomic, strong, readwrite) NSURL *videoUrl;
@property (nonatomic, strong) NSTimer *timer;
@property (nonatomic, assign) CGFloat recordTime;


@property (nonatomic, assign) PZXFlashState flashState;

@end


@implementation PZXVideoModel

- (instancetype)initWithPZXVideoViewType:(PZXVideoViewType)type superView:(UIView *)superView
{
    self = [super init];
    if (self) {
        _superView = superView;
        [self setUpWithType:type];
    }
    return self;
}


#pragma mark - lazy load
- (AVCaptureSession *)session
{
    // 录制5秒钟视频 高画质10M,压缩成中画质 0.5M
    // 录制5秒钟视频 中画质0.5M,压缩成中画质 0.5M
    // 录制5秒钟视频 低画质0.1M,压缩成中画质 0.1M
    // 只有高分辨率的视频才是全屏的，如果想要自定义长宽比，就需要先录制高分辨率，再剪裁，如果录制低分辨率，剪裁的区域不好控制
    if (!_session) {
        _session = [[AVCaptureSession alloc] init];
        if ([_session canSetSessionPreset:AVCaptureSessionPresetHigh]) {//设置分辨率
            _session.sessionPreset=AVCaptureSessionPresetHigh;
        }
    }
    return _session;
}

- (AVCaptureVideoPreviewLayer *)previewlayer
{
    if (!_previewlayer) {
        _previewlayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:self.session];
        _previewlayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    }
    return _previewlayer;
}

- (void)setRecordState:(PZXRecordState)recordState
{
    if (_recordState != recordState) {
        _recordState = recordState;
        if (self.delegate && [self.delegate respondsToSelector:@selector(updateRecordState:)]) {
            [self.delegate updateRecordState:_recordState];
        }
    }
}

- (UIImageView *)focusCursor
{
    if (!_focusCursor) {
        _focusCursor = [[UIImageView alloc]initWithFrame:CGRectMake(100, 100, 50, 50)];
        _focusCursor.image = [UIImage imageNamed:@"focusImg"];
        _focusCursor.alpha = 0;
    }
    return _focusCursor;
}
#pragma mark - setup
- (void)setUpWithType:(PZXVideoViewType )type
{
    
    //0. 初始化捕捉会话，数据的采集都在会话中处理
    [self setUpInit];
//
    ///1. 设置视频的输入
    [self setUpVideo];
//
    ///2. 设置音频的输入
    [self setUpAudio];
//
    ///3.添加写入文件的fileoutput
    [self setUpFileOut];
//
    ///4. 视频的预览层
    [self setUpPreviewLayerWithType:type];
//
    ///5. 开始采集画面
    [self.session startRunning];
//
//    /// 6. 将采集的数据写入文件（用户点击按钮即可将采集到的数据写入文件）
//
    /// 7. 增加聚焦功能（可有可无）
    [self addFocus];
    
}

#pragma mark - private method
//初始化设置
- (void)setUpInit
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(enterBack) name:UIApplicationDidEnterBackgroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(becomeActive) name:UIApplicationWillEnterForegroundNotification object:nil];
    [self clearFile];
    _recordTime = 0;
    _recordState = PZXRecordStateInit;
    
}
- (void)setUpVideo
{
    // 1.1 获取视频输入设备(摄像头)
    AVCaptureDevice *videoCaptureDevice=[self getCameraDeviceWithPosition:AVCaptureDevicePositionBack];//取得后置摄像头
    
    // 视频 HDR (高动态范围图像)
    // videoCaptureDevice.videoHDREnabled = YES;
    // 设置最大，最小帧速率
    //videoCaptureDevice.activeVideoMinFrameDuration = CMTimeMake(1, 60);
    // 1.2 创建视频输入源
    NSError *error=nil;
    self.videoInput= [[AVCaptureDeviceInput alloc] initWithDevice:videoCaptureDevice error:&error];
    // 1.3 将视频输入源添加到会话
    if ([self.session canAddInput:self.videoInput]) {
        [self.session addInput:self.videoInput];
        
    }
}
- (void)setUpAudio
{
    // 2.1 获取音频输入设备
    AVCaptureDevice *audioCaptureDevice=[[AVCaptureDevice devicesWithMediaType:AVMediaTypeAudio] firstObject];
    NSError *error=nil;
    // 2.2 创建音频输入源
    self.audioInput = [[AVCaptureDeviceInput alloc] initWithDevice:audioCaptureDevice error:&error];
    // 2.3 将音频输入源添加到会话
    if ([self.session canAddInput:self.audioInput]) {
        [self.session addInput:self.audioInput];
    }
}

- (void)setUpFileOut
{
    // 3.1初始化设备输出对象，用于获得输出数据
    self.FileOutput=[[AVCaptureMovieFileOutput alloc]init];
    
    // 3.2设置输出对象的一些属性
    AVCaptureConnection *captureConnection=[self.FileOutput connectionWithMediaType:AVMediaTypeVideo];
    //设置防抖
    //视频防抖 是在 iOS 6 和 iPhone 4S 发布时引入的功能。到了 iPhone 6，增加了更强劲和流畅的防抖模式，被称为影院级的视频防抖动。相关的 API 也有所改动 (目前为止并没有在文档中反映出来，不过可以查看头文件）。防抖并不是在捕获设备上配置的，而是在 AVCaptureConnection 上设置。由于不是所有的设备格式都支持全部的防抖模式，所以在实际应用中应事先确认具体的防抖模式是否支持：
    if ([captureConnection isVideoStabilizationSupported ]) {
        captureConnection.preferredVideoStabilizationMode=AVCaptureVideoStabilizationModeAuto;
    }
    //预览图层和视频方向保持一致
    captureConnection.videoOrientation = [self.previewlayer connection].videoOrientation;
    
    // 3.3将设备输出添加到会话中
    if ([_session canAddOutput:_FileOutput]) {
        [_session addOutput:_FileOutput];
    }
}

- (void)setUpPreviewLayerWithType:(PZXVideoViewType )type
{
    CGRect rect = CGRectZero;
    switch (type) {
        case Type1X1:
            rect = CGRectMake(0, 0, kScreenWidth, kScreenWidth);
            break;
        case Type4X3:
            rect = CGRectMake(0, 0, kScreenWidth, kScreenWidth*4/3);
            break;
        case TypeFullScreen:
            rect = [UIScreen mainScreen].bounds;
            break;
        default:
            rect = [UIScreen mainScreen].bounds;
            break;
    }    self.previewlayer.frame = rect;
    [_superView.layer insertSublayer:self.previewlayer atIndex:0];
}

//存放视频的文件夹
- (NSString *)videoFolder
{
    NSString *cacheDir = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) firstObject];
    NSString *direc = [cacheDir stringByAppendingPathComponent:VIDEO_FOLDER];
    if (![[NSFileManager defaultManager] fileExistsAtPath:direc]) {
        NSFileManager *manager = [NSFileManager defaultManager];
        BOOL isSuccess = [manager createDirectoryAtPath:direc withIntermediateDirectories:YES attributes:nil error:nil];
        NSLog(@"%d",isSuccess);
        
    }
    return direc;
}
//清空文件夹
- (void)clearFile
{
//    [XCFileManager removeItemAtPath:[self videoFolder]];
    [[NSFileManager defaultManager] removeItemAtPath:[self videoFolder] error:nil];
}

//写入的视频路径
- (NSString *)createVideoFilePath
{
    NSString *videoName = [NSString stringWithFormat:@"%@.mp4", [NSUUID UUID].UUIDString];
    NSString *path = [[self videoFolder] stringByAppendingPathComponent:videoName];
    return path;
    
}

- (void)refreshTimeLabel
{
    _recordTime += TIMER_INTERVAL;
    if(self.delegate && [self.delegate respondsToSelector:@selector(updateRecordingProgress:)]) {
        [self.delegate updateRecordingProgress:_recordTime/RECORD_MAX_TIME];
    }
    if (_recordTime >= RECORD_MAX_TIME) {
        [self stopRecord];
    }
}

#pragma mark - 获取摄像头
-(AVCaptureDevice *)getCameraDeviceWithPosition:(AVCaptureDevicePosition )position{
    NSArray *cameras= [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for (AVCaptureDevice *camera in cameras) {
        if ([camera position] == position) {
            return camera;
        }
    }
    return nil;
}

#pragma mark - AVCaptureFileOutputRecordingDelegate
- (void)captureOutput:(AVCaptureFileOutput *)captureOutput didStartRecordingToOutputFileAtURL:(NSURL *)fileURL
      fromConnections:(NSArray *)connections
{
    self.recordState = PZXRecordStateRecording;
    self.timer = [NSTimer scheduledTimerWithTimeInterval:TIMER_INTERVAL target:self selector:@selector(refreshTimeLabel) userInfo:nil repeats:YES];
}

- (void)captureOutput:(AVCaptureFileOutput *)captureOutput didFinishRecordingToOutputFileAtURL:(NSURL *)outputFileURL fromConnections:(NSArray *)connections error:(NSError *)error
{
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:[self.videoUrl path]]) {
        
        self.recordState = PZXRecordStateFinish;

        
    }
    
}

//添加视频聚焦
- (void)addFocus
{
    [self.superView addSubview:self.focusCursor];
    UITapGestureRecognizer *tapGesture= [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(tapScreen:)];
    [self.superView addGestureRecognizer:tapGesture];
}

-(void)tapScreen:(UITapGestureRecognizer *)tapGesture{
    CGPoint point= [tapGesture locationInView:self.superView];
    //将UI坐标转化为摄像头坐标
    CGPoint cameraPoint= [self.previewlayer captureDevicePointOfInterestForPoint:point];
    [self setFocusCursorWithPoint:point];
    [self focusWithMode:AVCaptureFocusModeAutoFocus exposureMode:AVCaptureExposureModeAutoExpose atPoint:cameraPoint];
}
-(void)setFocusCursorWithPoint:(CGPoint)point{
    self.focusCursor.center=point;
    self.focusCursor.transform=CGAffineTransformMakeScale(1.5, 1.5);
    self.focusCursor.alpha=1.0;
    [UIView animateWithDuration:1.0 animations:^{
        self.focusCursor.transform=CGAffineTransformIdentity;
    } completion:^(BOOL finished) {
        self.focusCursor.alpha=0;
        
    }];
}

//设置聚焦点
-(void)focusWithMode:(AVCaptureFocusMode)focusMode exposureMode:(AVCaptureExposureMode)exposureMode atPoint:(CGPoint)point{
    [self changeDeviceProperty:^(AVCaptureDevice *captureDevice) {
        if ([captureDevice isFocusModeSupported:focusMode]) {
            [captureDevice setFocusMode:AVCaptureFocusModeAutoFocus];
        }
        if ([captureDevice isFocusPointOfInterestSupported]) {
            [captureDevice setFocusPointOfInterest:point];
        }
        if ([captureDevice isExposureModeSupported:exposureMode]) {
            [captureDevice setExposureMode:AVCaptureExposureModeAutoExpose];
        }
        if ([captureDevice isExposurePointOfInterestSupported]) {
            [captureDevice setExposurePointOfInterest:point];
        }
    }];
}

-(void)changeDeviceProperty:(void(^)(AVCaptureDevice *captureDevice))propertyChange{
    AVCaptureDevice *captureDevice= [self.videoInput device];
    NSError *error;
    //注意改变设备属性前一定要首先调用lockForConfiguration:调用完之后使用unlockForConfiguration方法解锁
    if ([captureDevice lockForConfiguration:&error]) {
        propertyChange(captureDevice);
        [captureDevice unlockForConfiguration];
    }else{
        NSLog(@"设置设备属性过程发生错误，错误信息：%@",error.localizedDescription);
    }
}

#pragma mark - notification
- (void)enterBack
{
    self.videoUrl = nil;
    [self stopRecord];
}

- (void)becomeActive
{
    [self reset];
}

- (void)dealloc
{
    [self.timer invalidate];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - public method
//切换摄像头
- (void)turnCameraAction
{
    [self.session stopRunning];
    // 1. 获取当前摄像头
    AVCaptureDevicePosition position = self.videoInput.device.position;
    
    //2. 获取当前需要展示的摄像头
    if (position == AVCaptureDevicePositionBack) {
        position = AVCaptureDevicePositionFront;
    } else {
        position = AVCaptureDevicePositionBack;
    }
    
    // 3. 根据当前摄像头创建新的device
    AVCaptureDevice *device = [self getCameraDeviceWithPosition:position];
    
    // 4. 根据新的device创建input
    AVCaptureDeviceInput *newInput = [AVCaptureDeviceInput deviceInputWithDevice:device error:nil];
    
    //5. 在session中切换input
    [self.session beginConfiguration];
    [self.session removeInput:self.videoInput];
    [self.session addInput:newInput];
    [self.session commitConfiguration];
    self.videoInput = newInput;
    
    [self.session startRunning];
    
}


- (void)switchflash
{
    if(_flashState == PZXFlashClose){
        if ([self.videoInput.device hasTorch]) {
            [self.videoInput.device lockForConfiguration:nil];
            [self.videoInput.device setTorchMode:AVCaptureTorchModeOn];
            [self.videoInput.device unlockForConfiguration];
            _flashState = PZXFlashOpen;
        }
    }else if(_flashState == PZXFlashOpen){
        if ([self.videoInput.device hasTorch]) {
            [self.videoInput.device lockForConfiguration:nil];
            [self.videoInput.device setTorchMode:AVCaptureTorchModeAuto];
            [self.videoInput.device unlockForConfiguration];
            _flashState = PZXFlashAuto;
        }
    }else if(_flashState == PZXFlashAuto){
        if ([self.videoInput.device hasTorch]) {
            [self.videoInput.device lockForConfiguration:nil];
            [self.videoInput.device setTorchMode:AVCaptureTorchModeOff];
            [self.videoInput.device unlockForConfiguration];
            _flashState = PZXFlashClose;
        }
    };
    if (self.delegate && [self.delegate respondsToSelector:@selector(updateFlashState:)]) {
        [self.delegate updateFlashState:_flashState];
    }
    
}


- (void)startRecord
{
    [self writeDataTofile];
}

- (void)stopRecord
{
    
    [self.FileOutput stopRecording];
    [self.session stopRunning];
    [self.timer invalidate];
    self.timer = nil;
}

- (void)reset
{
    self.recordState = PZXRecordStateInit;
    _recordTime = 0;
    [self.session startRunning];
}

- (void)writeDataTofile
{
    NSString *videoPath = [self createVideoFilePath];
    self.videoUrl = [NSURL fileURLWithPath:videoPath];
    [self.FileOutput startRecordingToOutputFileURL:self.videoUrl recordingDelegate:self];
    
}
@end
