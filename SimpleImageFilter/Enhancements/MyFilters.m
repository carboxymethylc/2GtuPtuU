//
//  MyFilters.m
//  ColorBlendTutorial
//
//  Created by Swati Panchal on 5/19/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "MyFilters.h"
#import "CatmullRomSpline.h"
#import "UIImage+Filtrr.h"
#import "NYXImagesHelper.h"
#import <Accelerate/Accelerate.h>
#import "GPUImage.h"

#define SAFECOLOR(color) MIN(255,MAX(0,color))
#define RoundToQuantum(quantum)  ClampToQuantum(quantum)
#define ScaleCharToQuantum(value)  ((Quantum) (value))
#define SigmaGaussian  ScaleCharToQuantum(4)
#define TauGaussian  ScaleCharToQuantum(20)
#define QuantumRange  ((Quantum) 65535)
#define radian(x) x*(M_PI/180)

typedef unsigned char Quantum;
typedef double MagickRealType;
typedef void (*FilterCallback)(UInt8 *pixelBuf, UInt32 offset, void *context);
typedef void (*FilterBlendCallback)(UInt8 *pixelBuf, UInt8 *pixelBlendBuf, UInt32 offset, void *context);

enum {
    CurveChannelNone                 = 0,
    CurveChannelRed					 = 1 << 0,
    CurveChannelGreen				 = 1 << 1,
    CurveChannelBlue				 = 1 << 2,
};
typedef NSUInteger CurveChannel;

typedef struct
{
	CurveChannel channel;
	CGPoint *points;
	int length;
} CurveEquation;

void filterGreyscale(UInt8 *pixelBuf, UInt32 offset, void *context);
void filterSepia(UInt8 *pixelBuf, UInt32 offset, void *context);
void filterPosterize(UInt8 *pixelBuf, UInt32 offset, void *context);
void filterSaturate(UInt8 *pixelBuf, UInt32 offset, void *context);
void filterBrightness(UInt8 *pixelBuf, UInt32 offset, void *context);
void filterGamma(UInt8 *pixelBuf, UInt32 offset, void *context);
void filterOpacity(UInt8 *pixelBuf, UInt32 offset, void *context);
double calcContrast(double f, double c);
void filterContrast(UInt8 *pixelBuf, UInt32 offset, void *context);
double calcBias(double f, double bi);
void filterBias(UInt8 *pixelBuf, UInt32 offset, void *context);
void filterInvert(UInt8 *pixelBuf, UInt32 offset, void *context);
void filterNoise(UInt8 *pixelBuf, UInt32 offset, void *context);
double calcOverlay(float b, float t);
void filterOverlay(UInt8 *pixelBuf, UInt8 *pixedBlendBuf, UInt32 offset, void *context);
void filterMask(UInt8 *pixelBuf, UInt8 *pixedBlendBuf, UInt32 offset, void *context);
void filterMerge(UInt8 *pixelBuf, UInt8 *pixedBlendBuf, UInt32 offset, void *context);
int calcLevelColor(int color, int black, int mid, int white);
void filterLevels(UInt8 *pixelBuf, UInt32 offset, void *context);
double valueGivenCurve(CurveEquation equation, double xValue);
void filterCurve(UInt8 *pixelBuf, UInt32 offset, void *context);
void filterAdjust(UInt8 *pixelBuf, UInt32 offset, void *context);

@implementation UIImage (CiFilter)

+(UIImage*) convertCIImageToUIImage : (CIImage*) ciImage {
    CIContext *context = [CIContext contextWithOptions:nil];
    CGImageRef cgiimage = [context createCGImage:ciImage fromRect:ciImage.extent];
    UIImage *newImage = [UIImage imageWithCGImage:cgiimage];
    CGImageRelease(cgiimage);
    return newImage;
}

+(UIImage *) CIAdditionCompositingWithInputImage : (UIImage*) inputImage andInputBackgroundImage : (UIImage*) inputBackgroundImage {
    CIImage *ciInputImage = [CIImage imageWithCGImage:inputImage.CGImage];
    CIImage *ciBackgroundImage = [CIImage imageWithCGImage:inputBackgroundImage.CGImage];
    CIImage *ciOutput = [CIFilter filterWithName:@"CIAdditionCompositing" keysAndValues:kCIInputImageKey,ciInputImage,kCIInputBackgroundImageKey,ciBackgroundImage, nil].outputImage;
    
    return [self convertCIImageToUIImage:ciOutput];
    
}
+(UIImage *) CIAffineTransformWithInputImage : (UIImage*) inputImage  andInputTransform : (CGAffineTransform) transform {
    CIImage *ciInputImage = [CIImage imageWithCGImage:inputImage.CGImage];
    NSValue *value =[NSValue valueWithCGAffineTransform:transform];
    CIImage *ciOutput = [CIFilter filterWithName:@"CIAffineTransform" keysAndValues:kCIInputImageKey,ciInputImage,@"inputTransform",value, nil].outputImage;
    //CIImage *ciOutput = [ciInputImage imageByApplyingTransform:transform];
    return [self convertCIImageToUIImage:ciOutput];
}

+ (UIImage*) CIAffineTransformWithInputImage: (UIImage*) inputImage andRotationAngle : (float) angle {
    CIImage *ciInputImage = [CIImage imageWithCGImage:inputImage.CGImage];
    CGAffineTransform transform = CGAffineTransformMakeRotation(radian(angle));
    CIImage *ciOutput = [ciInputImage imageByApplyingTransform:transform];
    return [self convertCIImageToUIImage:ciOutput];
}

+ (UIImage*) CIAffineTransformWithInputImage: (UIImage*)inputImage andScaleX : (float) x ScaleY : (float) y {
    CIImage *ciInputImage = [CIImage imageWithCGImage:inputImage.CGImage];
    CGAffineTransform transform = CGAffineTransformMakeScale(x, y);
    CIImage *ciOutput = [ciInputImage imageByApplyingTransform:transform];
    return [self convertCIImageToUIImage:ciOutput];
}

+(UIImage *) CICheckerboardGeneratorWithInputCenter : (CIVector*) inputCenter inputColor0 : (CIColor*) color0 inputColor1 : (CIColor*) color1 inputWidth : (float) inputWidth inputSharpness : (float) inputSharpness {
    CIImage *ciTempOutput = [CIFilter filterWithName:@"CICheckerboardGenerator" keysAndValues:@"inputCenter",inputCenter,@"inputColor0",color0,@"inputColor1",color1,@"inputWidth",[NSNumber numberWithFloat:inputWidth],@"inputSharpness",[NSNumber numberWithFloat:inputSharpness], nil].outputImage;
    CGSize bounds = [UIScreen mainScreen].bounds.size;
    CIVector *vector = [CIVector vectorWithX:0.0 Y:0.0 Z:bounds.width W:bounds.height];
    CIImage *ciOutput = [CIFilter filterWithName:@"CICrop" keysAndValues:kCIInputImageKey,ciTempOutput,@"inputRectangle",vector, nil].outputImage;
    return [self convertCIImageToUIImage:ciOutput];
}

+(UIImage *) CIColorBlendModeWithInputImage : (UIImage*) inputImage andInputBackgroundImage : (UIImage*) inputBackgroundImage {
    CIImage *ciInputImage = [CIImage imageWithCGImage:inputImage.CGImage];
    CIImage *ciBackgroundImage = [CIImage imageWithCGImage:inputBackgroundImage.CGImage];
    CIImage *ciOutput = [CIFilter filterWithName:@"CIColorBlendMode" keysAndValues:kCIInputImageKey,ciInputImage,kCIInputBackgroundImageKey,ciBackgroundImage, nil].outputImage;
    
    return [self convertCIImageToUIImage:ciOutput];
}

+(UIImage *) CIColorBurnBlendModeWithInputImage : (UIImage*) inputImage andInputBackgroundImage : (UIImage*) inputBackgroundImage {
    CIImage *ciInputImage = [CIImage imageWithCGImage:inputImage.CGImage];
    CIImage *ciBackgroundImage = [CIImage imageWithCGImage:inputBackgroundImage.CGImage];
    CIImage *ciOutput = [CIFilter filterWithName:@"CIColorBurnBlendMode" keysAndValues:kCIInputImageKey,ciInputImage,kCIInputBackgroundImageKey,ciBackgroundImage, nil].outputImage;
    return [self convertCIImageToUIImage:ciOutput];
}

+(UIImage *) CIColorControlsWithInputImage : (UIImage*)inputImage inputSaturation : (float)inputSaturation inputBrightness : (float)inputBrightness inputContrast : (float)inputContrast {
    CIImage *ciInputImage = [CIImage imageWithCGImage:inputImage.CGImage];
    CIImage *ciOutput = [CIFilter filterWithName:@"CIColorControls" keysAndValues:kCIInputImageKey,ciInputImage,@"inputSaturation",[NSNumber numberWithFloat:inputSaturation],@"inputBrightness",[NSNumber numberWithFloat:inputBrightness],@"inputContrast",[NSNumber numberWithFloat:inputContrast], nil].outputImage;
    return [self convertCIImageToUIImage:ciOutput];
}

+(UIImage *) CIColorCubeWithInputImage : (UIImage*) inputImage inputCubeDimension : (float)inputCubeDimension inputCubeData : (NSData*) inputCubeData {
    CIImage *ciInputImage = [CIImage imageWithCGImage:inputImage.CGImage];
    CIImage *ciOutput = [CIFilter filterWithName:@"CIColorCube" keysAndValues:kCIInputImageKey,ciInputImage,@"inputCubeDimension",[NSNumber numberWithFloat:inputCubeDimension],@"inputCubeData",inputCubeData, nil].outputImage;
    return [self convertCIImageToUIImage:ciOutput];
}

+(UIImage *) CIColorDodgeBlendModeWithInputImage : (UIImage*) inputImage andInputBackgroundImage : (UIImage*) inputBackgroundImage {
    CIImage *ciInputImage = [CIImage imageWithCGImage:inputImage.CGImage];
    CIImage *ciBackgroundImage = [CIImage imageWithCGImage:inputBackgroundImage.CGImage];
    CIImage *ciOutput = [CIFilter filterWithName:@"CIColorDodgeBlendMode" keysAndValues:kCIInputImageKey,ciInputImage,kCIInputBackgroundImageKey,ciBackgroundImage, nil].outputImage;
    
    return [self convertCIImageToUIImage:ciOutput];
}

+(UIImage *) CIColorInvertWithInputImage : (UIImage*) inputImage {
    CIImage *ciInputImage = [CIImage imageWithCGImage:inputImage.CGImage];
    CIImage *ciOutput = [CIFilter filterWithName:@"CIColorInvert" keysAndValues:kCIInputImageKey,ciInputImage, nil].outputImage;
    return [self convertCIImageToUIImage:ciOutput];
}

+(UIImage *) CIColorMatrixWithInputImage : (UIImage*) inputImage inputRVector : (CIVector*)inputRVector inputGVector : (CIVector*)inputGVector
                            inputBVector : (CIVector*)inputBVector inputAVector : (CIVector*)inputAVector inputBiasVector : (CIVector*)inputBiasVector {
    CIImage *ciInputImage = [CIImage imageWithCGImage:inputImage.CGImage];
    CIImage *ciOutput = [CIFilter filterWithName:@"CIColorMatrix" keysAndValues:kCIInputImageKey,ciInputImage,@"inputRVector",inputRVector,@"inputGVector",inputGVector,@"inputBVector",inputBVector,@"inputAVector",inputAVector,@"inputBiasVector",inputBiasVector, nil].outputImage;
    return [self convertCIImageToUIImage:ciOutput];
}

+(UIImage *) CIColorMonochromeWithInputImage : (UIImage*)inputImage inputColor : (CIColor*)inputColor inputIntensity : (float) inputIntensity {
    CIImage *ciInputImage = [CIImage imageWithCGImage:inputImage.CGImage];
    CIImage *ciOutput = [CIFilter filterWithName:@"CIColorMonochrome" keysAndValues:kCIInputImageKey,ciInputImage,@"inputColor",inputColor,@"inputIntensity",[NSNumber numberWithFloat:inputIntensity], nil].outputImage;
    return [self convertCIImageToUIImage:ciOutput];
}

+(UIImage *) CIConstantColorGeneratorWithInputColor : (CIColor*) inputColor {
    CIImage *ciTempOutput = [CIFilter filterWithName:@"CIConstantColorGenerator" keysAndValues:@"inputColor",inputColor, nil].outputImage;
    CGSize bounds = [UIScreen mainScreen].bounds.size;
    CIVector *vector = [CIVector vectorWithX:0.0 Y:0.0 Z:bounds.width W:bounds.height];
    CIImage *ciOutput = [CIFilter filterWithName:@"CICrop" keysAndValues:kCIInputImageKey,ciTempOutput,@"inputRectangle",vector, nil].outputImage;
    return [self convertCIImageToUIImage:ciOutput];
}

+(UIImage *) CICropWithInputImage : (UIImage*)inputImage inputRectangle : (CIVector*)inputRectangle {
    CIImage *ciInputImage = [CIImage imageWithCGImage:inputImage.CGImage];
    CIImage *ciOutput = [CIFilter filterWithName:@"CICrop" keysAndValues:kCIInputImageKey,ciInputImage,@"inputRectangle",inputRectangle, nil].outputImage;
    return [self convertCIImageToUIImage:ciOutput];
}

+(UIImage *) CIDarkenBlendModeWithInputImage : (UIImage*) inputImage andInputBackgroundImage : (UIImage*) inputBackgroundImage {
    CIImage *ciInputImage = [CIImage imageWithCGImage:inputImage.CGImage];
    CIImage *ciBackgroundImage = [CIImage imageWithCGImage:inputBackgroundImage.CGImage];
    CIImage *ciOutput = [CIFilter filterWithName:@"CIDarkenBlendMode" keysAndValues:kCIInputImageKey,ciInputImage,kCIInputBackgroundImageKey,ciBackgroundImage, nil].outputImage;
    
    return [self convertCIImageToUIImage:ciOutput];
}

+(UIImage *) CIDifferenceBlendModeWithInputImage : (UIImage*) inputImage andInputBackgroundImage : (UIImage*) inputBackgroundImage {
    CIImage *ciInputImage = [CIImage imageWithCGImage:inputImage.CGImage];
    CIImage *ciBackgroundImage = [CIImage imageWithCGImage:inputBackgroundImage.CGImage];
    CIImage *ciOutput = [CIFilter filterWithName:@"CIDifferenceBlendMode" keysAndValues:kCIInputImageKey,ciInputImage,kCIInputBackgroundImageKey,ciBackgroundImage, nil].outputImage;
    
    return [self convertCIImageToUIImage:ciOutput];
}

+(UIImage *) CIExclusionBlendModeWithInputImage : (UIImage*) inputImage andInputBackgroundImage : (UIImage*) inputBackgroundImage {
    CIImage *ciInputImage = [CIImage imageWithCGImage:inputImage.CGImage];
    CIImage *ciBackgroundImage = [CIImage imageWithCGImage:inputBackgroundImage.CGImage];
    CIImage *ciOutput = [CIFilter filterWithName:@"CIExclusionBlendMode" keysAndValues:kCIInputImageKey,ciInputImage,kCIInputBackgroundImageKey,ciBackgroundImage, nil].outputImage;
    
    return [self convertCIImageToUIImage:ciOutput];
}

+(UIImage *) CIExposureAdjustWithInputImage : (UIImage*) inputImage inputEV : (float) inputEV {
    CIImage *ciInputImage = [CIImage imageWithCGImage:inputImage.CGImage];
    CIImage *ciOutput = [CIFilter filterWithName:@"CIExposureAdjust" keysAndValues:kCIInputImageKey,ciInputImage,@"inputEV",[NSNumber numberWithFloat:inputEV], nil].outputImage;
    return [self convertCIImageToUIImage:ciOutput];
}

+(UIImage *) CIFalseColorWithInputImage : (UIImage*) inputImage inputColor0 : (CIColor*) inputColor0 inputColor1 : (CIColor*) inputColor1 {
    CIImage *ciInputImage = [CIImage imageWithCGImage:inputImage.CGImage];
    CIImage *ciOutput = [CIFilter filterWithName:@"CIFalseColor" keysAndValues:kCIInputImageKey,ciInputImage,@"inputColor0",inputColor0,@"inputColor1",inputColor1, nil].outputImage;
    return [self convertCIImageToUIImage:ciOutput];
}

+(UIImage *) CIGammaAdjustWithInputImage : (UIImage*) inputImage inputPower : (float) inputPower {
    CIImage *ciInputImage = [CIImage imageWithCGImage:inputImage.CGImage];
    CIImage *ciOutput = [CIFilter filterWithName:@"CIGammaAdjust" keysAndValues:kCIInputImageKey,ciInputImage,@"inputPower",[NSNumber numberWithFloat:inputPower], nil].outputImage;
    return [self convertCIImageToUIImage:ciOutput];
}

+(UIImage *) CIGaussianGradientWithInputCenter : (CIVector*) inputCenter inputColor0 : (CIColor*) inputColor0 inputColor1 : (CIColor*) inputColor1 inputRadius : (float) inputRadius {
    CIImage *ciTempOutput = [CIFilter filterWithName:@"CIGaussianGradient" keysAndValues:@"inputCenter",inputCenter,@"inputColor0",inputColor0,@"inputColor1",inputColor1,@"inputRadius",[NSNumber numberWithFloat:inputRadius], nil].outputImage;
    //return [self convertCIImageToUIImage:ciOutput];
    CGSize bounds = [UIScreen mainScreen].bounds.size;
    CIVector *vector = [CIVector vectorWithX:0.0 Y:0.0 Z:bounds.width W:bounds.height];
    CIImage *ciOutput = [CIFilter filterWithName:@"CICrop" keysAndValues:kCIInputImageKey,ciTempOutput,@"inputRectangle",vector, nil].outputImage;
    return [self convertCIImageToUIImage:ciOutput];
}

+(UIImage *) CIHardLightBlendModeWithInputImage : (UIImage*) inputImage andInputBackgroundImage : (UIImage*) inputBackgroundImage {
    CIImage *ciInputImage = [CIImage imageWithCGImage:inputImage.CGImage];
    CIImage *ciBackgroundImage = [CIImage imageWithCGImage:inputBackgroundImage.CGImage];
    CIImage *ciOutput = [CIFilter filterWithName:@"CIHardLightBlendMode" keysAndValues:kCIInputImageKey,ciInputImage,kCIInputBackgroundImageKey,ciBackgroundImage, nil].outputImage;
    
    return [self convertCIImageToUIImage:ciOutput];
}

