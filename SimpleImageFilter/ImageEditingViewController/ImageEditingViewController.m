//
//  ImageEditingViewController.m
//  demo_mainpage
//
//  Created by LD.Chirag on 11/22/12.
//  Copyright (c) 2012 LD.Chirag. All rights reserved.
//

#import "ImageEditingViewController.h"
#import "UIImage+Enhancing.h"
#import "MyFilters.h"
#import "ImageCropper.h"
#import <QuartzCore/QuartzCore.h>
#import "UIImage+Resize.h"
#import "Macros.h"

@interface UIImageView (additions)
- (CGSize)imageScale;
@end

@implementation UIImageView (additions)
- (CGSize)imageScale
{
    CGFloat sx = self.frame.size.width / self.image.size.width;
    CGFloat sy = self.frame.size.height / self.image.size.height;
    CGFloat s = 1.0;
    switch (self.contentMode)
    {
        case UIViewContentModeScaleAspectFit:
            s = fminf(sx, sy);
            return CGSizeMake(s, s);
            break;
            
        case UIViewContentModeScaleAspectFill:
            s = fmaxf(sx, sy);
            return CGSizeMake(s, s);
            break;
            
        case UIViewContentModeScaleToFill:
            return CGSizeMake(sx, sy);
            
        default:
            return CGSizeMake(s, s);
    }
}
@end


@interface ImageEditingViewController ()

@end

@implementation ImageEditingViewController
@synthesize editingImageView,imageCropper;
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self)
    {
        // Custom initialization
    }
    return self;
}

-(void)viewWillAppear:(BOOL)animated
{
    self.title = @"PepperMill";
    appDelegate = [UIApplication sharedApplication].delegate;
    
    NSLog(@"\n appDelegate.globalImage width = %f and height = %f",appDelegate.globalImage.size.width,appDelegate.globalImage.size.height);
    
    
    
    /*
     appDelegate.globalImage= [appDelegate.globalImage resizedImageWithContentMode:UIViewContentModeScaleAspectFit bounds:CGSizeMake(appDelegate.globalImage.size.width*0.75,appDelegate.globalImage.size.height*0.75) interpolationQuality:kCGInterpolationHigh];
    */
    
     NSLog(@"\n after appDelegate.globalImage width = %f and height = %f",appDelegate.globalImage.size.width,appDelegate.globalImage.size.height);
    
    

    
    editingImageView.contentMode = UIViewContentModeScaleAspectFit;
    
    editingImageView.image = appDelegate.globalImage;

    CGSize scaled_size = [editingImageView imageScale];
    
    NSLogSize(scaled_size);
    
    
    queue = [[NSOperationQueue alloc]init];
    
    /*
    editingImageView.frame = CGRectMake(0, 0, appDelegate.globalImage.size.width, appDelegate.globalImage.size.height);
    */

    //0.36
    //0.58
    
   // editingImageView.image.scale = 0.58;
    

    
    NSLog(@"\n global ori iamge  w  = %f , h =  %f",appDelegate.globalImage.size.width,appDelegate.globalImage.size.height);
    
    //Hiding filter views
    brightness_view.hidden = TRUE;
    apply_cancel_view.hidden = TRUE;
    color_view.hidden = TRUE;
    gaussian_selective_blur_view.hidden = TRUE;
    bulge_distortion_view.hidden = TRUE;
    tiltshift_view.hidden = TRUE;
    rotation_view.hidden = TRUE;
    
    
    galleryButton.tag = BTN_GALLERY;
    editsButton.tag = BTN_EDITS;
    filtersButton.tag = BTN_FILTERS;
    framesButton.tag = BTN_FRAMES;
    extrasButton.tag = BTN_EXTRAS;
    saveButton.tag = BTN_SAVE;
    
    editsScrollView.contentSize = CGSizeMake(680,73);
    
    for(int i = 0;i<10;i++)
    {
        UIButton*effectButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        effectButton.tag = 2000+i;
        effectButton.frame = CGRectMake((66*i)+10,10,60,60);
        [effectButton addTarget:self action:@selector(effect_buton_clicked:) forControlEvents:UIControlEventTouchUpInside];
        NSString*effect_title_string;
        switch (i)
        {
            case 0:
            {
                effect_title_string = @"Autofix";
                break;
                
            }
            case 1:
            {
                effect_title_string = @"Strighten";
                break;
                
            }
            case 2:
            {
                effect_title_string = @"Brightness";
                break;
                
            }
            case 3:
            {
                effect_title_string = @"Color";
                break;
                
            }
            case 4:
            {
                effect_title_string = @"Focalpoint";
                break;
                
            }
            case 5:
            {
                effect_title_string = @"Tilt&Shift";
                break;
                
            }
            case 6:
            {
                effect_title_string = @"FishEye";
                break;
                
            }
            case 7:
            {
                effect_title_string = @"Crop";
                break;
                
            }
            case 8:
            {
                effect_title_string = @"Rotate";
                break;
                
            }
            case 9:
            {
                effect_title_string = @"Redeye";
                break;
                
            }
                
            
                
            default:
            {
                break;
            }
        
        }
        
        [effectButton setTitle:effect_title_string forState:UIControlStateNormal];
        
        effectButton.titleLabel.font = [UIFont systemFontOfSize:10];
        [editsScrollView addSubview:effectButton];
        
        
    }
    
    
    
    
    
    /*
    editingImageView.frame = [self calcFrameWithImage:editingImageView.image andMaxSize:CGSizeMake(editingImageView.frame.size.width,editingImageView.frame.size.height)];
    */
    NSLog(@"\n  editingImageView = height = %f, width = %f ", editingImageView.frame.size.height,editingImageView.frame.size.width);
    
   // editingImageView.contentMode = UIViewContentModeScaleAspectFit;
    
    
    editsView.hidden = TRUE;
    
    
}
- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(IBAction)bottom_menu_button_clicked:(id)sender
{
    UIButton*tempButton = (UIButton*)sender;
    int tag =tempButton.tag;
    
    switch (tag)
    {
        case 1001:
        {
            
            if(!editsButton.isSelected)
            {
                editsView.hidden = FALSE;
            }
            else
            {
                editsView.hidden = TRUE;
            }
            editsButton.selected = !editsButton.selected;
            break;
            
        }
        default:
        {
            break;
        }
    
    }
    
}

