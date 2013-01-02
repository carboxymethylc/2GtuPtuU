//
//  ViewController.m
//  demo_mainpage
//
//  Created by LD.Chirag on 11/18/12.
//  Copyright (c) 2012 LD.Chirag. All rights reserved.
//

#import "ViewController.h"
#import "FBLikeViewController.h"
#import "SimpleImageViewController.h"
#import "ImageEditingViewController.h"

@interface ViewController ()

@end

@implementation ViewController

#pragma mark -
#pragma mark Initialization and teardown

- (id)initWithFilterType:(GPUImageShowcaseFilterType)newFilterType;
{
    self = [super initWithNibName:@"ViewController" bundle:nil];
    if (self)
    {
        filterType = newFilterType;
    }
    return self;
}

-(void)viewWillAppear:(BOOL)animated
{
    self.title = @"Peppermill";
    appDelegate = [UIApplication sharedApplication].delegate;
    filterType = GPUIMAGE_NORMAL;
    lenseEffectView.hidden = TRUE;
    [self hideAllSettingsView];
    
    [self setupFilter];
    
    [super viewWillAppear:animated];
}



- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    
    
    tiltshift_left_line.tag =  tiltshift_left_line_tag;
    tiltshift_right_line.tag =  tiltshift_right_line_tag;
    
    tiltshift_top_line.tag =  tiltshift_top_line_tag;
    tiltshift_bottom_line.tag =  tiltshift_bottom_line_tag;
    
    
    
    
    UIButton*imageGalleryButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [imageGalleryButton setTitle:@"Gallery" forState:UIControlStateNormal];
    imageGalleryButton.frame = CGRectMake(0, 0,44,44);

    
    
    UIButton*faceBookLikeButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [faceBookLikeButton setTitle:@"FB" forState:UIControlStateNormal];
    [faceBookLikeButton addTarget:self action:@selector(fbButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
    faceBookLikeButton.frame = CGRectMake(0, 0,44,44);

    
    
    
    //UIBarButtonItem *rightBarButtonItem = [[[UIBarButtonItem alloc] initWithCustomView:imageGalleryButton] autorelease];
    //self.navigationItem.rightBarButtonItem = rightBarButtonItem;

    
    
    
    UIBarButtonItem *leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:faceBookLikeButton];
    self.navigationItem.leftBarButtonItem = leftBarButtonItem;

    
    
    //
    
    galleryImagePickerController = [[UIImagePickerController alloc] init];
    galleryImagePickerController.delegate = self;
    galleryImagePickerController.sourceType=UIImagePickerControllerSourceTypePhotoLibrary;
    
    [cameraFilterView setUserInteractionEnabled:TRUE];
    [tiltshift_top_line setUserInteractionEnabled:TRUE];
    [tiltshift_bottom_line setUserInteractionEnabled:TRUE];
    
    [self addGestureRecognizersToPiece:tiltshift_top_line];
    [self addGestureRecognizersToPiece:tiltshift_bottom_line];
    
    
    
}
-(void)viewDidAppear:(BOOL)animated
{
    
    [super viewDidAppear:animated];
    [videoCamera startCameraCapture];
}
- (void)viewWillDisappear:(BOOL)animated
{
    // Note: I needed to stop camera capture before the view went off the screen in order to prevent a crash from the camera still sending frames
    [videoCamera stopCameraCapture];
	[super viewWillDisappear:animated];
}

#pragma mark - focalEffectButton_Clicked
-(IBAction)focalEffectButton_Clicked:(id)sender
{
    //[videoCamera removeTarget:filter];
    [self hideAllSettingsView];
    foculPointSettingsView.hidden = FALSE;
    closeSettingsView.hidden = FALSE;
    
    filterType = GPUIMAGE_FOCALPOINT;
    [videoCamera removeAllTargets];
        tempOutput = gaussianSelectiveBlurFilter;
    [videoCamera addTarget:gaussianSelectiveBlurFilter];
    [gaussianSelectiveBlurFilter addTarget:filterView];
    
    lenseEffectView.hidden = TRUE;
    
}
#pragma mark - fishEyeEffectButton_Clicked
-(IBAction)fishEyeEffectButton_Clicked:(id)sender
{
    [self hideAllSettingsView];
    fishEyeSettingsView.hidden = FALSE;
    closeSettingsView.hidden = FALSE;
    
    filterType = GPUIMAGE_FISHEYE;
    [videoCamera removeAllTargets];
    
    [videoCamera addTarget:bulgeDistortionFilter];
    [bulgeDistortionFilter addTarget:filterView];

    
    lenseEffectView.hidden = TRUE;
}

