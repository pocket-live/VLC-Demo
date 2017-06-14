//
//  VLCPlayerView.m
//  VLCDemo
//
//  Created by pocket on 16/6/28.
//  Copyright © 2016年 pocket. All rights reserved.
//

#import "VLCPlayerView.h"
#import "CustomSlider.h"
#import <MediaPlayer/MediaPlayer.h>

#define ScreenWidth [UIScreen mainScreen].bounds.size.width
#define RGB(r,g,b,a) [UIColor colorWithRed:(r/255.0) green:(g/255.0) blue:(b/255.0) alpha:(a)]
#define titleFontSize 15.0
#define titleColor [UIColor whiteColor]
#define backgroundViewColor RGB(0, 0, 0, 0.6)
#define space 15.0
#define alphaDef 0.5
#define viewHeight 60.0
#define gestureMinimumTranslation 20.0
// 定义滑动手势类型
typedef enum {
    PlayerMoveDirectionNone = 0,
    PlayerMoveDirectionUp,
    PlayerMoveDirectionDown,
    PlayerMoveDirectionRight,
    PlayerMoveDirectionLeft
}PlayerMoveDirection;

@interface VLCPlayerView()
/*********************顶部栏*************************************/
@property (nonatomic,strong) UIView *topView; // 顶部view
@property (nonatomic,strong) UIButton *backBtn; // 返回按钮
@property (nonatomic,strong) UILabel *nameLabel; // 名字

/*********************底部栏*************************************/
@property (nonatomic,strong) UIView *bottomView;// 底部View
// 开始播放(暂停)按钮
@property (nonatomic,strong) UIButton *playBtn;
@property (nonatomic,strong) CustomSlider *sliderView; // 滑动条
// 当前时间标签
@property (nonatomic,strong) UILabel *currentTimeLabel;
// 结束时间标签
@property (nonatomic,strong) UILabel *endTimeLabel;

@property (nonatomic, strong) UIButton *rotateBtn; //!< 旋转按钮

/*********************快进/快退显示********************************/
@property (nonatomic,strong) UIView *baseView;// 快进/快退底View
@property (nonatomic,strong) UIButton *changeBtn;
@property (nonatomic,strong) UILabel *progressTitle;
@property (nonatomic,strong) UIProgressView *progressView;

@property (nonatomic, strong) UIView *lightView; //!< 亮度调节
@property (nonatomic, strong) UIView *volumeView; //!< 音量调节

// 屏幕锁
@property (nonatomic,strong) UIButton *lockBtn;

// sliderView是否正在滑动
@property (nonatomic,assign) BOOL isSliding;

// 滑动手势类型
@property (nonatomic,assign) PlayerMoveDirection moveDirection;
// 开始拖动的位置
@property (nonatomic,assign) CGPoint beginPoint;
// 当前拖动的位置
@property (nonatomic,assign) CGPoint currentPoint;

@property (nonatomic, strong) UISlider *volumeSlider;
@property (nonatomic, assign) float volume;
@end

@implementation VLCPlayerView

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        [self setUI];
        // 添加手势
        [self addGesture];
        
        // 5秒后自动隐藏
//        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//            if (self.topView.alpha>0.0) {
//                [self oneGestureClick];
//            }
//        });
    }
    
    return self;
}

