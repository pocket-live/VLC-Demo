//
//  VLCViewController.m
//  VLCDemo
//
//  Created by pocket on 16/6/27.
//  Copyright © 2016年 pocket. All rights reserved.
//

#import "VLCViewController.h"
#import <AVFoundation/AVFoundation.h>
#import<MobileVLCKit/MobileVLCKit.h>
#import "VLCPlayerView.h"
#import <CoreTelephony/CTCall.h>

@interface VLCViewController ()<VLCMediaPlayerDelegate>
/**
 *  VLC承载视图
 */
@property (nonatomic,strong) VLCPlayerView *vlcPlayerView;
/**
 *  是否本地路径
 */
@property (nonatomic,assign) BOOL isLocal;
/**
 *  视频总时间（秒）
 */
@property (nonatomic,assign) int videoAllTime;
/**
 *  当前播放时间（秒）
 */
@property (nonatomic,assign) int videoCurrentTime;
/**
 *  当前进度
 */
@property (nonatomic,assign) float currentProgress;
/**
 *  菊花加载
 */
@property (nonatomic,strong) UIActivityIndicatorView *activityView;

@end

@implementation VLCViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = self.playName;
    self.videoAllTime = 0;
    
    [self tarnsformView];
    // 添加播放的承载View
    [self addVLCPalyerView];
    
    // 菊花
    self.activityView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    self.activityView.center = self.vlcPlayerView.center;
    [self.activityView setHidesWhenStopped:YES]; // 旋转时隐藏
    [self.activityView startAnimating]; // 开始旋转
    [self.view addSubview:self.activityView];
    
    
    //视频播放
    if (_playPath) { // 本地
        _player = [[VLCPlayer alloc] initWithView:self.vlcPlayerView.playView andMediaPath:_playPath];
        _player.player.delegate = self;
        [_player playMedia]; // 播放
        self.isLocal = YES;
    }
    if (_playURL) { // 网络
        _player = [[VLCPlayer alloc] initWithView:self.vlcPlayerView.playView andMediaURL:_playURL];
        _player.player.delegate = self;
         NSMutableDictionary *mediaDictionary = [[NSMutableDictionary alloc] init];
        NSString *lastPath = [[_playURL absoluteString] pathExtension];
        if ([lastPath isEqualToString:@"rmvb"]||[lastPath isEqualToString:@"RMVB"]) {
            //设置缓存多少毫秒
            [mediaDictionary setObject:@"700" forKey:@"network-caching"];
        }else {
            //设置缓存多少毫秒
            [mediaDictionary setObject:@"100" forKey:@"network-caching"];
        }
        [_player.player.media addOptions:mediaDictionary];
        [_player playMedia];
        self.isLocal = NO;
    }
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(enterForeground) name:UIApplicationWillEnterForegroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(enterBackground) name:UIApplicationDidEnterBackgroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(callStateNotify:) name:@"kCTCallStateNotification" object:nil];
}

- (void)callStateNotify:(NSNotification*)notify
{
    NSString *callstate = [notify.userInfo objectForKey:@"callstate"];
    if ([callstate isEqualToString:CTCallStateDialing] || [callstate isEqualToString:CTCallStateIncoming]) {
        if (_player.player.isPlaying) {
            [_player.player pause];
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.vlcPlayerView changePlayBtnState:NO];
            });
        }
    }
}

- (void)enterForeground
{
    [_player.player play];
    [self.vlcPlayerView changePlayBtnState:YES];
}

- (void)enterBackground
{
    if (_player.player.isPlaying) {
        [_player.player pause];
    }
}