+(UIImage *) CIHighlightShadowAdjustWithInputImage : (UIImage*) inputImage inputHighlightAmount:(float) inputHighlightAmount inputShadowAmount : (float) inputShadowAmount {
    CIImage *ciInputImage = [CIImage imageWithCGImage:inputImage.CGImage];
    CIImage *ciOutput = [CIFilter filterWithName:@"CIHighlightShadowAdjust" keysAndValues:kCIInputImageKey,ciInputImage,@"inputHighlightAmount",[NSNumber numberWithFloat:inputHighlightAmount],@"inputShadowAmount",[NSNumber numberWithFloat:inputShadowAmount], nil].outputImage;
    return [self convertCIImageToUIImage:ciOutput];
}

+(UIImage *) CIHueAdjustWithInputImage : (UIImage*) inputImage inputAngle : (float) inputAngle {
    CIImage *ciInputImage = [CIImage imageWithCGImage:inputImage.CGImage];
    CIImage *ciOutput = [CIFilter filterWithName:@"CIHueAdjust" keysAndValues:kCIInputImageKey,ciInputImage,@"inputAngle",[NSNumber numberWithFloat:inputAngle], nil].outputImage;
    return [self convertCIImageToUIImage:ciOutput];
}

+(UIImage *) CIHueBlendModeWithInputImage : (UIImage*) inputImage andInputBackgroundImage : (UIImage*) inputBackgroundImage {
    CIImage *ciInputImage = [CIImage imageWithCGImage:inputImage.CGImage];
    CIImage *ciBackgroundImage = [CIImage imageWithCGImage:inputBackgroundImage.CGImage];
    CIImage *ciOutput = [CIFilter filterWithName:@"CIHueBlendMode" keysAndValues:kCIInputImageKey,ciInputImage,kCIInputBackgroundImageKey,ciBackgroundImage, nil].outputImage;
    
    return [self convertCIImageToUIImage:ciOutput];
}

+(UIImage *) CILightenBlendModeWithInputImage : (UIImage*) inputImage andInputBackgroundImage : (UIImage*) inputBackgroundImage {
    CIImage *ciInputImage = [CIImage imageWithCGImage:inputImage.CGImage];
    CIImage *ciBackgroundImage = [CIImage imageWithCGImage:inputBackgroundImage.CGImage];
    CIImage *ciOutput = [CIFilter filterWithName:@"CILightenBlendMode" keysAndValues:kCIInputImageKey,ciInputImage,kCIInputBackgroundImageKey,ciBackgroundImage, nil].outputImage;
    
    return [self convertCIImageToUIImage:ciOutput];
}

+(UIImage *) CILinearGradientWithInputPoint0 : (CIVector*) inputPoint0 inputPoint1 : (CIVector*) inputPoint1 inputColor0 : (CIColor*) inputColor0 inputColor1 : (CIColor*) inputColor1 {
    CIImage *ciTempOutput = [CIFilter filterWithName:@"CILinearGradient" keysAndValues:@"inputPoint0",inputPoint0,@"inputPoint1",inputPoint1,@"inputColor0",inputColor0,@"inputColor1",inputColor1, nil].outputImage;
    //return [self convertCIImageToUIImage:ciOutput];
    CGSize bounds = [UIScreen mainScreen].bounds.size;
    CIVector *vector = [CIVector vectorWithX:0.0 Y:0.0 Z:bounds.width W:bounds.height];
    CIImage *ciOutput = [CIFilter filterWithName:@"CICrop" keysAndValues:kCIInputImageKey,ciTempOutput,@"inputRectangle",vector, nil].outputImage;
    return [self convertCIImageToUIImage:ciOutput];
}

+(UIImage *) CILuminosityBlendModeWithInputImage : (UIImage*) inputImage andInputBackgroundImage : (UIImage*) inputBackgroundImage {
    CIImage *ciInputImage = [CIImage imageWithCGImage:inputImage.CGImage];
    CIImage *ciBackgroundImage = [CIImage imageWithCGImage:inputBackgroundImage.CGImage];
    CIImage *ciOutput = [CIFilter filterWithName:@"CILuminosityBlendMode" keysAndValues:kCIInputImageKey,ciInputImage,kCIInputBackgroundImageKey,ciBackgroundImage, nil].outputImage;
    
    return [self convertCIImageToUIImage:ciOutput];
}

+(UIImage *) CIMaximumCompositingWithInputImage : (UIImage*) inputImage andInputBackgroundImage : (UIImage*) inputBackgroundImage {
    CIImage *ciInputImage = [CIImage imageWithCGImage:inputImage.CGImage];
    CIImage *ciBackgroundImage = [CIImage imageWithCGImage:inputBackgroundImage.CGImage];
    CIImage *ciOutput = [CIFilter filterWithName:@"CIMaximumCompositing" keysAndValues:kCIInputImageKey,ciInputImage,kCIInputBackgroundImageKey,ciBackgroundImage, nil].outputImage;
    
    return [self convertCIImageToUIImage:ciOutput];
}

+(UIImage *) CIMinimumCompositingWithInputImage : (UIImage*) inputImage andInputBackgroundImage : (UIImage*) inputBackgroundImage {
    CIImage *ciInputImage = [CIImage imageWithCGImage:inputImage.CGImage];
    CIImage *ciBackgroundImage = [CIImage imageWithCGImage:inputBackgroundImage.CGImage];
    CIImage *ciOutput = [CIFilter filterWithName:@"CIMinimumCompositing" keysAndValues:kCIInputImageKey,ciInputImage,kCIInputBackgroundImageKey,ciBackgroundImage, nil].outputImage;
    
    return [self convertCIImageToUIImage:ciOutput];
}

+(UIImage *) CIMultiplyBlendModeWithInputImage : (UIImage*) inputImage andInputBackgroundImage : (UIImage*) inputBackgroundImage {
    CIImage *ciInputImage = [CIImage imageWithCGImage:inputImage.CGImage];
    CIImage *ciBackgroundImage = [CIImage imageWithCGImage:inputBackgroundImage.CGImage];
    CIImage *ciOutput = [CIFilter filterWithName:@"CIMultiplyBlendMode" keysAndValues:kCIInputImageKey,ciInputImage,kCIInputBackgroundImageKey,ciBackgroundImage, nil].outputImage;
    
    return [self convertCIImageToUIImage:ciOutput];
}

+(UIImage *) CIMultiplyCompositingWithInputImage : (UIImage*) inputImage andInputBackgroundImage : (UIImage*) inputBackgroundImage {
    CIImage *ciInputImage = [CIImage imageWithCGImage:inputImage.CGImage];
    CIImage *ciBackgroundImage = [CIImage imageWithCGImage:inputBackgroundImage.CGImage];
    CIImage *ciOutput = [CIFilter filterWithName:@"CIMultiplyCompositing" keysAndValues:kCIInputImageKey,ciInputImage,kCIInputBackgroundImageKey,ciBackgroundImage, nil].outputImage;
    
    return [self convertCIImageToUIImage:ciOutput];
}

+(UIImage *) CIOverlayBlendModeWithInputImage : (UIImage*) inputImage andInputBackgroundImage : (UIImage*) inputBackgroundImage {
    CIImage *ciInputImage = [CIImage imageWithCGImage:inputImage.CGImage];
    CIImage *ciBackgroundImage = [CIImage imageWithCGImage:inputBackgroundImage.CGImage];
    CIImage *ciOutput = [CIFilter filterWithName:@"CIOverlayBlendMode" keysAndValues:kCIInputImageKey,ciInputImage,kCIInputBackgroundImageKey,ciBackgroundImage, nil].outputImage;
    
    return [self convertCIImageToUIImage:ciOutput];
}

+(UIImage *) CIRadialGradientWithInputCenter : (CIVector*) inputCenter inputRadius0:(float) inputRadius0 inputRadius1: (float) inputRadius1 inputColor0 : (CIColor*) inputColor0 inputColor1 : (CIColor*) inputColor1 {
    CIImage *ciTempOutput = [CIFilter filterWithName:@"CIRadialGradient" keysAndValues:@"inputCenter",inputCenter,@"inputRadius0",[NSNumber numberWithFloat:inputRadius0],@"inputRadius1",[NSNumber numberWithFloat:inputRadius1],@"inputColor0",inputColor0,@"inputColor1",inputColor1, nil].outputImage;
    //return [self convertCIImageToUIImage:ciOutput];
    CGSize bounds = [UIScreen mainScreen].bounds.size;
    CIVector *vector = [CIVector vectorWithX:0.0 Y:0.0 Z:bounds.width W:bounds.height];
    CIImage *ciOutput = [CIFilter filterWithName:@"CICrop" keysAndValues:kCIInputImageKey,ciTempOutput,@"inputRectangle",vector, nil].outputImage;
    return [self convertCIImageToUIImage:ciOutput];

}

+(UIImage *) CISaturationBlendModeWithInputImage : (UIImage*) inputImage andInputBackgroundImage : (UIImage*) inputBackgroundImage {
    CIImage *ciInputImage = [CIImage imageWithCGImage:inputImage.CGImage];
    CIImage *ciBackgroundImage = [CIImage imageWithCGImage:inputBackgroundImage.CGImage];
    CIImage *ciOutput = [CIFilter filterWithName:@"CISaturationBlendMode" keysAndValues:kCIInputImageKey,ciInputImage,kCIInputBackgroundImageKey,ciBackgroundImage, nil].outputImage;
    
    return [self convertCIImageToUIImage:ciOutput];
}

+(UIImage *) CIScreenBlendModeWithInputImage : (UIImage*) inputImage andInputBackgroundImage : (UIImage*) inputBackgroundImage {
    CIImage *ciInputImage = [CIImage imageWithCGImage:inputImage.CGImage];
    CIImage *ciBackgroundImage = [CIImage imageWithCGImage:inputBackgroundImage.CGImage];
    CIImage *ciOutput = [CIFilter filterWithName:@"CIScreenBlendMode" keysAndValues:kCIInputImageKey,ciInputImage,kCIInputBackgroundImageKey,ciBackgroundImage, nil].outputImage;
    
    return [self convertCIImageToUIImage:ciOutput];
}

+(UIImage *) CISepiaToneWithInputImage : (UIImage*) inputImage inputIntensity : (float) inputIntensity {
    CIImage *ciInputImage = [CIImage imageWithCGImage:inputImage.CGImage];
    CIImage *ciOutput = [CIFilter filterWithName:@"CISepiaTone" keysAndValues:kCIInputImageKey,ciInputImage,@"inputIntensity",[NSNumber numberWithFloat:inputIntensity], nil].outputImage;
    return [self convertCIImageToUIImage:ciOutput];
}

+(UIImage *) CISoftLightBlendModeWithInputImage : (UIImage*) inputImage andInputBackgroundImage : (UIImage*) inputBackgroundImage {
    CIImage *ciInputImage = [CIImage imageWithCGImage:inputImage.CGImage];
    CIImage *ciBackgroundImage = [CIImage imageWithCGImage:inputBackgroundImage.CGImage];
    CIImage *ciOutput = [CIFilter filterWithName:@"CISoftLightBlendMode" keysAndValues:kCIInputImageKey,ciInputImage,kCIInputBackgroundImageKey,ciBackgroundImage, nil].outputImage;
    
    return [self convertCIImageToUIImage:ciOutput];
}

+(UIImage *) CISourceAtopCompositingWithInputImage : (UIImage*) inputImage andInputBackgroundImage : (UIImage*) inputBackgroundImage {
    CIImage *ciInputImage = [CIImage imageWithCGImage:inputImage.CGImage];
    CIImage *ciBackgroundImage = [CIImage imageWithCGImage:inputBackgroundImage.CGImage];
    CIImage *ciOutput = [CIFilter filterWithName:@"CISourceAtopCompositing" keysAndValues:kCIInputImageKey,ciInputImage,kCIInputBackgroundImageKey,ciBackgroundImage, nil].outputImage;
    
    return [self convertCIImageToUIImage:ciOutput];
}

+(UIImage *) CISourceInCompositingWithInputImage : (UIImage*) inputImage andInputBackgroundImage : (UIImage*) inputBackgroundImage {
    CIImage *ciInputImage = [CIImage imageWithCGImage:inputImage.CGImage];
    CIImage *ciBackgroundImage = [CIImage imageWithCGImage:inputBackgroundImage.CGImage];
    CIImage *ciOutput = [CIFilter filterWithName:@"CISourceInCompositing" keysAndValues:kCIInputImageKey,ciInputImage,kCIInputBackgroundImageKey,ciBackgroundImage, nil].outputImage;
    
    return [self convertCIImageToUIImage:ciOutput];

}

+(UIImage *) CISourceOutCompositingWithInputImage : (UIImage*) inputImage andInputBackgroundImage : (UIImage*) inputBackgroundImage {
    CIImage *ciInputImage = [CIImage imageWithCGImage:inputImage.CGImage];
    CIImage *ciBackgroundImage = [CIImage imageWithCGImage:inputBackgroundImage.CGImage];
    CIImage *ciOutput = [CIFilter filterWithName:@"CISourceOutCompositing" keysAndValues:kCIInputImageKey,ciInputImage,kCIInputBackgroundImageKey,ciBackgroundImage, nil].outputImage;
    
    return [self convertCIImageToUIImage:ciOutput];
}

+(UIImage *) CISourceOverCompositingWithInputImage : (UIImage*) inputImage andInputBackgroundImage : (UIImage*) inputBackgroundImage {
    CIImage *ciInputImage = [CIImage imageWithCGImage:inputImage.CGImage];
    CIImage *ciBackgroundImage = [CIImage imageWithCGImage:inputBackgroundImage.CGImage];
    CIImage *ciOutput = [CIFilter filterWithName:@"CISourceOverCompositing" keysAndValues:kCIInputImageKey,ciInputImage,kCIInputBackgroundImageKey,ciBackgroundImage, nil].outputImage;
    
    return [self convertCIImageToUIImage:ciOutput];
}

+(UIImage *) CIStraightenFilterWithInputImage : (UIImage*) inputImage inputAngle : (float) inputAngle {
    CIImage *ciInputImage = [CIImage imageWithCGImage:inputImage.CGImage];
    CIImage *ciOutput = [CIFilter filterWithName:@"CIStraightenFilter" keysAndValues:kCIInputImageKey,ciInputImage,@"inputAngle",[NSNumber numberWithFloat:inputAngle], nil].outputImage;
    
    return [self convertCIImageToUIImage:ciOutput];
}

+(UIImage *) CIStripesGeneratorWithInputCenter : (CIVector*) inputCenter inputColor0 : (CIColor*)inputColor0 inputColor1 : (CIColor*) inputColor1 inputWidth : (float) inputWidth inputSharpness : (float) inputSharpness {
    CIImage *ciTempOutput = [CIFilter filterWithName:@"CIStripesGenerator" keysAndValues:@"inputCenter",inputCenter,@"inputColor0",inputColor0,@"inputColor1",inputColor1,@"inputWidth",[NSNumber numberWithFloat:inputWidth],@"inputSharpness",[NSNumber numberWithFloat:inputSharpness], nil].outputImage;
    //return [self convertCIImageToUIImage:ciOutput];
    CGSize bounds = [UIScreen mainScreen].bounds.size;
    CIVector *vector = [CIVector vectorWithX:0.0 Y:0.0 Z:bounds.width W:bounds.height];
    CIImage *ciOutput = [CIFilter filterWithName:@"CICrop" keysAndValues:kCIInputImageKey,ciTempOutput,@"inputRectangle",vector, nil].outputImage;
    return [self convertCIImageToUIImage:ciOutput];
}

+(UIImage *) CITemperatureAndTintWithInputImage : (UIImage*) inputImage inputNeutral : (CIVector*) inputNeutral inputTargetNeutral : (CIVector*) inputTargetNeutral {
    CIImage *ciInputImage = [CIImage imageWithCGImage:inputImage.CGImage];
    CIImage *ciOutput = [CIFilter filterWithName:@"CITemperatureAndTint" keysAndValues:kCIInputImageKey,ciInputImage,@"inputNeutral",inputNeutral,@"inputTargetNeutral",inputTargetNeutral, nil].outputImage;
    
     return [self convertCIImageToUIImage:ciOutput];

}

+(UIImage *) CIToneCurveWithInputImage : (UIImage*) inputImage inputPoint0 : (CIVector*) inputPoint0 inputPoint1 : (CIVector*) inputPoint1 inputPoint2 : (CIVector*) inputPoint2 inputPoint3 : (CIVector*) inputPoint3 inputPoint4 : (CIVector*) inputPoint4 {
    CIImage *ciInputImage = [CIImage imageWithCGImage:inputImage.CGImage];
    CIImage *ciOutput = [CIFilter filterWithName:@"CIToneCurve" keysAndValues:kCIInputImageKey,ciInputImage,@"inputPoint0",inputPoint0,@"inputPoint1",inputPoint1,@"inputPoint2",inputPoint2,@"inputPoint3",inputPoint3, nil].outputImage;

    return [self convertCIImageToUIImage:ciOutput];
}

+(UIImage *) CIVibranceWithInputImage : (UIImage*) inputImage inputAmount : (float) inputAmount {
    CIImage *ciInputImage = [CIImage imageWithCGImage:inputImage.CGImage];
    CIImage *ciOutput = [CIFilter filterWithName:@"CIVibrance" keysAndValues:kCIInputImageKey,ciInputImage,@"inputAmount",[NSNumber numberWithFloat:inputAmount], nil].outputImage;
    
    return [self convertCIImageToUIImage:ciOutput];

}
+ (UIImage*) CIVignetteWithInputImage : (UIImage*) inputImage inputIntensity : (float) intensity inputRadius : (float) radius {
    CIImage *ciInputImage = [CIImage imageWithCGImage:inputImage.CGImage];
    CIImage *ciOutput = [CIFilter filterWithName:@"CIVignette" 
                                   keysAndValues: kCIInputImageKey, ciInputImage, 
                         @"inputIntensity", [NSNumber numberWithFloat:intensity],
                         @"inputRadius", [NSNumber numberWithFloat:radius],
                         nil].outputImage;
    return [self convertCIImageToUIImage:ciOutput];
}
+(UIImage *) CIWhitePointAdjustWithInputImage : (UIImage*) inputImage inputColor : (CIColor*) inputColor {
    CIImage *ciInputImage = [CIImage imageWithCGImage:inputImage.CGImage];
    CIImage *ciOutput = [CIFilter filterWithName:@"CIWhitePointAdjust" keysAndValues:kCIInputImageKey,ciInputImage,@"inputColor",inputColor, nil].outputImage;
    
    return [self convertCIImageToUIImage:ciOutput];

}

