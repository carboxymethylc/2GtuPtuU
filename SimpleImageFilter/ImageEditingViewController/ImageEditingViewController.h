//
//  ImageEditingViewController.h
//  demo_mainpage
//
//  Created by LD.Chirag on 11/22/12.
//  Copyright (c) 2012 LD.Chirag. All rights reserved.
//

/*
 Tag used
 From 1000 
 Bottom menu buttons...
 
 From 2000 To 2009
 Edits effect tag
 
 */

#import <UIKit/UIKit.h>
#import "SimpleImageAppDelegate.h"
#import "GPUImage.h"
@class ImageCropper;
typedef enum
{
    BTN_GALLERY=1000,
    BTN_EDITS,
    BTN_FILTERS,
    BTN_FRAMES,
    BTN_EXTRAS,
    BTN_SAVE,
    
    
} IMAGE_EDITING_BOTTOM_BUTTON;

enum
{
    
    kRotateClock = 900,
    kRotateFlipVertically,
    kRotateFlipHorizantally,
    
};

@interface ImageEditingViewController : UIViewController<UIGestureRecognizerDelegate>
{
    IBOutlet UIButton*galleryButton;
    IBOutlet UIButton*editsButton;
    IBOutlet UIButton*filtersButton;
    IBOutlet UIButton*framesButton;
    IBOutlet UIButton*extrasButton;
    IBOutlet UIButton*saveButton;
    
    
    IBOutlet UIView*editsView;
    IBOutlet UIScrollView*editsScrollView;
    
    
    IBOutlet UIImageView*editingImageView;
    
    SimpleImageAppDelegate*appDelegate;
    
    IBOutlet UIView*main_effects_bottom_view;
    
    IBOutlet UIView*brightness_view;
    IBOutlet UIView*color_view;
    IBOutlet UIView*gaussian_selective_blur_view;//Focal point
    
    IBOutlet UIView*tiltshift_view;
    
    IBOutlet UIView*bulge_distortion_view;//Fisheye
    
    IBOutlet UIView*rotation_view;//rotation_view
    
    IBOutlet UIButton*rotate_button;
    IBOutlet UIButton*flip_vertical_button;
    IBOutlet UIButton*flip_horizontal_button;
    
    
    IBOutlet UIView*apply_cancel_view;
    
    IBOutlet UIButton*btn_close;
    
    
    
    //GPUImage editing
    
    IBOutlet UISlider*brightness_slider;
    IBOutlet UISlider*contrast_slider;

    
    IBOutlet UISlider*saturation_slider;
    IBOutlet UISlider*hue_slider;
    
    IBOutlet UISlider*bulge_distortion_radius_slider;

    
    IBOutlet UISlider* focal_point_focal_size_slider_value;
    IBOutlet UISlider*focal_point_blur_amount_slider_value;
    IBOutlet UISlider* focal_point_color_shift_slider_value;

    
    IBOutlet UISlider* tilt_shift_color_shift_slider_value;
    IBOutlet UISlider*tilt_shift_blur_strength_slider_value;
    IBOutlet UIButton*tilt_shift_hor_or_ver_button;
    
    
    GPUImagePicture *still_image_brightness_source;
    GPUImagePicture *still_image_contrast_source;
    
    GPUImageBrightnessFilter *brightnessFilter;
    GPUImageContrastFilter*contrastFilter;
    GPUImageBulgeDistortionFilter *bulgeDistortionFilter;
    GPUImageGaussianSelectiveBlurFilter *gaussianSelectiveBlurFilter;
    GPUImageTiltShiftFilter*tiltShiftFilter;
    
    GPUImageTiltShiftFilterVertical*tiltShiftFilterVertical;
    
    GPUImageHueFilter*hueFilter;
    GPUImageSaturationFilter*saturationFilter;
    
    //Image Cropper
    
    ImageCropper *imageCropper;
    BOOL image_crop_selected;
    
    int current_image_edit;
    

    UIImage *temp_processed_image;
    BOOL is_image_processessing_running;
    
    NSOperationQueue *queue;
}

@property(nonatomic,strong)IBOutlet UIImageView*editingImageView;
@property (nonatomic,retain)    ImageCropper *imageCropper;

-(IBAction)bottom_menu_button_clicked:(id)sender;

//Brightness effect

- (IBAction)update_brightness_slider_value:(id)sender;
- (IBAction)update_contrast_slider_value:(id)sender;

//color effect

- (IBAction)update_hue_slider_value:(id)sender;
- (IBAction)update_saturation_slider_value:(id)sender;

//Bulge distortion(Fish eye)

- (IBAction)update_bulge_distortion_radius_slider_value:(id)sender;

//Gaussian selective blur(focal point)

- (IBAction)update_focal_point_focal_size_slider_value:(id)sender;
- (IBAction)update_focal_point_blur_amount_slider_value:(id)sender;
- (IBAction)update_focal_point_color_shift_slider_value:(id)sender;

//Tiltshift

- (IBAction)update_tilt_shift_color_shift_slider_value;
- (IBAction)update_tilt_shift_blur_strength_slider_value;
-(IBAction)tilt_shift_hor_or_ver_button_clicked:(id)sender;

-(IBAction)apply_button_pressed:(id)sender;
-(IBAction)discard_button_pressed:(id)sender;

-(IBAction)rotation_effect_selected:(id)sender;

-(void)set_default_slider_values;

@end
