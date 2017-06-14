//
//  ViewController.m
//  VLC-Demo
//
//  Created by 刘茂平 on 2017/6/14.
//  Copyright © 2017年 刘茂平. All rights reserved.
//

#import "ViewController.h"
#import "VLCViewController.h"

@interface ViewController ()

@end

@implementation ViewController


/**
  MobileVLCKit.framework库因为过大并没有上传，可以自行下载或者用我提供的链接
  下载好拖放进VLVPlayer工程目录下即可
   下载链接：http://pan.baidu.com/s/1pLiBQKb
 */

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    
}

- (NSString *)getDataPath
{
    return [[NSBundle mainBundle] pathForResource:@"贝尔科实验.mkv" ofType:nil];
}

// 这只是随便找一个视频测试，各位亲们可以自行找网络资源测
- (IBAction)beginBtn:(id)sender {
    VLCViewController *vlcVc = [[VLCViewController  alloc] init];
    vlcVc.playName = @"贝尔科实验";
    vlcVc.playPath = [self getDataPath];
    
    [self presentViewController:vlcVc animated:YES completion:^{
        
    }];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