+(UIImage*) stackBlurInputImage: (UIImage*) inputImage  andRadius : (NSUInteger)inRadius
{
	int radius=inRadius; // Transform unsigned into signed for further operations
	
	if (radius<1){
		return inputImage;
	}
	
    //	return [other applyBlendFilter:filterOverlay  other:self context:nil];
	// First get the image into your data buffer
	
	CGImageRef inImage = inputImage.CGImage;
	CFMutableDataRef m_DataRef = CFDataCreateMutableCopy(0, 0, CGDataProviderCopyData(CGImageGetDataProvider(inImage)));
	UInt8 * m_PixelBuf = (UInt8 *) CFDataGetMutableBytePtr(m_DataRef);  	
	
	
	CGContextRef ctx = CGBitmapContextCreate(m_PixelBuf,  
											 CGImageGetWidth(inImage),  
											 CGImageGetHeight(inImage),  
											 CGImageGetBitsPerComponent(inImage),
											 CGImageGetBytesPerRow(inImage),  
											 CGImageGetColorSpace(inImage),  
											 CGImageGetBitmapInfo(inImage) 
											 ); 
	
    
	int w=CGImageGetWidth(inImage);
	int h=CGImageGetHeight(inImage);
	int wm=w-1;
	int hm=h-1;
	int wh=w*h;
	int div=radius+radius+1;
	
	int *r=malloc(wh*sizeof(int));
	int *g=malloc(wh*sizeof(int));
	int *b=malloc(wh*sizeof(int));
	memset(r,0,wh*sizeof(int));
	memset(g,0,wh*sizeof(int));
	memset(b,0,wh*sizeof(int));
	int rsum,gsum,bsum,x,y,i,p,yp,yi,yw;
	int *vmin = malloc(sizeof(int)*MAX(w,h));
	memset(vmin,0,sizeof(int)*MAX(w,h));
	int divsum=(div+1)>>1;
	divsum*=divsum;
	int *dv=malloc(sizeof(int)*(256*divsum));
	for (i=0;i<256*divsum;i++){
		dv[i]=(i/divsum);
	}
	
	yw=yi=0;
	
	int *stack=malloc(sizeof(int)*(div*3));
	int stackpointer;
	int stackstart;
	int *sir;
	int rbs;
	int r1=radius+1;
	int routsum,goutsum,boutsum;
	int rinsum,ginsum,binsum;
	memset(stack,0,sizeof(int)*div*3);
	
	for (y=0;y<h;y++){
		rinsum=ginsum=binsum=routsum=goutsum=boutsum=rsum=gsum=bsum=0;
		
		for(int i=-radius;i<=radius;i++){
			sir=&stack[(i+radius)*3];
			/*			p=m_PixelBuf[yi+MIN(wm,MAX(i,0))];
			 sir[0]=(p & 0xff0000)>>16;
			 sir[1]=(p & 0x00ff00)>>8;
			 sir[2]=(p & 0x0000ff);
			 */
			int offset=(yi+MIN(wm,MAX(i,0)))*4;
			sir[0]=m_PixelBuf[offset];
			sir[1]=m_PixelBuf[offset+1];
			sir[2]=m_PixelBuf[offset+2];
			
			rbs=r1-abs(i);
			rsum+=sir[0]*rbs;
			gsum+=sir[1]*rbs;
			bsum+=sir[2]*rbs;
			if (i>0){
				rinsum+=sir[0];
				ginsum+=sir[1];
				binsum+=sir[2];
			} else {
				routsum+=sir[0];
				goutsum+=sir[1];
				boutsum+=sir[2];
			}
		}
		stackpointer=radius;
		
		
		for (x=0;x<w;x++){
			r[yi]=dv[rsum];
			g[yi]=dv[gsum];
			b[yi]=dv[bsum];
			
			rsum-=routsum;
			gsum-=goutsum;
			bsum-=boutsum;
			
			stackstart=stackpointer-radius+div;
			sir=&stack[(stackstart%div)*3];
			
			routsum-=sir[0];
			goutsum-=sir[1];
			boutsum-=sir[2];
			
			if(y==0){
				vmin[x]=MIN(x+radius+1,wm);
			}
			
			/*			p=m_PixelBuf[yw+vmin[x]];
			 
			 sir[0]=(p & 0xff0000)>>16;
			 sir[1]=(p & 0x00ff00)>>8;
			 sir[2]=(p & 0x0000ff);
			 */
			int offset=(yw+vmin[x])*4;
			sir[0]=m_PixelBuf[offset];
			sir[1]=m_PixelBuf[offset+1];
			sir[2]=m_PixelBuf[offset+2];
			rinsum+=sir[0];
			ginsum+=sir[1];
			binsum+=sir[2];
			
			rsum+=rinsum;
			gsum+=ginsum;
			bsum+=binsum;
			
			stackpointer=(stackpointer+1)%div;
			sir=&stack[((stackpointer)%div)*3];
			
			routsum+=sir[0];
			goutsum+=sir[1];
			boutsum+=sir[2];
			
			rinsum-=sir[0];
			ginsum-=sir[1];
			binsum-=sir[2];
			
			yi++;
		}
		yw+=w;
	}
	for (x=0;x<w;x++){
		rinsum=ginsum=binsum=routsum=goutsum=boutsum=rsum=gsum=bsum=0;
		yp=-radius*w;
		for(i=-radius;i<=radius;i++){
			yi=MAX(0,yp)+x;
			
			sir=&stack[(i+radius)*3];
			
			sir[0]=r[yi];
			sir[1]=g[yi];
			sir[2]=b[yi];
			
			rbs=r1-abs(i);
			
			rsum+=r[yi]*rbs;
			gsum+=g[yi]*rbs;
			bsum+=b[yi]*rbs;
			
			if (i>0){
				rinsum+=sir[0];
				ginsum+=sir[1];
				binsum+=sir[2];
			} else {
				routsum+=sir[0];
				goutsum+=sir[1];
				boutsum+=sir[2];
			}
			
			if(i<hm){
				yp+=w;
			}
		}
		yi=x;
		stackpointer=radius;
		for (y=0;y<h;y++){ //EXC_BAD_ACCESS
			//			m_PixelBuf[yi]=0xff000000 | (dv[rsum]<<16) | (dv[gsum]<<8) | dv[bsum];
			int offset=yi*4;
			m_PixelBuf[offset]=dv[rsum];
			m_PixelBuf[offset+1]=dv[gsum];
			m_PixelBuf[offset+2]=dv[bsum];
			rsum-=routsum;
			gsum-=goutsum;
			bsum-=boutsum;
			
			stackstart=stackpointer-radius+div;
			sir=&stack[(stackstart%div)*3];
			
			routsum-=sir[0];
			goutsum-=sir[1];
			boutsum-=sir[2];
			
			if(x==0){
				vmin[y]=MIN(y+r1,hm)*w;
			}
			p=x+vmin[y];
			
			sir[0]=r[p];
			sir[1]=g[p];
			sir[2]=b[p];
			
			rinsum+=sir[0];
			ginsum+=sir[1];
			binsum+=sir[2];
			
			rsum+=rinsum;
			gsum+=ginsum;
			bsum+=binsum;
			
			stackpointer=(stackpointer+1)%div;
			sir=&stack[(stackpointer)*3];
			
			routsum+=sir[0];
			goutsum+=sir[1];
			boutsum+=sir[2];
			
			rinsum-=sir[0];
			ginsum-=sir[1];
			binsum-=sir[2];
			
			yi+=w;
		}
	}
	free(r);
	free(g);
	free(b);
	free(vmin);
	free(dv);
	free(stack);
	CGImageRef imageRef = CGBitmapContextCreateImage(ctx);  
	CGContextRelease(ctx);	
	
	//	CFRelease(m_DataRef);
	UIImage *finalImage = [UIImage imageWithCGImage:imageRef];
	CGImageRelease(imageRef);	
	CFRelease(m_DataRef);
	return finalImage;
}
+ (NSMutableArray*) makeKernel:(int)length
{
	NSMutableArray *kernel = [[NSMutableArray alloc] initWithCapacity:10];
	int radius = length / 2;
	
	double m = 1.0f/(2*M_PI*radius*radius);
	double a = 2.0 * radius * radius;
	double sum = 0.0;
	
	for (int y = 0-radius; y < length-radius; y++)
	{
		NSMutableArray *row = [[NSMutableArray alloc] initWithCapacity:10];
        for (int x = 0-radius; x < length-radius; x++)
        {
			double dist = (x*x) + (y*y);
			double val = m*exp(-(dist / a));
			[row addObject:[NSNumber numberWithDouble:val]];			
			sum += val;
        }
		[kernel addObject:row];
	}
	
	//for Kernel-Sum of 1.0
	NSMutableArray *finalKernel = [[NSMutableArray alloc] initWithCapacity:length];
	for (int y = 0; y < length; y++)
	{
		NSMutableArray *row = [kernel objectAtIndex:y];
		NSMutableArray *newRow = [[NSMutableArray alloc] initWithCapacity:length];
        for (int x = 0; x < length; x++)
        {
			NSNumber *value = [row objectAtIndex:x];
			[newRow addObject:[NSNumber numberWithDouble:([value doubleValue] / sum)]];
        }
		[finalKernel addObject:newRow];
	}
	return finalKernel;
}

+ (UIImage*) kGaussianBlurOfImage : (UIImage*) inputImage andRadius : (float) radius {
    NSMutableArray *kernel = [self makeKernel:(int) ((radius*2)+1)];
	CGImageRef inImage = inputImage.CGImage;
	CFMutableDataRef m_DataRef = CFDataCreateMutableCopy(0, 0, CGDataProviderCopyData(CGImageGetDataProvider(inImage)));  
	CFMutableDataRef m_OutDataRef = CFDataCreateMutableCopy(0, 0, CGDataProviderCopyData(CGImageGetDataProvider(inImage)));  
	UInt8 * m_PixelBuf = (UInt8 *) CFDataGetMutableBytePtr(m_DataRef);  
	UInt8 * m_OutPixelBuf = (UInt8 *) CFDataGetMutableBytePtr(m_OutDataRef);  
	
	int h = CGImageGetHeight(inImage);
	int w = CGImageGetWidth(inImage);
	
	int kh = [kernel count] / 2;
	int kw = [[kernel objectAtIndex:0] count] / 2;
	int i = 0, j = 0, n = 0, m = 0;
	
	for (i = 0; i < h; i++) {
		for (j = 0; j < w; j++) {
			int outIndex = (i*w*4) + (j*4);
			double r = 0, g = 0, b = 0;
			for (n = -kh; n <= kh; n++) {
				for (m = -kw; m <= kw; m++) {
					if (i + n >= 0 && i + n < h) {
						if (j + m >= 0 && j + m < w) {
							double f = [[[kernel objectAtIndex:(n + kh)] objectAtIndex:(m + kw)] doubleValue];
							if (f == 0) {continue;}
							int inIndex = ((i+n)*w*4) + ((j+m)*4);
							r += m_PixelBuf[inIndex] * f;
							g += m_PixelBuf[inIndex + 1] * f;
							b += m_PixelBuf[inIndex + 2] * f;
						}
					}
				}
			}
			m_OutPixelBuf[outIndex]     = SAFECOLOR((int)r);
			m_OutPixelBuf[outIndex + 1] = SAFECOLOR((int)g);
			m_OutPixelBuf[outIndex + 2] = SAFECOLOR((int)b);
			m_OutPixelBuf[outIndex + 3] = 255;
		}
	}
	
	CGContextRef ctx = CGBitmapContextCreate(m_OutPixelBuf,  
											 CGImageGetWidth(inImage),  
											 CGImageGetHeight(inImage),  
											 CGImageGetBitsPerComponent(inImage),
											 CGImageGetBytesPerRow(inImage),  
											 CGImageGetColorSpace(inImage),  
											 CGImageGetBitmapInfo(inImage) 
											 ); 
	
	CGImageRef imageRef = CGBitmapContextCreateImage(ctx);  
	CGContextRelease(ctx);
	UIImage *finalImage = [UIImage imageWithCGImage:imageRef];
	CGImageRelease(imageRef);
	CFRelease(m_DataRef);
    CFRelease(m_OutDataRef);
	return finalImage;
}

+ (UIImage*) applyFilterOnImage :(UIImage*) inputImage andFilter : (FilterCallback)filter context:(void*)context
{
	CGImageRef inImage = inputImage.CGImage;
	CFMutableDataRef m_DataRef = CFDataCreateMutableCopy(0, 0, CGDataProviderCopyData(CGImageGetDataProvider(inImage)));  
	UInt8 * m_PixelBuf = (UInt8 *) CFDataGetMutableBytePtr(m_DataRef);  
	
	int length = CFDataGetLength(m_DataRef);
	
	for (int i=0; i<length; i+=4)
	{
		filter(m_PixelBuf,i,context);
	}  
	
	CGContextRef ctx = CGBitmapContextCreate(m_PixelBuf,  
											 CGImageGetWidth(inImage),  
											 CGImageGetHeight(inImage),  
											 CGImageGetBitsPerComponent(inImage),
											 CGImageGetBytesPerRow(inImage),  
											 CGImageGetColorSpace(inImage),  
											 CGImageGetBitmapInfo(inImage) 
											 ); 
	
	CGImageRef imageRef = CGBitmapContextCreateImage(ctx);  
	CGContextRelease(ctx);
	UIImage *finalImage = [UIImage imageWithCGImage:imageRef];
	CGImageRelease(imageRef);
	CFRelease(m_DataRef);
	return finalImage;
	
}

void filterGreyscale(UInt8 *pixelBuf, UInt32 offset, void *context)
{	
	int r = offset;
	int g = offset+1;
	int b = offset+2;
	
	int red = pixelBuf[r];
	int green = pixelBuf[g];
	int blue = pixelBuf[b];
	
	uint32_t gray = 0.3 * red + 0.59 * green + 0.11 * blue;
	
	pixelBuf[r] = gray;
	pixelBuf[g] = gray;  
	pixelBuf[b] = gray;  
}
void filterSepia(UInt8 *pixelBuf, UInt32 offset, void *context)
{	
	int r = offset;
	int g = offset+1;
	int b = offset+2;
	
	int red = pixelBuf[r];
	int green = pixelBuf[g];
	int blue = pixelBuf[b];
	
	pixelBuf[r] = SAFECOLOR((red * 0.393) + (green * 0.769) + (blue * 0.189));
	pixelBuf[g] = SAFECOLOR((red * 0.349) + (green * 0.686) + (blue * 0.168));
	pixelBuf[b] = SAFECOLOR((red * 0.272) + (green * 0.534) + (blue * 0.131));
}

void filterPosterize(UInt8 *pixelBuf, UInt32 offset, void *context)
{
	int levels = *((int*)context);
	if (levels == 0) levels = 1; // avoid divide by zero
	int step = 255 / levels;
	
	int r = offset;
	int g = offset+1;
	int b = offset+2;
	
	int red = pixelBuf[r];
	int green = pixelBuf[g];
	int blue = pixelBuf[b];
	
	pixelBuf[r] = SAFECOLOR((red / step) * step);
	pixelBuf[g] = SAFECOLOR((green / step) * step);
	pixelBuf[b] = SAFECOLOR((blue / step) * step);
}


void filterSaturate(UInt8 *pixelBuf, UInt32 offset, void *context)
{
	double t = *((double*)context);
	
	int r = offset;
	int g = offset+1;
	int b = offset+2;
	
	int red = pixelBuf[r];
	int green = pixelBuf[g];
	int blue = pixelBuf[b];
	
	int avg = ( red + green + blue ) / 3;
	
	pixelBuf[r] = SAFECOLOR((avg + t * (red - avg)));
	pixelBuf[g] = SAFECOLOR((avg + t * (green - avg)));
	pixelBuf[b] = SAFECOLOR((avg + t * (blue - avg)));	
}

void filterBrightness(UInt8 *pixelBuf, UInt32 offset, void *context)
{
	double t = *((double*)context);
	
	int r = offset;
	int g = offset+1;
	int b = offset+2;
	
	int red = pixelBuf[r];
	int green = pixelBuf[g];
	int blue = pixelBuf[b];
	
	pixelBuf[r] = SAFECOLOR(red*t);
	pixelBuf[g] = SAFECOLOR(green*t);
	pixelBuf[b] = SAFECOLOR(blue*t);
}

void filterGamma(UInt8 *pixelBuf, UInt32 offset, void *context)
{	
	double amount = *((double*)context);
	int r = offset;
	int g = offset+1;
	int b = offset+2;
	
	int red = pixelBuf[r];
	int green = pixelBuf[g];
	int blue = pixelBuf[b];
	
	pixelBuf[r] = SAFECOLOR(pow(red,amount));
	pixelBuf[g] = SAFECOLOR(pow(green,amount));
	pixelBuf[b] = SAFECOLOR(pow(blue,amount));
}
void filterOpacity(UInt8 *pixelBuf, UInt32 offset, void *context)
{
	double val = *((double*)context);
	
	int a = offset+3;
	
	int alpha = pixelBuf[a];
	
	pixelBuf[a] = SAFECOLOR(alpha * val);
}

double calcContrast(double f, double c){
	return (f-0.5) * c + 0.5;
}

void filterContrast(UInt8 *pixelBuf, UInt32 offset, void *context)
{
	double val = *((double*)context);
	int r = offset;
	int g = offset+1;
	int b = offset+2;
	
	int red = pixelBuf[r];
	int green = pixelBuf[g];
	int blue = pixelBuf[b];
	
	pixelBuf[r] = SAFECOLOR(255 * calcContrast((double)((double)red / 255.0f), val));
	pixelBuf[g] = SAFECOLOR(255 * calcContrast((double)((double)green / 255.0f), val));
	pixelBuf[b] = SAFECOLOR(255 * calcContrast((double)((double)blue / 255.0f), val));
}

double calcBias(double f, double bi){
	return (double) (f / ((1.0 / bi - 1.9) * (0.9 - f) + 1));
}

void filterBias(UInt8 *pixelBuf, UInt32 offset, void *context)
{
	double val = *((double*)context);
	int r = offset;
	int g = offset+1;
	int b = offset+2;
	
	int red = pixelBuf[r];
	int green = pixelBuf[g];
	int blue = pixelBuf[b];
	
	pixelBuf[r] = SAFECOLOR((red * calcBias(((double)red / 255.0f), val)));
	pixelBuf[g] = SAFECOLOR((green * calcBias(((double)green / 255.0f), val)));
	pixelBuf[b] = SAFECOLOR((blue * calcBias(((double)blue / 255.0f), val)));
}

void filterInvert(UInt8 *pixelBuf, UInt32 offset, void *context)
{	
	int r = offset;
	int g = offset+1;
	int b = offset+2;
	
	int red = pixelBuf[r];
	int green = pixelBuf[g];
	int blue = pixelBuf[b];
	
	pixelBuf[r] = SAFECOLOR(255-red);
	pixelBuf[g] = SAFECOLOR(255-green);
	pixelBuf[b] = SAFECOLOR(255-blue);
}

//
// Noise filter was adapted from ImageMagick
//
static inline Quantum ClampToQuantum(const MagickRealType value)
{
	if (value <= 0.0)
		return((Quantum) 0);
	if (value >= (MagickRealType) QuantumRange)
		return((Quantum) QuantumRange);
	return((Quantum) (value+0.5));
}

static inline double RandBetweenZeroAndOne() 
{
	double value = arc4random() % 1000000;
	value = value / 1000000;
	return value;
}	

