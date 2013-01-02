//
//  GPUImageBlackAndWhiteFilter.m
//  SimpleImageFilter
//
//  Created by LD.Chirag on 11/10/12.
//  Copyright (c) 2012 Cell Phone. All rights reserved.
//

#import "GPUImageBlackAndWhiteFilter.h"

@implementation GPUImageBlackAndWhiteFilter

#pragma mark -
#pragma mark Initialization and teardown

- (id)init;
{
    if (!(self = [super init]))
    {
        return nil;
    }
    
    self.intensity = 1.0;
    self.colorMatrix = (GPUMatrix4x4){
        {0.3333, 0.3333, 0.3333, 0.0},
        {0.3333, 0.3333, 0.3333, 0.0},
        {0.3333, 0.3333, 0.3333 ,0.0},
        {0,0,0,1.0},
    };
    
    return self;
}
@end