- (void)setUI
{
    // 承载视频view
    self.playView = [[UIView alloc] init];
    self.playView.backgroundColor = [UIColor blackColor];
    [self addSubview:self.playView];
    
    // 顶部View
    self.topView = [[UIView alloc] init];
    self.topView.backgroundColor = backgroundViewColor;
    [self addSubview:self.topView];
    // 名字
    self.nameLabel = [[UILabel alloc] init];
    self.nameLabel.textColor = titleColor;
    self.nameLabel.textAlignment = NSTextAlignmentCenter;
    self.nameLabel.font = [UIFont systemFontOfSize:titleFontSize];
    [self.topView addSubview:self.nameLabel];
    // 返回按钮
    self.backBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.backBtn setImage:[UIImage imageNamed:@"ic_jt_bf"] forState:UIControlStateNormal];
    [self.backBtn addTarget:self action:@selector(backClick) forControlEvents:UIControlEventTouchUpInside];
    [self.topView addSubview:self.backBtn];
    
    // 底部view
    self.bottomView = [[UIView alloc] init];
    self.bottomView.backgroundColor = backgroundViewColor;
    [self addSubview:self.bottomView];
    // 暂停
    self.playBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    self.playBtn.selected = YES;
    [self.playBtn setImage:[UIImage imageNamed:@"ic_bf_zt"] forState:UIControlStateSelected];
    [self.playBtn setImage:[UIImage imageNamed:@"ic_bf_zt"] forState:UIControlStateNormal];
    [self.playBtn setAdjustsImageWhenHighlighted:NO]; // 设置无高亮状态
    [self.playBtn addTarget:self action:@selector(playBtnClick) forControlEvents:UIControlEventTouchUpInside];
    [self.bottomView addSubview:self.playBtn];
    // 当前标签
    self.currentTimeLabel = [[UILabel alloc] init];
    self.currentTimeLabel.textColor = titleColor;
    self.currentTimeLabel.text = @"--:--";
    self.currentTimeLabel.textAlignment = NSTextAlignmentLeft;
    self.currentTimeLabel.font = [UIFont systemFontOfSize:titleFontSize];
    [self.bottomView addSubview:self.currentTimeLabel];
    // 结束标签
    self.endTimeLabel = [[UILabel alloc] init];
    self.endTimeLabel.textColor = titleColor;
    self.endTimeLabel.text = @"--:--";
    self.endTimeLabel.textAlignment = NSTextAlignmentRight;
    self.endTimeLabel.font = [UIFont systemFontOfSize:titleFontSize];
    [self.bottomView addSubview:self.endTimeLabel];
    // 滑动条
    self.sliderView = [[CustomSlider alloc] init];
    self.sliderView.minimumTrackTintColor = RGB(240,113,74,1.0); // 设置滑动过的颜色
    self.sliderView.maximumTrackTintColor = [UIColor grayColor]; // 设置总长度颜色
    self.sliderView.thumbTintColor = RGB(255, 255, 255, 0.7); // 设置滑块颜色
    [self.sliderView addTarget:self action:@selector(slideringListening) forControlEvents:UIControlEventValueChanged];
    [self.sliderView addTarget:self action:@selector(sliderChange) forControlEvents:UIControlEventTouchUpInside];
    [self.bottomView addSubview:self.sliderView];
    
    // 旋转
    self.rotateBtn = [UIButton buttonWithType:UIButtonTypeCustom];
//    [self.rotateBtn setTitle:CustomLocalizedString(@"旋转", nil) forState:UIControlStateNormal];
    [self.rotateBtn setImage:[UIImage imageNamed:@"ic_sp_xz"] forState:UIControlStateNormal];
    self.rotateBtn.titleLabel.textAlignment = NSTextAlignmentCenter;
    [self.rotateBtn addTarget:self action:@selector(rotateClick) forControlEvents:UIControlEventTouchUpInside];
    [self.bottomView addSubview:self.rotateBtn];
    
    // 快进/快退view
    self.baseView = [[UIView alloc] init];
    self.baseView.backgroundColor = backgroundViewColor;
    self.baseView.layer.cornerRadius = 8.0;
    self.baseView.layer.masksToBounds = YES;
    self.baseView.alpha = 0.0;
    [self addSubview:self.baseView];
    
    self.changeBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.changeBtn setImage:[UIImage imageNamed:@"ic_kj_bf"] forState:UIControlStateNormal];
    [self.changeBtn setImage:[UIImage imageNamed:@"ic_kt_bf"] forState:UIControlStateSelected];
    [self.baseView addSubview:self.changeBtn];
    
    self.progressTitle = [[UILabel alloc] init];
    self.progressTitle.textColor = titleColor;
    self.progressTitle.textAlignment = NSTextAlignmentCenter;
    self.progressTitle.font = [UIFont systemFontOfSize:titleFontSize];
