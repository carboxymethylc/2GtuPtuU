//
//  ViewController.h
//  demo_mainpage
//
//  Created by LD.Chirag on 11/18/12.
//  Copyright (c) 2012 LD.Chirag. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GPUImage.h"
#import "SimpleImageAppDelegate.h"

typedef enum
{
    GPUIMAGE_FOCALPOINT,
    GPUIMAGE_FISHEYE,
    GPUIMAGE_TILTSHIFTVERTICAL,
    GPUIMAGE_TILTSHIFTHORIZONTAL,
    GPUIMAGE_NORMAL,
    
} GPUImageShowcaseFilterType;

typedef enum
{
    tiltshift_left_line_tag  = 2001,
    tiltshift_right_line_tag  = 2002,
    tiltshift_top_line_tag  = 2003,
    tiltshift_bottom_line_tag  = 2004,
    

    
}tiltshift_bar_tags;

@interface ViewController : UIViewController<UIImagePickerControllerDelegate,UINavigationControllerDelegate,UIGestureRecognizerDelegate>
{
    GPUImageStillCamera *videoCamera;
    GPUImageSepiaFilter*filter;
    
    
    GPUImagePicture *sourcePicture;
    GPUImageShowcaseFilterType filterType;
    
    GPUImageFilterPipeline *pipeline;
    
    IBOutlet GPUImageView*cameraFilterView;
    
    IBOutlet UIView*lenseEffectView;
    IBOutlet UIButton*lenseButton;
    
    GPUImageOutput*tempOutput;
    
    //Filters
    GPUImageView *filterView;
    GPUImageGaussianSelectiveBlurFilter *gaussianSelectiveBlurFilter;
    GPUImageBulgeDistortionFilter *bulgeDistortionFilter;
    GPUImageTiltShiftFilter*tiltShiftFilter;
    GPUImageTiltShiftFilterVertical*tiltShiftFilterVertical;
    
    //Filter Settings View
    
    IBOutlet UIView*fishEyeSettingsView;
    IBOutlet UIView*foculPointSettingsView;
    IBOutlet UIView*tiltShiftVerticalSettingsView;
    IBOutlet UIView*tiltShiftHorizontalSettingsView;
    IBOutlet UIView*closeSettingsView;
    
    //Setting view Sliders
    
    IBOutlet UISlider*fish_eye_slider;
    
    IBOutlet UISlider*focal_size_slider;
    IBOutlet UISlider*blur_amount_slider;
    IBOutlet UISlider*color_shift_slider;

    
    IBOutlet UISlider*tiltshiftV_blur_amount_slider;
    IBOutlet UISlider*tiltshiftV_color_shift_slider;

    IBOutlet UIImageView*tiltshift_left_line;
    IBOutlet UIImageView*tiltshift_right_line;

    
    
    IBOutlet UISlider*tiltshiftH_blur_amount_slider;
    IBOutlet UISlider*tiltshiftH_color_shift_slider;

    
    IBOutlet UIImageView*tiltshift_top_line;
    IBOutlet UIImageView*tiltshift_bottom_line;

    
    
    
    
    IBOutlet UIButton*focalEffectButton;
    IBOutlet UIButton*fishEyeEffectButton;
    IBOutlet UIButton*tiltShiftVerticalEffectButton;
    IBOutlet UIButton*tiltShiftHorizontalEffectButton;
    IBOutlet UIButton*clear_effects_button;
    IBOutlet UIButton*closeSettingsViewButton;
    
    IBOutlet UIButton*galleryButton;
    
    //Image Picker
    
    UIImagePickerController*galleryImagePickerController;
    
    //AppDelegate
    SimpleImageAppDelegate*appDelegate;
    

    
    
}

// Initialization and teardown
- (id)initWithFilterType:(GPUImageShowcaseFilterType)newFilterType;
- (void)setupFilter;

// Filter adjustments
//- (IBAction)updateFilterFromSlider:(id)sender;
-(IBAction)captureImage:(id)sender;
-(void)fbButtonClicked:(id)sender;
-(IBAction)lenseButton_Clicked:(id)sender;

-(IBAction)focalEffectButton_Clicked:(id)sender;
-(IBAction)fishEyeEffectButton_Clicked:(id)sender;
-(IBAction)tiltShiftVerticalEffectButton_Clicked:(id)sender;
-(IBAction)tiltShiftHorizontalEffectButton_Clicked:(id)sender;
-(IBAction)clear_effects_button_clicked:(id)sender;

-(void)hideAllSettingsView;
-(IBAction)close_settingsview_button_clicked:(id)sender;

//FishEye

- (IBAction)update_fisheye_slider_value:(id)sender;


//Focal Point

- (IBAction)update_focal_size_slider:(id)sender;
- (IBAction)update_blur_amount_slider:(id)sender;
- (IBAction)update_color_shift_slider:(id)sender;

//Vertical tiltShift

- (IBAction)update_tiltshiftV_blur_amount_slider:(id)sender;
- (IBAction)update_tiltshiftV_color_shift_slider:(id)sender;


//Horizontal tiltShift
- (IBAction)update_tiltshiftH_blur_amount_slider:(id)sender;
- (IBAction)update_tiltshiftH_color_shift_slider:(id)sender;

-(IBAction)galler_button_pressed:(id)sender;


@end