-(void)effect_buton_clicked:(id)sender
{
    UIButton*tempButton = (UIButton*)sender;
    NSLog(@"\n tag = %d",tempButton.tag);
    
    main_effects_bottom_view.hidden = TRUE;
    editsView.hidden = TRUE;
    apply_cancel_view.hidden = FALSE;
    
    current_image_edit = tempButton.tag;
    
    switch (tempButton.tag)
    {
            
        case 2000:
        {
            NSData*temp_image_date = UIImagePNGRepresentation(appDelegate.globalImage);
            UIImage*temp_auto_enhance_image = [UIImage imageWithData:temp_image_date];
            editingImageView.image = [temp_auto_enhance_image autoEnhance];
            break;
            
        }
        case 2001:
        {
            break;
        }

        case 2002:
        {

            brightness_view.hidden = FALSE;
            
           
           
            brightnessFilter = [[GPUImageBrightnessFilter alloc] init] ;
            brightnessFilter.brightness = 0.0f;
            
            //[still_image_brightness_source addTarget:brightnessFilter];
            //[still_image_brightness_source processImage];
            //UIImage *processed_image = [brightnessFilter imageFromCurrentlyProcessedOutput];
            
            
            contrastFilter = [[GPUImageContrastFilter alloc] init] ;
            contrastFilter.contrast = 1.0;
            NSLog(@"\n going to brightness process %@",appDelegate.globalImage);

            UIImage *processed_image = [brightnessFilter imageByFilteringImage:appDelegate.globalImage];
            
            NSLog(@"\n 1 brightness process = %@",processed_image);
            
            
            
            
            
                        
            //[still_image_contrast_source addTarget:contrastFilter];
            //[still_image_contrast_source processImage];
            processed_image = [contrastFilter imageByFilteringImage:processed_image];
            editingImageView.image = processed_image;
            
            NSLog(@"\n brightness process = %@",processed_image);

            
            
            break;
        }

        case 2003:
        {
            color_view.hidden = FALSE;
            
            hueFilter = [[GPUImageHueFilter alloc] init];
            hueFilter.hue = 0.0f;
            UIImage *processed_image = [hueFilter imageByFilteringImage:appDelegate.globalImage];
            
            
            saturationFilter = [[GPUImageSaturationFilter alloc] init];
            saturationFilter.saturation = 1.0;
            processed_image = [saturationFilter imageByFilteringImage:processed_image];
            
            
            editingImageView.image = processed_image;
            
            
            break;
        }

        case 2004:
        {
            gaussian_selective_blur_view.hidden = FALSE;
            gaussianSelectiveBlurFilter = [[GPUImageGaussianSelectiveBlurFilter alloc] init];
            [(GPUImageGaussianSelectiveBlurFilter*)gaussianSelectiveBlurFilter setExcludeCircleRadius:80.0/280.0];
            [(GPUImageGaussianSelectiveBlurFilter*)gaussianSelectiveBlurFilter setExcludeCirclePoint:CGPointMake(0.5f, 0.5f)];
            [(GPUImageGaussianSelectiveBlurFilter*)gaussianSelectiveBlurFilter setAspectRatio:0.85];
            
            gaussianSelectiveBlurFilter.blurSize = 3.0;
            
            
            
            
            UIImage *processed_image = [gaussianSelectiveBlurFilter imageByFilteringImage:appDelegate.globalImage];
             editingImageView.image = processed_image;
            
            break;
        }

        case 2005:
        {
            tiltshift_view.hidden = FALSE;
            
            tiltShiftFilter = [[GPUImageTiltShiftFilter alloc] init];
            tiltShiftFilter.saturationFilter.saturation = 1.0;

            tiltShiftFilterVertical= [[GPUImageTiltShiftFilterVertical alloc] init];
            tiltShiftFilter.saturationFilter.saturation = 1.0;
            
            
            
            UIImage *processed_image = [tiltShiftFilter imageByFilteringImage:appDelegate.globalImage];
            editingImageView.image = processed_image;

            
            break;
        }

        case 2006:
        {
            bulge_distortion_view.hidden = FALSE;
            bulgeDistortionFilter= [[GPUImageBulgeDistortionFilter alloc] init];
            bulgeDistortionFilter.center = CGPointMake(0.5,0.5);
            UIImage *processed_image = [bulgeDistortionFilter imageByFilteringImage:appDelegate.globalImage];
            editingImageView.image = processed_image;
            
            break;
        }

        case 2007:
        {
            
            if(image_crop_selected)
            {
               // [self.imageCropper removeFromSuperview];
            }
            
            CGSize scaled_size = [editingImageView imageScale];
            
            NSLogSize(scaled_size);
            
            /*
            self.imageCropper = [[ImageCropper alloc] initWithImage:appDelegate.globalImage andMaxSize:CGSizeMake(editingImageView.frame.size.width,editingImageView.frame.size.height)];
             */
            
            self.imageCropper = [[ImageCropper alloc] initWithImage:appDelegate.globalImage andMaxSize:CGSizeMake(appDelegate.globalImage.size.width*scaled_size.width,appDelegate.globalImage.size.height*scaled_size.height)];
            
            
            self.imageCropper.backgroundColor = [UIColor redColor];
            
            [self.view addSubview:self.imageCropper];
            [self.imageCropper setHidden:FALSE];
            
            //Frame of image cropper.(identical with imageview frame)
            
            
            
            
            
            self.imageCropper.frame = CGRectMake(20,20,appDelegate.globalImage.size.width*scaled_size.width,appDelegate.globalImage.size.height*scaled_size.height);
            
            
            //self.imageCropper.center = CGPointMake(160,210);
            self.imageCropper.imageView.layer.shadowColor = [[UIColor blackColor] CGColor];
            //self.imageCropper.imageView.layer.shadowRadius = 3.0f;
            self.imageCropper.imageView.layer.shadowOpacity = 0.8f;
            self.imageCropper.imageView.layer.shadowOffset = CGSizeMake(1, 1);
            self.imageCropper.center = editingImageView.center;
            /*
             self.imageCropper.imageView.autoresizingMask=
             UIViewAutoresizingFlexibleLeftMargin |
             UIViewAutoresizingFlexibleWidth        |
             UIViewAutoresizingFlexibleRightMargin |
             UIViewAutoresizingFlexibleTopMargin    |
             UIViewAutoresizingFlexibleHeight       |
             UIViewAutoresizingFlexibleBottomMargin;
             */
            [self.imageCropper addObserver:self forKeyPath:@"crop" options:NSKeyValueObservingOptionNew context:nil];
            
            
            break;
        }

        case 2008:
        {
            rotation_view.hidden = FALSE;
            
            break;
        }
        case 2009:
        {
            NSData*temp_image_date = UIImagePNGRepresentation(appDelegate.globalImage);
            UIImage*temp_auto_enhance_image = [UIImage imageWithData:temp_image_date];
            editingImageView.image = [temp_auto_enhance_image redEyeCorrection];
            break;

            
        }

    
            
        default:
        {
            break;
        }
    
    }
}