#pragma mark - tiltShiftVerticalEffectButton_Clicked

-(IBAction)tiltShiftVerticalEffectButton_Clicked:(id)sender
{
    [self hideAllSettingsView];
    tiltShiftVerticalSettingsView.hidden = FALSE;
    closeSettingsView.hidden = FALSE;
    
    filterType = GPUIMAGE_TILTSHIFTVERTICAL;
    [videoCamera removeAllTargets];
    
    
    [videoCamera addTarget:tiltShiftFilterVertical];
    [tiltShiftFilterVertical addTarget:filterView];

    
    
    lenseEffectView.hidden = TRUE;
}

#pragma mark - tiltShiftHorizontalEffectButton_Clicked

-(IBAction)tiltShiftHorizontalEffectButton_Clicked:(id)sender
{
    [self hideAllSettingsView];
    tiltShiftHorizontalSettingsView.hidden = FALSE;
    closeSettingsView.hidden = FALSE;
    
    filterType = GPUIMAGE_TILTSHIFTHORIZONTAL;
    [videoCamera removeAllTargets];
    
    [videoCamera addTarget:tiltShiftFilter];
    [tiltShiftFilter addTarget:filterView];

    
    lenseEffectView.hidden = TRUE;
}

#pragma mark - clear_effects_button_clicked

-(IBAction)clear_effects_button_clicked:(id)sender
{
    [self hideAllSettingsView];
    lenseEffectView.hidden = TRUE;
    [videoCamera removeAllTargets];
    [videoCamera addTarget:filter];
}

#pragma mark - hideAllSettingsView

-(void)hideAllSettingsView
{
    
    fishEyeSettingsView.hidden = TRUE;
    foculPointSettingsView.hidden = TRUE;
    
    tiltShiftHorizontalSettingsView.hidden = TRUE;
    tiltShiftVerticalSettingsView.hidden = TRUE;
    closeSettingsView.hidden = TRUE;
    
    
}



#pragma mark - lenseButton_Clicked

-(IBAction)lenseButton_Clicked:(id)sender
{
     lenseEffectView.hidden = FALSE;
}

#pragma mark - fbButtonClicked

-(void)fbButtonClicked:(id)sender
{
    
    FBLikeViewController*viewController = [[FBLikeViewController alloc] initWithNibName:@"FBLikeViewController" bundle:nil];
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:viewController];
    [self.navigationController presentModalViewController:navController animated:TRUE];
    
}

#pragma mark - setupFilter