static inline Quantum GenerateGaussianNoise(double alpha, const Quantum pixel)
{	
	double beta = RandBetweenZeroAndOne();
	double sigma = sqrt(-2.0*log((double) alpha))*cos((double) (2.0*M_PI*beta));
	double tau = sqrt(-2.0*log((double) alpha))*sin((double) (2.0*M_PI*beta));
	double noise = (MagickRealType) pixel+sqrt((double) pixel)*SigmaGaussian*sigma+TauGaussian*tau;
    
	return RoundToQuantum(noise);
}	

void filterNoise(UInt8 *pixelBuf, UInt32 offset, void *context)
{	
	double alpha = 1.0 - *((double*)context);
    
	int r = offset;
	int g = offset+1;
	int b = offset+2;
	
	int red = pixelBuf[r];
	int green = pixelBuf[g];
	int blue = pixelBuf[b];
    
	pixelBuf[r] = GenerateGaussianNoise(alpha, red);
	pixelBuf[g] = GenerateGaussianNoise(alpha, green);
	pixelBuf[b] = GenerateGaussianNoise(alpha, blue);
}

+ (UIImage*) kGrayScaleOnImage : (UIImage*) inputImage {
    return [self applyFilterOnImage:inputImage andFilter:filterGreyscale context:nil];
}
+ (UIImage*) kSepiaOnImage : (UIImage*) inputImage {
    return [self applyFilterOnImage:inputImage andFilter:filterSepia context:nil];
}
+ (UIImage*) kPosterizeImage : (UIImage*) inputImage withLevels : (float) level {
    int levelIntValue = (int)level;
    return [self applyFilterOnImage:inputImage andFilter:filterPosterize context:&levelIntValue];
}
+(UIImage*) kSaturateImage : (UIImage*) inputImage withAmount : (double) amount {
    return [self applyFilterOnImage:inputImage andFilter:filterSaturate context:&amount];
}
+(UIImage*) kBrightnessAdjustOnImage : (UIImage*) inputImage withAmount : (double) amount {
    return [self applyFilterOnImage:inputImage andFilter:filterBrightness context:&amount];
}
+(UIImage*) kGammaAdjustOnImage : (UIImage*) inputImage withAmount : (double) amount {
    return [self applyFilterOnImage:inputImage andFilter:filterGamma context:&amount];
}
+(UIImage*) kOpacityOnImage : (UIImage*) inputImage withAmount : (double) amount {
    return [self applyFilterOnImage:inputImage andFilter:filterOpacity context:&amount];
}
+(UIImage*) kContrastOnImage : (UIImage*) inputImage WithAmount : (double) amount {
    return [self applyFilterOnImage:inputImage andFilter:filterContrast context:&amount];
}
+(UIImage*) kBiasOnImage : (UIImage*) inputImage WithAmount : (double) amount {
    return [self applyFilterOnImage:inputImage andFilter:filterBias context:&amount];	
}
+(UIImage*) kInvertOnImage : (UIImage*) inputImage {
    return [self applyFilterOnImage:inputImage andFilter:filterInvert context:nil];
}
+(UIImage*) kNoisOnImage : (UIImage*) inputImage WithAmount : (double) amount {
    return [self applyFilterOnImage:inputImage andFilter:filterNoise context:&amount];
}

+ (UIImage*) applyBlendFilterOnImage : (UIImage*) inputImage andFilter : (FilterBlendCallback)filter other:(UIImage*)other context:(void*)context
{
	CGImageRef inImage = inputImage.CGImage;
	CFMutableDataRef m_DataRef = CFDataCreateMutableCopy(0, 0, CGDataProviderCopyData(CGImageGetDataProvider(inImage)));  
	UInt8 * m_PixelBuf = (UInt8 *) CFDataGetMutableBytePtr(m_DataRef);  	
	
	CGImageRef otherImage = other.CGImage;
	CFMutableDataRef m_OtherDataRef =  CFDataCreateMutableCopy(0, 0, CGDataProviderCopyData(CGImageGetDataProvider(otherImage)));
	UInt8 * m_OtherPixelBuf = (UInt8 *) CFDataGetMutableBytePtr(m_OtherDataRef);  	
	
	int h = inputImage.size.height;
	int w = inputImage.size.width;
	
	
	for (int i=0; i<h; i++)
	{
		for (int j = 0; j < w; j++)
		{
			int index = (i*w*4) + (j*4);
			filter(m_PixelBuf,m_OtherPixelBuf,index,context);			
		}
	}  
	
	CGContextRef ctx = CGBitmapContextCreate(m_PixelBuf,  
											 CGImageGetWidth(inImage),  
											 CGImageGetHeight(inImage),  
											 CGImageGetBitsPerComponent(inImage),
											 CGImageGetBytesPerRow(inImage),  
											 CGImageGetColorSpace(inImage),  
											 CGImageGetBitmapInfo(inImage) 
											 ); 
	
	CGImageRef imageRef = CGBitmapContextCreateImage(ctx);  
	CGContextRelease(ctx);
	UIImage *finalImage = [UIImage imageWithCGImage:imageRef];
	CGImageRelease(imageRef);
    CFRelease(m_DataRef);
	CFRelease(m_OtherDataRef);
	return finalImage;
	
}

double calcOverlay(float b, float t) {
	return (b > 128.0f) ? 255.0f - 2.0f * (255.0f - t) * (255.0f - b) / 255.0f: (b * t * 2.0f) / 255.0f;
}

void filterOverlay(UInt8 *pixelBuf, UInt8 *pixedBlendBuf, UInt32 offset, void *context)
{	
	int r = offset;
	int g = offset+1;
	int b = offset+2;
	int a = offset+3;
	
	int red = pixelBuf[r];
	int green = pixelBuf[g];
	int blue = pixelBuf[b];
	
	int blendRed = pixedBlendBuf[r];
	int blendGreen = pixedBlendBuf[g];
	int blendBlue = pixedBlendBuf[b];
	double blendAlpha = pixedBlendBuf[a] / 255.0f;
	
	// http://en.wikipedia.org/wiki/Alpha_compositing
	//	double blendAlpha = pixedBlendBuf[a] / 255.0f;
	//	double blendRed = pixedBlendBuf[r] * blendAlpha + red * (1-blendAlpha);
	//	double blendGreen = pixedBlendBuf[g] * blendAlpha + green * (1-blendAlpha);
	//	double blendBlue = pixedBlendBuf[b] * blendAlpha + blue * (1-blendAlpha);
	
	int resultR = SAFECOLOR(calcOverlay(red, blendRed));
	int resultG = SAFECOLOR(calcOverlay(green, blendGreen));
	int resultB = SAFECOLOR(calcOverlay(blue, blendBlue));
	
	// take this result, and blend it back again using the alpha of the top guy	
	pixelBuf[r] = SAFECOLOR(resultR * blendAlpha + red * (1 - blendAlpha));
	pixelBuf[g] = SAFECOLOR(resultG * blendAlpha + green * (1 - blendAlpha));
	pixelBuf[b] = SAFECOLOR(resultB * blendAlpha + blue * (1 - blendAlpha));
	
}

void filterMask(UInt8 *pixelBuf, UInt8 *pixedBlendBuf, UInt32 offset, void *context)
{	
	int r = offset;
    //	int g = offset+1;
    //	int b = offset+2;
	int a = offset+3;
    
	// take this result, and blend it back again using the alpha of the top guy	
	pixelBuf[a] = pixedBlendBuf[r];
}

void filterMerge(UInt8 *pixelBuf, UInt8 *pixedBlendBuf, UInt32 offset, void *context)
{	
	int r = offset;
	int g = offset+1;
	int b = offset+2;
	int a = offset+3;
	
	int red = pixelBuf[r];
	int green = pixelBuf[g];
	int blue = pixelBuf[b];
	
	int blendRed = pixedBlendBuf[r];
	int blendGreen = pixedBlendBuf[g];
	int blendBlue = pixedBlendBuf[b];
	double blendAlpha = pixedBlendBuf[a] / 255.0f;
    
	// take this result, and blend it back again using the alpha of the top guy	
	pixelBuf[r] = SAFECOLOR(blendRed * blendAlpha + red * (1 - blendAlpha));
	pixelBuf[g] = SAFECOLOR(blendGreen * blendAlpha + green * (1 - blendAlpha));
	pixelBuf[b] = SAFECOLOR(blendBlue * blendAlpha + blue * (1 - blendAlpha));	
}

+(UIImage*) kOverlayOnImage : (UIImage*) inputImage withBackgroundImage : (UIImage*) background {
    return [self applyBlendFilterOnImage:inputImage andFilter:filterOverlay other:background context:nil];
}

+(UIImage*) kMaskOnImage : (UIImage*) inputImage withBackgroundImage : (UIImage*) background {
    return [self applyBlendFilterOnImage:inputImage andFilter:filterMask other:background context:nil];
}

+(UIImage*) kMergeImage : (UIImage*) inputImage withBackgroundImage : (UIImage*) background {
    return [self applyBlendFilterOnImage:inputImage andFilter:filterMerge other:background context:nil];
}

#pragma mark -
#pragma mark Color Correction
#pragma mark C Implementation
typedef struct
{
	int blackPoint;
	int whitePoint;
	int midPoint;
} LevelsOptions;

int calcLevelColor(int color, int black, int mid, int white)
{
	if (color < black) {
		return 0;
	} else if (color < mid) {
		int width = (mid - black);
		double stepSize = ((double)width / 128.0f);
		return (int)((double)(color - black) / stepSize);		
	} else if (color < white) {
		int width = (white - mid);
		double stepSize = ((double)width / 128.0f);
		return 128 + (int)((double)(color - mid) / stepSize);		
	}
	
	return 255;
}
void filterLevels(UInt8 *pixelBuf, UInt32 offset, void *context)
{
	LevelsOptions val = *((LevelsOptions*)context);
	int r = offset;
	int g = offset+1;
	int b = offset+2;
	
	int red = pixelBuf[r];
	int green = pixelBuf[g];
	int blue = pixelBuf[b];
	
	pixelBuf[r] = SAFECOLOR(calcLevelColor(red, val.blackPoint, val.midPoint, val.whitePoint));
	pixelBuf[g] = SAFECOLOR(calcLevelColor(green, val.blackPoint, val.midPoint, val.whitePoint));
	pixelBuf[b] = SAFECOLOR(calcLevelColor(blue, val.blackPoint, val.midPoint, val.whitePoint));
}

double valueGivenCurve(CurveEquation equation, double xValue)
{
	assert(xValue <= 255);
	assert(xValue >= 0);
	
	CGPoint point1 = CGPointZero;
	CGPoint point2 = CGPointZero;
	NSInteger idx = 0;
	
	for (idx = 0; idx < equation.length; idx++)
	{
		CGPoint point = equation.points[idx];
		if (xValue < point.x)
		{
			point2 = point;
			if (idx - 1 >= 0)
			{
				point1 = equation.points[idx-1];
			}
			else
			{
				point1 = point2;
			}
			
			break;
		}		
	}
	
	double m = (point2.y - point1.y)/(point2.x - point1.x);
	double b = point2.y - (m * point2.x);
	double y = m * xValue + b;
	return y;
}

void filterCurve(UInt8 *pixelBuf, UInt32 offset, void *context)
{
	CurveEquation equation = *((CurveEquation*)context);
	
	int r = offset;
	int g = offset+1;
	int b = offset+2;
	
	int red = pixelBuf[r];
	int green = pixelBuf[g];
	int blue = pixelBuf[b];
	
	red = equation.channel & CurveChannelRed ? valueGivenCurve(equation, red) : red;
	green = equation.channel & CurveChannelGreen ? valueGivenCurve(equation, green) : green;
	blue = equation.channel & CurveChannelBlue ? valueGivenCurve(equation, blue) : blue;
	
	pixelBuf[r] = SAFECOLOR(red);
	pixelBuf[g] = SAFECOLOR(green);
	pixelBuf[b] = SAFECOLOR(blue);
}
typedef struct 
{
	double r;
	double g;
	double b;
} RGBAdjust;


void filterAdjust(UInt8 *pixelBuf, UInt32 offset, void *context)
{
	RGBAdjust val = *((RGBAdjust*)context);
	int r = offset;
	int g = offset+1;
	int b = offset+2;
	
	int red = pixelBuf[r];
	int green = pixelBuf[g];
	int blue = pixelBuf[b];
	
	pixelBuf[r] = SAFECOLOR(red * (1 + val.r));
	pixelBuf[g] = SAFECOLOR(green * (1 + val.g));
	pixelBuf[b] = SAFECOLOR(blue * (1 + val.b));
}

/*
 * Levels: Similar to levels in photoshop. 
 * todo: Specify per-channel
 *
 * Parameters:
 *   black: 0-255
 *   mid: 0-255
 *   white: 0-255
 */
+(UIImage*) kLevelsWithInputImage : (UIImage*) inputImage Black : (NSInteger) black Mid : (NSInteger) mid White :(NSInteger) white {
    LevelsOptions l;
	l.midPoint = mid;
	l.whitePoint = white;
	l.blackPoint = black;
    
    return [self applyFilterOnImage:inputImage andFilter:filterLevels context:&l];
}
/*
 * Levels: Similar to curves in photoshop. 
 * todo: Use a Bicubic spline not a catmull rom spline
 *
 * Parameters:
 *   points: An NSArray of CGPoints through which the curve runs
 *   toChannel: A bitmask of the channels to which the curve gets applied
 */

+(UIImage*) kRedCurveToImage : (UIImage*) inputImge WithRedChannelPoints : (NSMutableArray*) points {
    CGPoint firstPoint = ((NSValue*)[points objectAtIndex:0]).CGPointValue;
	CatmullRomSpline *spline = [CatmullRomSpline catmullRomSplineAtPoint:firstPoint];	
	NSInteger idx = 0;
	NSInteger length = [points count];
	for (idx = 1; idx < length; idx++)
	{
		CGPoint point = ((NSValue*)[points objectAtIndex:idx]).CGPointValue;
		[spline addPoint:point];
		NSLog(@"Adding point %@",NSStringFromCGPoint(point));
	}		
	
	NSArray *splinePoints = [spline asPointArray];		
	length = [splinePoints count];
	CGPoint *cgPoints = malloc(sizeof(CGPoint) * length);
	memset(cgPoints, 0, sizeof(CGPoint) * length);
	for (idx = 0; idx < length; idx++)
	{
		CGPoint point = ((NSValue*)[splinePoints objectAtIndex:idx]).CGPointValue;
		NSLog(@"Adding point %@",NSStringFromCGPoint(point));
		cgPoints[idx].x = point.x;
		cgPoints[idx].y = point.y;
	}
	
	CurveEquation equation;
	equation.length = length;
	equation.points = cgPoints;	
	equation.channel = CurveChannelRed;
    UIImage *result = [self applyFilterOnImage:inputImge andFilter:filterCurve context:&equation];	
	free(cgPoints);
	return result;
}

+(UIImage*) kGreenCurveToImage : (UIImage*) inputImge WithGreenChannelPoints : (NSMutableArray*) points {
    CGPoint firstPoint = ((NSValue*)[points objectAtIndex:0]).CGPointValue;
	CatmullRomSpline *spline = [CatmullRomSpline catmullRomSplineAtPoint:firstPoint];	
	NSInteger idx = 0;
	NSInteger length = [points count];
	for (idx = 1; idx < length; idx++)
	{
		CGPoint point = ((NSValue*)[points objectAtIndex:idx]).CGPointValue;
		[spline addPoint:point];
		NSLog(@"Adding point %@",NSStringFromCGPoint(point));
	}		
	
	NSArray *splinePoints = [spline asPointArray];		
	length = [splinePoints count];
	CGPoint *cgPoints = malloc(sizeof(CGPoint) * length);
	memset(cgPoints, 0, sizeof(CGPoint) * length);
	for (idx = 0; idx < length; idx++)
	{
		CGPoint point = ((NSValue*)[splinePoints objectAtIndex:idx]).CGPointValue;
		NSLog(@"Adding point %@",NSStringFromCGPoint(point));
		cgPoints[idx].x = point.x;
		cgPoints[idx].y = point.y;
	}
	
	CurveEquation equation;
	equation.length = length;
	equation.points = cgPoints;	
	equation.channel = CurveChannelGreen;
    UIImage *result = [self applyFilterOnImage:inputImge andFilter:filterCurve context:&equation];	
	free(cgPoints);
	return result;
}
+(UIImage*) kBlueCurveToImage : (UIImage*) inputImge WithBlueChannelPoints : (NSMutableArray*) points {
    CGPoint firstPoint = ((NSValue*)[points objectAtIndex:0]).CGPointValue;
	CatmullRomSpline *spline = [CatmullRomSpline catmullRomSplineAtPoint:firstPoint];	
	NSInteger idx = 0;
	NSInteger length = [points count];
	for (idx = 1; idx < length; idx++)
	{
		CGPoint point = ((NSValue*)[points objectAtIndex:idx]).CGPointValue;
		[spline addPoint:point];
		NSLog(@"Adding point %@",NSStringFromCGPoint(point));
	}		
	
	NSArray *splinePoints = [spline asPointArray];		
	length = [splinePoints count];
	CGPoint *cgPoints = malloc(sizeof(CGPoint) * length);
	memset(cgPoints, 0, sizeof(CGPoint) * length);
	for (idx = 0; idx < length; idx++)
	{
		CGPoint point = ((NSValue*)[splinePoints objectAtIndex:idx]).CGPointValue;
		NSLog(@"Adding point %@",NSStringFromCGPoint(point));
		cgPoints[idx].x = point.x;
		cgPoints[idx].y = point.y;
	}
	
	CurveEquation equation;
	equation.length = length;
	equation.points = cgPoints;	
	equation.channel = CurveChannelBlue;
    UIImage *result = [self applyFilterOnImage:inputImge andFilter:filterCurve context:&equation];	
	free(cgPoints);
	return result;
}
/*
 * adjust: Similar to color balance
 *
 * Parameters:
 *   r: Multiplier of r. Make < 0 to reduce red, > 0 to increase red
 *   g: Multiplier of g. Make < 0 to reduce green, > 0 to increase green
 *   b: Multiplier of b. Make < 0 to reduce blue, > 0 to increase blue
 */
+(UIImage*) kAdjustImage : (UIImage*) inputImage WithRed : (double) red Green : (double) green Blue : (double) blue {
    RGBAdjust adjust;
	adjust.r = red;
	adjust.g = green;
	adjust.b = blue;
    return [self applyFilterOnImage:inputImage andFilter:filterAdjust context:&adjust];
}