//    self.progressTitle.text = @"30秒";
    [self.baseView addSubview:self.progressTitle];
    
    self.progressView = [[UIProgressView alloc] init];
    self.progressView.trackTintColor = [UIColor clearColor];
    self.progressView.progressTintColor = RGB(240,113,74,1.0);
    [self.progressView setProgress:0.0];
    [self.baseView addSubview:self.progressView];
    
    // 亮度、音量
    self.lightView = [UIView new];
    [self addSubview:self.lightView];
    self.volumeView = [UIView new];
    [self addSubview:self.volumeView];
    [self addManagerGesture];
    
    // 屏幕锁
    self.lockBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.lockBtn setImage:[UIImage imageNamed:@"ic_sp_bf"] forState:UIControlStateNormal];
    [self.lockBtn setImage:[UIImage imageNamed:@"ic_ks_bf"] forState:UIControlStateSelected];
    [self.lockBtn addTarget:self action:@selector(lockClick) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:self.lockBtn];
    
    MPVolumeView *v = [MPVolumeView new];
    v.showsRouteButton = NO;
    v.showsVolumeSlider = NO;
    UISlider *s = nil;
    for (id obj in [v subviews]) {
        if ([obj isKindOfClass:[UISlider class]]) {
            s = obj;
            break;
        }
    }
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        NSLog(@"当前音量；%lf",s.value);
        self.volume = s.value;
    });
}

- (void)addManagerGesture
{
    // 拖动
    UIPanGestureRecognizer *lightPan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(lightPanGestureClick:)];
    [self.lightView addGestureRecognizer:lightPan];
    UIPanGestureRecognizer *volumePan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(volumePanGestureClick:)];
    [self.volumeView addGestureRecognizer:volumePan];
}

- (void)lightPanGestureClick:(UIPanGestureRecognizer *)panGesture
{
    CGPoint translation = [panGesture translationInView:self.lightView];
    if (panGesture.state == UIGestureRecognizerStateBegan){
        NSLog (@"滑动开始");
        self.beginPoint = translation;
        self.currentPoint = translation;
    }else if (panGesture.state == UIGestureRecognizerStateChanged){
        self.moveDirection = [self determineCameraDirectionIfNeeded:translation];
        self.currentPoint = translation; // 刷新当前位置
        float change = self.beginPoint.y - self.currentPoint.y;
        NSLog(@"变化：%lf",change);
        switch (self.moveDirection) {
            case PlayerMoveDirectionDown:
            {
                NSLog(@"PlayerMoveDirectionDown");
                float value = [[UIScreen mainScreen] brightness];
                [[UIScreen mainScreen] setBrightness:value + change/(CGRectGetHeight(self.volumeView.frame))];
            }
                break;
            case PlayerMoveDirectionUp:
            {
                NSLog(@"PlayerMoveDirectionUp");
                float value = [[UIScreen mainScreen] brightness];
                [[UIScreen mainScreen] setBrightness:value + change/(CGRectGetHeight(self.volumeView.frame))];
            }
                break;
            case PlayerMoveDirectionRight:
            {
                NSLog(@"PlayerMoveDirectionRight");
                
            }
                break;
            case PlayerMoveDirectionLeft:
            {
                NSLog(@"PlayerMoveDirectionLeft");
                
            }
                break;
            default :
                break;
        }
        float v = [[UIScreen mainScreen] brightness];
        NSLog(@"屏幕亮度:%lf",v);
        
    }else if (panGesture.state == UIGestureRecognizerStateEnded){
        NSLog (@"滑动结束");
    }

}

