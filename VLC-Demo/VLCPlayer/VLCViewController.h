//
//  VLCViewController.h
//  VLCDemo
//
//  Created by pocket on 16/6/27.
//  Copyright © 2016年 pocket. All rights reserved.
//

// VLC播放控制器
#import <UIKit/UIKit.h>
#import "VLCPlayer.h"

@interface VLCViewController : UIViewController
/**
 *  文件名字
 */
@property (nonatomic, strong) NSString *playName;
/**
 *  文件路径（本地资源路径）
 */
@property (nonatomic, strong) NSString *playPath;
/**
 *  网络URL路径
 */
@property (nonatomic, strong) NSURL *playURL;

@property (nonatomic, strong) VLCPlayer *player;
@end