//Crop observer

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([object isEqual:self.imageCropper] && [keyPath isEqualToString:@"crop"])
    {
        // [self updateDisplay];
    }
}


//Brightness effect

- (IBAction)update_brightness_slider_value:(id)sender
{
    
    CGFloat midpoint = [(UISlider *)sender value];

    
    [btn_close setTitle:[NSString stringWithFormat:@" %f",midpoint] forState:UIControlStateNormal];
    
    
    /*
    NSOperationQueue *queue = [[NSOperationQueue alloc]init];
    NSInvocationOperation *operation = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(apply_brightness:) object:sender ];
    [queue addOperation:operation];
     */
    //[self performSelector:@selector(apply_brightness:arg2:) withObject:senderß]
    
    
       
    
    /* Original*/
    brightnessFilter = [[GPUImageBrightnessFilter alloc] init] ;
    brightnessFilter.brightness = midpoint;
    
    contrastFilter = [[GPUImageContrastFilter alloc] init] ;
    contrastFilter.contrast = contrast_slider.value;
   
    
    // [still_image_brightness_source processImage];
   // UIImage *processed_image = [brightnessFilter imageFromCurrentlyProcessedOutput];
    
    UIImage *processed_image = [brightnessFilter imageByFilteringImage:appDelegate.globalImage];
    processed_image = [contrastFilter imageByFilteringImage:processed_image];
    
    editingImageView.image = processed_image;
    processed_image = nil;
     

}