- (void)volumePanGestureClick:(UIPanGestureRecognizer *)panGesture
{
    CGPoint translation = [panGesture translationInView:self.lightView];
    if (panGesture.state == UIGestureRecognizerStateBegan){
        NSLog (@"滑动开始");
        self.beginPoint = translation;
        self.currentPoint = translation;
    }else if (panGesture.state == UIGestureRecognizerStateChanged){
        self.moveDirection = [self determineCameraDirectionIfNeeded:translation];
        self.currentPoint = translation; // 刷新当前位置
        float change = self.beginPoint.y - self.currentPoint.y;
        NSLog(@"变化：%lf",change);
        switch (self.moveDirection) {
            case PlayerMoveDirectionDown:
            {
                NSLog(@"PlayerMoveDirectionDown");
                MPVolumeView *v = [MPVolumeView new];
                v.showsRouteButton = NO;
                v.showsVolumeSlider = NO;
                [self addSubview:v];
                __weak __typeof(self)weakSelf = self;
                [[v subviews] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                    if ([obj isKindOfClass:[UISlider class]]) {
                        __strong __typeof(weakSelf)strongSelf = weakSelf;
                        strongSelf.volumeSlider = obj;
                        *stop = YES;
                    }
                }];
                self.volume = self.volume + change/(CGRectGetHeight(self.volumeView.frame));
                if (self.volume <= 0.0) {
                    self.volume = 0.0;
                }
                
                [self.volumeSlider setValue:self.volume animated:YES];
            }
                break;
            case PlayerMoveDirectionUp:
            {
                NSLog(@"PlayerMoveDirectionUp");
                MPVolumeView *v = [MPVolumeView new];
                v.transform = CGAffineTransformMakeRotation(M_PI/2); // 旋转90°
                v.showsRouteButton = NO;
                v.showsVolumeSlider = NO;
                [self addSubview:v];
                __weak __typeof(self)weakSelf = self;
                [[v subviews] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                    if ([obj isKindOfClass:[UISlider class]]) {
                        __strong __typeof(weakSelf)strongSelf = weakSelf;
                        strongSelf.volumeSlider = obj;
                        *stop = YES;
                    }
                }];
                
                self.volume = self.volume + change/(CGRectGetHeight(self.volumeView.frame));
                if (self.volume >= 1.0) {
                    self.volume = 1.0;
                }
                [self.volumeSlider setValue:self.volume animated:YES];
            }
                break;
            case PlayerMoveDirectionRight:
            {
                NSLog(@"PlayerMoveDirectionRight");
                
            }
                break;
            case PlayerMoveDirectionLeft:
            {
                NSLog(@"PlayerMoveDirectionLeft");
                
            }
                break;
            default :
                break;
        }

        
    }else if (panGesture.state == UIGestureRecognizerStateEnded){
        NSLog (@"滑动结束");
    }

}

- (void)setVideoName:(NSString *)videoName
{
    _videoName = videoName;
    self.nameLabel.text = videoName;
}

- (void)setCurrentTime:(NSString *)currentTime
{
    _currentTime = currentTime;
    self.currentTimeLabel.text = currentTime;
}

- (void)setRemainingTime:(NSString *)remainingTime
{
    _remainingTime = remainingTime;
    self.endTimeLabel.text = remainingTime;
}


- (void)setSliderValue:(float)sliderValue
{
    _sliderValue = sliderValue;
    if (!self.isSliding) { // 防止滑动过程中的手动设值
        [self .sliderView setValue:sliderValue animated:YES];
    }
}

// 返回按钮监听
- (void)backClick
{
    if (self.backBlock) {
        self.backBlock(); // block返回回调
    }
}

// 播放（暂停）监听
- (void)playBtnClick
{
    NSLog(@"twoGesture");
    self.playBtn.selected = !self.playBtn.selected;
    [self changePlayBtnState:self.playBtn.selected];
    if (self.playBlock) {
        self.playBlock(self.playBtn);
    }
}

- (void)rotateClick
{
    if (self.frame.size.width == ScreenWidth) { // 竖屏
        if (self.rotateBlock) {
            self.rotateBlock(0);
        }
    } else { // 横屏
        if (self.rotateBlock) {
            self.rotateBlock(1);
        }
    }
    
}

