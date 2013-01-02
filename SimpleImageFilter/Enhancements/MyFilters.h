//
//  MyFilters.h
//  ColorBlendTutorial
//
//  Created by Swati Panchal on 5/19/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>

@interface UIImage (CiFilter)
{
    
}

+(UIImage *) CIAdditionCompositingWithInputImage : (UIImage*) inputImage andInputBackgroundImage : (UIImage*) inputBackgroundImage;

+(UIImage *) CIAffineTransformWithInputImage : (UIImage*) inputImage  andInputTransform : (CGAffineTransform) transform;

+ (UIImage*) CIAffineTransformWithInputImage: (UIImage*) inputImage andRotationAngle : (float) angle;

+ (UIImage*) CIAffineTransformWithInputImage: (UIImage*)inputImage andScaleX : (float) x ScaleY : (float) y;

+(UIImage *) CICheckerboardGeneratorWithInputCenter : (CIVector*) inputCenter inputColor0 : (CIColor*) color0 inputColor1 : (CIColor*) color1 inputWidth : (float) inputWidth inputSharpness : (float) inputSharpness;

+(UIImage *) CIColorBlendModeWithInputImage : (UIImage*) inputImage andInputBackgroundImage : (UIImage*) inputBackgroundImage;

+(UIImage *) CIColorBurnBlendModeWithInputImage : (UIImage*) inputImage andInputBackgroundImage : (UIImage*) inputBackgroundImage;

+(UIImage *) CIColorControlsWithInputImage : (UIImage*)inputImage inputSaturation : (float)inputSaturation inputBrightness : (float)inputBrightness inputContrast : (float)inputContrast;

+(UIImage *) CIColorCubeWithInputImage : (UIImage*) inputImage inputCubeDimension : (float)inputCubeDimension inputCubeData : (NSData*) inputCubeData;

+(UIImage *) CIColorDodgeBlendModeWithInputImage : (UIImage*) inputImage andInputBackgroundImage : (UIImage*) inputBackgroundImage;

+(UIImage *) CIColorInvertWithInputImage : (UIImage*) inputImage;

+(UIImage *) CIColorMatrixWithInputImage : (UIImage*) inputImage inputRVector : (CIVector*)inputRVector inputGVector : (CIVector*)inputGVector
    inputBVector : (CIVector*)inputBVector inputAVector : (CIVector*)inputAVector inputBiasVector : (CIVector*)inputBiasVector;

+(UIImage *) CIColorMonochromeWithInputImage : (UIImage*)inputImage inputColor : (CIColor*)inputColor inputIntensity : (float) inputIntensity;

+(UIImage *) CIConstantColorGeneratorWithInputColor : (CIColor*) inputColor;

+(UIImage *) CICropWithInputImage : (UIImage*)inputImage inputRectangle : (CIVector*)inputRectangle;

+(UIImage *) CIDarkenBlendModeWithInputImage : (UIImage*) inputImage andInputBackgroundImage : (UIImage*) inputBackgroundImage;

+(UIImage *) CIDifferenceBlendModeWithInputImage : (UIImage*) inputImage andInputBackgroundImage : (UIImage*) inputBackgroundImage;

+(UIImage *) CIExclusionBlendModeWithInputImage : (UIImage*) inputImage andInputBackgroundImage : (UIImage*) inputBackgroundImage;

+(UIImage *) CIExposureAdjustWithInputImage : (UIImage*) inputImage inputEV : (float) inputEV;

+(UIImage *) CIFalseColorWithInputImage : (UIImage*) inputImage inputColor0 : (CIColor*) inputColor0 inputColor1 : (CIColor*) inputColor1;

+(UIImage *) CIGammaAdjustWithInputImage : (UIImage*) inputImage inputPower : (float) inputPower;

+(UIImage *) CIGaussianGradientWithInputCenter : (CIVector*) inputCenter inputColor0 : (CIColor*) inputColor0 inputColor1 : (CIColor*) inputColor1 inputRadius : (float) inputRadius;

+(UIImage *) CIHardLightBlendModeWithInputImage : (UIImage*) inputImage andInputBackgroundImage : (UIImage*) inputBackgroundImage;

+(UIImage *) CIHighlightShadowAdjustWithInputImage : (UIImage*) inputImage inputHighlightAmount:(float) inputHighlightAmount inputShadowAmount : (float) inputShadowAmount;