- (IBAction)update_contrast_slider_value:(id)sender
{
    CGFloat midpoint = [(UISlider *)sender value];
    
    NSLog(@"\n midpoint = %f",midpoint);
    
[btn_close setTitle:[NSString stringWithFormat:@"  %f",midpoint] forState:UIControlStateNormal];
    
    contrastFilter = [[GPUImageContrastFilter alloc] init] ;
    contrastFilter.contrast = midpoint;
    
    
    brightnessFilter = [[GPUImageBrightnessFilter alloc] init] ;
    brightnessFilter.brightness = brightness_slider.value;
    
   
    
    UIImage *processed_image = [brightnessFilter imageByFilteringImage:appDelegate.globalImage];
    processed_image = [contrastFilter imageByFilteringImage:processed_image];
    
    editingImageView.image = processed_image;

    processed_image = nil;
    

}
- (IBAction)update_hue_slider_value:(id)sender
{
    
    CGFloat midpoint = [(UISlider *)sender value];
    
    [btn_close setTitle:[NSString stringWithFormat:@" %f",midpoint] forState:UIControlStateNormal];
    
    NSLog(@"\n midpoint = %f",midpoint);
    
    hueFilter = [[GPUImageHueFilter alloc] init] ;
    hueFilter.hue = midpoint;
    

    saturationFilter = [[GPUImageSaturationFilter alloc] init] ;
    saturationFilter.saturation = saturation_slider.value;
    
    
    
    UIImage *processed_image = [hueFilter imageByFilteringImage:appDelegate.globalImage];
    processed_image = [saturationFilter imageByFilteringImage:processed_image];
    
    NSLog(@"\n hue processed_image = %@",processed_image);

    
    
    /*
    NSData *dataForPNGFile =UIImageJPEGRepresentation(processed_image, 0.8);
    UIImage*temp_image = [UIImage imageWithData:dataForPNGFile];
    
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
                                                         NSUserDomainMask, YES);
    
    NSString *documentsDirectory = [paths objectAtIndex:0];
    
    NSError *error2 = nil;
    if (![dataForPNGFile writeToFile:[documentsDirectory
                                      stringByAppendingPathComponent:@"FilteredPhoto.jpg"] options:NSAtomicWrite error:&error2])
    {
        
        return;
    }
*/
    
   // editingImageView.image = processed_image;
    
    
    
    //editingImageView.image = nil;
    editingImageView.image = processed_image;
    
    //processed_image = nil;

    
}
- (IBAction)update_saturation_slider_value:(id)sender
{
    
    CGFloat midpoint = [(UISlider *)sender value];
    
    [btn_close setTitle:[NSString stringWithFormat:@" %f",midpoint] forState:UIControlStateNormal];
    
    NSLog(@"\n midpoint saturation= %f",midpoint);
    
    hueFilter = [[GPUImageHueFilter alloc] init] ;
    hueFilter.hue = hue_slider.value;
    
    
    saturationFilter = [[GPUImageSaturationFilter alloc] init] ;
    saturationFilter.saturation = midpoint;
    
    
    
    UIImage *processed_image = [hueFilter imageByFilteringImage:appDelegate.globalImage];
    processed_image = [saturationFilter imageByFilteringImage:processed_image];
    
    
    
    
    editingImageView.image = processed_image;
    
    
    //processed_image = nil;

    
}


- (IBAction)update_bulge_distortion_radius_slider_value:(id)sender
{
    CGFloat midpoint = [(UISlider *)sender value];
    
    [btn_close setTitle:[NSString stringWithFormat:@"  %f",midpoint] forState:UIControlStateNormal];
    
    
    bulgeDistortionFilter.radius = midpoint;
    UIImage *processed_image = [bulgeDistortionFilter imageByFilteringImage:appDelegate.globalImage];
    editingImageView.image = processed_image;
}

