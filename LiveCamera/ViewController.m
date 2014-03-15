//
//  AppDelegate.h
//  LiveCamera
//
//  Created by M on 2013-01-04.
//  Copyright (c) 2013 Black Magma Inc. All rights reserved.
//

#import <CoreLocation/CoreLocation.h>
#import "ViewController.h"
#import "Filter.h"
#import "AVCamUtilities.h"
#import "SettingsViewController.h"
#import "NSMutableDictionary+ImageMetadata.h"
#import "UIDevice+Hardware.h"

#define kButtonGridHeight 90
#define kButtonGridTopHeight 35

@interface ViewController () <AVCaptureVideoDataOutputSampleBufferDelegate, CLLocationManagerDelegate>

@property (nonatomic, strong) AVCaptureSession *captureSession;
@property (nonatomic, strong) AVCaptureVideoDataOutput *dataOutput;
@property (nonatomic, strong) CALayer *customPreviewLayer;

@property (nonatomic, strong) UIView* settingsOverlay;
@property (nonatomic, strong) UIView* buttonGrid;
@property (nonatomic, strong) UIView* buttonGridTop;

@property (nonatomic) CGFloat highlights;
@property (nonatomic) CGFloat shadows;
@property (nonatomic) CGFloat warmth;
@property (nonatomic) CGFloat tint;
@property (nonatomic) CGFloat brightness;
@property (nonatomic) CGFloat saturation;
@property (nonatomic) CGFloat contrast;
@property (nonatomic) BOOL graduated;

@property (nonatomic, strong) CLLocation *currentLocation;

- (void)setupCameraSession;
@end


@implementation ViewController
{
    AVCaptureSession *_captureSession;
    AVCaptureVideoDataOutput *_dataOutput;
    
    CALayer *_customPreviewLayer;
}


@synthesize captureSession = _captureSession;
@synthesize dataOutput = _dataOutput;
@synthesize customPreviewLayer = _customPreviewLayer;

// using volume buttons as shutter buttons
void volumeListenerCallback (void *inClientData, AudioSessionPropertyID inID, UInt32 inDataSize, const void *inData);
void volumeListenerCallback (void *inClientData, AudioSessionPropertyID inID, UInt32 inDataSize, const void *inData){    
    [(__bridge ViewController *)inClientData act_shutter];
}

UIButton *_shutter;
UIButton *_btn_reset;
CIContext *_context;
Filter *_imageFilter;
SettingsViewController *_settings;
CLLocationManager *_locationManager;

CGFloat _btnWidth = 90;
CGFloat _btnYOrigin = 0;

#pragma mark - Initial loading and layout