- (void)dealloc
{
    [_player stopPlaying];
    _player = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

+ (void)initialize
{
    AVAudioSession *session = [AVAudioSession sharedInstance];
    [session setCategory:AVAudioSessionCategoryPlayback error:nil];
    [session setActive:YES error:nil];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [self addObserver];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    
    [self removeObserver];
}

#pragma mark - -- 屏幕旋转控制处理
// 这里采用假旋转，因为其他界面并不需要支持横屏（缺点是状态栏不支持转动，所以采取presentView方式最好）
- (void)tarnsformView
{
    // 旋转view
//    self.view.transform = CGAffineTransformMakeRotation(M_PI/2); // 旋转90°
//    CGRect frame = [UIScreen mainScreen].applicationFrame; // 获取当前屏幕大小
//    // 重新设置所有view的frame
//    self.view.bounds = CGRectMake(0, 0,frame.size.height + 20,frame.size.width);
    self.vlcPlayerView.frame = self.view.bounds;
}
// 隐藏状态栏显得和谐
- (BOOL)prefersStatusBarHidden
{
    return YES;
}

#pragma mark - -- 播放的承载View的设置
- (void)addVLCPalyerView
{
    //承载播放的视图初始化(自定义播放界面可在这里做UI定制)
    self.vlcPlayerView = [[VLCPlayerView alloc] initWithFrame:self.view.bounds];
    // 设置视频名称
    self.vlcPlayerView.videoName = self.playName;
    // 设置播放监听回调
    __weak typeof(self) weakSelf = self;
    self.vlcPlayerView.playBlock = ^(UIButton *playBtn){
        [weakSelf playClick:playBtn];
    };
    // 设置进度条监听回调
    self.vlcPlayerView.changeSliderBlock = ^(UISlider *sliderView){
        [weakSelf changeProgress:sliderView];
    };
    // 设置屏幕锁监听回调
    self.vlcPlayerView.lockBlock = ^(UIButton *lockBtn){
        // 屏幕锁操作逻辑
        // ...后续
    };
    // 设置返回按钮回调
    self.vlcPlayerView.backBlock = ^{
        // 关闭视图控制器
        [weakSelf.player stopPlaying];
        [weakSelf dismissViewControllerAnimated:YES completion:^{
            
        }];
    };
    
    // 左右滑动手势结束回调
    self.vlcPlayerView.endPanGesture = ^(float progress,int type){
        if (type == 4) { // 快退
            [weakSelf.player.player shortJumpBackward];
        } else if (type == 3) { // 快进
            [weakSelf.player.player shortJumpForward];
        }
    };
    
    self.vlcPlayerView.rotateBlock = ^(NSInteger result){
        if (result == 0) { // 竖屏
            // 旋转view
            weakSelf.view.transform = CGAffineTransformMakeRotation(M_PI/2); // 旋转90°
            CGRect frame = [UIScreen mainScreen].applicationFrame; // 获取当前屏幕大小
            // 重新设置所有view的frame
            weakSelf.view.bounds = CGRectMake(0, 0,frame.size.height + 20,frame.size.width);
            weakSelf.vlcPlayerView.frame = weakSelf.view.bounds;
        } else { // 横屏
            // 旋转view
            weakSelf.view.transform = CGAffineTransformMakeRotation(M_PI*2); // 旋转90°
            CGRect frame = [UIScreen mainScreen].applicationFrame; // 获取当前屏幕大小
            // 重新设置所有view的frame
            weakSelf.view.bounds = CGRectMake(0, 0,frame.size.width,frame.size.height);
            weakSelf.vlcPlayerView.frame = weakSelf.view.bounds;
        }
    };
    
    [self.view addSubview:self.vlcPlayerView];
}

#pragma mark - -- vlcPlayerView播放操作
// 播放（暂停）监听
- (void)playClick:(UIButton *)playBtn
{
    if ([_player.player isPlaying]) { // 正在播放
        [_player.player pause]; // 暂停
    } else {
        [_player.player play]; // 播放
    }
}

// 倍率速度播放(一般很少使用)
- (void)fastForwardAtRate:(float)rate
{
    [_player.player fastForwardAtRate:rate];
}
// 进度条拖拽
- (void)changeProgress:(UISlider *)sliderView
{
    if (!_player.player.isPlaying) { // 防止暂停状态拖动（拖动触发播放）
        [self.vlcPlayerView changePlayBtnState:YES];
        [_player.player play];
    }
    // 根据拖动比例计算开始到播放节点的总秒数
    int allSec = (int)(self.videoAllTime * sliderView.value);
    // 根据当前播放秒数计算需要seek的秒数
    int sec = abs(allSec - self.videoCurrentTime);
    // 如果为获取到时间信息
    if (sec == 0 && allSec == 0) {
        UIAlertView *al = [[UIAlertView alloc] initWithTitle:@"未获取到视频总时间，请尝试手势快进" message:nil delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil];
        [al show];
        return;
    }
    NSLog(@"sec:%d",sec);
    if (sec==0) { // 刚好等于视频总时间
        [_player.player stop];
        return;
    }
    if (self.currentProgress<=sliderView.value) { // 快进滑动
        [_player.player jumpForward:sec]; // 快进播放
    } else {
        [_player.player jumpBackward:sec]; // 快退播放
    }
    
//    if (sliderView.value >= 1.0) {
//        [_player.player stop];
//        return;
//    }
//    [_player.player setPosition:sliderView.value];
}

#pragma  mark - -- vlcPlayerView时间和进度刷新
- (void)updateTime
{
    // 设置剩余时间
    self.vlcPlayerView.remainingTime = [[_player.player remainingTime] stringValue];
    // 设置当前时间
    self.vlcPlayerView.currentTime = [[_player.player time] stringValue];
    // 设置当前进度
    self.vlcPlayerView.sliderValue = [_player.player position];
}

#pragma mark - -- KVO监听
// 添加监听
- (void)addObserver
{
    // 监听VLC对象属性（时间和播放）
    [_player.player addObserver:self forKeyPath:@"remainingTime" options:0 context:nil];
    [_player.player addObserver:self forKeyPath:@"isPlaying" options:0 context:nil];
}

// 移除监听
- (void)removeObserver
{
    [_player.player removeObserver:self forKeyPath:@"remainingTime"];
    [_player.player removeObserver:self forKeyPath:@"isPlaying"];
}

// kvo监听回调
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context {
    
    // 可以在这里设置显示的时间和进度
    // 记录当前进度
    self.currentProgress = [_player.player position];
    // 根据分钟计算播放的秒数（这里不够严格，还得加上秒数）
    self.videoCurrentTime = [[[_player.player time] minuteStringValue] intValue] * 60;
    // 根据剩余时间和已经播放的计算总秒数（这里不够严格，还得加上秒数）
    self.videoAllTime = [[[_player.player remainingTime] minuteStringValue] intValue]*60 + self.videoCurrentTime;
    
    // 有时候获取不到时间（个人想法是结合定时器和进度比例计算总时间等）
    // ...
    
    // 刷新最新时间和播放进度
    [self updateTime];
    // 停止菊花加载
    if (self.activityView.isAnimating) {
        [self.activityView stopAnimating];
    }
}


#pragma mark - 监听程序进入前台和后台

#pragma mark - VLCMediaPlayerDelegate
// 播放状态改变的回调
- (void)mediaPlayerStateChanged:(NSNotification *)aNotification
{
    /**
     *  VLCMediaPlayerStateStopped,        //< Player has stopped
     VLCMediaPlayerStateOpening,        //< Stream is opening
     VLCMediaPlayerStateBuffering,      //< Stream is buffering
     VLCMediaPlayerStateEnded,          //< Stream has ended
     VLCMediaPlayerStateError,          //< Player has generated an error
     VLCMediaPlayerStatePlaying,        //< Stream is playing
     VLCMediaPlayerStatePaused          //< Stream is paused
     */
    NSLog(@"mediaPlayerStateChanged");
    NSLog(@"状态：%ld",(long)_player.player.state);
    switch ((int)_player.player.state) {
        case VLCMediaPlayerStateStopped: // 停止播放（播放完毕或手动stop）
        {
            [_player.player stop]; // 手动调用一次停止(一遍再次点击播放)
            [self.vlcPlayerView changePlayBtnState:NO];
            if (self.activityView.isAnimating) {
                [self.activityView stopAnimating];
            }
        }
            break;
        case VLCMediaPlayerStateBuffering: // 播放中缓冲状态
        {
            // 显示菊花
            if (!self.activityView.isAnimating) {
                self.activityView.center = self.vlcPlayerView.center;
                [self.activityView startAnimating];
            }
        }
            break;
        case VLCMediaPlayerStatePlaying: // 被暂停后开始播放
        {
            if (self.activityView.isAnimating) {
                [self.activityView stopAnimating];
            }
        }
            break;
        case VLCMediaPlayerStatePaused:  // 播放后被暂停
        {
            if (self.activityView.isAnimating) {
                [self.activityView stopAnimating];
            }
        }
            break;
            
    }
}
// 播放时间改变的回调
- (void)mediaPlayerTimeChanged:(NSNotification *)aNotification
{
//    NSLog(@"mediaPlayerTimeChanged");
}

@end