//Focal point

- (IBAction)update_focal_point_focal_size_slider_value_touchup_inside:(id)sender
{
    is_image_processessing_running = NO;
    [queue cancelAllOperations];
    
    NSInvocationOperation *operation = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(apply_focal_point_focal_size:) object:sender];
    [queue addOperation:operation];

}

- (IBAction)update_focal_point_focal_size_slider_value:(id)sender
{
 

    
    if(is_image_processessing_running)
    {
       return;
    }
    
    is_image_processessing_running = TRUE;
    
    
    NSInvocationOperation *operation = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(apply_focal_point_focal_size:) object:sender];
    [queue addOperation:operation];
    
       
}
-(void)apply_focal_point_focal_size:(id)sender
{
    CGFloat midpoint = [(UISlider *)sender value];
    //midpoint /=100.0f;
    
    [btn_close setTitle:[NSString stringWithFormat:@"  %f",midpoint] forState:UIControlStateNormal];
    
    NSLog(@"\n midpoint = %f",midpoint);
    
    
    
    
    [(GPUImageGaussianSelectiveBlurFilter*)gaussianSelectiveBlurFilter setExcludeCircleRadius:midpoint];
    
    temp_processed_image = [gaussianSelectiveBlurFilter imageByFilteringImage:appDelegate.globalImage];
    
    
    [(GPUImageGaussianSelectiveBlurFilter*)gaussianSelectiveBlurFilter setBlurSize:focal_point_blur_amount_slider_value.value];
    temp_processed_image = [gaussianSelectiveBlurFilter imageByFilteringImage:appDelegate.globalImage];
    [self performSelectorOnMainThread:@selector(finish_applying_focal_size) withObject:nil waitUntilDone:TRUE];

}
-(void)finish_applying_focal_size
{
    NSLog(@"\n processed_image = %@",temp_processed_image);
    editingImageView.image = temp_processed_image;
    
    is_image_processessing_running = FALSE;
}

- (IBAction)update_focal_point_blur_amount_slider_value_touchUp_inside:(id)sender
{
    is_image_processessing_running = FALSE;
    [queue cancelAllOperations];
    NSInvocationOperation *operation = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(apply_focal_point_blur_size:) object:sender];
    [queue addOperation:operation];

}

- (IBAction)update_focal_point_blur_amount_slider_value:(id)sender
{
    
    
    if(is_image_processessing_running)
    {
        return;
    }
    
    is_image_processessing_running = TRUE;
    
    
    NSInvocationOperation *operation = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(apply_focal_point_blur_size:) object:sender];
    [queue addOperation:operation];
    
    
    
    

    
}
-(void)apply_focal_point_blur_size:(id)sender
{
    
    CGFloat midpoint = [(UISlider *)sender value];
    [btn_close setTitle:[NSString stringWithFormat:@" %f",midpoint] forState:UIControlStateNormal];
    
    [(GPUImageGaussianSelectiveBlurFilter*)gaussianSelectiveBlurFilter setBlurSize:midpoint];
    
    
    temp_processed_image = [gaussianSelectiveBlurFilter imageByFilteringImage:appDelegate.globalImage];
    [self performSelectorOnMainThread:@selector(finish_applying_focal_point_blur_size) withObject:nil waitUntilDone:TRUE];
    
    
    
}
-(void)finish_applying_focal_point_blur_size
{
    editingImageView.image = temp_processed_image;
    is_image_processessing_running = FALSE;
}


- (IBAction)update_focal_point_color_shift_slider_value_touchUp_inside:(id)sender
{
    is_image_processessing_running = NO;
    
    [queue cancelAllOperations];
    
    NSInvocationOperation *operation = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(apply_focal_point_color_shift:) object:sender];
    [queue addOperation:operation];

}

- (IBAction)update_focal_point_color_shift_slider_value:(id)sender
{
    
    
    if(is_image_processessing_running)
    {
        return;
    }
    
    is_image_processessing_running = TRUE;
    
    
    NSInvocationOperation *operation = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(apply_focal_point_color_shift:) object:sender];
    [queue addOperation:operation];

    
    
    
}