+ (UIImage*) applyConvolveOnImage : (UIImage*) inputImage andKernel : (NSArray*) kernel {
	CGImageRef inImage = inputImage.CGImage;
	CFMutableDataRef m_DataRef = CFDataCreateMutableCopy(0, 0, CGDataProviderCopyData(CGImageGetDataProvider(inImage)));  
	CFMutableDataRef m_OutDataRef = CFDataCreateMutableCopy(0, 0, CGDataProviderCopyData(CGImageGetDataProvider(inImage)));  
	UInt8 * m_PixelBuf = (UInt8 *) CFDataGetMutableBytePtr(m_DataRef);  
	UInt8 * m_OutPixelBuf = (UInt8 *) CFDataGetMutableBytePtr(m_OutDataRef);  
	
	int h = CGImageGetHeight(inImage);
	int w = CGImageGetWidth(inImage);
	
	int kh = [kernel count] / 2;
	int kw = [[kernel objectAtIndex:0] count] / 2;
	int i = 0, j = 0, n = 0, m = 0;
	
	for (i = 0; i < h; i++) {
		for (j = 0; j < w; j++) {
			int outIndex = (i*w*4) + (j*4);
			double r = 0, g = 0, b = 0;
			for (n = -kh; n <= kh; n++) {
				for (m = -kw; m <= kw; m++) {
					if (i + n >= 0 && i + n < h) {
						if (j + m >= 0 && j + m < w) {
							double f = [[[kernel objectAtIndex:(n + kh)] objectAtIndex:(m + kw)] doubleValue];
							if (f == 0) {continue;}
							int inIndex = ((i+n)*w*4) + ((j+m)*4);
							r += m_PixelBuf[inIndex] * f;
							g += m_PixelBuf[inIndex + 1] * f;
							b += m_PixelBuf[inIndex + 2] * f;
						}
					}
				}
			}
			m_OutPixelBuf[outIndex]     = SAFECOLOR((int)r);
			m_OutPixelBuf[outIndex + 1] = SAFECOLOR((int)g);
			m_OutPixelBuf[outIndex + 2] = SAFECOLOR((int)b);
			m_OutPixelBuf[outIndex + 3] = 255;
		}
	}
	
	CGContextRef ctx = CGBitmapContextCreate(m_OutPixelBuf,  
											 CGImageGetWidth(inImage),  
											 CGImageGetHeight(inImage),  
											 CGImageGetBitsPerComponent(inImage),
											 CGImageGetBytesPerRow(inImage),  
											 CGImageGetColorSpace(inImage),  
											 CGImageGetBitmapInfo(inImage) 
											 ); 
	
	CGImageRef imageRef = CGBitmapContextCreateImage(ctx);  
	CGContextRelease(ctx);
	UIImage *finalImage = [UIImage imageWithCGImage:imageRef];
	CGImageRelease(imageRef);
	CFRelease(m_DataRef);
    CFRelease(m_OutDataRef);
	return finalImage;
}

+(UIImage*) kSharpenImage : (UIImage*) inputImage {
    double dKernel[5][5]={ 
		{0, 0.0, -0.2,  0.0, 0},
		{0, -0.2, 1.8, -0.2, 0},
		{0, 0.0, -0.2,  0.0, 0}};
    
	NSMutableArray *kernel = [[NSMutableArray alloc] initWithCapacity:5];
	for (int i = 0; i < 5; i++) {
		NSMutableArray *row = [[NSMutableArray alloc] initWithCapacity:5];
		for (int j = 0; j < 5; j++) {
			[row addObject:[NSNumber numberWithDouble:dKernel[i][j]]];
		}
		[kernel addObject:row];
	}
	return [self applyConvolveOnImage:inputImage andKernel:kernel];
}

+ (UIImage*) kEdgeDetectOfImage : (UIImage*) inputImage {
	double dKernel[5][5]={ 
		{0, 0.0, 1.0,  0.0, 0},
		{0, 1.0, -4.0, 1.0, 0},
		{0, 0.0, 1.0,  0.0, 0}};
	
	NSMutableArray *kernel = [[NSMutableArray alloc] initWithCapacity:5];
	for (int i = 0; i < 5; i++) {
		NSMutableArray *row = [[NSMutableArray alloc] initWithCapacity:5];
		for (int j = 0; j < 5; j++) {
			[row addObject:[NSNumber numberWithDouble:dKernel[i][j]]];
		}
		[kernel addObject:row];
	}
	return [self applyConvolveOnImage:inputImage andKernel:kernel];
}

+ (UIImage*) kDarkVignetteEffectOnImage : (UIImage*) inputImage
{
	CGImageRef inImage = inputImage.CGImage;
	CFMutableDataRef m_DataRef = CFDataCreateMutableCopy(0, 0, CGDataProviderCopyData(CGImageGetDataProvider(inImage)));  
	UInt8 * m_PixelBuf = (UInt8 *) CFDataGetMutableBytePtr(m_DataRef);  	
	int length = CFDataGetLength(m_DataRef);
	memset(m_PixelBuf,0,length);
	
	CGContextRef ctx = CGBitmapContextCreate(m_PixelBuf,  
											 CGImageGetWidth(inImage),  
											 CGImageGetHeight(inImage),  
											 CGImageGetBitsPerComponent(inImage),
											 CGImageGetBytesPerRow(inImage),  
											 CGImageGetColorSpace(inImage),  
											 CGImageGetBitmapInfo(inImage) 
											 ); 
	
	
	int borderWidth = 0.05 * inputImage.size.width;
	CGContextSetRGBFillColor(ctx, 1.0,1.0,1.0,1);
	CGContextFillRect(ctx, CGRectMake(0, 0, inputImage.size.width, inputImage.size.height));
	CGContextSetRGBFillColor(ctx, 0,0,0,1);
	CGContextFillRect(ctx, CGRectMake(borderWidth, borderWidth, 
                                      inputImage.size.width-(2*borderWidth), 
                                      inputImage.size.height-(2*borderWidth)));
	
	CGImageRef imageRef = CGBitmapContextCreateImage(ctx);  
	CGContextRelease(ctx);
	UIImage *finalImage = [UIImage imageWithCGImage:imageRef];
	CGImageRelease(imageRef);	

	UIImage *mask = [self kGaussianBlurOfImage:finalImage andRadius:10.00];

    
	
	ctx = CGBitmapContextCreate(m_PixelBuf,  
                                CGImageGetWidth(inImage),  
                                CGImageGetHeight(inImage),  
                                CGImageGetBitsPerComponent(inImage),
                                CGImageGetBytesPerRow(inImage),  
                                CGImageGetColorSpace(inImage),  
                                CGImageGetBitmapInfo(inImage) 
                                ); 
	CGContextSetRGBFillColor(ctx, 0,0,0,1);
	CGContextFillRect(ctx, CGRectMake(0, 0, inputImage.size.width, inputImage.size.height));
	imageRef = CGBitmapContextCreateImage(ctx);  
	CGContextRelease(ctx);
	UIImage *blackSquare = [UIImage imageWithCGImage:imageRef];
	CGImageRelease(imageRef);	
	CFRelease(m_DataRef);	
    
    UIImage *maskedSquare = [UIImage kMaskOnImage:blackSquare withBackgroundImage:mask];
    
    return [self kOverlayOnImage:inputImage withBackgroundImage:[UIImage kOpacityOnImage:maskedSquare withAmount:1.00]];
}

+ (UIImage*) kLomoOfImage : (UIImage*) inputImage {
    UIImage *image = [UIImage kSaturateImage:inputImage withAmount:1.2];
    image = [UIImage kContrastOnImage:image WithAmount:1.15];
	NSMutableArray *redPoints = [NSMutableArray arrayWithObjects:
                          [NSValue valueWithCGPoint:CGPointMake(0, 0)],
                          [NSValue valueWithCGPoint:CGPointMake(137, 118)],
                          [NSValue valueWithCGPoint:CGPointMake(255, 255)],
						  [NSValue valueWithCGPoint:CGPointMake(255, 255)],
                          nil];
	NSMutableArray *greenPoints = [NSMutableArray arrayWithObjects:
                            [NSValue valueWithCGPoint:CGPointMake(0, 0)],
                            [NSValue valueWithCGPoint:CGPointMake(64, 54)],
                            [NSValue valueWithCGPoint:CGPointMake(175, 194)],
                            [NSValue valueWithCGPoint:CGPointMake(255, 255)],
                            nil];
	NSMutableArray *bluePoints = [NSMutableArray arrayWithObjects:
                           [NSValue valueWithCGPoint:CGPointMake(0, 0)],
                           [NSValue valueWithCGPoint:CGPointMake(59, 64)],
						   [NSValue valueWithCGPoint:CGPointMake(203, 189)],
                           [NSValue valueWithCGPoint:CGPointMake(255, 255)],
                           nil];
    image = [UIImage kRedCurveToImage:image WithRedChannelPoints:redPoints];
    image = [UIImage kGreenCurveToImage:image WithGreenChannelPoints:greenPoints];
    image = [UIImage kBlueCurveToImage:image WithBlueChannelPoints:bluePoints];
	
	return [self kDarkVignetteEffectOnImage:image];
}

+ (UIImage*) kVignetteOnImage : (UIImage*) inputImage
{
	CGImageRef inImage = inputImage.CGImage;
	CFMutableDataRef m_DataRef = CFDataCreateMutableCopy(0, 0, CGDataProviderCopyData(CGImageGetDataProvider(inImage)));  
	UInt8 * m_PixelBuf = (UInt8 *) CFDataGetMutableBytePtr(m_DataRef);  	
	int length = CFDataGetLength(m_DataRef);
	memset(m_PixelBuf,0,length);
	
	CGContextRef ctx = CGBitmapContextCreate(m_PixelBuf,  
											 CGImageGetWidth(inImage),  
											 CGImageGetHeight(inImage),  
											 CGImageGetBitsPerComponent(inImage),
											 CGImageGetBytesPerRow(inImage),  
											 CGImageGetColorSpace(inImage),  
											 CGImageGetBitmapInfo(inImage) 
											 ); 
	
	
	int borderWidth = 0.10 * inputImage.size.width;
	CGContextSetRGBFillColor(ctx, 0,0,0,1);
	CGContextFillRect(ctx, CGRectMake(0, 0, inputImage.size.width, inputImage.size.height));
	CGContextSetRGBFillColor(ctx, 1.0,1.0,1.0,1);
	CGContextFillEllipseInRect(ctx, CGRectMake(borderWidth, borderWidth, 
                                               inputImage.size.width-(2*borderWidth), 
                                               inputImage.size.height-(2*borderWidth)));
	
	CGImageRef imageRef = CGBitmapContextCreateImage(ctx);  
	CGContextRelease(ctx);
	UIImage *finalImage = [UIImage imageWithCGImage:imageRef];
	CGImageRelease(imageRef);
	CFRelease(m_DataRef);
    
	UIImage *mask = [self kGaussianBlurOfImage:finalImage andRadius:10.00];//[finalImage gaussianBlur:10];
	UIImage *blurredSelf = [self kGaussianBlurOfImage:inputImage andRadius:2.00];//[inputImage gaussianBlur:2];
	UIImage *maskedSelf = [self kMaskOnImage:inputImage withBackgroundImage:mask];//[inputImage mask:mask];
	return [self kMergeImage:blurredSelf withBackgroundImage:maskedSelf];//[blurredSelf merge:maskedSelf];
}

+ (UIImage*) kPolaroidishOnImage : (UIImage*) inputImage {
    NSMutableArray *redPoints = [NSMutableArray arrayWithObjects:
                          [NSValue valueWithCGPoint:CGPointMake(0, 0)],
                          [NSValue valueWithCGPoint:CGPointMake(93, 81)],
                          [NSValue valueWithCGPoint:CGPointMake(247, 241)],
						  [NSValue valueWithCGPoint:CGPointMake(255, 255)],
                          nil];
	NSMutableArray *bluePoints = [NSMutableArray arrayWithObjects:
                           [NSValue valueWithCGPoint:CGPointMake(0, 0)],
                           [NSValue valueWithCGPoint:CGPointMake(57, 59)],
                           [NSValue valueWithCGPoint:CGPointMake(223, 205)],
                           [NSValue valueWithCGPoint:CGPointMake(255, 241)],
                           nil];
	UIImage *image = [self kRedCurveToImage:inputImage WithRedChannelPoints:redPoints];    
    image = [self kBlueCurveToImage:image WithBlueChannelPoints:bluePoints];
                         
	redPoints = [NSArray arrayWithObjects:
                 [NSValue valueWithCGPoint:CGPointMake(0, 0)],
                 [NSValue valueWithCGPoint:CGPointMake(93, 76)],
                 [NSValue valueWithCGPoint:CGPointMake(232, 226)],
                 [NSValue valueWithCGPoint:CGPointMake(255, 255)],
                 nil];
	bluePoints = [NSArray arrayWithObjects:
                  [NSValue valueWithCGPoint:CGPointMake(0, 0)],
                  [NSValue valueWithCGPoint:CGPointMake(57, 59)],
                  [NSValue valueWithCGPoint:CGPointMake(220, 202)],
                  [NSValue valueWithCGPoint:CGPointMake(255, 255)],
                  nil];
    image = [self kRedCurveToImage:image WithRedChannelPoints:redPoints];
    image = [self kBlueCurveToImage:image WithBlueChannelPoints:bluePoints];
	
	
    return image;
}

+ (UIImage*) kBlueMoodOnInputImage : (UIImage*) inputImage {
    return [self CIFalseColorWithInputImage:inputImage inputColor0:[CIColor colorWithRed:0.0 green:0.0 blue:1.0 alpha:1.0] inputColor1:[CIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:1.0]];
}

+ (UIImage*) kSunKissedOnImage : (UIImage*) inputImage {
    static const CGFloat redVector[4]   = { 1.f, 0.0f, 0.0f, 0.0f };
    static const CGFloat greenVector[4] = { 0.0f, .6f, 0.0f, 0.0f };
    static const CGFloat blueVector[4]  = { 0.0f, 0.0f, .3f, 0.0f };
    static const CGFloat alphaVector[4] = { 0.0f, 0.0f, 0.0f, 1.0f };
    static const CGFloat biasVector[4]  = { .2f, .2f, .2f, 0.0f };
    
    inputImage = [self CIColorMatrixWithInputImage:inputImage inputRVector:[CIVector vectorWithValues:redVector count:4] inputGVector:[CIVector vectorWithValues:greenVector count:4] inputBVector:[CIVector vectorWithValues:blueVector count:4] inputAVector:[CIVector vectorWithValues:alphaVector count:4] inputBiasVector:[CIVector vectorWithValues:biasVector count:4]];
    return [self CIColorControlsWithInputImage:inputImage inputSaturation:1.00 inputBrightness:.4 inputContrast:3.0];
    
}

+ (UIImage*) kPolarizeOnImage : (UIImage*) inputImage {
    static const CGFloat redVector[4]   = { 1.f, 0.0f, 0.0f, 0.0f };
    static const CGFloat greenVector[4] = { 0.0f, .5f, 0.0f, 0.0f };
    static const CGFloat blueVector[4]  = { 0.0f, 0.0f, 1.f, 0.0f };
    static const CGFloat alphaVector[4] = { 0.0f, 0.0f, 0.0f, 1.0f };
    static const CGFloat biasVector[4]  = { .2f, .2f, .2f, 0.0f };
    
    inputImage = [self CIColorMatrixWithInputImage:inputImage inputRVector:[CIVector vectorWithValues:redVector count:4] inputGVector:[CIVector vectorWithValues:greenVector count:4] inputBVector:[CIVector vectorWithValues:blueVector count:4] inputAVector:[CIVector vectorWithValues:alphaVector count:4] inputBiasVector:[CIVector vectorWithValues:biasVector count:4]];
    return [self CIColorControlsWithInputImage:inputImage inputSaturation:1.00 inputBrightness:0.4 inputContrast:3.0];
}

+ (UIImage*) kEnvyOnImage : (UIImage*) inputImage {
    return [self CIFalseColorWithInputImage:inputImage inputColor0:[CIColor colorWithRed:0.0 green:1.0 blue:0.0 alpha:1.0] inputColor1:[CIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:1.0]];
}

+ (UIImage*) kCrossProcessOnImage : (UIImage*) inputImage withBackgroundImage : (UIImage*) backgroundImage {
    inputImage = [self CIColorControlsWithInputImage:inputImage inputSaturation:.4 inputBrightness:0.00 inputContrast:1.00];
    //inputImage = [UIImage imageNamed:@"crossprocess.png"];
    
    return [self CIOverlayBlendModeWithInputImage:backgroundImage andInputBackgroundImage:inputImage];
}

+ (UIImage*) kMagicHourOnImage : (UIImage*) inputImage withBackgroundImage : (UIImage*) backgroundImage {
    inputImage = [self CIColorControlsWithInputImage:inputImage inputSaturation:1.00 inputBrightness:0.00 inputContrast:1.00];
    //inputImage = [UIImage imageNamed:@"magichour2.png"];
    return [self CIMultiplyBlendModeWithInputImage:backgroundImage andInputBackgroundImage:inputImage];
}

+ (UIImage*) kToycameraOnImage : (UIImage*) inputImage withBackgroundImage : (UIImage*) backgroungImage {
    //UIImage *backgroundImage = inputImage;
    //inputImage = [UIImage imageNamed:@"toycamera.png"];
    return [self CIOverlayBlendModeWithInputImage:backgroungImage andInputBackgroundImage:inputImage];
    
}