- (void)viewDidLoad {
    [super viewDidLoad];
    
//    // Make the input image recipe
//    UIImage *im = [UIImage imageNamed:@"ff-av.jpg"];
//    UIImageView *imageView = [[UIImageView alloc] initWithImage:im];
//    [imageView sizeToFit];
//    [self.view addSubview:imageView];
//    
//    CIImage *inputImage = [CIImage imageWithCGImage:im.CGImage]; // 1
//    
//    // Make the filter
//    CIFilter *colorMatrixFilter = [CIFilter filterWithName:@"CIColorMatrix"]; // 2
//    [colorMatrixFilter setDefaults]; // 3
//    [colorMatrixFilter setValue:inputImage forKey:kCIInputImageKey]; // 4
//    [colorMatrixFilter setValue:[CIVector vectorWithX:1 Y:1 Z:1 W:0] forKey:@"inputRVector"]; // 5
//    [colorMatrixFilter setValue:[CIVector vectorWithX:0 Y:1 Z:0 W:0] forKey:@"inputGVector"]; // 6
//    [colorMatrixFilter setValue:[CIVector vectorWithX:0 Y:0 Z:1 W:0] forKey:@"inputBVector"]; // 7
//    [colorMatrixFilter setValue:[CIVector vectorWithX:0 Y:0 Z:0 W:1] forKey:@"inputAVector"]; // 8
//    
//    // Get the output image recipe
//    CIImage *outputImage = [colorMatrixFilter outputImage];  // 9
//    
//    // Create the context and instruct CoreImage to draw the output image recipe into a CGImage
//    CIContext *context = [CIContext contextWithOptions:nil];
//    CGImageRef cgimg = [context createCGImage:outputImage fromRect:imageView.frame]; // 10
//    
//    // Draw the image in screen
//    UIImageView *imageView2 = [[UIImageView alloc] initWithImage:[UIImage imageWithCGImage:cgimg]];
//    CGRect f = imageView2.frame;
//    f.origin.y = CGRectGetMaxY(imageView.frame);
//    imageView2.frame = f;
//    [self.view addSubview:imageView2];
    
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7")) _btnYOrigin = 20;
    
    self.cameraOutput = [[UIView alloc] initWithFrame:CGRectZero];
    [self.view addSubview:self.cameraOutput];

    self.settingsOverlay = [[UIView alloc] initWithFrame:CGRectZero];
    self.buttonGrid = [[UIView alloc] initWithFrame:CGRectZero];
   
    // buttons at the top of the screen
    self.buttonGridTop = [[UIView alloc] initWithFrame:CGRectZero];

    [self.view addSubview:self.buttonGridTop];
    UIButton *btn_settings = [UIButton buttonWithType:UIButtonTypeCustom];
    [btn_settings setTitle:@"Settings" forState:UIControlStateNormal];
    btn_settings.frame = CGRectMake(self.cameraOutput.frame.size.width - _btnWidth - 5, 5+_btnYOrigin, _btnWidth, 30);
    [btn_settings addTarget:self action:@selector(act_settingsToggle:) forControlEvents:UIControlEventTouchUpInside];
    btn_settings.tag = 30;
    btn_settings.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
    [self.buttonGridTop addSubview:btn_settings];

    _btn_reset = [UIButton buttonWithType:UIButtonTypeCustom];
    [_btn_reset setTitle:@"Reset" forState:UIControlStateNormal];
    _btn_reset.frame = CGRectMake(5, 5+_btnYOrigin, _btnWidth, 30);
    [_btn_reset addTarget:_settings action:@selector(resetSettings) forControlEvents:UIControlEventTouchUpInside];
    _btn_reset.hidden = YES;
    _btn_reset.tag = 31;
    [self.buttonGridTop addSubview:_btn_reset];

    for (int i=30; i<32; i++) {
        UIButton *button = (UIButton*) [self.buttonGridTop viewWithTag:i];
        button.backgroundColor = [UIColor colorWithWhite:0.2 alpha:0.5];
        button.layer.cornerRadius = 15;
        button.layer.borderWidth = 1.5;
        button.layer.borderColor = [UIColor whiteColor].CGColor;
        button.clipsToBounds = YES;
        button.titleLabel.font = [UIFont boldSystemFontOfSize:14];
    }

    
    // settings - actual sliders
    [self.view addSubview:self.settingsOverlay];
    _settings = [[SettingsViewController alloc] initWithStyle:UITableViewStyleGrouped];
    [self.settingsOverlay addSubview:_settings.tableView];
    // set targets to continuously capture changes from touches
    for (UIControl *c in @[_settings.highlightSlider, _settings.shadowSlider, _settings.brightnessSlider, _settings.saturationSlider, _settings.contrastSlider, _settings.graduatedSwitch])
        [c addTarget:self action:@selector(settingsChanged:) forControlEvents:UIControlEventValueChanged];
    // set observers to capture changes from programmatic resets
    for (UISlider *s in @[_settings.highlightSlider, _settings.shadowSlider, _settings.brightnessSlider, _settings.saturationSlider, _settings.contrastSlider])
        [s addObserver:self forKeyPath:@"value" options:NSKeyValueObservingOptionNew context:nil];
    [_settings.graduatedSwitch addObserver:self forKeyPath:@"on" options:NSKeyValueObservingOptionNew context:nil];
    // get initial values
    [self settingsChanged:nil];
    self.settingsOverlay.opaque = NO;
    self.settingsOverlay.backgroundColor = [UIColor clearColor];
    self.settingsOverlay.hidden = YES;

    
    [self.view addSubview:self.buttonGrid];
    
    // enable GPS tagging of photos
    _locationManager = [[CLLocationManager alloc] init];
    _locationManager.delegate = self;
    _locationManager.distanceFilter = kCLDistanceFilterNone;
    _locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    [_locationManager startUpdatingLocation];

    // shutter button
    _shutter = [UIButton buttonWithType:UIButtonTypeCustom];
    [_shutter setImage:[UIImage imageNamed:@"shutter"] forState:UIControlStateNormal];
    [_shutter setImage:[UIImage imageNamed:@"shutter_pressed"] forState:UIControlStateHighlighted];
    [_shutter addTarget:self action:@selector(act_shutter) forControlEvents:UIControlEventTouchUpInside];
    [_shutter sizeToFit];
    _shutter.center = self.buttonGrid.center;
    _shutter.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
    [self.buttonGrid addSubview:_shutter];

    // using volume buttons as shutter
    AudioSessionInitialize(NULL, NULL, NULL, NULL);
    AudioSessionSetActive(YES);
    AudioSessionAddPropertyListener(kAudioSessionProperty_CurrentHardwareOutputVolume, volumeListenerCallback, (__bridge void *)(self));

    [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleOrientationChange) name:UIDeviceOrientationDidChangeNotification object:nil];
    
    // enable low light boost if available
    AVCaptureDevice *backFacingCamera;
    for (AVCaptureDevice *device in [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo]) {
        if ([device position] == AVCaptureDevicePositionBack) backFacingCamera = device;
    }
    if ([backFacingCamera respondsToSelector:@selector(isLowLightBoostSupported)]) {
        if ([backFacingCamera lockForConfiguration:nil]) {
            if (backFacingCamera.isLowLightBoostSupported)
                backFacingCamera.automaticallyEnablesLowLightBoostWhenAvailable = YES;
            [backFacingCamera unlockForConfiguration];
        }
    }
    
    [self setupCameraSession];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    // Turn on remote control event delivery
    [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
    
    // Set itself as the first responder
    [self becomeFirstResponder];
}


