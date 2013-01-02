#import <UIKit/UIKit.h>
#import "GPUImage.h"


@interface SimpleImageAppDelegate : UIResponder <UIApplicationDelegate>
{
    //SimpleImageViewController *rootViewController;
    UIImage*globalImage;//This image is used for editing..If user discards any changes original image from the doc directory will be used.If user save image or apply effect this image will replace document directory's image.
    
}

@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) UINavigationController *navigationController;
@property (strong, nonatomic) UIImage*globalImage;


@end