+ (UIImage*) kE1ofFilterAppOnImage : (UIImage*) inputImage {
    UIImage *topImage = [inputImage duplicate];
    topImage = [[topImage saturationByFactor:0] blur];
    
    UIImage * newImage = [inputImage multiply:topImage];
    
    RGBA minrgb, maxrgb;
    
    minrgb.red = 60;
    minrgb.green = 35;
    minrgb.blue = 10;
    
    maxrgb.red = 170;
    maxrgb.green = 140;
    maxrgb.blue = 160;
    
    newImage = [[[inputImage tintWithMinRGB:minrgb MaxRGB:maxrgb] contrastByFactor:0.8] brightnessByFactor:10];
    
    return newImage;
}
+ (UIImage*) kE2ofFilterAppOnImage : (UIImage*) inputImage {
    RGBA minrgb, maxrgb;
    
    minrgb.red = 50;
    minrgb.green = 35;
    minrgb.blue = 10;
    
    maxrgb.red = 190;
    maxrgb.green = 190;
    maxrgb.blue = 230;
    
    return [[[inputImage saturationByFactor:0.3] posterizeByLevel:70] tintWithMinRGB:minrgb MaxRGB:maxrgb];
}
+ (UIImage*) kE3ofFilterAppOnImage : (UIImage*) inputImage {
    RGBA minrgb, maxrgb;
    
    minrgb.red = 60;
    minrgb.green = 35;
    minrgb.blue = 10;
    
    maxrgb.red = 170;
    maxrgb.green = 170;
    maxrgb.blue = 230;
    
    return [[inputImage tintWithMinRGB:minrgb MaxRGB:maxrgb] contrastByFactor:0.8];
}
+ (UIImage*) kE4ofFilterAppOnImage : (UIImage*) inputImage {
    RGBA minrgb, maxrgb;
    
    minrgb.red = 60;
    minrgb.green = 60;
    minrgb.blue = 30;
    
    maxrgb.red = 210;
    maxrgb.green = 210;
    maxrgb.blue = 210;
    
    return [[inputImage grayScale] tintWithMinRGB:minrgb MaxRGB:maxrgb];

}
+ (UIImage*) kE5ofFilterAppOnImage : (UIImage*) inputImage {
    RGBA minrgb, maxrgb;
    
    minrgb.red = 30;
    minrgb.green = 40;
    minrgb.blue = 30;
    
    maxrgb.red = 120;
    maxrgb.green = 170;
    maxrgb.blue = 210;
    
    return [[[[[inputImage tintWithMinRGB:minrgb MaxRGB:maxrgb] contrastByFactor:0.75] biasByFactor:1] saturationByFactor:0.6] brightnessByFactor:20];
}
+ (UIImage*) kE6ofFilterAppOnImage : (UIImage*) inputImage {
    RGBA minrgb, maxrgb;
    
    minrgb.red = 30;
    minrgb.green = 40;
    minrgb.blue = 30;
    
    maxrgb.red = 120;
    maxrgb.green = 170;
    maxrgb.blue = 210;
    
    return [[[inputImage saturationByFactor:0.4] contrastByFactor:0.75] tintWithMinRGB:minrgb MaxRGB:maxrgb];
}
+ (UIImage*) kE7ofFilterAppOnImage : (UIImage*) inputImage {
    UIImage *topImage = [inputImage duplicate];
    
    RGBA minrgb, maxrgb;
    
    minrgb.red = 20;
    minrgb.green = 35;
    minrgb.blue = 10;
    
    maxrgb.red = 150;
    maxrgb.green = 160;
    maxrgb.blue = 230;
    
    topImage = [[topImage tintWithMinRGB:minrgb MaxRGB:maxrgb] saturationByFactor:0.6];
    
    UIImage *newImage = [[[inputImage adjustRedChannel:0.1 GreenChannel:0.7 BlueChannel:0.4] saturationByFactor:0.6] contrastByFactor:0.8];
    newImage = [newImage multiply:topImage];
    
    return newImage;

}
+ (UIImage*) kE8ofFilterAppOnImage : (UIImage*) inputImage {
    UIImage *topImage1 = [inputImage duplicate];
    UIImage *topImage2 = [inputImage duplicate];
    UIImage *topImage3 = [inputImage duplicate];
    
    topImage3 = [topImage3 fillRedChannel:167 GreenChannel:118 BlueChannel:12];
    topImage2 = [topImage2 gaussianBlur];
    topImage1 = [topImage1 saturationByFactor:0];
    
    return [[[[[inputImage overlay:topImage1] softLight:topImage2] softLight:topImage3] saturationByFactor:0.5] contrastByFactor:0.86];

}
+ (UIImage*) kE9ofFilterAppOnImage : (UIImage*) inputImage {
    UIImage *topImage = [inputImage duplicate];
    
    DataField shiftIn = DataFieldMake(2, 3, 0, 1);
    DataField shiftOut = DataFieldMake(3, 0, 1, 2);
    
    topImage = [topImage applyFiltrrByStep:4 
                                   ShiftIn:shiftIn
                                  ShiftOut:shiftOut
                                  Callback:^RGBA (int r, int g, int b, int a) {
                                      RGBA retVal;
                                      int t = 0;
                                      float avg = (r + g + b) / 3.0;
                                      
                                      retVal.red = [topImage safe:avg + t * (r - avg)];
                                      retVal.green = [topImage safe:avg + t * (g - avg)];
                                      retVal.blue = [topImage safe:avg + t * (b - avg)];
                                      retVal.alpha = a;
                                      
                                      return retVal;
                                  }];
    
    topImage = [topImage blur];
    
    UIImage * newImage = [inputImage multiply:topImage];
    
    RGBA minrgb, maxrgb;
    
    minrgb.red = 60;
    minrgb.green = 35;
    minrgb.blue = 10;
    
    maxrgb.red = 170;
    maxrgb.green = 140;
    maxrgb.blue = 160;
    
    newImage = [newImage applyFiltrrByStep:4 
                                   ShiftIn:shiftIn
                                  ShiftOut:shiftOut
                                  Callback:^RGBA (int r, int g, int b, int a) {
                                      RGBA retVal;
                                      
                                      retVal.red = [newImage safe:(r - minrgb.red) * (255.0 / (maxrgb.red - minrgb.red))];
                                      retVal.green = [newImage safe:(g - minrgb.green) * (255.0 / (maxrgb.green - minrgb.green))];
                                      retVal.blue = [newImage safe:(b - minrgb.blue) * (255.0 / (maxrgb.blue - minrgb.blue))];
                                      retVal.alpha = a;
                                      
                                      return retVal;
                                  }];
    
    newImage = [newImage applyFiltrrByStep:4 
                                   ShiftIn:shiftIn
                                  ShiftOut:shiftOut
                                  Callback:^RGBA (int r, int g, int b, int a) {
                                      RGBA retVal;
                                      float val = 0.8;
                                      
                                      retVal.red = [newImage safe:(255.0 * [newImage calc_contrast:(r / 255.0) contrast:val])];
                                      retVal.green = [newImage safe:(255.0 * [newImage calc_contrast:(g / 255.0) contrast:val])];
                                      retVal.blue = [newImage safe:(255.0 * [newImage calc_contrast:(b / 255.0) contrast:val])];
                                      retVal.alpha = a;
                                      
                                      return retVal;
                                  }];
    
    newImage = [newImage applyFiltrrByStep:4 
                                   ShiftIn:shiftIn
                                  ShiftOut:shiftOut
                                  Callback:^RGBA (int r, int g, int b, int a) {
                                      RGBA retVal;
                                      float t = 10.0; 
                                      retVal.red = [newImage safe:r + t];
                                      retVal.green = [newImage safe:g + t];
                                      retVal.blue = [newImage safe:b + t];
                                      retVal.alpha = a;
                                      
                                      return retVal;
                                  }];
    
    return newImage;
}
+ (UIImage*) kE10ofFilterAppOnImage : (UIImage*) inputImage {
    return [[inputImage sepia] biasByFactor:0.6];
}
+ (UIImage*) kE11ofFilterAppOnImage : (UIImage*) inputImage {
    UIImage *topImage = [inputImage duplicate];
    
    DataField shiftIn = DataFieldMake(1, 2, 3, 0);
    DataField shiftOut = DataFieldMake(1, 1, 1, 2);
    
    topImage = [topImage applyFiltrrByStep:4 
                                   ShiftIn:shiftIn
                                  ShiftOut:shiftOut
                                  Callback:^RGBA (int r, int g, int b, int a) {
                                      RGBA retVal;
                                      int t = 0;
                                      float avg = (r + g + b) / 3.0;
                                      
                                      retVal.red = [topImage safe:avg + t * (r - avg)];
                                      retVal.green = [topImage safe:avg + t * (g - avg)];
                                      retVal.blue = [topImage safe:avg + t * (b - avg)];
                                      retVal.alpha = a;
                                      
                                      return retVal;
                                  }];
    
    topImage = [topImage blur];
    
    UIImage * newImage = [inputImage multiply:topImage];
    
    RGBA minrgb, maxrgb;
    
    minrgb = RGBAMake(60, 35, 10, 255);    
    maxrgb = RGBAMake(170, 140, 160, 255);
    
    newImage = [newImage applyFiltrrByStep:4 
                                   ShiftIn:shiftIn
                                  ShiftOut:shiftOut
                                  Callback:^RGBA (int r, int g, int b, int a) {
                                      RGBA retVal;
                                      
                                      retVal.red = [newImage safe:(r - minrgb.red) * (255.0 / (maxrgb.red - minrgb.red))];
                                      retVal.green = [newImage safe:(g - minrgb.green) * (255.0 / (maxrgb.green - minrgb.green))];
                                      retVal.blue = [newImage safe:(b - minrgb.blue) * (255.0 / (maxrgb.blue - minrgb.blue))];
                                      retVal.alpha = a;
                                      
                                      return retVal;
                                  }];
    
    newImage = [newImage applyFiltrrByStep:4 
                                   ShiftIn:shiftIn
                                  ShiftOut:shiftOut
                                  Callback:^RGBA (int r, int g, int b, int a) {
                                      RGBA retVal;
                                      float val = 0.8;
                                      
                                      retVal.red = [newImage safe:(255.0 * [newImage calc_contrast:(r / 255.0) contrast:val])];
                                      retVal.green = [newImage safe:(255.0 * [newImage calc_contrast:(g / 255.0) contrast:val])];
                                      retVal.blue = [newImage safe:(255.0 * [newImage calc_contrast:(b / 255.0) contrast:val])];
                                      retVal.alpha = a;
                                      
                                      return retVal;
                                  }];
    
    newImage = [newImage applyFiltrrByStep:4 
                                   ShiftIn:shiftIn
                                  ShiftOut:shiftOut
                                  Callback:^RGBA (int r, int g, int b, int a) {
                                      RGBA retVal;
                                      float t = 10.0; 
                                      retVal.red = [newImage safe:r + t];
                                      retVal.green = [newImage safe:g + t];
                                      retVal.blue = [newImage safe:b + t];
                                      retVal.alpha = a;
                                      
                                      return retVal;
                                  }];
    
    return newImage;
}

static float __f_gaussianblur_kernel_5x5[25] = { 
	1.0f/256.0f,  4.0f/256.0f,  6.0f/256.0f,  4.0f/256.0f, 1.0f/256.0f,
	4.0f/256.0f, 16.0f/256.0f, 24.0f/256.0f, 16.0f/256.0f, 4.0f/256.0f,
	6.0f/256.0f, 24.0f/256.0f, 36.0f/256.0f, 24.0f/256.0f, 6.0f/256.0f,
	4.0f/256.0f, 16.0f/256.0f, 24.0f/256.0f, 16.0f/256.0f, 4.0f/256.0f,
	1.0f/256.0f,  4.0f/256.0f,  6.0f/256.0f,  4.0f/256.0f, 1.0f/256.0f
};

static int16_t __s_gaussianblur_kernel_5x5[25] = {
	1, 4, 6, 4, 1, 
	4, 16, 24, 16, 4,
	6, 24, 36, 24, 6,
	4, 16, 24, 16, 4,
	1, 4, 6, 4, 1
};


+ (UIImage*) NYXGaussianBlureOnImage : (UIImage*) inputImage Bias : (NSInteger) bias {
    /// Create an ARGB bitmap context
	const size_t width = inputImage.size.width;
	const size_t height = inputImage.size.height;
	const size_t bytesPerRow = width * kNyxNumberOfComponentsPerARBGPixel;
	CGContextRef bmContext = NYXCreateARGBBitmapContext(width, height, bytesPerRow);
	if (!bmContext) 
		return nil;
    
	/// Draw the image in the bitmap context
	CGContextDrawImage(bmContext, (CGRect){.origin.x = 0.0f, .origin.y = 0.0f, .size.width = width, .size.height = height}, inputImage.CGImage); 
    
	/// Grab the image raw data
	UInt8* data = (UInt8*)CGBitmapContextGetData(bmContext);
	if (!data)
	{
		CGContextRelease(bmContext);
		return nil;
	}
    
	/// vImage (iOS 5)
	if ((&vImageConvolveWithBias_ARGB8888))
	{
		const size_t n = sizeof(UInt8) * width * height * 4;
		void* outt = malloc(n);
		vImage_Buffer src = {data, height, width, bytesPerRow};
		vImage_Buffer dest = {outt, height, width, bytesPerRow};
		vImageConvolveWithBias_ARGB8888(&src, &dest, NULL, 0, 0, __s_gaussianblur_kernel_5x5, 5, 5, 256, bias, NULL, kvImageCopyInPlace);
		memcpy(data, outt, n);
		free(outt);
	}
	else
	{
		const size_t pixelsCount = width * height;
		const size_t n = sizeof(float) * pixelsCount;
		float* dataAsFloat = malloc(n);
		float* resultAsFloat = malloc(n);
        
		/// Red components
		vDSP_vfltu8(data + 1, 4, dataAsFloat, 1, pixelsCount);
		vDSP_f5x5(dataAsFloat, height, width, __f_gaussianblur_kernel_5x5, resultAsFloat);
		vDSP_vfixu8(resultAsFloat, 1, data + 1, 4, pixelsCount);
        
		/// Green components
		vDSP_vfltu8(data + 2, 4, dataAsFloat, 1, pixelsCount);
		vDSP_f5x5(dataAsFloat, height, width, __f_gaussianblur_kernel_5x5, resultAsFloat);
		vDSP_vfixu8(resultAsFloat, 1, data + 2, 4, pixelsCount);
        
		/// Blue components
		vDSP_vfltu8(data + 3, 4, dataAsFloat, 1, pixelsCount);
		vDSP_f5x5(dataAsFloat, height, width, __f_gaussianblur_kernel_5x5, resultAsFloat);
		vDSP_vfixu8(resultAsFloat, 1, data + 3, 4, pixelsCount);
        
		free(resultAsFloat);
		free(dataAsFloat);
	}
    
	CGImageRef blurredImageRef = CGBitmapContextCreateImage(bmContext);
	UIImage* blurred = [UIImage imageWithCGImage:blurredImageRef];
    
	/// Cleanup
	CGImageRelease(blurredImageRef);
	CGContextRelease(bmContext);
    
	return blurred;

}

+(UIImage*) NYXReflectedImage : (UIImage*) inputImage withHeight:(NSUInteger)height fromAlpha:(float)fromAlpha toAlpha:(float)toAlpha {
    if (!height)
		return inputImage;
    
	// create a bitmap graphics context the size of the image
	//UIGraphicsBeginImageContextWithOptions((CGSize){.width = inputImage.size.width, .height = height}, NO, 0.0f);
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(inputImage.size.width, height), NO, 0.0f);
    CGContextRef mainViewContentContext = UIGraphicsGetCurrentContext();
    
	// create a 2 bit CGImage containing a gradient that will be used for masking the
	// main view content to create the 'fade' of the reflection. The CGImageCreateWithMask
	// function will stretch the bitmap image as required, so we can create a 1 pixel wide gradient
	CGImageRef gradientMaskImage = NYXCreateGradientImage(1, height, fromAlpha, toAlpha);
    
	// create an image by masking the bitmap of the mainView content with the gradient view
	// then release the  pre-masked content bitmap and the gradient bitmap

	//CGContextClipToMask(mainViewContentContext, (CGRect){.origin.x = 0.0f, .origin.y = 0.0f, .size.width = inputImage.size.width, .size.height = height}, gradientMaskImage);
    CGContextClipToMask(mainViewContentContext, CGRectMake(0.0f, 0.0f, inputImage.size.width, height), gradientMaskImage);
	CGImageRelease(gradientMaskImage);
    
	// draw the image into the bitmap context
	//CGContextDrawImage(mainViewContentContext, (CGRect){.origin.x = 0.0f, .origin.y = 0.0f, .size = inputImage.size}, inputImage.CGImage);
    
    CGContextDrawImage(mainViewContentContext, CGRectMake(0.0f, 0.0f, inputImage.size.width, height), inputImage.CGImage);
    
	// convert the finished reflection image to a UIImage
	UIImage* theImage = UIGraphicsGetImageFromCurrentImageContext();
    
	UIGraphicsEndImageContext();
    
	return theImage;

}

+ (UIImage*) NYXAutoEnhanceImage : (UIImage*) inputImage {
    /// No Core Image, return original image
	if (![CIImage class])
		return inputImage;
    
	CIImage* ciImage = [[CIImage alloc] initWithCGImage:inputImage.CGImage];
    
	NSArray* adjustments = [ciImage autoAdjustmentFiltersWithOptions:[NSDictionary dictionaryWithObject:[NSNumber numberWithBool:NO] forKey:kCIImageAutoAdjustRedEye]];
    
	for (CIFilter* filter in adjustments)
	{
		[filter setValue:ciImage forKey:kCIInputImageKey];
		ciImage = filter.outputImage;
	}
    
	CIContext* ctx = [CIContext contextWithOptions:nil];
	CGImageRef cgImage = [ctx createCGImage:ciImage fromRect:[ciImage extent]];
	UIImage* final = [UIImage imageWithCGImage:cgImage];
	CGImageRelease(cgImage);
	return final;

}

+ (UIImage*)NYXRedEyeCorrectionOnImage : (UIImage*) inputImage {
	/// No Core Image, return original image
	if (![CIImage class])
		return inputImage;
    
	CIImage* ciImage = [[CIImage alloc] initWithCGImage:inputImage.CGImage];
    
	/// Get the filters and apply them to the image
	NSArray* filters = [ciImage autoAdjustmentFiltersWithOptions:[NSDictionary dictionaryWithObject:[NSNumber numberWithBool:NO] forKey:kCIImageAutoAdjustEnhance]];
	for (CIFilter* filter in filters)
	{
		[filter setValue:ciImage forKey:kCIInputImageKey];
		ciImage = filter.outputImage;
	}
    
	/// Create the corrected image
	CIContext* ctx = [CIContext contextWithOptions:nil];
	CGImageRef cgImage = [ctx createCGImage:ciImage fromRect:[ciImage extent]];
	UIImage* final = [UIImage imageWithCGImage:cgImage];
	CGImageRelease(cgImage);
	return final;
}

/* vDSP kernel */
static float __f_edgedetect_kernel_3x3[9] = {
	-1.0f, -1.0f, -1.0f, 
	-1.0f, 8.0f, -1.0f, 
	-1.0f, -1.0f, -1.0f
};