- (void)remoteControlReceivedWithEvent:(UIEvent *)theEvent {
    // using headset buttons as shutter
    if (theEvent.type == UIEventTypeRemoteControl) {
        [self act_shutter];
    }
}

- (BOOL)canBecomeFirstResponder {
    return YES;
}

- (void)viewWillLayoutSubviews{
    
    CGRect frame = self.view.bounds;
    if (frame.size.height > frame.size.width) {
        // vertical
        frame.size.height -= kButtonGridHeight;
    } else {
        // horizontal
        frame.size.width -= kButtonGridHeight;
        if ([UIApplication sharedApplication].statusBarOrientation == UIInterfaceOrientationLandscapeLeft)
            frame.origin.x = kButtonGridHeight;

    }
    self.cameraOutput.frame = frame;
    [_customPreviewLayer setFrame:self.cameraOutput.bounds];

    // adjust the frames of settings and shutter to fit current orientation
    switch ([UIApplication sharedApplication].statusBarOrientation) {
        case UIInterfaceOrientationPortrait: {
            self.buttonGrid.frame = CGRectMake(0, self.cameraOutput.frame.size.height + self.cameraOutput.frame.origin.y, self.cameraOutput.frame.size.width, kButtonGridHeight);
            
            
        } break;
        case UIInterfaceOrientationPortraitUpsideDown: {
        } break;
        case UIInterfaceOrientationLandscapeRight: {
            self.buttonGrid.frame = CGRectMake(self.cameraOutput.frame.size.width + self.cameraOutput.frame.origin.x, 0, kButtonGridHeight, self.cameraOutput.frame.size.height);

        } break;
        case UIInterfaceOrientationLandscapeLeft: {
            self.buttonGrid.frame = CGRectMake(0, 0, kButtonGridHeight, self.cameraOutput.frame.size.height);
            
        } break;
    }

    frame.size.height = kButtonGridTopHeight;
    self.buttonGridTop.frame = frame;
    

    frame.size.height = self.cameraOutput.frame.size.height - kButtonGridTopHeight;
    frame.origin.y += kButtonGridTopHeight;
    self.settingsOverlay.frame = frame;
    _settings.tableView.frame = self.settingsOverlay.bounds;

}

#pragma mark - Handling settings changes

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    [self settingsChanged:object];
}

- (void) act_settingsToggle:(UIButton *)sender {
    self.settingsOverlay.hidden = !self.settingsOverlay.hidden;
    _btn_reset.hidden = !_btn_reset.hidden;
    [sender setTitle:self.settingsOverlay.hidden ? @"Settings" : @"Done" forState:UIControlStateNormal];
}

- (void) settingsChanged:(id)object {
    self.highlights = _settings.highlightSlider.value;
    self.shadows = _settings.shadowSlider.value;
    self.brightness = _settings.brightnessSlider.value;
    self.saturation = _settings.saturationSlider.value;
    self.contrast = _settings.contrastSlider.value;
    self.graduated = _settings.graduatedSwitch.on;
}

