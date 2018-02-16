//
//  ViewController.h
//  ObjCCamera
//
//  Created by Chihiro on 2018/02/16.
//  Copyright © 2018 Chihiro. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@interface ViewController : UIViewController<AVCaptureVideoDataOutputSampleBufferDelegate>

@property (nonatomic, strong) AVCaptureSession* session;
//@property (nonatomic, strong) IBOutlet UIImageView* ;
@property (strong, nonatomic) IBOutlet UIImageView *imageView;

@end