/* vImage kernel */
/*static int16_t __s_edgedetect_kernel_3x3[9] = {
 -1, -1, -1, 
 -1, 8, -1, 
 -1, -1, -1
 };
*/
+ (UIImage*) NYXEdgeDetectionOnImage : (UIImage*) inputImage WithBias:(NSInteger)bias {
#pragma unused(bias)
	/// Create an ARGB bitmap context
	const size_t width = inputImage.size.width;
	const size_t height = inputImage.size.height;
	const size_t bytesPerRow = width * kNyxNumberOfComponentsPerARBGPixel;
	CGContextRef bmContext = NYXCreateARGBBitmapContext(width, height, bytesPerRow);
	if (!bmContext) 
		return nil;
    
	/// Draw the image in the bitmap context
	CGContextDrawImage(bmContext, (CGRect){.origin.x = 0.0f, .origin.y = 0.0f, .size.width = width, .size.height = height}, inputImage.CGImage); 
    
	/// Grab the image raw data
	UInt8* data = (UInt8*)CGBitmapContextGetData(bmContext);
	if (!data)
	{
		CGContextRelease(bmContext);
		return nil;
	}
    /*
	/// vImage (iOS 5) works on simulator but not on device
	if ((&vImageConvolveWithBias_ARGB8888))
     {
     const size_t n = sizeof(UInt8) * width * height * 4;
     void* outt = malloc(n);
     vImage_Buffer src = {data, height, width, bytesPerRow};
     vImage_Buffer dest = {outt, height, width, bytesPerRow};
     
     vImageConvolveWithBias_ARGB8888(&src, &dest, NULL, 0, 0, __s_edgedetect_kernel_3x3, 3, 3, 1, bias, NULL, kvImageCopyInPlace);
     
     CGDataProviderRef dp = CGDataProviderCreateWithData(NULL, data, n, NULL);
     
     CGColorSpaceRef cs = CGColorSpaceCreateDeviceRGB();
     CGImageRef edgedImageRef = CGImageCreate(width, height, 8, 32, bytesPerRow, cs, kCGBitmapByteOrderDefault | kCGImageAlphaNoneSkipFirst, dp, NULL, true, kCGRenderingIntentDefault);
     CGColorSpaceRelease(cs);
     
     //memcpy(data, outt, n);
     //CGImageRef edgedImageRef = CGBitmapContextCreateImage(bmContext);
     UIImage* edged = [UIImage imageWithCGImage:edgedImageRef];
     
     /// Cleanup
     CGImageRelease(edgedImageRef);
     CGDataProviderRelease(dp);
     free(outt);
     CGContextRelease(bmContext);
     
     return edged;
     }
     else
     {*/
    const size_t pixelsCount = width * height;
    const size_t n = sizeof(float) * pixelsCount;
    float* dataAsFloat = malloc(n);
    float* resultAsFloat = malloc(n);
    float min = (float)kNyxMinPixelComponentValue, max = (float)kNyxMaxPixelComponentValue;
    
    /// Red components
    vDSP_vfltu8(data + 1, 4, dataAsFloat, 1, pixelsCount);
    vDSP_f3x3(dataAsFloat, height, width, __f_edgedetect_kernel_3x3, resultAsFloat);
    vDSP_vclip(resultAsFloat, 1, &min, &max, resultAsFloat, 1, pixelsCount);
    vDSP_vfixu8(resultAsFloat, 1, data + 1, 4, pixelsCount);
    
    /// Green components
    vDSP_vfltu8(data + 2, 4, dataAsFloat, 1, pixelsCount);
    vDSP_f3x3(dataAsFloat, height, width, __f_edgedetect_kernel_3x3, resultAsFloat);
    vDSP_vclip(resultAsFloat, 1, &min, &max, resultAsFloat, 1, pixelsCount);
    vDSP_vfixu8(resultAsFloat, 1, data + 2, 4, pixelsCount);
    
    /// Blue components
    vDSP_vfltu8(data + 3, 4, dataAsFloat, 1, pixelsCount);
    vDSP_f3x3(dataAsFloat, height, width, __f_edgedetect_kernel_3x3, resultAsFloat);
    vDSP_vclip(resultAsFloat, 1, &min, &max, resultAsFloat, 1, pixelsCount);
    vDSP_vfixu8(resultAsFloat, 1, data + 3, 4, pixelsCount);
    
    CGImageRef edgedImageRef = CGBitmapContextCreateImage(bmContext);
    UIImage* edged = [UIImage imageWithCGImage:edgedImageRef];
    
    /// Cleanup
    CGImageRelease(edgedImageRef);
    free(resultAsFloat);
    free(dataAsFloat);
    CGContextRelease(bmContext);
    
    return edged;
	//}
}
/* vImage kernel */
static int16_t __s_emboss_kernel_3x3[9] = {
	-2, 0, 0, 
	0, 1, 0, 
	0, 0, 2
};
/* vDSP kernel */
static float __f_emboss_kernel_3x3[9] = {
	-2.0f, 0.0f, 0.0f, 
	0.0f, 1.0f, 0.0f, 
	0.0f, 0.0f, 2.0f
};
+(UIImage*) NYXEmbossImage : (UIImage*) inputImage WithBias:(NSInteger)bias {
    /// Create an ARGB bitmap context
	const size_t width = inputImage.size.width;
	const size_t height = inputImage.size.height;
	const size_t bytesPerRow = width * kNyxNumberOfComponentsPerARBGPixel;
	CGContextRef bmContext = NYXCreateARGBBitmapContext(width, height, bytesPerRow);
	if (!bmContext) 
		return nil;
    
	/// Draw the image in the bitmap context
	CGContextDrawImage(bmContext, (CGRect){.origin.x = 0.0f, .origin.y = 0.0f, .size.width = width, .size.height = height}, inputImage.CGImage); 
    
	/// Grab the image raw data
	UInt8* data = (UInt8*)CGBitmapContextGetData(bmContext);
	if (!data)
	{
		CGContextRelease(bmContext);
		return nil;
	}
    
	/// vImage (iOS 5)
	if ((&vImageConvolveWithBias_ARGB8888))
	{
		const size_t n = sizeof(UInt8) * width * height * 4;
		void* outt = malloc(n);
		vImage_Buffer src = {data, height, width, bytesPerRow};
		vImage_Buffer dest = {outt, height, width, bytesPerRow};
		vImageConvolveWithBias_ARGB8888(&src, &dest, NULL, 0, 0, __s_emboss_kernel_3x3, 3, 3, 1/*divisor*/, bias, NULL, kvImageCopyInPlace);
        
		memcpy(data, outt, n);
        
		free(outt);
	}
	else
	{
		const size_t pixelsCount = width * height;
		const size_t n = sizeof(float) * pixelsCount;
		float* dataAsFloat = malloc(n);
		float* resultAsFloat = malloc(n);
		float min = (float)kNyxMinPixelComponentValue, max = (float)kNyxMaxPixelComponentValue;
        
		/// Red components
		vDSP_vfltu8(data + 1, 4, dataAsFloat, 1, pixelsCount);
		vDSP_f3x3(dataAsFloat, height, width, __f_emboss_kernel_3x3, resultAsFloat);
		vDSP_vclip(resultAsFloat, 1, &min, &max, resultAsFloat, 1, pixelsCount);
		vDSP_vfixu8(resultAsFloat, 1, data + 1, 4, pixelsCount);
        
		/// Green components
		vDSP_vfltu8(data + 2, 4, dataAsFloat, 1, pixelsCount);
		vDSP_f3x3(dataAsFloat, height, width, __f_emboss_kernel_3x3, resultAsFloat);
		vDSP_vclip(resultAsFloat, 1, &min, &max, resultAsFloat, 1, pixelsCount);
		vDSP_vfixu8(resultAsFloat, 1, data + 2, 4, pixelsCount);
        
		/// Blue components
		vDSP_vfltu8(data + 3, 4, dataAsFloat, 1, pixelsCount);
		vDSP_f3x3(dataAsFloat, height, width, __f_emboss_kernel_3x3, resultAsFloat);
		vDSP_vclip(resultAsFloat, 1, &min, &max, resultAsFloat, 1, pixelsCount);
		vDSP_vfixu8(resultAsFloat, 1, data + 3, 4, pixelsCount);
        
		free(dataAsFloat);
		free(resultAsFloat);
	}
    
	CGImageRef embossImageRef = CGBitmapContextCreateImage(bmContext);
	UIImage* emboss = [UIImage imageWithCGImage:embossImageRef];
    
	/// Cleanup
	CGImageRelease(embossImageRef);
	CGContextRelease(bmContext);
    
	return emboss;
}

/// (0.01, 8)
+ (UIImage*) NYXGammaCorrectionOfImage : (UIImage*) inputImage WithValue:(float)value {
    const size_t width = inputImage.size.width;
	const size_t height = inputImage.size.height;
	/// Number of bytes per row, each pixel in the bitmap will be represented by 4 bytes (ARGB), 8 bits of alpha/red/green/blue
	const size_t bytesPerRow = width * kNyxNumberOfComponentsPerARBGPixel;
    
	/// Create an ARGB bitmap context
	CGContextRef bmContext = NYXCreateARGBBitmapContext(width, height, bytesPerRow);
	if (!bmContext) 
		return nil;
    
	/// Draw the image in the bitmap context
	CGContextDrawImage(bmContext, (CGRect){.origin.x = 0.0f, .origin.y = 0.0f, .size.width = width, .size.height = height}, inputImage.CGImage);
    
	/// Grab the image raw data
	UInt8* data = (UInt8*)CGBitmapContextGetData(bmContext);
	if (!data)
	{
		CGContextRelease(bmContext);
		return nil;
	}
    
	/// vForce functions (iOS 5)
	if ((&vvpowf))
	{
		const size_t pixelsCount = width * height;
		const size_t n = sizeof(float) * pixelsCount;
		float* dataAsFloat = (float*)malloc(n);
		float* temp = (float*)malloc(n);
		float min = (float)kNyxMinPixelComponentValue, max = (float)kNyxMaxPixelComponentValue;
		const int iPixels = (int)pixelsCount;
        
		/// Need a vector with same size :(
		vDSP_vfill(&value, temp, 1, pixelsCount);
        
		/// Calculate red components
		vDSP_vfltu8(data + 1, 4, dataAsFloat, 1, pixelsCount);
		vDSP_vsdiv(dataAsFloat, 1, &max, dataAsFloat, 1, pixelsCount);
		vvpowf(dataAsFloat, temp, dataAsFloat, &iPixels);
		vDSP_vsmul(dataAsFloat, 1, &max, dataAsFloat, 1, pixelsCount);
		vDSP_vclip(dataAsFloat, 1, &min, &max, dataAsFloat, 1, pixelsCount);
		vDSP_vfixu8(dataAsFloat, 1, data + 1, 4, pixelsCount);
        
		/// Calculate green components
		vDSP_vfltu8(data + 2, 4, dataAsFloat, 1, pixelsCount);
		vDSP_vsdiv(dataAsFloat, 1, &max, dataAsFloat, 1, pixelsCount);
		vvpowf(dataAsFloat, temp, dataAsFloat, &iPixels);
		vDSP_vsmul(dataAsFloat, 1, &max, dataAsFloat, 1, pixelsCount);
		vDSP_vclip(dataAsFloat, 1, &min, &max, dataAsFloat, 1, pixelsCount);
		vDSP_vfixu8(dataAsFloat, 1, data + 2, 4, pixelsCount);
        
		/// Calculate blue components
		vDSP_vfltu8(data + 3, 4, dataAsFloat, 1, pixelsCount);
		vDSP_vsdiv(dataAsFloat, 1, &max, dataAsFloat, 1, pixelsCount);
		vvpowf(dataAsFloat, temp, dataAsFloat, &iPixels);
		vDSP_vsmul(dataAsFloat, 1, &max, dataAsFloat, 1, pixelsCount);
		vDSP_vclip(dataAsFloat, 1, &min, &max, dataAsFloat, 1, pixelsCount);
		vDSP_vfixu8(dataAsFloat, 1, data + 3, 4, pixelsCount);	
        
		/// Cleanup
		free(temp);
		free(dataAsFloat);
	}
	else
	{
		const size_t bitmapByteCount = bytesPerRow * height;
		for (size_t i = 0; i < bitmapByteCount; i += kNyxNumberOfComponentsPerARBGPixel)
		{
			const float red = (float)data[i + 1];
			const float green = (float)data[i + 2];
			const float blue = (float)data[i + 3];
            
			data[i + 1] = NYX_SAFE_PIXEL_COMPONENT_VALUE(255 * powf((red / 255.0f), value));
			data[i + 2] = NYX_SAFE_PIXEL_COMPONENT_VALUE(255 * powf((green / 255.0f), value));
			data[i + 3] = NYX_SAFE_PIXEL_COMPONENT_VALUE(255 * powf((blue / 255.0f), value));
		}
	}
    
	/// Create an image object from the context
	CGImageRef gammaImageRef = CGBitmapContextCreateImage(bmContext);
	UIImage* gamma = [UIImage imageWithCGImage:gammaImageRef];
    
	/// Cleanup
	CGImageRelease(gammaImageRef);
	CGContextRelease(bmContext);
    
	return gamma;
}

+(UIImage*) NYXGrayscaleOfImage : (UIImage*) inputImage {
    /* const UInt8 luminance = (red * 0.2126) + (green * 0.7152) + (blue * 0.0722); // Good luminance value */
	/// Create a gray bitmap context
	const size_t width = inputImage.size.width;
	const size_t height = inputImage.size.height;
    
    CGRect imageRect = CGRectMake(0, 0, inputImage.size.width, inputImage.size.height);
    
	CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceGray();
	CGContextRef bmContext = CGBitmapContextCreate(NULL, width, height, 8/*Bits per component*/, width * kNyxNumberOfComponentsPerGreyPixel, colorSpace, kCGImageAlphaNone);
	CGColorSpaceRelease(colorSpace);
	if (!bmContext)
		return nil;
    
	/// Image quality
	CGContextSetShouldAntialias(bmContext, false);
	CGContextSetInterpolationQuality(bmContext, kCGInterpolationHigh);
    
	/// Draw the image in the bitmap context
	CGContextDrawImage(bmContext, imageRect, inputImage.CGImage);
    
	/// Create an image object from the context
	CGImageRef grayscaledImageRef = CGBitmapContextCreateImage(bmContext);
    UIImage *grayscaled = [UIImage imageWithCGImage:grayscaledImageRef
                                              scale:inputImage.scale 
                                        orientation:inputImage.imageOrientation];
    
	/// Cleanup
	CGImageRelease(grayscaledImageRef);
	CGContextRelease(bmContext);
    
	return grayscaled;

}

