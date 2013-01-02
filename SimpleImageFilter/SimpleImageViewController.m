#import "SimpleImageViewController.h"

@implementation SimpleImageViewController

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle
-(void)viewDidLoad
{
    
    [super viewDidLoad];
    appDelegate = (SimpleImageAppDelegate*)[UIApplication sharedApplication].delegate;
    [self setupDisplayFiltering];
}



#pragma mark -
#pragma mark Image filtering

- (void)setupDisplayFiltering;
{
    
    //inputImage = [UIImage imageNamed:@"image_1.png"];
    inputImage = appDelegate.globalImage;
    
    imageView.image = inputImage;
    stillImageSource = [[GPUImagePicture alloc] initWithImage:inputImage smoothlyScaleOutput:TRUE];
    
    
    brightnessFilter = [[GPUImageBrightnessFilter alloc] init];
    brightnessFilter.brightness = -0.5f;
    
    
    //[stillImageSource addTarget:brightnessFilter];
    //[stillImageSource processImage];
    
    
    contrastFilter = [[GPUImageContrastFilter alloc] init];
    contrastFilter.contrast = 1.0;
    
    //[stillImageSource addTarget:contrastFilter];
    //[stillImageSource processImage];
    
    
    UIImage *currentFilteredVideoFrame = [contrastFilter imageByFilteringImage:inputImage];
    
    
    currentFilteredVideoFrame = [brightnessFilter imageByFilteringImage:currentFilteredVideoFrame];
    
    
    
    
    //UIImage *currentFilteredVideoFrame = [contrastFilter imageByFilteringImage:inputImage];
    
    /*
    tmpVi = [[UIImageView alloc] initWithImage:currentFilteredVideoFrame];
    tmpVi.frame = CGRectMake(0, 0,320,320);
    [self.view addSubview:tmpVi];
    */
    [self.view bringSubviewToFront:imageSlider];
    [self.view bringSubviewToFront:brightness_slider];
    
    
    
    
}

- (IBAction)updateSliderValue:(id)sender
{
    
    CGFloat midpoint = [(UISlider *)sender value];
    
    NSLog(@"\n midpoint = %f",midpoint);
    
    
   // [stillImageSource processImage];
    
    //UIImage *currentFilteredVideoFrame = [contrastFilter imageByFilteringImage:inputImage];
    
    brightnessFilter = [[GPUImageBrightnessFilter alloc] init];
    brightnessFilter.brightness = brightness_slider.value;
    
    
    contrastFilter = [[GPUImageContrastFilter alloc] init];
    contrastFilter.contrast = midpoint;


    
    UIImage *currentFilteredVideoFrame = [contrastFilter imageByFilteringImage:inputImage];
    currentFilteredVideoFrame = [brightnessFilter imageByFilteringImage:currentFilteredVideoFrame];
    imageView.image = currentFilteredVideoFrame;
    
    
    
}


- (IBAction)update_brightness_slider_value:(id)sender
{
    CGFloat midpoint = [(UISlider *)sender value];
    
    NSLog(@"\n midpoint = %f",midpoint);
    
    
    // [stillImageSource processImage];
    
    //UIImage *currentFilteredVideoFrame = [contrastFilter imageByFilteringImage:inputImage];
    
    brightnessFilter = [[GPUImageBrightnessFilter alloc] init];
    brightnessFilter.brightness = midpoint;
    
    
    contrastFilter = [[GPUImageContrastFilter alloc] init];
    contrastFilter.contrast = imageSlider.value;
    
    
    
    UIImage *currentFilteredVideoFrame = [contrastFilter imageByFilteringImage:inputImage];
    currentFilteredVideoFrame = [brightnessFilter imageByFilteringImage:currentFilteredVideoFrame];
    imageView.image = currentFilteredVideoFrame;

}


- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    if (interfaceOrientation == UIInterfaceOrientationPortrait)
    {
        return YES;
    }
    return NO;
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
    
    
     
}
-(void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    NSLog(@"\n touchesMoved");
}

@end