+(UIImage *) CIHueAdjustWithInputImage : (UIImage*) inputImage inputAngle : (float) inputAngle;

+(UIImage *) CIHueBlendModeWithInputImage : (UIImage*) inputImage andInputBackgroundImage : (UIImage*) inputBackgroundImage;

+(UIImage *) CILightenBlendModeWithInputImage : (UIImage*) inputImage andInputBackgroundImage : (UIImage*) inputBackgroundImage;

+(UIImage *) CILinearGradientWithInputPoint0 : (CIVector*) inputPoint0 inputPoint1 : (CIVector*) inputPoint1 inputColor0 : (CIColor*) inputColor0 inputColor1 : (CIColor*) inputColor1;

+(UIImage *) CILuminosityBlendModeWithInputImage : (UIImage*) inputImage andInputBackgroundImage : (UIImage*) inputBackgroundImage; 

+(UIImage *) CIMaximumCompositingWithInputImage : (UIImage*) inputImage andInputBackgroundImage : (UIImage*) inputBackgroundImage;

+(UIImage *) CIMinimumCompositingWithInputImage : (UIImage*) inputImage andInputBackgroundImage : (UIImage*) inputBackgroundImage;

+(UIImage *) CIMultiplyBlendModeWithInputImage : (UIImage*) inputImage andInputBackgroundImage : (UIImage*) inputBackgroundImage;

+(UIImage *) CIMultiplyCompositingWithInputImage : (UIImage*) inputImage andInputBackgroundImage : (UIImage*) inputBackgroundImage;

+(UIImage *) CIOverlayBlendModeWithInputImage : (UIImage*) inputImage andInputBackgroundImage : (UIImage*) inputBackgroundImage;

+(UIImage *) CIRadialGradientWithInputCenter : (CIVector*) inputCenter inputRadius0:(float) inputRadius0 inputRadius1: (float) inputRadius1 inputColor0 : (CIColor*) inputColor0 inputColor1 : (CIColor*) inputColor1;

+(UIImage *) CISaturationBlendModeWithInputImage : (UIImage*) inputImage andInputBackgroundImage : (UIImage*) inputBackgroundImage;

+(UIImage *) CIScreenBlendModeWithInputImage : (UIImage*) inputImage andInputBackgroundImage : (UIImage*) inputBackgroundImage;

+(UIImage *) CISepiaToneWithInputImage : (UIImage*) inputImage inputIntensity : (float) inputIntensity;

+(UIImage *) CISoftLightBlendModeWithInputImage : (UIImage*) inputImage andInputBackgroundImage : (UIImage*) inputBackgroundImage;

+(UIImage *) CISourceAtopCompositingWithInputImage : (UIImage*) inputImage andInputBackgroundImage : (UIImage*) inputBackgroundImage;

+(UIImage *) CISourceInCompositingWithInputImage : (UIImage*) inputImage andInputBackgroundImage : (UIImage*) inputBackgroundImage;

+(UIImage *) CISourceOutCompositingWithInputImage : (UIImage*) inputImage andInputBackgroundImage : (UIImage*) inputBackgroundImage;

+(UIImage *) CISourceOverCompositingWithInputImage : (UIImage*) inputImage andInputBackgroundImage : (UIImage*) inputBackgroundImage;

+(UIImage *) CIStraightenFilterWithInputImage : (UIImage*) inputImage inputAngle : (float) inputAngle;

+(UIImage *) CIStripesGeneratorWithInputCenter : (CIVector*) inputCenter inputColor0 : (CIColor*)inputColor0 inputColor1 : (CIColor*) inputColor1 inputWidth : (float) inputWidth inputSharpness : (float) inputSharpness;

+(UIImage *) CITemperatureAndTintWithInputImage : (UIImage*) inputImage inputNeutral : (CIVector*) inputNeutral inputTargetNeutral : (CIVector*) inputTargetNeutral;

+(UIImage *) CIToneCurveWithInputImage : (UIImage*) inputImage inputPoint0 : (CIVector*) inputPoint0 inputPoint1 : (CIVector*) inputPoint1 inputPoint2 : (CIVector*) inputPoint2 inputPoint3 : (CIVector*) inputPoint3 inputPoint4 : (CIVector*) inputPoint4;

+ (UIImage*) CIVignetteWithInputImage : (UIImage*) inputImage inputIntensity : (float) intensity inputRadius : (float) radius;
+(UIImage *) CIVibranceWithInputImage : (UIImage*) inputImage inputAmount : (float) inputAmount;