// 屏幕锁监听
- (void)lockClick
{
    self.lockBtn.selected = !self.lockBtn.selected;
    if (self.lockBtn.selected) {
        self.playView.userInteractionEnabled = NO;
        [UIView transitionWithView:self.lockBtn duration:1.0 options:0 animations:^{
            self.topView.alpha = 0.0;
            self.bottomView.alpha = 0.0;
            self.lockBtn.alpha = 0.0;
        } completion:^(BOOL finished) {
            
        }];
    } else {
        self.topView.alpha = 1.0;
        self.bottomView.alpha = 1.0;
        self.playView.userInteractionEnabled = YES;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [UIView transitionWithView:self.lockBtn duration:1.0 options:0 animations:^{
                self.topView.alpha = 0.0;
                self.bottomView.alpha = 0.0;
                self.lockBtn.alpha = 0.0;
            } completion:^(BOOL finished) {
                
            }];
        });
    }
}

- (void)changePlayBtnState:(BOOL)select
{
    self.playBtn.selected = select;
    if (select) {
        [self.playBtn setImage:[UIImage imageNamed:@"ic_bf_zt"] forState:UIControlStateNormal];
    } else {
        [self.playBtn setImage:[UIImage imageNamed:@"ic_bf_ks"] forState:UIControlStateNormal];
    }
}

// 滑动结束监听
- (void)sliderChange
{
//    NSLog(@"滑动结束");
    self.isSliding = NO;
    if (self.changeSliderBlock) {
        self.changeSliderBlock(self.sliderView);
    }
}

// 滑动监听
- (void)slideringListening
{
//    NSLog(@"正在滑动");
    if (!self.isSliding) {
        self.isSliding = YES;
    }

}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    CGFloat width = self.frame.size.width;
    CGFloat height = self.frame.size.height;
    
    // 承载视频View
    self.playView.frame = self.bounds;
    
    CGFloat mW = 120;
    CGFloat mH = height - viewHeight - 2*space - viewHeight;
    self.lightView.frame = CGRectMake(0, (height - mH)/2, mW, mH);
    self.volumeView.frame = CGRectMake(width - mW, (height - mH)/2, mW, mH);
    
    // 顶部view
    CGFloat topX = 0;
    CGFloat topY = 0;
    CGFloat topW = width;
    CGFloat topH = viewHeight - 10;
    self.topView.frame = CGRectMake(topX, topY, topW, topH);
    // 返回按钮
//    CGFloat backW = 30.0;
//    CGFloat backH = backW;
//    CGFloat backX = space;
//    CGFloat backY = (topH - backH)/2;
    self.backBtn.frame = CGRectMake(0, 0, topH, topH);
    self.backBtn.contentEdgeInsets = UIEdgeInsetsMake(15/2, space, 15/2, 0);
    // 视频名称
    CGFloat nameX = space + CGRectGetMaxX(self.backBtn.frame);
    CGFloat nameH = 20.0;
    CGFloat nameW = width - 2*nameX;
    CGFloat nameY = (topH - nameH)/2;
    self.nameLabel.frame = CGRectMake(nameX, nameY, nameW, nameH);
    
    
    // 底部view
    CGFloat bottomX = 0;
    CGFloat bottomY = height - viewHeight;
    CGFloat bottomW = width;
    CGFloat bottomH = viewHeight;
    self.bottomView.frame = CGRectMake(bottomX, bottomY, bottomW, bottomH);
    // 播放（暂停）按钮
    CGFloat playW = viewHeight - 5;
    CGFloat playH = viewHeight;
    CGFloat playX = 0;
    CGFloat playY = 0;
    self.playBtn.frame = CGRectMake(playX, playY, playW, playH);
    self.playBtn.contentEdgeInsets = UIEdgeInsetsMake(10, space, 10, 0);
    // 滑动条
    CGFloat sliderX = CGRectGetMaxY(self.playBtn.frame) + 5;
    CGFloat sliderH = 30;
    CGFloat sliderW = width - sliderX - space - 60;
    CGFloat sliderY = 10;
    self.sliderView.frame = CGRectMake(sliderX, sliderY, sliderW, sliderH);
    
    // 旋转
    self.rotateBtn.frame = CGRectMake(CGRectGetMaxX(self.sliderView.frame) + (width - CGRectGetMaxX(self.sliderView.frame) - 45)/2, (bottomH - 45)/2, 45, 45);
    
    // 当前标签
    CGFloat currentX = sliderX;
    CGFloat currentY = CGRectGetMaxY(self.sliderView.frame);
    CGFloat currentH = 20.0;
    CGFloat currentW = sliderW/2;
    self.currentTimeLabel.frame = CGRectMake(currentX, currentY, currentW, currentH);
    // 结束标签
    CGFloat endW = currentW;
    CGFloat endX = CGRectGetMaxX(self.sliderView.frame) - endW;
    CGFloat endY = currentY;
    CGFloat endH = currentH;
    self.endTimeLabel.frame = CGRectMake(endX, endY, endW, endH);
    
    // 快进/快退view
    CGFloat baseW = 140.0;
    CGFloat baseH = 74.0;
    CGFloat baseY = CGRectGetMaxY(self.topView.frame) + 20.0;
    CGFloat baseX = (width - baseW)/2;
    self.baseView.frame = CGRectMake(baseX, baseY, baseW, baseH);
    
    CGFloat changeW = 30.0;
    CGFloat changeH = 20.0;
    CGFloat changeX = (baseW - changeW)/2;
    CGFloat changeY = 8.0;
    self.changeBtn.frame = CGRectMake(changeX, changeY, changeW, changeH);
    
    CGFloat titleY = 8.0 + CGRectGetMaxY(self.changeBtn.frame);
    CGFloat titleX = 0;
    CGFloat titleW = baseW;
    CGFloat titleH = 20.0;
    self.progressTitle.frame = CGRectMake(titleX, titleY, titleW, titleH);
    
    CGFloat progressX = 3.0;
    CGFloat progressY = 8.0 + CGRectGetMaxY(self.progressTitle.frame);
    CGFloat progressW = baseW - 2*progressX;
    CGFloat progressH = 0.0;
    self.progressView.frame = CGRectMake(progressX, progressY, progressW, progressH);
    
    // 屏幕锁
    CGFloat lockX = space;
    CGFloat lockW = 50.0;
    CGFloat lockH = 50.0;
    CGFloat lockY = (height - lockH)/2;
    self.lockBtn.frame = CGRectMake(lockX, lockY, lockW, lockH);
}