- (void)setupFilter;
{
    
    /*
     videoCamera = [[GPUImageStillCamera alloc] initWithSessionPreset:AVCaptureSessionPreset640x480 cameraPosition:AVCaptureDevicePositionBack];
     */
    
    videoCamera = [[GPUImageStillCamera alloc] init];
    videoCamera.outputImageOrientation = UIInterfaceOrientationPortrait;
    
    
    
    
    
    filter = [[GPUImageSepiaFilter alloc] init];
    filter.intensity = 0.0;
    videoCamera.runBenchmark = YES;
    
    [videoCamera addTarget:filter];
    filterView = (GPUImageView *)cameraFilterView;
    [filter addTarget:filterView];

    
     /*Starts: gaussianSelectiveBlurFilter */
    gaussianSelectiveBlurFilter = [[GPUImageGaussianSelectiveBlurFilter alloc] init];
    [(GPUImageGaussianSelectiveBlurFilter*)gaussianSelectiveBlurFilter setExcludeCircleRadius:80.0/301.0];
    [(GPUImageGaussianSelectiveBlurFilter*)gaussianSelectiveBlurFilter setExcludeCirclePoint:CGPointMake(0.5f, 0.5f)];
    [(GPUImageGaussianSelectiveBlurFilter*)gaussianSelectiveBlurFilter setAspectRatio:1.20];// height/width
    gaussianSelectiveBlurFilter.saturationFilter.saturation = 0.0;
    gaussianSelectiveBlurFilter.blurSize = 2.0;
/*Ends: gaussianSelectiveBlurFilter */
    
/*Starts: GPUImageBulgeDistortionFilter */
    bulgeDistortionFilter= [[GPUImageBulgeDistortionFilter alloc] init];
    bulgeDistortionFilter.center = CGPointMake(0.5,0.5);
    bulgeDistortionFilter.radius = 0.25f;
/*Ends: GPUImageBulgeDistortionFilter */

    
    /*Starts: GPUImageTiltShiftFilter */

    tiltShiftFilter = [[GPUImageTiltShiftFilter alloc] init];
    tiltShiftFilter.saturationFilter.saturation = 1.0;
    tiltShiftFilter.blurSize = 2.0f;
    /*Ends: GPUImageTiltShiftFilter */

    
    /*Starts: GPUImageTiltShiftFilterVertical */
    
    tiltShiftFilterVertical = [[GPUImageTiltShiftFilterVertical alloc] init];
    tiltShiftFilterVertical.saturationFilter.saturation = 1.0;
    tiltShiftFilterVertical.blurSize = 2.0f;
    
    /*Starts: GPUImageTiltShiftFilterVertical */
    
    
    NSLog(@"\n filterView x = %f",filterView.frame.origin.x);
    NSLog(@"\n filterView y = %f",filterView.frame.origin.y);
    NSLog(@"\n filterView height= %f",filterView.frame.size.height);
    NSLog(@"\n filterView width = %f",filterView.frame.size.width);
    
    
    [videoCamera startCameraCapture];

}

#pragma mark - close_settings_view

-(IBAction)close_settingsview_button_clicked:(id)sender;
{
    [self hideAllSettingsView];
    
}


#pragma mark - Fish Eye

#pragma mark - update_fisheye_slider_value
- (IBAction)update_fisheye_slider_value:(id)sender
{
    CGFloat midpoint = [(UISlider *)sender value];
    bulgeDistortionFilter.radius = midpoint;
    

}

#pragma mark - Focal Point

#pragma mark - update_focal_size_slider


- (IBAction)update_focal_size_slider:(id)sender
{

    CGFloat midpoint = [(UISlider *)sender value];
    midpoint /=100.0f;
    NSLog(@"\n midpoint = %f",midpoint);
    
    [(GPUImageGaussianSelectiveBlurFilter*)gaussianSelectiveBlurFilter setExcludeCircleRadius:midpoint];

    
}

#pragma mark - update_blur_amount_slider
- (IBAction)update_blur_amount_slider:(id)sender
{
    CGFloat midpoint = [(UISlider *)sender value];
    [(GPUImageGaussianSelectiveBlurFilter*)gaussianSelectiveBlurFilter setBlurSize:midpoint];

}

#pragma mark - update_color_shift_slider
- (IBAction)update_color_shift_slider:(id)sender
{
    CGFloat midpoint = [(UISlider *)sender value];
    NSLog(@"\n update_color_shift_slider = %f",midpoint);
    gaussianSelectiveBlurFilter.saturationFilter.saturation = midpoint;
}

#pragma mark - Vertical Tilt Shift

#pragma mark - update_tiltshiftV_blur_amount_slider


- (IBAction)update_tiltshiftV_blur_amount_slider:(id)sender
{
    CGFloat midpoint = [(UISlider *)sender value];
    NSLog(@"\n update_tiltshiftV_color_shift_slider = %f",midpoint);
    tiltShiftFilterVertical.blurSize = midpoint;
}

#pragma mark - update_tiltshiftV_color_shift_slider

- (IBAction)update_tiltshiftV_color_shift_slider:(id)sender
{
    CGFloat midpoint = [(UISlider *)sender value];
    NSLog(@"\n update_tiltshiftV_color_shift_slider = %f",midpoint);

    tiltShiftFilterVertical.saturationFilter.saturation = midpoint;
}


#pragma mark - Horizotnal Tilt Shift


#pragma mark - update_tiltshiftH_blur_amount_slider

- (IBAction)update_tiltshiftH_blur_amount_slider:(id)sender
{
    CGFloat midpoint = [(UISlider *)sender value];
    NSLog(@"\n update_tiltshiftV_color_shift_slider = %f",midpoint);
    
    tiltShiftFilter.blurSize = midpoint;

}

