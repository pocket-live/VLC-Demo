//
//  VLCPlayerView.h
//  VLCDemo
//
//  Created by pocket on 16/6/28.
//  Copyright © 2016年 pocket. All rights reserved.
//

// VLC播放界面
#import <UIKit/UIKit.h>

@interface VLCPlayerView : UIView
/**
 *  承载视频的View
 */
@property (nonatomic,strong) UIView *playView;
/**
 *  视频名称
 */
@property (nonatomic,copy) NSString *videoName;
/**
 *  剩余时间
 */
@property (nonatomic,copy) NSString *remainingTime;
/**
 *  当前时间
 */
@property (nonatomic,copy) NSString *currentTime;
/**
 *  当前进度
 */
@property (nonatomic,assign) float sliderValue;
/**
 *  返回按钮监听回调
 */
@property (nonatomic,copy) void (^backBlock)(void);
/**
 *  屏幕锁监听回调
 */
@property (nonatomic,copy) void (^lockBlock)(UIButton *lockBtn);
/**
 *  播放（暂停）监听回调
 */
@property (nonatomic,copy) void (^playBlock)(UIButton *playBtn);
/**
 *  进度条监听回调
 */
@property (nonatomic,copy) void (^changeSliderBlock)(UISlider *sliderView);
/**
 *  拖动结束监听(progress：幅度,type: 3:右 ，4：左)
 */
@property (nonatomic,copy) void (^endPanGesture)(float progress,int type);
/**
 *  变更播放（暂停）按钮状态
 */
- (void)changePlayBtnState:(BOOL)select;

@property (nonatomic, copy) void (^rotateBlock)(NSInteger result);
@end