#pragma mark - -- 手势操作
- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    NSLog(@"touchesBegan");
    if (self.lockBtn.selected) { // 锁屏状态
        [UIView transitionWithView:self.lockBtn duration:1.0 options:0 animations:^{
            self.lockBtn.alpha = 1.0;
        } completion:^(BOOL finished) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                if (self.lockBtn.selected) {
                    [UIView transitionWithView:self.lockBtn duration:1.0 options:0 animations:^{
                        self.lockBtn.alpha = 0.0;
                    } completion:^(BOOL finished) {
                        
                    }];
                }
            });
        }];
    }
}

// 添加手势处理
- (void)addGesture
{
    // 单点
    UITapGestureRecognizer *oneGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(oneGestureClick)];
    oneGesture.numberOfTapsRequired = 1; // 单击
    oneGesture.numberOfTouchesRequired = 1; // 单指单击
    [self.playView addGestureRecognizer:oneGesture];
    
    // 双击
    UITapGestureRecognizer *twoGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(playBtnClick)];
    twoGesture.numberOfTapsRequired = 2; // 双击
    twoGesture.numberOfTouchesRequired = 1; // 单指双击
    [self.playView addGestureRecognizer:twoGesture];
    
    // 长按
    UILongPressGestureRecognizer *longGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longGestureClick:)];
    longGesture.minimumPressDuration = 3.0; // 长按3秒触发
    [self.playView addGestureRecognizer:longGesture];
    
    // 拖动
    UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panGestureClick:)];
    [self.playView addGestureRecognizer:panGesture];
    
    //解决拖动和长按手势之间的冲突
    [longGesture requireGestureRecognizerToFail:panGesture];
    // 解决单击和双击手势的冲突
    [oneGesture requireGestureRecognizerToFail:twoGesture];
}