+(UIImage *) CIWhitePointAdjustWithInputImage : (UIImage*) inputImage inputColor : (CIColor*) inputColor;

+ (UIImage*) stackBlurInputImage: (UIImage*) inputImage  andRadius : (NSUInteger)inRadius;

+ (UIImage*) kGaussianBlurOfImage : (UIImage*) inputImage andRadius : (float) radius;

+ (UIImage*) kGrayScaleOnImage : (UIImage*) inputImage;

+ (UIImage*) kSepiaOnImage : (UIImage*) inputImage;

+ (UIImage*) kPosterizeImage : (UIImage*) inputImage withLevels : (float) level;

+(UIImage*) kSaturateImage : (UIImage*) inputImage withAmount : (double) amount;

+(UIImage*) kBrightnessAdjustOnImage : (UIImage*) inputImage withAmount : (double) amount;

+(UIImage*) kGammaAdjustOnImage : (UIImage*) inputImage withAmount : (double) amount;

+(UIImage*) kOpacityOnImage : (UIImage*) inputImage withAmount : (double) amount;

+(UIImage*) kContrastOnImage : (UIImage*) inputImage WithAmount : (double) amount;

+(UIImage*) kBiasOnImage : (UIImage*) inputImage WithAmount : (double) amount;

+(UIImage*) kInvertOnImage : (UIImage*) inputImage;

+(UIImage*) kNoisOnImage : (UIImage*) inputImage WithAmount : (double) amount;

+(UIImage*) kOverlayOnImage : (UIImage*) inputImage withBackgroundImage : (UIImage*) background;

+(UIImage*) kMaskOnImage : (UIImage*) inputImage withBackgroundImage : (UIImage*) background;

+(UIImage*) kMergeImage : (UIImage*) inputImage withBackgroundImage : (UIImage*) background;

+(UIImage*) kLevelsWithInputImage : (UIImage*) inputImage Black : (NSInteger) black Mid : (NSInteger) mid White :(NSInteger) white;

+(UIImage*) kRedCurveToImage : (UIImage*) inputImge WithRedChannelPoints : (NSMutableArray*) points;

+(UIImage*) kGreenCurveToImage : (UIImage*) inputImge WithGreenChannelPoints : (NSMutableArray*) points;

+(UIImage*) kBlueCurveToImage : (UIImage*) inputImge WithBlueChannelPoints : (NSMutableArray*) points;

+(UIImage*) kAdjustImage : (UIImage*) inputImage WithRed : (double) red Green : (double) green Blue : (double) blue;

+(UIImage*) kSharpenImage : (UIImage*) inputImage;

+(UIImage*) kEdgeDetectOfImage : (UIImage*) inputImage;

+(UIImage*) kLomoOfImage : (UIImage*) inputImage;

+ (UIImage*) kDarkVignetteEffectOnImage : (UIImage*) inputImage;

+ (UIImage*) kLomoOfImage : (UIImage*) inputImage;

+ (UIImage*) kVignetteOnImage : (UIImage*) inputImage;

+ (UIImage*) kPolaroidishOnImage : (UIImage*) inputImage;

+ (UIImage*) kBlueMoodOnInputImage : (UIImage*) inputImage;

+ (UIImage*) kSunKissedOnImage : (UIImage*) inputImage;

+ (UIImage*) kPolarizeOnImage : (UIImage*) inputImage;

+ (UIImage*) kEnvyOnImage : (UIImage*) inputImage;

+ (UIImage*) kCrossProcessOnImage : (UIImage*) inputImage withBackgroundImage : (UIImage*) backgroundImage;

+ (UIImage*) kMagicHourOnImage : (UIImage*) inputImage withBackgroundImage : (UIImage*) backgroundImage;

+ (UIImage*) kToycameraOnImage : (UIImage*) inputImage withBackgroundImage : (UIImage*) backgroungImage;

+ (UIImage*) kE1ofFilterAppOnImage : (UIImage*) inputImage;

+ (UIImage*) kE2ofFilterAppOnImage : (UIImage*) inputImage;

+ (UIImage*) kE3ofFilterAppOnImage : (UIImage*) inputImage;

+ (UIImage*) kE4ofFilterAppOnImage : (UIImage*) inputImage;

+ (UIImage*) kE5ofFilterAppOnImage : (UIImage*) inputImage;

