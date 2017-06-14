//
//  VLCPlayer.h
//  VLCDemo
//
//  Created by pocket on 16/6/27.
//  Copyright © 2016年 pocket. All rights reserved.
//

// VLC播放对象
#import <Foundation/Foundation.h>
#import <MobileVLCKit/MobileVLCKit.h>
#import <UIKit/UIKit.h>

@interface VLCPlayer : NSObject
/**
 *  VCL对象
 */
@property (nonatomic, strong) VLCMediaPlayer *player;
/**
 *  根据路径初始化VCL对象
 *
 *  @param playView 播放承载View
 *  @param path     本地路径
 *
 *  @return VLCPlayer 类
 */
- (id)initWithView:(UIView *)playView andMediaPath:(NSString *)path;
/**
 *  根据URL初始化VCL对象
 *
 *  @param playView 播放承载View
 *  @param url      url路径
 *
 *  @return VLCPlayer 类
 */
- (id)initWithView:(UIView *)playView andMediaURL:(NSURL *)url;

/**
 *  开始播放
 */
- (void)playMedia;
/**
 *  暂停播放
 */
- (void)stopPlaying;
@end
