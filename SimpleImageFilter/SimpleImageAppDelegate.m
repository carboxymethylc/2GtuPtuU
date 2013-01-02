#import "SimpleImageAppDelegate.h"
#import "ViewController.h"
@implementation SimpleImageAppDelegate

@synthesize window = _window;
@synthesize globalImage;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    // Override point for customization after application launch.
    self.window.backgroundColor = [UIColor whiteColor];
    
    /*
    rootViewController = [[SimpleImageViewController alloc] initWithNibName:@"SimpleImageViewController" bundle:nil];
    [self.window addSubview:rootViewController.view];
    */
    
    ViewController *viewController = [[ViewController alloc] initWithFilterType:GPUIMAGE_TILTSHIFTHORIZONTAL];
    
    globalImage = [[UIImage alloc] init];
    self.navigationController = [[UINavigationController alloc] initWithRootViewController:viewController] ;
    
    
    self.window.rootViewController = self.navigationController;

    
    
    [self.window makeKeyAndVisible];
    return YES;
}
							
@end