// 单击手势监听
- (void)oneGestureClick
{
    NSLog(@"oneGestureClick");
    if (self.topView.alpha<=0.0) { // 显示
        // 动画显示
        [UIView transitionWithView:self.topView duration:1.0 options:0 animations:^{
            self.topView.alpha = 1.0;
            self.bottomView.alpha = 1.0;
            self.lockBtn.alpha = 1.0;
        } completion:^(BOOL finished) {
            // 5秒后自动隐藏
//            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//                if (self.topView.alpha>0.0) {
//                    [self oneGestureClick];
//                }
//            });
        }];
    } else {
        // 动画隐藏
        [UIView transitionWithView:self.topView duration:1.0 options:0 animations:^{
            self.topView.alpha = 0.0;
            self.bottomView.alpha = 0.0;
            self.lockBtn.alpha = 0.0;
        } completion:^(BOOL finished) {
            
        }];
    }
}

// 长按监听
- (void)longGestureClick:(UILongPressGestureRecognizer *)longGesture
{
    // 长按手势会调用多次监听方法，先判断手势状态
    if (longGesture.state == UIGestureRecognizerStateBegan) {
        NSLog(@"长按开始");
    }
}

// 拖动监听
- (void)panGestureClick:(UIPanGestureRecognizer *)panGesture
{
    CGPoint translation = [panGesture translationInView:self.playView]; // 取得相对位置的偏移点（相对位置为手指第一次在屏幕的点）
    NSLog(@"translation:%@",NSStringFromCGPoint(translation));
    if (panGesture.state == UIGestureRecognizerStateBegan){
        NSLog (@"滑动开始");
        self.beginPoint = translation;
        self.currentPoint = translation;
    }else if (panGesture.state == UIGestureRecognizerStateChanged){
        self.moveDirection = [self determineCameraDirectionIfNeeded:translation];
        switch (self.moveDirection) {
            case PlayerMoveDirectionDown:
                NSLog(@"PlayerMoveDirectionDown");
                break;
            case PlayerMoveDirectionUp:
                NSLog(@"PlayerMoveDirectionUp");
                break;
            case PlayerMoveDirectionRight:
            {
                NSLog(@"PlayerMoveDirectionRight");
                self.changeBtn.selected = NO;
                self.progressTitle.text = @"快进10s";
                if (self.baseView.alpha == 0.0) {
                    self.baseView.alpha = 1.0;
                }
            }
                break;
            case PlayerMoveDirectionLeft:
            {
                NSLog(@"PlayerMoveDirectionLeft");
                self.changeBtn.selected = YES;
                self.progressTitle.text = @"快退10s";
                if (self.baseView.alpha == 0.0) {
                    self.baseView.alpha = 1.0;
                }
            }
                break;
            default :
                break;
        }
        self.currentPoint = translation; // 刷新当前位置
        
    }else if (panGesture.state == UIGestureRecognizerStateEnded){
        NSLog (@"滑动结束");
        [UIView transitionWithView:self.baseView duration:1.0 options:0 animations:^{
            self.baseView.alpha = 0.0;
        } completion:^(BOOL finished) {
            
        }];
        if (self.endPanGesture) {
            self.endPanGesture(0.5,self.moveDirection);
        }
    }
}

- (PlayerMoveDirection) determineCameraDirectionIfNeeded:(CGPoint)translation
{
    // 设定一个幅度使拖动在不够水平（略微有点偏差）的方向上的处理，上下一般不处理
    if (translation.x > self.currentPoint.x && (fabs(translation.y - self.currentPoint.y) <= gestureMinimumTranslation)){ // 说明水平向右拖动了
        return PlayerMoveDirectionRight;
    }else if(translation.x < self.currentPoint.x && (fabs(translation.y - self.currentPoint.y) <= gestureMinimumTranslation)){ // 说明水平向左
        return PlayerMoveDirectionLeft;
    }else if (translation.x == self.currentPoint.x && translation.y > self.currentPoint.y) { // 向下
        return PlayerMoveDirectionDown;
    } else if (translation.x == self.currentPoint.x && translation.y < self.currentPoint.y) { // 向上
        return PlayerMoveDirectionUp;
    } else{
        return PlayerMoveDirectionNone;
    }
}

- (void)updateFastImage:(int)type
{
    if (type == 4) { // 左
        
    } else if (type == 3) { // 右
        
    }
}

@end
