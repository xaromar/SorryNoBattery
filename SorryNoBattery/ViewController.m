//
//  ViewController.m
//  SorryNoBattery
//
//  Created by Xavi on 11/4/13.
//  Copyright (c) 2013 Xavier Roman. All rights reserved.
//

#import "ViewController.h"
#import <QuartzCore/QuartzCore.h>
#import "UIImage+Tools.h"

#define THRESHOLD 5 //RGB value comparison between screenshot and top bar file

static NSString * const kOnePercentBlueFileName = @"1PercentBlue.JPG";
static NSString * const kOnePercentBlackFileName = @"1PercentBlack.JPG";


@interface ViewController ()<UINavigationControllerDelegate,UIImagePickerControllerDelegate>

@property (nonatomic) BOOL imageSelected;

@end

@implementation ViewController

#pragma mark - Screen proccesing

-(UIImage *)takeScreenShoot{

    CGSize screenDimensions = [[UIScreen mainScreen] bounds].size;
    
    // Create a graphics context with the target size
    // (last parameter takes scale into account)
    UIGraphicsBeginImageContextWithOptions(screenDimensions, NO, 0);
    
    // Render the view to a new context
    CGContextRef context = UIGraphicsGetCurrentContext();
    [self.view.layer renderInContext:context];
    
    UIImage *screenshot = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    return screenshot;
}

#pragma mark - Save to Camera Roll

-(void)saveToCameraRoll{
    UIImageWriteToSavedPhotosAlbum([self takeScreenShoot], self, @selector(image:didFinishSavingWithError:contextInfo:), nil);
}

- (void)image:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo
{
    if (error != NULL){
        NSLog(@"There is an error");
    }
    else {
        //NSLog(@"Image successfully saved");
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Congratulations!",nil)
                                                        message:NSLocalizedString(@"Image has saved successfully",nil)
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        [alert show];

    }
}

-(BOOL)compareArray:(NSArray*)array1 withArray:(NSArray*)array2 andThreshold:(int)threshold{
    if(array1.count != array2.count) return FALSE;
    
    for(int i=0;i<array1.count;i++){
        NSNumber *number1 =[array1 objectAtIndex:i];
        NSNumber *number2 =[array2 objectAtIndex:i];
        int result = abs(number1.intValue - number2.intValue);
        if(result > threshold) return FALSE;
    }
    
    return TRUE;
}


/*
 Return Values:
 0 = Blue TopBar
 1 = Black TopBar
 -1 = Unknown Color
 */
- (NSUInteger) getTopBarColor {
    
    NSArray *colorTopBarScreenshot = [UIImage getRGBAsFromImage:[self takeScreenShoot] atX:0 andY:10];
    //NSLog(@"%@",colorTopBarScreenshot);
    NSArray *colorTopBarBlue = [UIImage getRGBAsFromImage:[UIImage imageNamed:kOnePercentBlueFileName] atX:0 andY:10];
    //NSLog(@"%@",colorTopBarBlue);
    
    if([self compareArray:colorTopBarScreenshot withArray:colorTopBarBlue andThreshold:THRESHOLD]){
        NSLog(@"Blue tabBar detected");
        return 0;
    }
    NSArray *colorTopBarBlack = [UIImage getRGBAsFromImage:[UIImage imageNamed:kOnePercentBlackFileName] atX:0 andY:10];
    //NSLog(@"%@",colorTopBarBlack);
    if([colorTopBarScreenshot isEqual:colorTopBarBlack]){
        NSLog(@"Black tabBar detected");
        return 1;
    }
    else{
        NSLog(@"Translucent tabBar detected");
        return -1;
    }
}

#pragma mark - Gesture recognizer

-(void)doSingleTap{
    //NSLog(@"Single Tap");
    
    UIActivityIndicatorView *activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    activityIndicator.alpha = 1.0;
    activityIndicator.center = self.view.center;
    activityIndicator.hidesWhenStopped = YES;
    [self.view addSubview:activityIndicator];
    [activityIndicator startAnimating];
    
    UIImagePickerController *imagePicker = [[UIImagePickerController alloc] init];
    imagePicker.delegate = self;
    [self presentViewController:imagePicker animated:YES completion:^{
        [activityIndicator stopAnimating];
    }];
}

-(void)doDoubleTap{
    //NSLog(@"Double Tap");
    
    if(self.imageSelected){
        [self getTopBarColor];
        [UIView animateWithDuration:1.0 animations:^{
            if(self.onePercentOverlay.alpha == 0.0)
                self.onePercentOverlay.alpha = 1.0;
            else if(self.onePercentOverlay.alpha == 1.0)
                self.onePercentOverlay.alpha = 0.0;
        }];
        [self saveToCameraRoll];
    }
    else {
        NSLog(@"Show alert view");
    }
}

-(void)doSwipe{
    //NSLog(@"Swipe");
    
    if(self.imageSelected){
        int colorBar = [self getTopBarColor];
        if(colorBar == -1){
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error!",nil)
                                                            message:NSLocalizedString(@"Invalid image, please choose another one",nil)
                                                           delegate:nil
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];
            [alert show];
        }
        else{
            if(colorBar == 0)self.onePercentOverlay.image = [UIImage imageNamed:kOnePercentBlueFileName];
            else if (colorBar == 1)self.onePercentOverlay.image = [UIImage imageNamed:kOnePercentBlackFileName];
            [UIView animateWithDuration:1.0 animations:^{
                if(self.onePercentOverlay.alpha == 0.0){
                    self.onePercentOverlay.alpha = 1.0;
                    [self saveToCameraRoll];
                }
                else if(self.onePercentOverlay.alpha == 1.0)
                    self.onePercentOverlay.alpha = 0.0;
            }];
        }
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
    self.imageSelected = true;
    self.onePercentOverlay.alpha = 0.0;
    [picker dismissViewControllerAnimated:YES completion:nil];
}

-(void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [picker dismissViewControllerAnimated:YES completion:nil];
    self.imageBackground.image = nil;
    self.imageBackground.hidden = true;
    self.imageSelected = false;
    self.onePercentOverlay.alpha = 0.0;
}


-(void)viewDidLoad{
    [super viewDidLoad];
    self.imageSelected = false;
    
    UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc] initWithTarget: self action:@selector(doSingleTap)];
    singleTap.numberOfTapsRequired = 1;
    [self.view addGestureRecognizer:singleTap];
    
//    UITapGestureRecognizer *doubleTap = [[UITapGestureRecognizer alloc] initWithTarget: self action:@selector(doDoubleTap)];
//    doubleTap.numberOfTapsRequired = 2;
//    [self.view addGestureRecognizer:doubleTap];
//    
//    [singleTap requireGestureRecognizerToFail:doubleTap];
    
    UISwipeGestureRecognizer *swipe = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(doSwipe)];
    [swipe setDirection:UISwipeGestureRecognizerDirectionUp];
    [self.view addGestureRecognizer:swipe];
      
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    
}


@end