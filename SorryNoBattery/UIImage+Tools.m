//
//  UIImage+Tools.m
//  SorryNoBattery
//
//  Created by Xavi on 14/4/13.
//  Copyright (c) 2013 Xavier Roman. All rights reserved.
//

#import "UIImage+Tools.h"

@implementation UIImage (Tools)

+ (NSArray *)getRGBAsFromImage:(UIImage*)image atX:(int)xx andY:(int)yy
{
    // First get the image into your data buffer
    CGImageRef imageRef = [image CGImage];
    NSUInteger width = CGImageGetWidth(imageRef);
    NSUInteger height = CGImageGetHeight(imageRef);
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    unsigned char *rawData = (unsigned char*) calloc(height * width * 4, sizeof(unsigned char));
    NSUInteger bytesPerPixel = 4;
    NSUInteger bytesPerRow = bytesPerPixel * width;
    NSUInteger bitsPerComponent = 8;
    CGContextRef context = CGBitmapContextCreate(rawData, width, height,
                                                 bitsPerComponent, bytesPerRow, colorSpace,
                                                 kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    CGColorSpaceRelease(colorSpace);
    
    CGContextDrawImage(context, CGRectMake(0, 0, width, height), imageRef);
    CGContextRelease(context);
    
    // Now your rawData contains the image data in the RGBA8888 pixel format.
    int byteIndex = (bytesPerRow * yy) + xx * bytesPerPixel;
    
    NSMutableArray *arrayRGB = [NSMutableArray arrayWithCapacity:4];
    [arrayRGB addObject:[NSNumber numberWithFloat:(rawData[byteIndex]* 1.0)]];
    [arrayRGB addObject:[NSNumber numberWithFloat:(rawData[byteIndex + 1]* 1.0)]];
    [arrayRGB addObject:[NSNumber numberWithFloat:(rawData[byteIndex + 2]* 1.0)]];
    [arrayRGB addObject:[NSNumber numberWithFloat:(rawData[byteIndex + 3]* 1.0)]];
    
    free(rawData);
    
    return [arrayRGB copy];
}

@end
