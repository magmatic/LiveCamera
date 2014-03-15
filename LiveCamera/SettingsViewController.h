//
//  SettingsViewController.h
//  LiveCamera
//
//  Created by M on 2013-01-10.
//  Copyright (c) 2013 Black Magma Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>

@interface SettingsViewController : UITableViewController

@property (nonatomic, strong) UISlider *shadowSlider;
@property (nonatomic, strong) UISlider *highlightSlider;
@property (nonatomic, strong) UISlider *warmthSlider;
@property (nonatomic, strong) UISlider *tintSlider;
@property (nonatomic, strong) UISlider *brightnessSlider;
@property (nonatomic, strong) UISlider *saturationSlider;
@property (nonatomic, strong) UISlider *contrastSlider;
@property (nonatomic, strong) UISwitch *graduatedSwitch;

- (void) resetSettings;
@end
