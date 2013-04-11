//
//  ViewController.m
//  SorryNoBattery
//
//  Created by Xavi on 11/4/13.
//  Copyright (c) 2013 Xavier Roman. All rights reserved.
//

#import "ViewController.h"
#import <QuartzCore/QuartzCore.h>

@interface ViewController ()<UINavigationControllerDelegate,UIImagePickerControllerDelegate>

@property (nonatomic) BOOL imageSelected;

@end

@implementation ViewController

#pragma mark Put in into a category

+ (NSArray*)getRGBAsFromImage:(UIImage*)image atX:(int)xx andY:(int)yy count:(int)count
{
    NSMutableArray *result = [NSMutableArray arrayWithCapacity:count];
    
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
    for (int ii = 0 ; ii < count ; ++ii)
    {
        CGFloat red   = (rawData[byteIndex]     * 1.0) / 255.0;
        CGFloat green = (rawData[byteIndex + 1] * 1.0) / 255.0;
        CGFloat blue  = (rawData[byteIndex + 2] * 1.0) / 255.0;
        CGFloat alpha = (rawData[byteIndex + 3] * 1.0) / 255.0;
        byteIndex += 4;
        
        UIColor *acolor = [UIColor colorWithRed:red green:green blue:blue alpha:alpha];
        [result addObject:acolor];
    }
    
    free(rawData);
    
    return result;
}

#pragma mark - Screen proccesing

-(UIImage *)takeScreenShoot{
    UIGraphicsBeginImageContext(self.view.frame.size);
    [self.view.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *screenShot = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return screenShot;
}

-(void)saveToCameraRoll{
    
    UIImageWriteToSavedPhotosAlbum([self takeScreenShoot], self, @selector(image:didFinishSavingWithError:contextInfo:), nil);
}

- (void)image:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo
{
    if (error != NULL){
        NSLog(@"There is an error");
    }
    else {
        NSLog(@"Image successfully saved");
    }
}


/*Return Values:
 0 = Blue TopBar
 1 = Black TopBar
 -1 = Unknown Color
 */
- (NSUInteger) getTopBarColor {
    
    NSArray *colorsArray = [ViewController getRGBAsFromImage:[self takeScreenShoot] atX:0 andY:0 count:1];
    UIColor *colorIndex = (UIColor*) colorsArray [0];
    CGColorRef color = [colorIndex CGColor];
    int numComponents = CGColorGetNumberOfComponents(color);
    if (numComponents == 4)
    {
        const CGFloat *components = CGColorGetComponents(color);
        CGFloat red = components[0];
        CGFloat green = components[1];
        CGFloat blue = components[2];
        CGFloat alpha = components[3];
        
        NSLog(@"%f   %f   %f   %f", red, green, blue, alpha);
    }
    return -1;
}

#pragma mark - Gesture recognizer

-(void)doSingleTap{
    NSLog(@"Single Tap");
    
    UIImagePickerController *imagePicker = [[UIImagePickerController alloc] init];
    imagePicker.delegate = self;
    [self presentViewController:imagePicker animated:YES completion:nil];
}

-(void)doDoubleTap{
    NSLog(@"Double Tap");
    if(self.imageSelected){
        [self getTopBarColor];
        //Select the image for overlay
        self.onePercentOverlay.hidden = !self.onePercentOverlay.hidden; //Change to save only and no go back to the previous battery level
        [self saveToCameraRoll];
    }
    else {
        NSLog(@"Show alert view");
    }
}

#pragma mark - UIImagePickerControllerDelegate methods

-(void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    // Get the selected image.
    UIImage *image = [info objectForKey:UIImagePickerControllerOriginalImage];
    
    // Convert the image to JPEG data.
    //NSData *imageData = UIImageJPEGRepresentation(image, 1.0);
    
    self.imageBackground.image = image;
    self.imageBackground.hidden = false;
    self.labelNoImages.hidden = true;
    self.imageSelected = true;
    [picker dismissViewControllerAnimated:YES completion:nil];
}

-(void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [picker dismissViewControllerAnimated:YES completion:nil];
    self.imageBackground.image = nil;
    self.imageBackground.hidden = true;
    self.labelNoImages.hidden = false;
    self.imageSelected = false;
    self.onePercentOverlay.hidden = true;
}


-(void)viewDidLoad{
    [super viewDidLoad];
    self.imageSelected = false;
    
    UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc] initWithTarget: self action:@selector(doSingleTap)];
    singleTap.numberOfTapsRequired = 1;
    [self.view addGestureRecognizer:singleTap];
    
    UITapGestureRecognizer *doubleTap = [[UITapGestureRecognizer alloc] initWithTarget: self action:@selector(doDoubleTap)];
    doubleTap.numberOfTapsRequired = 2;
    [self.view addGestureRecognizer:doubleTap];
    
    [singleTap requireGestureRecognizerToFail:doubleTap];
}


@end