+ (UIImage*) kE6ofFilterAppOnImage : (UIImage*) inputImage;

+ (UIImage*) kE7ofFilterAppOnImage : (UIImage*) inputImage;

+ (UIImage*) kE8ofFilterAppOnImage : (UIImage*) inputImage;

+ (UIImage*) kE9ofFilterAppOnImage : (UIImage*) inputImage;

+ (UIImage*) kE10ofFilterAppOnImage : (UIImage*) inputImage;

+ (UIImage*) kE11ofFilterAppOnImage : (UIImage*) inputImage;

+ (UIImage*) NYXGaussianBlureOnImage : (UIImage*) inputImage Bias : (NSInteger) bias;

+ (UIImage*) NYXReflectedImage : (UIImage*) inputImage withHeight:(NSUInteger)height fromAlpha:(float)fromAlpha toAlpha:(float)toAlpha;

+ (UIImage*) NYXAutoEnhanceImage : (UIImage*) inputImage;

+ (UIImage*) NYXRedEyeCorrectionOnImage : (UIImage*) inputImage;

+ (UIImage*) NYXEdgeDetectionOnImage : (UIImage*) inputImage WithBias:(NSInteger)bias;

+ (UIImage*) NYXEmbossImage : (UIImage*) inputImage WithBias:(NSInteger)bias;

+ (UIImage*) NYXGammaCorrectionOfImage : (UIImage*) inputImage WithValue:(float)value;

+(UIImage*) NYXGrayscaleOfImage : (UIImage*) inputImage;

+(UIImage*) NYXInvertImage : (UIImage*) inputImage withNegativeMultiplier : (float) __negativeMultiplier;

+(UIImage*) NYXOpacityOfImage :(UIImage*) inputImage withOpacityValue : (float)value;

+(UIImage*) NYXSepiaOfImage : (UIImage*) inputImage sepiaFactorRedRed : (float) __sepiaFactorRedRed sepiaFactorRedGreen : (float) __sepiaFactorRedGreen sepiaFactorRedBlue : (float) __sepiaFactorRedBlue sepiaFactorGreenRed : (float) __sepiaFactorGreenRed sepiaFactorGreenGreen : (float) __sepiaFactorGreenGreen sepiaFactorGreenBlue : (float) __sepiaFactorGreenBlue sepiaFactorBlueRed : (float) __sepiaFactorBlueRed sepiaFactorBlueGreen : (float) __sepiaFactorBlueGreen sepiaFactorBlueBlue : (float) __sepiaFactorBlueBlue;

+(UIImage*) NYXSharpenImage: (UIImage*) inputImage WithBias:(NSInteger)bias;

+(UIImage*) NYXUnsharpenImage : (UIImage*)inputImage WithBias:(NSInteger)bias;

+ (UIImage*) GPUSepiaFilterOnImage : (UIImage*) inputImage withValue : (float) value;

+ (UIImage*) GPUSketchOfImage : (UIImage*) inputImage;

+ (UIImage*) GPUTiltShiftOnImage : (UIImage*) inputImage TopFocusLevel : (float) topFocusLevel BottomFocusLevel : (float) bottomFocusLevel FocusFallOfRate : (float) focusFallOfRate;

+ (UIImage*) GPUGaussianSelectiveBlurOnImage : (UIImage*) inputImage withRadius : (float) radius;

+ (UIImage*) GPUCropImage : (UIImage*) inputImage withinRect : (CGRect) rect;

+ (UIImage*) GPUSaturationOnImage : (UIImage*) inputImage withValue : (float) value;

+ (UIImage*) GPUBrightnessOnImage : (UIImage*) inputImage withValue : (float) value;

+ (UIImage*) GPUContrastOnImage : (UIImage*) inputImage withValue : (float) value;

+ (UIImage*) GPUGaussianBlurOnImage : (UIImage*) inputImage withValue : (float) value;

+ (UIImage*) GPUSharpenImage : (UIImage*) inputImage withValue : (float) value;

+ (UIImage*) GPUFastBlur : (UIImage*) inputImage withValue : (float) value;

+ (UIImage*) GPUTransform2DImage : (UIImage*) inputImage withAngle : (float) value;

+ (UIImage*) Rotate : (UIImage*) src toOrientation : (UIImageOrientation) orientation;

+ (UIImage *) Rotate : (UIImage*) inputImage ByDegrees:(CGFloat)degrees;

@end
