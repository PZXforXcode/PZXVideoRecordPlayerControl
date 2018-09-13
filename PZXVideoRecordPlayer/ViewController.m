//
//  ViewController.m
//  PZXVideoRecordPlayer
//
//  Created by xrkj on 2018/9/11.
//  Copyright © 2018年 pengzuxin. All rights reserved.
//

#import "ViewController.h"
#import "PZXVideoView.h"
#import "PZXPlayerViewController.h"
@interface ViewController ()<PZXVideoViewDelegate>
@property (nonatomic, strong) PZXVideoView *videoView;

@end

@implementation ViewController

- (BOOL)prefersStatusBarHidden{
    return YES;
}
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    self.navigationController.navigationBar.hidden = YES;
    
    _videoView = [[PZXVideoView alloc] initWithFMVideoViewType:TypeFullScreen];
    _videoView.delegate = self;
    [self.view addSubview:_videoView];
    
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - FMFVideoViewDelegate
- (void)dismissVC
{
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

- (void)recordFinishWithvideoUrl:(NSURL *)videoUrl
{
    
    
    PZXPlayerViewController *playVC = [[PZXPlayerViewController alloc] init];
    playVC.videoUrl =  videoUrl;
    [self.navigationController pushViewController:playVC animated:YES];
}
@end