-(void)apply_focal_point_color_shift:(id)sender
{
    CGFloat midpoint = [(UISlider *)sender value];
    
    NSLog(@"\n midpoint = %f",midpoint);
    
    [btn_close setTitle:[NSString stringWithFormat:@" %f",midpoint] forState:UIControlStateNormal];
    
    //[(GPUImageSaturationFilter*)stillImageFilter setSaturation:midpoint];
    gaussianSelectiveBlurFilter.saturationFilter.saturation = midpoint;
    
    
    temp_processed_image= [gaussianSelectiveBlurFilter imageByFilteringImage:appDelegate.globalImage];
    
    
    [self performSelectorOnMainThread:@selector(finish_apply_focal_point_color_shift) withObject:nil waitUntilDone:TRUE];
    
    
}
-(void)finish_apply_focal_point_color_shift
{
    editingImageView.image = temp_processed_image;
    is_image_processessing_running = NO;
}

//Tiltshift

- (IBAction)update_tilt_shift_color_shift_slider_value_touchUp_inside
{
    is_image_processessing_running = NO;
    [queue cancelAllOperations];
    NSInvocationOperation *operation = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(apply_tiltshift_color_shift) object:nil];
    [queue addOperation:operation];
}

- (IBAction)update_tilt_shift_color_shift_slider_value
{
    
    
    if(is_image_processessing_running)
    {
        return;
    }
    
    is_image_processessing_running = TRUE;
    
    
    NSInvocationOperation *operation = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(apply_tiltshift_color_shift) object:nil];
    [queue addOperation:operation];

    


    
}

-(void)apply_tiltshift_color_shift
{
    
    if(tilt_shift_hor_or_ver_button.selected)
    {
        
        tiltShiftFilterVertical= [[GPUImageTiltShiftFilterVertical alloc] init];
        tiltShiftFilterVertical.saturationFilter.saturation = tilt_shift_color_shift_slider_value.value;
        tiltShiftFilterVertical.blurSize = tilt_shift_blur_strength_slider_value.value;
        
        
        
        
        temp_processed_image = [tiltShiftFilterVertical imageByFilteringImage:appDelegate.globalImage];
        
        
    }
    else
    {
        tiltShiftFilter = [[GPUImageTiltShiftFilter alloc] init];
        
        
        tiltShiftFilter.saturationFilter.saturation = tilt_shift_color_shift_slider_value.value;
        tiltShiftFilter.blurSize = tilt_shift_blur_strength_slider_value.value;
        
        
        
        temp_processed_image = [tiltShiftFilter imageByFilteringImage:appDelegate.globalImage];
        
        
    }
    [self performSelectorOnMainThread:@selector(finish_apply_tiltshift_color_shift) withObject:nil waitUntilDone:TRUE];
    
}

-(void)finish_apply_tiltshift_color_shift
{
    editingImageView.image = temp_processed_image;
    is_image_processessing_running = NO;
}



- (IBAction)update_tilt_shift_blur_strength_slider_value_touchUp_inside
{
    is_image_processessing_running = NO;
    [queue cancelAllOperations];
    
    NSInvocationOperation *operation = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(apply_tilt_shift_blur_strength) object:nil];
    [queue addOperation:operation];
    
}


- (IBAction)update_tilt_shift_blur_strength_slider_value
{
    
    if(is_image_processessing_running)
    {
        return;
    }
    
    is_image_processessing_running = TRUE;
    
    
    NSInvocationOperation *operation = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(apply_tilt_shift_blur_strength) object:nil];
    [queue addOperation:operation];
    

}

-(void)apply_tilt_shift_blur_strength
{
    if(tilt_shift_hor_or_ver_button.selected)
    {
        
        tiltShiftFilterVertical= [[GPUImageTiltShiftFilterVertical alloc] init];
        tiltShiftFilterVertical.saturationFilter.saturation = tilt_shift_color_shift_slider_value.value;
        tiltShiftFilterVertical.blurSize = tilt_shift_blur_strength_slider_value.value;
        
        
        
        
        temp_processed_image = [tiltShiftFilterVertical imageByFilteringImage:appDelegate.globalImage];
        
        
    }
    else
    {
        tiltShiftFilter = [[GPUImageTiltShiftFilter alloc] init];
        
        
        tiltShiftFilter.saturationFilter.saturation = tilt_shift_color_shift_slider_value.value;
        tiltShiftFilter.blurSize = tilt_shift_blur_strength_slider_value.value;
        
        
        
        temp_processed_image = [tiltShiftFilter imageByFilteringImage:appDelegate.globalImage];
        
        
    }
    
    [self performSelectorOnMainThread:@selector(finish_apply_tilt_shift_blur_strength) withObject:nil waitUntilDone:TRUE];

}

-(void)finish_apply_tilt_shift_blur_strength
{
    editingImageView.image = temp_processed_image;
    is_image_processessing_running = NO;
}

