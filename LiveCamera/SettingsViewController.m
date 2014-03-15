//
//  SettingsViewController.m
//  LiveCamera
//
//  Created by M on 2013-01-10.
//  Copyright (c) 2013 Black Magma Inc. All rights reserved.
//

#import "SettingsViewController.h"

@interface SettingsViewController ()

@end

@implementation SettingsViewController

UILabel *_currentSettingValue;
NSUserDefaults *_defaults;

typedef enum {
	SettingsRowBrightness = 0,
	SettingsRowSaturation,
	SettingsRowContrast,
	SettingsRowHighlight,
	SettingsRowShadow,
	SettingsRowWarmth,
	SettingsRowTint,
	SettingsRowGraduated,
	SettingsRow_COUNT
} SettingsRow;

- (id)initWithStyle:(UITableViewStyle)style {
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.tableView.backgroundView = [[UIView alloc] initWithFrame:CGRectZero];
    self.tableView.backgroundColor = [UIColor clearColor];
//    self.tableView.scrollEnabled = NO;
    self.tableView.separatorColor = [UIColor clearColor];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    
    _defaults = [NSUserDefaults standardUserDefaults];
    
    [[UISlider appearance] setMinimumTrackTintColor:[UIColor colorWithWhite:0.2 alpha:1]];
    [[UISlider appearance] setMaximumTrackTintColor:[UIColor colorWithWhite:0.8 alpha:1]];
    
    self.highlightSlider = [[UISlider alloc] init];
    self.highlightSlider.minimumValue = 0.0;
    self.highlightSlider.maximumValue = 1.0;
    
    CGRect frame = self.highlightSlider.frame;
    frame.size.width = self.tableView.frame.size.width * 0.63;
    self.highlightSlider.frame = frame;
    
    self.shadowSlider = [[UISlider alloc] initWithFrame:frame];
    self.shadowSlider.minimumValue = -1.0;
    self.shadowSlider.maximumValue = 1.0;
    
    self.brightnessSlider = [[UISlider alloc] initWithFrame:frame];
    self.brightnessSlider.minimumValue = -1.0;
    self.brightnessSlider.maximumValue = 1.0;
    
    self.saturationSlider = [[UISlider alloc] initWithFrame:frame];
    self.saturationSlider.minimumValue = 0.0;
    self.saturationSlider.maximumValue = 2.0;
    
    self.contrastSlider = [[UISlider alloc] initWithFrame:frame];
    self.contrastSlider.minimumValue = 0.0;
    self.contrastSlider.maximumValue = 2.0;
    
    self.warmthSlider = [[UISlider alloc] initWithFrame:frame];
    self.warmthSlider.minimumValue = -1.0;
    self.warmthSlider.maximumValue = 1.0;

    self.tintSlider = [[UISlider alloc] initWithFrame:frame];
    self.tintSlider.minimumValue = -1.0;
    self.tintSlider.maximumValue = 1.0;

    NSArray *sliders = @[self.warmthSlider, self.tintSlider, self.highlightSlider, self.shadowSlider, self.contrastSlider, self.brightnessSlider, self.saturationSlider];
    for (UISlider *slider in sliders){
        [slider addTarget:self action:@selector(actSliderTouched:) forControlEvents:UIControlEventTouchDown];
        [slider addTarget:self action:@selector(actSliderTouchUp:) forControlEvents:UIControlEventTouchUpInside];
        [slider addTarget:self action:@selector(actSliderTouchUp:) forControlEvents:UIControlEventTouchUpOutside];
        [slider addTarget:self action:@selector(actUpdateValue:) forControlEvents:UIControlEventValueChanged];
        // observer to save the new value into defaults
        [slider addObserver:self forKeyPath:@"value" options:NSKeyValueObservingOptionNew context:nil];
    }
    
    // label to show the current value of the filter that's being adjusted
    _currentSettingValue = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 50, 30)];
    _currentSettingValue.hidden = YES;
    _currentSettingValue.backgroundColor = [UIColor colorWithWhite:0.2 alpha:0.5];
    _currentSettingValue.layer.cornerRadius = 15;
    _currentSettingValue.layer.borderWidth = 1.5;
    _currentSettingValue.layer.borderColor = [UIColor whiteColor].CGColor;
    _currentSettingValue.clipsToBounds = YES;
    _currentSettingValue.font = [UIFont boldSystemFontOfSize:14];
    _currentSettingValue.textAlignment = NSTextAlignmentCenter;
    _currentSettingValue.textColor = [UIColor whiteColor];
    _currentSettingValue.center = self.view.center;
    self.view.clipsToBounds = NO; // allow the label with settings value of top row to extend above the view
    [self.view addSubview:_currentSettingValue];
    
    self.graduatedSwitch = [[UISwitch alloc] init];
    self.graduatedSwitch.onTintColor = [UIColor colorWithWhite:0.2 alpha:1];
    [self.graduatedSwitch addObserver:self forKeyPath:@"on" options:NSKeyValueObservingOptionNew context:nil];

    if ([_defaults objectForKey:@"lastBrightness"]) {
        // set the values from last saved session
        self.highlightSlider.value = [_defaults floatForKey:@"lastHighlight"];
        self.shadowSlider.value = [_defaults floatForKey:@"lastShadow"];
        self.warmthSlider.value = [_defaults floatForKey:@"lastWarmth"];
        self.tintSlider.value = [_defaults floatForKey:@"lastTint"];
        self.brightnessSlider.value = [_defaults floatForKey:@"lastBrightness"];
        self.saturationSlider.value = [_defaults floatForKey:@"lastSaturation"];
        self.contrastSlider.value = [_defaults floatForKey:@"lastContrast"];
        self.graduatedSwitch.on = [_defaults boolForKey:@"lastGrad"];
    } else {
        // use default non-adjusted settings
        [self resetSettings];
    }
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    // save the last value for next time the app is restarted
    if ([object isKindOfClass:[UISlider class]]){
        UISlider *slider = (UISlider *) object;
        // save the setting into defaults
        if (slider == self.highlightSlider) [_defaults setFloat:slider.value forKey:@"lastHighlight"];
        else if (slider == self.shadowSlider) [_defaults setFloat:slider.value forKey:@"lastShadow"];
        else if (slider == self.warmthSlider) [_defaults setFloat:slider.value forKey:@"lastWarmth"];
        else if (slider == self.tintSlider) [_defaults setFloat:slider.value forKey:@"lastTint"];
        else if (slider == self.brightnessSlider) [_defaults setFloat:slider.value forKey:@"lastBrightness"];
        else if (slider == self.saturationSlider) [_defaults setFloat:slider.value forKey:@"lastSaturation"];
        else if (slider == self.contrastSlider) [_defaults setFloat:slider.value forKey:@"lastContrast"];
        [_defaults synchronize];
    } else if ([object isKindOfClass:[UISwitch class]]){
        if (object == self.graduatedSwitch) [_defaults setBool:self.graduatedSwitch.on forKey:@"lastGrad"];
    }
    [_defaults synchronize];
}

