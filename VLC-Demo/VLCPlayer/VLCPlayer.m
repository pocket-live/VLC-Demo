//
//  VLCPlayer.m
//  VLCDemo
//
//  Created by pocket on 16/6/27.
//  Copyright © 2016年 pocket. All rights reserved.
//

#import "VLCPlayer.h"

@implementation VLCPlayer

- (id)initWithView:(UIView *)playView andMediaPath:(NSString *)path {
    self = [super init];
    if (self) {
        // 创建VCL对象
        _player = [[VLCMediaPlayer alloc] init];
        // 设置VCL播放界面的View
        _player.drawable = playView;
        // 设置需要加载的路径
        VLCMedia *media = [VLCMedia mediaWithPath:path];
        [_player setMedia:media];
    }
    return self;
}

- (id)initWithView:(UIView *)playView andMediaURL:(NSURL *)url {
    self = [super init];
    if (self) {
        _player = [[VLCMediaPlayer alloc] init];
        _player.drawable = playView;
        // 设置需要加载的url
        VLCMedia *media = [VLCMedia mediaWithURL:url];
//        NSMutableDictionary *mediaDictionary = [[NSMutableDictionary alloc] init];
//        //设置缓存多少毫秒
//        [mediaDictionary setObject:@"700" forKey:@"network-caching"];
//        [media addOptions:mediaDictionary];
        [_player setMedia:media];
    }
    return self;
}

// 播放
- (void)playMedia {
    [_player play];
}

// 暂停
- (void)stopPlaying {
    [_player stop];
}
@end