-(IBAction)tilt_shift_hor_or_ver_button_clicked:(id)sender
{
    UIButton*temp_button = (UIButton*)sender;
    temp_button.selected =  !temp_button.selected;
    
    if(temp_button.selected)
    {
        
        tiltShiftFilterVertical= [[GPUImageTiltShiftFilterVertical alloc] init];
        tiltShiftFilterVertical.saturationFilter.saturation = tilt_shift_color_shift_slider_value.value;
        tiltShiftFilterVertical.blurSize = tilt_shift_blur_strength_slider_value.value;
        
        
        
        
        UIImage *processed_image = [tiltShiftFilterVertical imageByFilteringImage:appDelegate.globalImage];
        editingImageView.image = processed_image;

    }
    else
    {
        tiltShiftFilter = [[GPUImageTiltShiftFilter alloc] init];
       
        
        tiltShiftFilter.saturationFilter.saturation = tilt_shift_color_shift_slider_value.value;
        tiltShiftFilter.blurSize = tilt_shift_blur_strength_slider_value.value;

        
        
        UIImage *processed_image = [tiltShiftFilter imageByFilteringImage:appDelegate.globalImage];
        editingImageView.image = processed_image;

    }
    
    
}
-(IBAction)apply_button_pressed:(id)sender
{
    
    
    main_effects_bottom_view.hidden = FALSE;
    editsView.hidden = FALSE;
    
    apply_cancel_view.hidden = TRUE;
    
    
    NSLog(@"\n global image in apply = %@",appDelegate.globalImage);
    
    NSLog(@"\n image in apply = %@",editingImageView.image);
    
    [self set_default_slider_values];
    
    //appDelegate.globalImage = editingImageView.image;
    
    appDelegate.globalImage = [UIImage imageWithCGImage:[editingImageView.image CGImage]]  ;
    
    /*Chirag:pending.Issue of crashing.
    
    NSData *dataForPNGFile =UIImagePNGRepresentation(appDelegate.globalImage);
    
    
    // NSLog(@"\n dataForPNGFile = %@",dataForPNGFile);
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
                                                         NSUserDomainMask, YES);
    
    NSString *documentsDirectory = [paths objectAtIndex:0];
    
    NSError *error2 = nil;
    if (![dataForPNGFile writeToFile:[documentsDirectory
                                      stringByAppendingPathComponent:@"FilteredPhoto.jpg"] options:NSAtomicWrite error:&error2])
    {
        
        return;
    }
    */
    
    switch (current_image_edit)
    {
            
        case 2000:
        {
            
            break;
            
        }
        case 2001:
        {
            break;
        }
            
        case 2002:
        {
            
            brightness_view.hidden = TRUE;
            break;
        }
            
        case 2003:
        {
            color_view.hidden = TRUE;
            break;
        }
            
        case 2004:
        {
            gaussian_selective_blur_view.hidden = TRUE;
            break;
        }
            
        case 2005:
        {
            tiltshift_view.hidden = TRUE;
            break;
        }
            
        case 2006:
        {
            bulge_distortion_view.hidden = TRUE;
            break;
        }
            
        case 2007:
        {
            break;
        }
            
        case 2008:
        {
            rotation_view.hidden = TRUE;
            break;
        }
        case 2009:
        {
            break;
        }
            
            
            
        default:
        {
            break;
        }
            
    }
    

}
-(IBAction)discard_button_pressed:(id)sender
{
    main_effects_bottom_view.hidden = FALSE;
    editsView.hidden = FALSE;
    
    apply_cancel_view.hidden = TRUE;
    editingImageView.image = appDelegate.globalImage;
    
    [self set_default_slider_values];
    switch (current_image_edit)
    {
            
        case 2000:
        {
            
            break;
            
        }
        case 2001:
        {
            break;
        }
            
        case 2002:
        {
            
            brightness_view.hidden = TRUE;
            break;
        }
            
        case 2003:
        {
            color_view.hidden = TRUE;
            break;
        }
            
        case 2004:
        {
            gaussian_selective_blur_view.hidden = TRUE;
            break;
        }
            
        case 2005:
        {
            tiltshift_view.hidden = TRUE;
            break;
        }
            
        case 2006:
        {
            bulge_distortion_view.hidden = TRUE;
            break;
        }
            
        case 2007:
        {
            [self.imageCropper removeFromSuperview];
            break;
        }
            
        case 2008:
        {
            rotation_view.hidden = TRUE;
            break;
        }
        case 2009:
        {
            break;
        }
            
            
            
        default:
        {
            break;
        }
            
    }


}