- (void) actSliderTouched: (UISlider *) slider {
    UITableViewCell *cell;
    int n; // sequence # of current slider
    for (int i = 0; i < SettingsRow_COUNT; i++){
        cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0]];
        if (cell.accessoryView != slider) cell.alpha = 0;
        else {
            cell.backgroundColor = [UIColor clearColor];
//            cell.textLabel.alpha = 0.8;
            n = i;
        }
    }
    CGRect f = _currentSettingValue.frame;
    f.origin.y = n * 44 - 15;
    _currentSettingValue.frame = f;
    [self actUpdateValue:slider];
    _currentSettingValue.hidden = NO;
}

- (void) actSliderTouchUp: (UISlider *) slider {
    _currentSettingValue.hidden = YES;
    
    UITableViewCell *cell;
    for (int i = 0; i < SettingsRow_COUNT; i++){
        cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0]];
        if (cell.accessoryView != slider) cell.alpha = 1;
        else {
            cell.backgroundColor = [UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:0.5];
            cell.textLabel.alpha = 1;
            cell.textLabel.backgroundColor = [UIColor clearColor];
        }
    }
    CGRect f = slider.frame;
    f.size.width = self.view.frame.size.width * 0.63;
    slider.frame = f;
    
}

- (void) actUpdateValue: (UISlider *) slider {
    _currentSettingValue.text = [NSString stringWithFormat:@"%.2f", slider.value];
}

