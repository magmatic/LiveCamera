//
//  AppDelegate.h
//  LiveCamera
//
//  Created by M on 2013-01-04.
//  Copyright (c) 2013 Black Magma Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>
#import <CoreMedia/CoreMedia.h>

@interface Filter : NSObject

- (CIImage *)inputImage:(CIImage *)image highlights:(NSNumber*)highl shadows:(NSNumber*)shadow brightness:(NSNumber*)bright saturation:(NSNumber*)sat contrast:(NSNumber*)cont graduated:(BOOL)grad fullSize:(BOOL)full;

@end