- (void) handleOrientationChange {
    // rotate select elements based on current device orientation
    [self.view setNeedsLayout];
    
    // for portrait mode, settings 
    switch ([[UIDevice currentDevice] orientation]) {
        case UIDeviceOrientationPortrait:
            break;
        case UIDeviceOrientationPortraitUpsideDown:
            break;
        case UIDeviceOrientationLandscapeLeft:
            // home button on the right
//            [UIView beginAnimations:nil context:NULL];
//            [UIView setAnimationDuration:3.0];
//            
//            self.buttonGridTop.transform = CGAffineTransformMakeRotation(90 * M_PI / 180.0);
//            
//            [UIView commitAnimations];

            break;
        case UIDeviceOrientationLandscapeRight:
            // home button on the left
            break;
            
        default:
            // do not do anything for face up and face down orientations
            break;
    }
    
}

#pragma mark - Handling the video feed

- (void) act_shutter {
    AVCaptureConnection *stillImageConnection = [AVCamUtilities connectionWithMediaType:AVMediaTypeVideo fromConnections:[self.stillImageOutput connections]];
    [self.stillImageOutput captureStillImageAsynchronouslyFromConnection:stillImageConnection
            completionHandler:^(CMSampleBufferRef imageDataSampleBuffer, NSError *error) {
                if (imageDataSampleBuffer != NULL) {
                    NSData *imageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageDataSampleBuffer];
                   
                    CGImageSourceRef source = CGImageSourceCreateWithData((__bridge CFDataRef)imageData, NULL);
                                        
                    NSMutableDictionary *metadata = [[NSMutableDictionary alloc] initWithDictionary:(__bridge NSDictionary *) CGImageSourceCopyPropertiesAtIndex(source,0,NULL)];
                    [metadata setUserComment:@"Created with LiveCamera"];
                    [metadata setMake:@"Apple" model:[UIDevice currentDevice].platformString software:[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleDisplayName"]];
                    [metadata setLocation:self.currentLocation];
                    
                    ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
                    CIImage *image = [CIImage imageWithData:imageData];
                    CIImage *outputImage = [_imageFilter inputImage:image highlights:[NSNumber numberWithFloat:self.highlights] shadows:[NSNumber numberWithFloat:self.shadows] brightness:[NSNumber numberWithFloat:self.brightness] saturation:[NSNumber numberWithFloat:self.saturation] contrast:[NSNumber numberWithFloat:self.contrast] graduated:self.graduated fullSize:YES];
                    
                    CGImageRef cgImg = [_context createCGImage:outputImage fromRect:[outputImage extent]];
                    [library writeImageToSavedPhotosAlbum:cgImg metadata:metadata
                                    completionBlock:^(NSURL *assetURL, NSError *error) { CGImageRelease(cgImg); }];

//                    UIGraphicsBeginImageContext([outputImage extent].size);
//                    CGRect rect = [outputImage extent];
//                    [[UIImage imageWithCIImage:outputImage] drawInRect:rect];
//                    UIImage *i = UIGraphicsGetImageFromCurrentImageContext();
//                    UIGraphicsEndImageContext();
//                    NSData *jpegData = UIImageJPEGRepresentation(i, 0.60);
//                    [library writeImageDataToSavedPhotosAlbum:jpegData metadata:metadata completionBlock:nil];
                }
                
            }];
}

- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation {
    self.currentLocation = newLocation;
}


- (void)setupCameraSession {
    // set up the input device and the output layer
    // this should only be run once during app initialization
    _imageFilter = [[Filter alloc] init];
    _context = [CIContext contextWithOptions:nil];
    
    // Session
    _captureSession = [AVCaptureSession new];
    [_captureSession setSessionPreset:AVCaptureSessionPresetPhoto];
    
    // Capture device
    AVCaptureDevice *inputDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    NSError *error;
    
    // Device input
    AVCaptureDeviceInput *deviceInput = [AVCaptureDeviceInput deviceInputWithDevice:inputDevice error:&error];
	if ( [_captureSession canAddInput:deviceInput] )
		[_captureSession addInput:deviceInput];
            
    _customPreviewLayer = [[CALayer alloc] init];
    [_customPreviewLayer setBackgroundColor:[[UIColor blueColor] CGColor]];
	[self.view.layer setMasksToBounds:YES];
	[_customPreviewLayer setFrame:self.cameraOutput.bounds];
    [self.cameraOutput.layer insertSublayer:_customPreviewLayer atIndex:0];
    
    AVCaptureStillImageOutput *newStillImageOutput = [[AVCaptureStillImageOutput alloc] init];
    NSDictionary *outputSettings = [[NSDictionary alloc] initWithObjectsAndKeys:AVVideoCodecJPEG, AVVideoCodecKey, nil];
    [newStillImageOutput setOutputSettings:outputSettings];
    self.stillImageOutput = newStillImageOutput;
    [_captureSession addOutput:self.stillImageOutput];
    
    _dataOutput = [AVCaptureVideoDataOutput new];
    _dataOutput.videoSettings = [NSDictionary dictionaryWithObject:[NSNumber numberWithUnsignedInt:kCVPixelFormatType_420YpCbCr8BiPlanarFullRange] forKey:(NSString *)kCVPixelBufferPixelFormatTypeKey];
    
    [_dataOutput setAlwaysDiscardsLateVideoFrames:YES];
        
    if ( [_captureSession canAddOutput:_dataOutput] )
        [_captureSession addOutput:_dataOutput];    
    [_captureSession commitConfiguration];

    dispatch_queue_t queue = dispatch_queue_create("VideoQueue", DISPATCH_QUEUE_SERIAL);
    [_dataOutput setSampleBufferDelegate:self queue:queue];
    
    [_captureSession startRunning];
}


- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    CIImage *beginImage = [CIImage imageWithCVPixelBuffer:CMSampleBufferGetImageBuffer(sampleBuffer)];
    
    CIImage *outputImage = [_imageFilter inputImage:beginImage highlights:[NSNumber numberWithFloat:self.highlights] shadows:[NSNumber numberWithFloat:self.shadows] brightness:[NSNumber numberWithFloat:self.brightness] saturation:[NSNumber numberWithFloat:self.saturation] contrast:[NSNumber numberWithFloat:self.contrast] graduated:self.graduated fullSize:NO];
    
    switch ([UIApplication sharedApplication].statusBarOrientation) {
        case UIInterfaceOrientationPortrait: {
            // rotate 90 degrees
            CGAffineTransform rotation = CGAffineTransformMakeRotation(-M_PI/2);
            CGAffineTransform translation = CGAffineTransformMakeTranslation(0, self.cameraOutput.frame.size.width);
            CGAffineTransform transform = CGAffineTransformConcat(rotation, translation);
            CIFilter *rotate = [CIFilter filterWithName:@"CIAffineTransform" keysAndValues:@"inputImage", outputImage, nil];
            [rotate setValue:[NSValue valueWithBytes:&transform objCType:@encode(CGAffineTransform)] forKey:@"inputTransform"];
            outputImage = rotate.outputImage;
        } break;
        case UIInterfaceOrientationPortraitUpsideDown: {
            // this will need a 90 degree rotation in the opposite direction
            CGAffineTransform rotation = CGAffineTransformMakeRotation(M_PI/2);
            CGAffineTransform translation = CGAffineTransformMakeTranslation(0, self.cameraOutput.frame.size.width);
            CGAffineTransform transform = CGAffineTransformConcat(rotation, translation);
            CIFilter *rotate = [CIFilter filterWithName:@"CIAffineTransform" keysAndValues:@"inputImage", outputImage, nil];
            [rotate setValue:[NSValue valueWithBytes:&transform objCType:@encode(CGAffineTransform)] forKey:@"inputTransform"];
            outputImage = rotate.outputImage;
        } break;
        case UIInterfaceOrientationLandscapeRight:
            // this is the default and requires no corrections
            break;
        case UIInterfaceOrientationLandscapeLeft: {
            // home button on the left
            // this requires 180 degree rotation
            CGAffineTransform rotation = CGAffineTransformMakeRotation(-M_PI);
            CIFilter *rotate = [CIFilter filterWithName:@"CIAffineTransform" keysAndValues:@"inputImage", outputImage, nil];
            [rotate setValue:[NSValue valueWithBytes:&rotation objCType:@encode(CGAffineTransform)] forKey:@"inputTransform"];
            outputImage = rotate.outputImage;

        } break;
    }

    
//    NSLog(@"%@", NSStringFromCGRect([outputImage extent]));
    CGImageRef dstImageFilter = [_context createCGImage:outputImage fromRect:[outputImage extent]];
    dispatch_sync(dispatch_get_main_queue(), ^{
        _customPreviewLayer.contents = (__bridge id)dstImageFilter;
    });
    CGImageRelease(dstImageFilter);
}



@end