- (void) resetSettings {
    self.highlightSlider.value = 1.0;
    self.shadowSlider.value = 0.0;
    self.warmthSlider.value = 0.0;
    self.tintSlider.value = 0.0;
    self.brightnessSlider.value = 0.0;
    self.saturationSlider.value = 1.0;
    self.contrastSlider.value = 1.0;
    self.graduatedSwitch.on = NO;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    return SettingsRow_COUNT;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    
    NSShadow *shadow = [[NSShadow alloc] init];
    shadow.shadowBlurRadius = 2;
    shadow.shadowColor = [UIColor whiteColor];
    shadow.shadowOffset = CGSizeMake(0, 0);
    NSDictionary *textAttributes = @{NSFontAttributeName : [UIFont fontWithName:@"HelveticaNeue-Light" size:14],
                                            NSShadowAttributeName : shadow};
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if(cell == nil) {
		cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        cell.selectionStyle = UITableViewCellSelectionStyleGray;
        cell.textLabel.backgroundColor = [UIColor clearColor];
        cell.textLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:14];
        cell.backgroundColor = [UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:0.5];
        UIView *selBack = [[UIView alloc] initWithFrame:CGRectZero];
        selBack.backgroundColor = [UIColor colorWithRed:0.5 green:0.5 blue:0.5 alpha:0.5];
        cell.selectedBackgroundView = selBack;
    }

    NSString* text = nil;
    
    switch(indexPath.row) {
		case SettingsRowHighlight:
			text = @"Highlights";
            cell.accessoryView = self.highlightSlider;
			break;
		case SettingsRowShadow:
			text = @"Shadows";
            cell.accessoryView = self.shadowSlider;
			break;
		case SettingsRowWarmth:
			text = @"Warmth";
            cell.accessoryView = self.warmthSlider;
			break;
		case SettingsRowTint:
			text = @"Tint";
            cell.accessoryView = self.tintSlider;
			break;
		case SettingsRowBrightness:
			text = @"Brightness";
            cell.accessoryView = self.brightnessSlider;
			break;
		case SettingsRowSaturation:
			text = @"Saturation";
            cell.accessoryView = self.saturationSlider;
			break;
		case SettingsRowContrast:
			text = @"Contrast";
            cell.accessoryView = self.contrastSlider;
			break;
		case SettingsRowGraduated:
			text = @"Graduated ND Filter";
            cell.accessoryView = self.graduatedSwitch;
			break;
	}
    
//	cell.textLabel.text = text;
    cell.textLabel.attributedText = [[NSAttributedString alloc] initWithString:text attributes:textAttributes];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    switch(indexPath.row) {
		case SettingsRowHighlight:
            self.highlightSlider.value = 1.0;
			break;
		case SettingsRowShadow:
            self.shadowSlider.value = 0.0;
			break;
		case SettingsRowWarmth:
            self.warmthSlider.value = 0.0;
			break;
		case SettingsRowTint:
            self.tintSlider.value = 0.0;
			break;
		case SettingsRowBrightness:
            self.brightnessSlider.value = 0.0;
			break;
		case SettingsRowSaturation:
            self.saturationSlider.value = 1.0;
			break;
		case SettingsRowContrast:
            self.contrastSlider.value = 1.0;
			break;
		case SettingsRowGraduated:
            self.graduatedSwitch.on = NO;
			break;
	}

    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
}

/*
 // Override to support rearranging the table view.
 - (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
 {
 }
 */

/*
 // Override to support conditional rearranging of the table view.
 - (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
 {
 // Return NO if you do not want the item to be re-orderable.
 return YES;
 }
 */


@end
