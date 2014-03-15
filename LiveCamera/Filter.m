//
//  AppDelegate.h
//  LiveCamera
//
//  Created by M on 2013-01-04.
//  Copyright (c) 2013 Black Magma Inc. All rights reserved.
//

#import "Filter.h"

@implementation Filter

CIFilter *_gradMask;

- (id)init {
    self = [super init];
    if (self) {
        _gradMask = [CIFilter filterWithName:@"CILinearGradient" keysAndValues:
                     @"inputPoint1", [CIVector vectorWithX:[[UIScreen mainScreen] bounds].size.width Y:0], nil];
        _gradMask = [CIFilter filterWithName:@"CICrop" keysAndValues:@"inputImage", _gradMask.outputImage,
                     @"inputRectangle", [CIVector vectorWithX:0 Y:0 Z:[UIScreen mainScreen].bounds.size.width W:[UIScreen mainScreen].bounds.size.height*2], nil];
    }
    return self;
}

- (CIImage *)inputImage:(CIImage *)image highlights:(NSNumber*)highl shadows:(NSNumber*)shadow brightness:(NSNumber *)bright saturation:(NSNumber *)sat contrast:(NSNumber *)cont graduated:(BOOL)grad fullSize:(BOOL)full {
    
    CIFilter *filter;
    
    if (grad && full) {
        CIFilter *gradMask = [CIFilter filterWithName:@"CILinearGradient" keysAndValues:
                    @"inputPoint1", [CIVector vectorWithX:[image extent].size.width Y:0], nil];
        gradMask = [CIFilter filterWithName:@"CICrop" keysAndValues:@"inputImage", gradMask.outputImage,
                    @"inputRectangle", [CIVector vectorWithX:0 Y:0 Z:[image extent].size.width W:[image extent].size.height*2], nil];

        filter = [CIFilter filterWithName:@"CIExposureAdjust" keysAndValues:@"inputImage", image, @"inputEV", @-2, nil];
        CIFilter *gradFilter = [CIFilter filterWithName:@"CIBlendWithMask" keysAndValues:@"inputImage", filter.outputImage,
                                @"inputBackgroundImage", image, @"inputMaskImage", gradMask.outputImage, nil];
        image = gradFilter.outputImage;

    } else if (grad) {
        filter = [CIFilter filterWithName:@"CIExposureAdjust" keysAndValues:@"inputImage", image, @"inputEV", @-2, nil];
        CIFilter *gradFilter = [CIFilter filterWithName:@"CIBlendWithMask" keysAndValues:@"inputImage", filter.outputImage,
                                @"inputBackgroundImage", image, @"inputMaskImage", _gradMask.outputImage, nil];
        image = gradFilter.outputImage;
    }
    
    filter = [CIFilter filterWithName:@"CIHighlightShadowAdjust" keysAndValues:@"inputImage", image, @"inputHighlightAmount", highl, @"inputShadowAmount", shadow, nil];
    image = filter.outputImage;
    
    // check if any of the color controls are non-default
    int def = 0;
    if (!bright) { bright = @0; def += 1; }
    if (!sat) { sat = @1; def += 1; }
    if (!cont) { cont = @1; def += 1; }
    if (def < 3){
        filter = [CIFilter filterWithName:@"CIColorControls" keysAndValues: kCIInputImageKey, image, @"inputSaturation", sat, @"inputContrast", cont, @"inputBrightness", bright, nil];
        image = filter.outputImage;
    }
    
    return image;
}

@end