-(IBAction)rotation_effect_selected:(id)sender
{
    
    
    switch ([sender tag])
    {
        case kRotateClock:
        {
            editingImageView.image = [UIImage CIAffineTransformWithInputImage:editingImageView.image andRotationAngle:-90];
            break;
            
        }
        case kRotateFlipVertically:
        {
            editingImageView.image = [UIImage CIAffineTransformWithInputImage:editingImageView.image andScaleX:1.0 ScaleY:-1.0];
            break;

        }
        case kRotateFlipHorizantally:
        {
            editingImageView.image = [UIImage CIAffineTransformWithInputImage:editingImageView.image andScaleX:-1.0 ScaleY:1.0];
            break;
            
        }
        default:
        {
            break;
        }
           
            
       

}
    editingImageView.contentMode = UIViewContentModeScaleAspectFit;
    NSLog(@"\n image height = %f",editingImageView.image.size.height);
    NSLog(@"\n image width = %f",editingImageView.image.size.width);
    
}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    NSLog(@"\n touches begin");
}
-(void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    NSLog(@"\n touchesCancelled");
}
-(void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    NSLog(@"\n touchesEnded");
    
    UITouch *touch = [[event allTouches] anyObject];
    CGPoint location = [touch locationInView:touch.view];
    NSLog(@"X: %f",location.x);
    NSLog(@"Y: %f",location.y);
    
    
    /* GPUImageGaussianSelectiveBlurFilter
     [(GPUImageGaussianSelectiveBlurFilter*)gaussianSelectiveBlurFilter setExcludeCirclePoint:CGPointMake(location.x/320.0f, location.y/460.0f)];
     [stillImageSource processImage];
     
     
     UIImage *currentFilteredVideoFrame = [gaussianSelectiveBlurFilter imageFromCurrentlyProcessedOutput];
     tmpVi.image = currentFilteredVideoFrame;
     */
    
    switch (current_image_edit)
    {
        case 2004:
        {
            [(GPUImageGaussianSelectiveBlurFilter*)gaussianSelectiveBlurFilter setExcludeCirclePoint:CGPointMake(location.x/280.0f, location.y/333.0f)];
            
           
            UIImage *processed_image = [gaussianSelectiveBlurFilter imageByFilteringImage:appDelegate.globalImage];

            editingImageView.image = processed_image;
            break;
        }
        case 2006:
        {
            bulgeDistortionFilter.center = CGPointMake(location.x/280.0f, location.y/333.0f);
            UIImage *processed_image = [bulgeDistortionFilter imageByFilteringImage:appDelegate.globalImage];
            editingImageView.image = processed_image;
            break;
            
        }
            
        default:
        {
            break;
        }
    
    }
    
   
    
    
}
-(void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    NSLog(@"\n touchesMoved");
}


- (CGRect)calcFrameWithImage:(UIImage*)image andMaxSize:(CGSize)maxSize
{
    CGFloat increase = IMAGE_CROPPER_OUTSIDE_STILL_TOUCHABLE * 1.2;
    CGFloat imageScale;
    // if it already fits, return that
    
    //CGRect noScale = CGRectMake(0.0, 20.0, maxSize.width, maxSize.height );
    // return noScale;
    
    CGRect noScale = CGRectMake(0.0, 0.0, image.size.width + increase, image.size.height + increase);
    
    if (CGWidth(noScale) <= maxSize.width && CGHeight(noScale) <= maxSize.height)
    {
        imageScale = 1.0;
        return noScale;
    }
    
    CGRect scaled;
    
    // first, try scaling the height to fit
    imageScale = (maxSize.height - increase) / image.size.height;
    scaled = CGRectMake(0.0, 0.0, image.size.width * imageScale + increase, image.size.height * imageScale + increase);
    if (CGWidth(scaled) <= maxSize.width && CGHeight(scaled) <= maxSize.height) {
        return scaled;
    }
    
    // scale with width if that failed
    imageScale = (maxSize.width - increase) / image.size.width;
    scaled = CGRectMake(0.0, 0.0, image.size.width * imageScale + increase, image.size.height * imageScale + increase);
    
    NSLogRect(scaled);
    
    return scaled;
}

-(void)set_default_slider_values
{
    
    //Brightnessview
    brightness_slider.value = 0.0;
    contrast_slider.value = 2.0;
    
    //ColorView
    
    saturation_slider.value = 1.0;
    hue_slider.value = 0.0;
    
    
    
    
    //bulge_distortion view
    bulge_distortion_radius_slider.value = 0.5;

    
    //Gaussian selective blur
    
    focal_point_focal_size_slider_value.value = 0.25;
    focal_point_color_shift_slider_value.value =1;
    focal_point_blur_amount_slider_value.value = 1;
    
    //tilt shift view
    
    tilt_shift_blur_strength_slider_value.value = 1.0;
    tilt_shift_color_shift_slider_value.value = 1.0f;
    
    
    
    
    
    
}

@end