#pragma mark - update_tiltshiftH_color_shift_slider

- (IBAction)update_tiltshiftH_color_shift_slider:(id)sender
{
    CGFloat midpoint = [(UISlider *)sender value];
    NSLog(@"\n update_tiltshiftV_color_shift_slider = %f",midpoint);
    
    tiltShiftFilter.saturationFilter.saturation = midpoint;

}



#pragma mark - captureImage

-(IBAction)captureImage:(id)sender
{
       
    
    
    switch (filterType)
    {
        case GPUIMAGE_FOCALPOINT:
        {
            
            
            [videoCamera
             capturePhotoAsImageProcessedUpToFilter:gaussianSelectiveBlurFilter withCompletionHandler:^(UIImage
                                                                                   *processedImage, NSError *error)
             {
                 
                 appDelegate.globalImage = processedImage;
                 UIImageWriteToSavedPhotosAlbum(processedImage,nil, nil, nil);
                 /*
                 NSData *dataForPNGFile =UIImageJPEGRepresentation(processedImage, 0.8);
                 
                 
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
             }
             ];

            
            
            break;
            
        }
        case GPUIMAGE_FISHEYE:
        {
            
            [videoCamera
             capturePhotoAsImageProcessedUpToFilter:bulgeDistortionFilter withCompletionHandler:^(UIImage
                                                                                                        *processedImage, NSError *error)
             {
                 
                 appDelegate.globalImage = processedImage;
                 UIImageWriteToSavedPhotosAlbum(processedImage,nil, nil, nil);
                 /*
                 NSData *dataForPNGFile =UIImageJPEGRepresentation(processedImage, 0.8);
                 
                 
                 //NSLog(@"\n dataForPNGFile = %@",dataForPNGFile);
                 
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
             }
             ];
            

            
            break;
        }
        case GPUIMAGE_TILTSHIFTHORIZONTAL:
        {
            
            
            [videoCamera
             capturePhotoAsImageProcessedUpToFilter:tiltShiftFilter withCompletionHandler:^(UIImage
                                                                                                  *processedImage, NSError *error)
             {
                 
                 appDelegate.globalImage = processedImage;
                  UIImageWriteToSavedPhotosAlbum(processedImage,nil, nil, nil);
                 
                 /*
                 NSData *dataForPNGFile =UIImageJPEGRepresentation(processedImage, 0.8);
                 
                 
               //  NSLog(@"\n dataForPNGFile = %@",dataForPNGFile);
                 
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
                  
             }
             ];

            
            break;
        }
        case GPUIMAGE_TILTSHIFTVERTICAL:
        {
            
            [videoCamera
             capturePhotoAsImageProcessedUpToFilter:tiltShiftFilterVertical withCompletionHandler:^(UIImage
                                                                                                  *processedImage, NSError *error)
             {
                 
                 appDelegate.globalImage = processedImage;
                 UIImageWriteToSavedPhotosAlbum(processedImage,nil, nil, nil);
                 
                 /*
                 NSData *dataForPNGFile =UIImageJPEGRepresentation(processedImage, 0.8);
                 
                 
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
             }
             ];

            
            break;
        }
        
        case GPUIMAGE_NORMAL:
        {
            [videoCamera
             capturePhotoAsImageProcessedUpToFilter:filter withCompletionHandler:^(UIImage
                                                                                   *processedImage, NSError *error)
             {
                 
                 appDelegate.globalImage = processedImage;
                 UIImageWriteToSavedPhotosAlbum(processedImage,nil, nil, nil);
                 
                 /*
                 NSData *dataForPNGFile =UIImageJPEGRepresentation(processedImage, 0.8);
                 
                 
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
             }
             ];
            
            break;

        }
        default:
        {
            
            
            [videoCamera
             capturePhotoAsImageProcessedUpToFilter:filter withCompletionHandler:^(UIImage
                                                                                                  *processedImage, NSError *error)
             {
                 
                 appDelegate.globalImage = processedImage;
                 UIImageWriteToSavedPhotosAlbum(processedImage,nil, nil, nil);
                 
                 /*
                 NSData *dataForPNGFile =UIImageJPEGRepresentation(processedImage, 0.8);
                 
                 
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
             }
             ];
            
            break;
        }
    
    }
    
    ImageEditingViewController*viewController = [[ImageEditingViewController alloc] initWithNibName:@"ImageEditingViewController" bundle:nil];
    [self.navigationController pushViewController:viewController animated:TRUE];

    
}

#pragma mark - galler_button_pressed Method

-(IBAction)galler_button_pressed:(id)sender
{
    [self presentModalViewController:galleryImagePickerController animated:YES];
}
#pragma mark - ImagePicker Delegation Method

-(void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [self dismissModalViewControllerAnimated:NO];
    //[self pictureFromCamera:nil];
    
}

-(void)imagePickerController:(UIImagePickerController *)picker didFinishPickingImage:(UIImage *)image editingInfo:(NSDictionary *)editingInfo
{
    
   // appDelegate.globalImage = image;
    NSData *dataForPNGFile =UIImageJPEGRepresentation(image, 0.8);
    UIImage*temp_image = [UIImage imageWithData:dataForPNGFile];
    
    appDelegate.globalImage = image;
    [self dismissModalViewControllerAnimated:YES];
    
    /*
    SimpleImageViewController*viewController = [[SimpleImageViewController alloc] initWithNibName:@"SimpleImageViewController" bundle:nil];
    [self.navigationController pushViewController:viewController animated:TRUE];
     */
    
    ImageEditingViewController*viewController = [[ImageEditingViewController alloc] initWithNibName:@"ImageEditingViewController" bundle:nil];
    [self.navigationController pushViewController:viewController animated:TRUE];
    
     
    
    
}

#pragma mark - Touch Methods

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    NSLog(@"\n touches begin");
    UITouch *touch = [touches anyObject];
    
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
    
    switch (filterType)
    {
        case GPUIMAGE_FOCALPOINT:
        {

            [(GPUImageGaussianSelectiveBlurFilter*)gaussianSelectiveBlurFilter setExcludeCirclePoint:CGPointMake(location.x/301.0f, location.y/360.0f)];
            break;
            
        }
            case GPUIMAGE_FISHEYE:
        {
            bulgeDistortionFilter.center = CGPointMake(location.x/301.0f, location.y/360.0f);
            break;
        }
            
        default:
            break;
    }
        
    
        
    
    
    
    
    
    
     
    
}
-(void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    /*
    NSLog(@"\n touchesMoved");
    UITouch *touch = [[event allTouches] anyObject];
    
    CGPoint location = [touch locationInView:touch.view];
    //CGPoint location = CGPointMake(lineTop.frame.origin.x, lineTop.frame.origin.y);
    NSLog(@"X: %f",location.x);
    NSLog(@"Y: %f",location.y);
    
    */
    
    
    
}


#pragma mark - Gesture Recoginer methods


- (void)addGestureRecognizersToPiece:(UIView *)piece
{
    UIRotationGestureRecognizer *rotationGesture = [[UIRotationGestureRecognizer alloc] initWithTarget:self action:@selector(rotatePiece:)];
    [piece addGestureRecognizer:rotationGesture];
    
    
    UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panPiece:)];
    [panGesture setMaximumNumberOfTouches:2];
    [panGesture setDelegate:self];
    [piece addGestureRecognizer:panGesture];
    
    
    UITapGestureRecognizer *tapGesture=[[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(tapGesture:)];
    [piece addGestureRecognizer:tapGesture];
    [tapGesture setNumberOfTapsRequired:1];
    
    
    UITapGestureRecognizer *doubletapGesture2=[[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(doubleTapForImage:)];
    [piece addGestureRecognizer:doubletapGesture2];
    
    [tapGesture requireGestureRecognizerToFail: doubletapGesture2];
    [doubletapGesture2 setNumberOfTapsRequired:2];
    
    UIPinchGestureRecognizer *pinchGesture = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(scalePiece:)];
    [pinchGesture setDelegate:self];
    [piece addGestureRecognizer:pinchGesture];
    
    
    //[doubletapGesture2 release];
}

// scale and rotation transforms are applied relative to the layer's anchor point
// this method moves a gesture recognizer's view's anchor point between the user's fingers
- (void)adjustAnchorPointForGestureRecognizer:(UIGestureRecognizer *)gestureRecognizer
{
    if (gestureRecognizer.state == UIGestureRecognizerStateBegan) {
        UIView *piece = gestureRecognizer.view;
        CGPoint locationInView = [gestureRecognizer locationInView:piece];
        CGPoint locationInSuperview = [gestureRecognizer locationInView:piece.superview];
        
        piece.layer.anchorPoint = CGPointMake(locationInView.x / piece.bounds.size.width, locationInView.y / piece.bounds.size.height);
        piece.center = locationInSuperview;
    }
}

- (void)rotatePiece:(UIRotationGestureRecognizer *)gestureRecognizer
{
	
    [self adjustAnchorPointForGestureRecognizer:gestureRecognizer];
    
    if ([gestureRecognizer state] == UIGestureRecognizerStateBegan || [gestureRecognizer state] == UIGestureRecognizerStateChanged) {
        [gestureRecognizer view].transform = CGAffineTransformRotate([[gestureRecognizer view] transform], [gestureRecognizer rotation]);
        [gestureRecognizer setRotation:0];
    }
}

// scale the piece by the current scale
// reset the gesture recognizer's rotation to 0 after applying so the next callback is a delta from the current scale
- (void)scalePiece:(UIPinchGestureRecognizer *)gestureRecognizer
{
    [self adjustAnchorPointForGestureRecognizer:gestureRecognizer];
    
	
    if ([gestureRecognizer state] == UIGestureRecognizerStateBegan || [gestureRecognizer state] == UIGestureRecognizerStateChanged)
    {
        [gestureRecognizer view].transform = CGAffineTransformScale([[gestureRecognizer view] transform], [gestureRecognizer scale], [gestureRecognizer scale]);
        [gestureRecognizer setScale:1];
    }
}
- (void)doubleTapForImage:(UITapGestureRecognizer *)recognizer
{
    
    
    UIImageView*imageviewTap = (UIImageView *)recognizer.view;
    NSLog(@"imageviewTap ===  %d",imageviewTap.tag);
    
    
}
- (void)tapGesture:(UITapGestureRecognizer *)recognizer
{
    //[effectview setHidden:YES];
    UIImageView*imageviewTap = (UIImageView *)recognizer.view;
    NSLog(@"imageviewTap ===  %d",imageviewTap.tag);
    [self.view bringSubviewToFront:imageviewTap];
}


// shift the piece's center by the pan amount
// reset the gesture recognizer's translation to {0, 0} after applying so the next callback is a delta from the current position
- (void)panPiece:(UIPanGestureRecognizer *)gestureRecognizer
{
    UIView *piece = [gestureRecognizer view];
    UIView*second_view;
    
    int selected_line;
    
    if(piece.tag == 2003)
    {
        second_view = [self.view viewWithTag:2004];
        selected_line = 3;
    }
    else if(piece.tag == 2004)
    {
         second_view = [self.view viewWithTag:2003];
        selected_line = 4;
    }
    
    NSLog(@"\n piece = %d",piece.tag);
    
    [self adjustAnchorPointForGestureRecognizer:gestureRecognizer];
    
    if ([gestureRecognizer state] == UIGestureRecognizerStateBegan || [gestureRecognizer state] == UIGestureRecognizerStateChanged)
    {
        CGPoint translation = [gestureRecognizer translationInView:[piece superview]];
        
        CGFloat cx=[piece center].x;
        CGFloat cy=[piece center].y;
        
        
        
        
        CGFloat ctx=[piece center].x + translation.x;
        CGFloat cty=[piece center].y + translation.y;
        // if(cx >55 && cy >55 && ctx <240 && cty <240)
        
       
        if(selected_line == 3)
        {
            if(cty < cy)
            {
                [piece setCenter:CGPointMake(cx,cty)];
            }
            
            else if(piece.frame.origin.y+20<=second_view.frame.origin.y)
            {
                [piece setCenter:CGPointMake(cx,cty)];
            }
            
        }
        else if(selected_line == 4)
        {
         //
            if(cty < cy)
            {
                [piece setCenter:CGPointMake(cx,cty)];
            }
            else if(piece.frame.origin.y-20<=second_view.frame.origin.y)
            {
                [piece setCenter:CGPointMake(cx,cty)];
            }
        }
        
        [gestureRecognizer setTranslation:CGPointZero inView:[piece superview]];
    }
    
    else
    {
        
        
        NSLog(@"\n end state");
    }
}



#pragma mark - 


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}



@end