+(UIImage*) NYXInvertImage : (UIImage*) inputImage withNegativeMultiplier : (float) __negativeMultiplier {
    /// Create an ARGB bitmap context
	const size_t width = inputImage.size.width;
	const size_t height = inputImage.size.height;
	CGContextRef bmContext = NYXCreateARGBBitmapContext(width, height, width * kNyxNumberOfComponentsPerARBGPixel);
	if (!bmContext) 
		return nil;
    
	/// Draw the image in the bitmap context
	CGContextDrawImage(bmContext, (CGRect){.origin.x = 0.0f, .origin.y = 0.0f, .size.width = width, .size.height = height}, inputImage.CGImage); 
    
	/// Grab the image raw data
	UInt8* data = (UInt8*)CGBitmapContextGetData(bmContext);
	if (!data)
	{
		CGContextRelease(bmContext);
		return nil;
	}
    
	const size_t pixelsCount = width * height;
	float* dataAsFloat = (float*)malloc(sizeof(float) * pixelsCount);
	float min = (float)kNyxMinPixelComponentValue, max = (float)kNyxMaxPixelComponentValue;
	UInt8* dataRed = data + 1;
	UInt8* dataGreen = data + 2;
	UInt8* dataBlue = data + 3;
    
	/// vDSP_vsmsa() = multiply then add
	/// slightly faster than the couple vDSP_vneg() & vDSP_vsadd()
	/// Probably because there are 3 function calls less
    
	/// Calculate red components
	vDSP_vfltu8(dataRed, 4, dataAsFloat, 1, pixelsCount);
	vDSP_vsmsa(dataAsFloat, 1, &__negativeMultiplier, &max, dataAsFloat, 1, pixelsCount);
	vDSP_vclip(dataAsFloat, 1, &min, &max, dataAsFloat, 1, pixelsCount);
	vDSP_vfixu8(dataAsFloat, 1, dataRed, 4, pixelsCount);
    
	/// Calculate green components
	vDSP_vfltu8(dataGreen, 4, dataAsFloat, 1, pixelsCount);
	vDSP_vsmsa(dataAsFloat, 1, &__negativeMultiplier, &max, dataAsFloat, 1, pixelsCount);
	vDSP_vclip(dataAsFloat, 1, &min, &max, dataAsFloat, 1, pixelsCount);
	vDSP_vfixu8(dataAsFloat, 1, dataGreen, 4, pixelsCount);
    
	/// Calculate blue components
	vDSP_vfltu8(dataBlue, 4, dataAsFloat, 1, pixelsCount);
	vDSP_vsmsa(dataAsFloat, 1, &__negativeMultiplier, &max, dataAsFloat, 1, pixelsCount);
	vDSP_vclip(dataAsFloat, 1, &min, &max, dataAsFloat, 1, pixelsCount);
	vDSP_vfixu8(dataAsFloat, 1, dataBlue, 4, pixelsCount);
    
	CGImageRef invertedImageRef = CGBitmapContextCreateImage(bmContext);
	UIImage* inverted = [UIImage imageWithCGImage:invertedImageRef];
    
	/// Cleanup
	CGImageRelease(invertedImageRef);
	free(dataAsFloat);
	CGContextRelease(bmContext);
    
	return inverted;

}
+(UIImage*) NYXOpacityOfImage :(UIImage*) inputImage withOpacityValue : (float)value {
    /// Create an ARGB bitmap context
	const size_t width = inputImage.size.width;
	const size_t height = inputImage.size.height;
	CGContextRef bmContext = NYXCreateARGBBitmapContext(width, height, width * kNyxNumberOfComponentsPerARBGPixel);
	if (!bmContext) 
		return nil;
    
	/// Set the alpha value and draw the image in the bitmap context
	CGContextSetAlpha(bmContext, value);
	CGContextDrawImage(bmContext, (CGRect){.origin.x = 0.0f, .origin.y = 0.0f, .size.width = width, .size.height = height}, inputImage.CGImage);
    
	/// Create an image object from the context
	CGImageRef transparentImageRef = CGBitmapContextCreateImage(bmContext);
	UIImage* transparent = [UIImage imageWithCGImage:transparentImageRef];
    
	/// Cleanup
	CGImageRelease(transparentImageRef);
	CGContextRelease(bmContext);
    
	return transparent;
}
+(UIImage*) NYXSepiaOfImage : (UIImage*) inputImage sepiaFactorRedRed : (float) __sepiaFactorRedRed sepiaFactorRedGreen : (float) __sepiaFactorRedGreen sepiaFactorRedBlue : (float) __sepiaFactorRedBlue sepiaFactorGreenRed : (float) __sepiaFactorGreenRed sepiaFactorGreenGreen : (float) __sepiaFactorGreenGreen sepiaFactorGreenBlue : (float) __sepiaFactorGreenBlue sepiaFactorBlueRed : (float) __sepiaFactorBlueRed sepiaFactorBlueGreen : (float) __sepiaFactorBlueGreen sepiaFactorBlueBlue : (float) __sepiaFactorBlueBlue {
    /* 1.6x faster than before */
    /// Create an ARGB bitmap context
    const size_t width = inputImage.size.width;
    const size_t height = inputImage.size.height;
    CGContextRef bmContext = NYXCreateARGBBitmapContext(width, height, width * kNyxNumberOfComponentsPerARBGPixel);
    if (!bmContext) 
        return nil;
    
    /// Draw the image in the bitmap context
    CGContextDrawImage(bmContext, (CGRect){.origin.x = 0.0f, .origin.y = 0.0f, .size.width = width, .size.height = height}, inputImage.CGImage);
    
    /// Grab the image raw data
    UInt8* data = (UInt8*)CGBitmapContextGetData(bmContext);
    if (!data)
    {
        CGContextRelease(bmContext);
        return nil;
    }
    
    const size_t pixelsCount = width * height;
    const size_t n = sizeof(float) * pixelsCount;
    float* reds = (float*)malloc(n);
    float* greens = (float*)malloc(n);
    float* blues = (float*)malloc(n);
    float* tmpRed = (float*)malloc(n);
    float* tmpGreen = (float*)malloc(n);
    float* tmpBlue = (float*)malloc(n);
    float* finalRed = (float*)malloc(n);
    float* finalGreen = (float*)malloc(n);
    float* finalBlue = (float*)malloc(n);
    float min = (float)kNyxMinPixelComponentValue, max = (float)kNyxMaxPixelComponentValue;
    
    /// Convert byte components to float
    vDSP_vfltu8(data + 1, 4, reds, 1, pixelsCount);
    vDSP_vfltu8(data + 2, 4, greens, 1, pixelsCount);
    vDSP_vfltu8(data + 3, 4, blues, 1, pixelsCount);
    
    /// Calculate red components
    vDSP_vsmul(reds, 1, &__sepiaFactorRedRed, tmpRed, 1, pixelsCount);
    vDSP_vsmul(greens, 1, &__sepiaFactorGreenRed, tmpGreen, 1, pixelsCount);
    vDSP_vsmul(blues, 1, &__sepiaFactorBlueRed, tmpBlue, 1, pixelsCount);
    vDSP_vadd(tmpRed, 1, tmpGreen, 1, finalRed, 1, pixelsCount);
    vDSP_vadd(finalRed, 1, tmpBlue, 1, finalRed, 1, pixelsCount);
    vDSP_vclip(finalRed, 1, &min, &max, finalRed, 1, pixelsCount);
    vDSP_vfixu8(finalRed, 1, data + 1, 4, pixelsCount);
    
    /// Calculate green components
    vDSP_vsmul(reds, 1, &__sepiaFactorRedGreen, tmpRed, 1, pixelsCount);
    vDSP_vsmul(greens, 1, &__sepiaFactorGreenGreen, tmpGreen, 1, pixelsCount);
    vDSP_vsmul(blues, 1, &__sepiaFactorBlueGreen, tmpBlue, 1, pixelsCount);
    vDSP_vadd(tmpRed, 1, tmpGreen, 1, finalGreen, 1, pixelsCount);
    vDSP_vadd(finalGreen, 1, tmpBlue, 1, finalGreen, 1, pixelsCount);
    vDSP_vclip(finalGreen, 1, &min, &max, finalGreen, 1, pixelsCount);
    vDSP_vfixu8(finalGreen, 1, data + 2, 4, pixelsCount);
    
    /// Calculate blue components
    vDSP_vsmul(reds, 1, &__sepiaFactorRedBlue, tmpRed, 1, pixelsCount);
    vDSP_vsmul(greens, 1, &__sepiaFactorGreenBlue, tmpGreen, 1, pixelsCount);
    vDSP_vsmul(blues, 1, &__sepiaFactorBlueBlue, tmpBlue, 1, pixelsCount);
    vDSP_vadd(tmpRed, 1, tmpGreen, 1, finalBlue, 1, pixelsCount);
    vDSP_vadd(finalBlue, 1, tmpBlue, 1, finalBlue, 1, pixelsCount);
    vDSP_vclip(finalBlue, 1, &min, &max, finalBlue, 1, pixelsCount);
    vDSP_vfixu8(finalBlue, 1, data + 3, 4, pixelsCount);
    
    /// Create an image object from the context
    CGImageRef sepiaImageRef = CGBitmapContextCreateImage(bmContext);
    UIImage* sepia = [UIImage imageWithCGImage:sepiaImageRef];
    
    /// Cleanup
    CGImageRelease(sepiaImageRef);
    free(reds), free(greens), free(blues), free(tmpRed), free(tmpGreen), free(tmpBlue), free(finalRed), free(finalGreen), free(finalBlue);
    CGContextRelease(bmContext);
    
    return sepia;
}
/* vImage kernel */
static int16_t __s_sharpen_kernel_3x3[9] = {
	-1, -1, -1, 
	-1, 9, -1, 
	-1, -1, -1
};
/* vDSP kernel */
static float __f_sharpen_kernel_3x3[9] = {
	-1.0f, -1.0f, -1.0f, 
	-1.0f, 9.0f, -1.0f, 
	-1.0f, -1.0f, -1.0f
};
+(UIImage*) NYXSharpenImage: (UIImage*) inputImage WithBias:(NSInteger)bias {
    /// Create an ARGB bitmap context
	const size_t width = inputImage.size.width;
	const size_t height = inputImage.size.height;
	const size_t bytesPerRow = width * kNyxNumberOfComponentsPerARBGPixel;
	CGContextRef bmContext = NYXCreateARGBBitmapContext(width, height, bytesPerRow);
	if (!bmContext) 
		return nil;
    
	/// Draw the image in the bitmap context
	CGContextDrawImage(bmContext, (CGRect){.origin.x = 0.0f, .origin.y = 0.0f, .size.width = width, .size.height = height}, inputImage.CGImage); 
    
	/// Grab the image raw data
	UInt8* data = (UInt8*)CGBitmapContextGetData(bmContext);
	if (!data)
	{
		CGContextRelease(bmContext);
		return nil;
	}
    
	/// vImage (iOS 5)
	if ((&vImageConvolveWithBias_ARGB8888))
	{
		const size_t n = sizeof(UInt8) * width * height * 4;
		void* outt = malloc(n);
		vImage_Buffer src = {data, height, width, bytesPerRow};
		vImage_Buffer dest = {outt, height, width, bytesPerRow};
		vImageConvolveWithBias_ARGB8888(&src, &dest, NULL, 0, 0, __s_sharpen_kernel_3x3, 3, 3, 1/*divisor*/, bias, NULL, kvImageCopyInPlace);
        
		memcpy(data, outt, n);
        
		free(outt);
	}
	else
	{
		const size_t pixelsCount = width * height;
		const size_t n = sizeof(float) * pixelsCount;
		float* dataAsFloat = malloc(n);
		float* resultAsFloat = malloc(n);
		float min = (float)kNyxMinPixelComponentValue, max = (float)kNyxMaxPixelComponentValue;
        
		/// Red components
		vDSP_vfltu8(data + 1, 4, dataAsFloat, 1, pixelsCount);
		vDSP_f3x3(dataAsFloat, height, width, __f_sharpen_kernel_3x3, resultAsFloat);
		vDSP_vclip(resultAsFloat, 1, &min, &max, resultAsFloat, 1, pixelsCount);
		vDSP_vfixu8(resultAsFloat, 1, data + 1, 4, pixelsCount);
        
		/// Green components
		vDSP_vfltu8(data + 2, 4, dataAsFloat, 1, pixelsCount);
		vDSP_f3x3(dataAsFloat, height, width, __f_sharpen_kernel_3x3, resultAsFloat);
		vDSP_vclip(resultAsFloat, 1, &min, &max, resultAsFloat, 1, pixelsCount);
		vDSP_vfixu8(resultAsFloat, 1, data + 2, 4, pixelsCount);
        
		/// Blue components
		vDSP_vfltu8(data + 3, 4, dataAsFloat, 1, pixelsCount);
		vDSP_f3x3(dataAsFloat, height, width, __f_sharpen_kernel_3x3, resultAsFloat);
		vDSP_vclip(resultAsFloat, 1, &min, &max, resultAsFloat, 1, pixelsCount);
		vDSP_vfixu8(resultAsFloat, 1, data + 3, 4, pixelsCount);
        
		free(dataAsFloat);
		free(resultAsFloat);
	}
    
	CGImageRef sharpenedImageRef = CGBitmapContextCreateImage(bmContext);
	UIImage* sharpened = [UIImage imageWithCGImage:sharpenedImageRef];
    
	/// Cleanup
	CGImageRelease(sharpenedImageRef);
	CGContextRelease(bmContext);
    
	return sharpened;

}
/* vImage kernel */
static int16_t __s_unsharpen_kernel_3x3[9] = {
	-1, -1, -1, 
	-1, 17, -1, 
	-1, -1, -1
};
/* vDSP kernel */
static float __f_unsharpen_kernel_3x3[9] = {
	-1.0f/9.0f, -1.0f/9.0f, -1.0f/9.0f, 
	-1.0f/9.0f, 17.0f/9.0f, -1.0f/9.0f, 
	-1.0f/9.0f, -1.0f/9.0f, -1.0f/9.0f
};

+(UIImage*) NYXUnsharpenImage : (UIImage*)inputImage WithBias:(NSInteger)bias {
    /// Create an ARGB bitmap context
	const size_t width = inputImage.size.width;
	const size_t height = inputImage.size.height;
	const size_t bytesPerRow = width * kNyxNumberOfComponentsPerARBGPixel;
	CGContextRef bmContext = NYXCreateARGBBitmapContext(width, height, bytesPerRow);
	if (!bmContext) 
		return nil;
    
	/// Draw the image in the bitmap context
	CGContextDrawImage(bmContext, (CGRect){.origin.x = 0.0f, .origin.y = 0.0f, .size.width = width, .size.height = height}, inputImage.CGImage); 
    
	/// Grab the image raw data
	UInt8* data = (UInt8*)CGBitmapContextGetData(bmContext);
	if (!data)
	{
		CGContextRelease(bmContext);
		return nil;
	}
    
	/// vImage (iOS 5)
	if ((&vImageConvolveWithBias_ARGB8888))
	{
		const size_t n = sizeof(UInt8) * width * height * 4;
		void* outt = malloc(n);
		vImage_Buffer src = {data, height, width, bytesPerRow};
		vImage_Buffer dest = {outt, height, width, bytesPerRow};
		vImageConvolveWithBias_ARGB8888(&src, &dest, NULL, 0, 0, __s_unsharpen_kernel_3x3, 3, 3, 9/*divisor*/, bias, NULL, kvImageCopyInPlace);
        
		memcpy(data, outt, n);
        
		free(outt);
	}
	else
	{
		const size_t pixelsCount = width * height;
		const size_t n = sizeof(float) * pixelsCount;
		float* dataAsFloat = malloc(n);
		float* resultAsFloat = malloc(n);
		float min = (float)kNyxMinPixelComponentValue, max = (float)kNyxMaxPixelComponentValue;
        
		/// Red components
		vDSP_vfltu8(data + 1, 4, dataAsFloat, 1, pixelsCount);
		vDSP_f3x3(dataAsFloat, height, width, __f_unsharpen_kernel_3x3, resultAsFloat);
		vDSP_vclip(resultAsFloat, 1, &min, &max, resultAsFloat, 1, pixelsCount);
		vDSP_vfixu8(resultAsFloat, 1, data + 1, 4, pixelsCount);
        
		/// Green components
		vDSP_vfltu8(data + 2, 4, dataAsFloat, 1, pixelsCount);
		vDSP_f3x3(dataAsFloat, height, width, __f_unsharpen_kernel_3x3, resultAsFloat);
		vDSP_vclip(resultAsFloat, 1, &min, &max, resultAsFloat, 1, pixelsCount);
		vDSP_vfixu8(resultAsFloat, 1, data + 2, 4, pixelsCount);
        
		/// Blue components
		vDSP_vfltu8(data + 3, 4, dataAsFloat, 1, pixelsCount);
		vDSP_f3x3(dataAsFloat, height, width, __f_unsharpen_kernel_3x3, resultAsFloat);
		vDSP_vclip(resultAsFloat, 1, &min, &max, resultAsFloat, 1, pixelsCount);
		vDSP_vfixu8(resultAsFloat, 1, data + 3, 4, pixelsCount);
        
		free(dataAsFloat);
		free(resultAsFloat);
	}
    
	CGImageRef unsharpenedImageRef = CGBitmapContextCreateImage(bmContext);
	UIImage* unsharpened = [UIImage imageWithCGImage:unsharpenedImageRef];
    
	/// Cleanup
	CGImageRelease(unsharpenedImageRef);
	CGContextRelease(bmContext);
    
	return unsharpened;
}

+ (UIImage*) GPURotateWrtOrienationOfImage : (UIImage*) image {
    UIImage *output;
    //GPUImageRotationFilter *rotationFilter;
    switch ([[UIDevice currentDevice] orientation]) {
        case UIInterfaceOrientationPortrait:
            //rotationFilter = [[GPUImageRotationFilter alloc] initWithRotation:kGPUImageRotateRight];
            //output = [rotationFilter imageByFilteringImage:image];
            break;
        case UIInterfaceOrientationLandscapeRight:
            break;
        case UIInterfaceOrientationLandscapeLeft:
            break;
        case UIInterfaceOrientationPortraitUpsideDown:
            break;
        default:
            break;
    }
    return output;
}

+ (UIImage*) GPUSepiaFilterOnImage : (UIImage*) inputImage withValue : (float) value {
    GPUImageSepiaFilter *gpuFilter = [[GPUImageSepiaFilter alloc] init];
    [gpuFilter setIntensity:value];
    return [gpuFilter imageByFilteringImage:inputImage];
}

+ (UIImage*) GPUSketchOfImage : (UIImage*) inputImage {
    GPUImageSketchFilter *gpuFilter = [[GPUImageSketchFilter alloc] init];
    return [gpuFilter imageByFilteringImage:inputImage];
}

+ (UIImage*) GPUTiltShiftOnImage : (UIImage*) inputImage TopFocusLevel : (float) topFocusLevel BottomFocusLevel : (float) bottomFocusLevel FocusFallOfRate : (float) focusFallOfRate {
    
    GPUImageTiltShiftFilter *gpuFilter = [[GPUImageTiltShiftFilter alloc] init];
    [gpuFilter setTopFocusLevel:topFocusLevel];
    [gpuFilter setBottomFocusLevel:bottomFocusLevel];
    [gpuFilter setFocusFallOffRate:focusFallOfRate];
    return [gpuFilter imageByFilteringImage:inputImage];
}

+ (UIImage*) GPUGaussianSelectiveBlurOnImage : (UIImage*) inputImage withRadius : (float) radius {
    GPUImageGaussianSelectiveBlurFilter *gpuFilter = [[GPUImageGaussianSelectiveBlurFilter alloc] init];
    [gpuFilter setExcludeCircleRadius:radius];
    return [gpuFilter imageByFilteringImage:inputImage];
}

+ (UIImage*) GPUCropImage : (UIImage*) inputImage withinRect : (CGRect) rect {
    GPUImageCropFilter *gpuFilter = [[GPUImageCropFilter alloc] initWithCropRegion:rect];
    return [gpuFilter imageByFilteringImage:inputImage];
}

+ (UIImage*) GPUSaturationOnImage : (UIImage*) inputImage withValue : (float) value {
    GPUImageSaturationFilter *gpuFilter = [[GPUImageSaturationFilter alloc] init];
    [gpuFilter setSaturation:value];
    return [gpuFilter imageByFilteringImage:inputImage];
}

+ (UIImage*) GPUBrightnessOnImage : (UIImage*) inputImage withValue : (float) value {
    GPUImageBrightnessFilter *gpuFilter = [[GPUImageBrightnessFilter alloc] init];
    [gpuFilter setBrightness:value];
    return [gpuFilter imageByFilteringImage:inputImage];
}

+ (UIImage*) GPUContrastOnImage : (UIImage*) inputImage withValue : (float) value {
    GPUImageContrastFilter *gpuFilter = [[GPUImageContrastFilter alloc] init];
    [gpuFilter setContrast:value];
    return [gpuFilter imageByFilteringImage:inputImage];
}

+ (UIImage*) GPUGaussianBlurOnImage : (UIImage*) inputImage withValue : (float) value {
    GPUImageGaussianBlurFilter *gpuFilter = [[GPUImageGaussianBlurFilter alloc] init];
    [gpuFilter setBlurSize:value];
    return [gpuFilter imageByFilteringImage:inputImage];
}

+ (UIImage*) GPUSharpenImage : (UIImage*) inputImage withValue : (float) value {
    GPUImageSharpenFilter *gpuFilter = [[GPUImageSharpenFilter alloc] init];
    [gpuFilter setSharpness:value];
    return [gpuFilter imageByFilteringImage:inputImage];
}

+ (UIImage*) GPUFastBlur : (UIImage*) inputImage withValue : (float) value {
    GPUImageFastBlurFilter *gpuFilter = [[GPUImageFastBlurFilter alloc] init];
    [gpuFilter setBlurSize:value];
    return [gpuFilter imageByFilteringImage:inputImage];
}

+ (UIImage*) GPUTransform2DImage : (UIImage*) inputImage withAngle : (float) value {
    GPUImageTransformFilter *gpuFilter = [[GPUImageTransformFilter alloc] init];
    [gpuFilter setAffineTransform:CGAffineTransformMakeRotation(radian(value))];
    return [gpuFilter imageByFilteringImage:inputImage];
}
+ (UIImage*) Rotate : (UIImage*) src toOrientation : (UIImageOrientation) orientation
{
    UIImage *output;
    
    if (orientation == UIImageOrientationRight) {
        output = [[UIImage alloc] initWithCGImage:src.CGImage scale:1.0 orientation:UIImageOrientationRight];
    } else if (orientation == UIImageOrientationLeft) {
        output = [[UIImage alloc] initWithCGImage:src.CGImage scale:1.0 orientation:UIImageOrientationLeft];
    } else if (orientation == UIImageOrientationDown) {
        output = [[UIImage alloc] initWithCGImage:src.CGImage scale:1.0 orientation:UIImageOrientationDown];
    } else if (orientation == UIImageOrientationUp) {
        output = [[UIImage alloc] initWithCGImage:src.CGImage scale:1.0 orientation:UIImageOrientationUp];
    }

    return output;
}
+ (UIImage *) Rotate : (UIImage*) inputImage ByDegrees:(CGFloat)degrees 
{   
    // calculate the size of the rotated view's containing box for our drawing space
    UIView *rotatedViewBox = [[UIView alloc] initWithFrame:CGRectMake(0,0,inputImage.size.width, inputImage.size.height)];
    CGAffineTransform t = CGAffineTransformMakeRotation(radian(degrees));
    rotatedViewBox.transform = t;
    CGSize rotatedSize = rotatedViewBox.frame.size;
    
    // Create the bitmap context
    UIGraphicsBeginImageContext(rotatedSize);
    CGContextRef bitmap = UIGraphicsGetCurrentContext();
    
    // Move the origin to the middle of the image so we will rotate and scale around the center.
    CGContextTranslateCTM(bitmap, rotatedSize.width/2, rotatedSize.height/2);
    
    //   // Rotate the image context
    CGContextRotateCTM(bitmap, radian(degrees));
    
    // Now, draw the rotated/scaled image into the context
    CGContextScaleCTM(bitmap, 1.0, -1.0);
    CGContextDrawImage(bitmap, CGRectMake(-inputImage.size.width / 2, -inputImage.size.height / 2, inputImage.size.width, inputImage.size.height), [inputImage CGImage]);
    
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    CGContextRelease(bitmap);
    UIGraphicsEndImageContext();
    return newImage;
}

@end
