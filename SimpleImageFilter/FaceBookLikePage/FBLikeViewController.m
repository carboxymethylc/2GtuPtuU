//
//  DetailViewController.m
//  FaceBookLikePage
//
//  Created by LD.Chirag on 11/10/12.
//  Copyright (c) 2012 LD.Chirag. All rights reserved.
//

#import "FBLikeViewController.h"

@interface FBLikeViewController ()
{
}

@end

@implementation FBLikeViewController




- (void)viewDidLoad
{
    [super viewDidLoad];
    
    UIBarButtonItem *closeButton = [[UIBarButtonItem alloc] initWithTitle:@"Close" style:UIBarButtonItemStylePlain target:self action:@selector(closeView:)] ;
    self.navigationItem.leftBarButtonItem = closeButton;
    
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"https://www.facebook.com/pages/Peppermill/387649817965000?ref=hl"]];
    [faceBookLikePageWebView loadRequest:request];
    
    
	// Do any additional setup after loading the view, typically from a nib.

}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.title = NSLocalizedString(@"FaceBook", @"FaceBook");
    }
    return self;
}
-(void)closeView:(id)sender
{
    [self.navigationController dismissModalViewControllerAnimated:TRUE];
}
@end
