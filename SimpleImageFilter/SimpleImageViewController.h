#import <UIKit/UIKit.h>
#import "GPUImage.h"
#import "SimpleImageAppDelegate.h"

@interface SimpleImageViewController : UIViewController
{
    GPUImagePicture *sourcePicture;
    IBOutlet UISlider *imageSlider;
    
    IBOutlet UISlider *brightness_slider;
    
    
    GPUImageContrastFilter*contrastFilter;
    GPUImageBrightnessFilter *brightnessFilter;
    
    GPUImagePicture *stillImageSource;
    
    UIImageView*topLine;
    UIImageView*bottomLine;
    
    UIImageView*tmpVi;
    
    UIImage *inputImage;
    
    IBOutlet UIImageView*imageView;
    
    SimpleImageAppDelegate*appDelegate;
}

// Image filtering
- (void)setupDisplayFiltering;
- (void)setupImageFilteringToDisk;
- (void)setupImageResampling;

- (IBAction)updateSliderValue:(id)sender;
- (IBAction)update_brightness_slider_value:(id)sender;

@end
