//
//  AppDelegate.h
//  LiveCamera
//
//  Created by M on 2013-01-04.
//  Copyright (c) 2013 Black Magma Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <QuartzCore/QuartzCore.h>
#import <CoreMedia/CoreMedia.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import <ImageIO/ImageIO.h>

@interface ViewController : UIViewController

@property (nonatomic, strong) UIView* cameraOutput;
@property (strong) AVCaptureStillImageOutput *stillImageOutput;


@end
