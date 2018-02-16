//
//  ViewController.m
//  ObjCCamera
//
//  Created by Chihiro on 2018/02/16.
//  Copyright © 2018 Chihiro. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Get a device
    AVCaptureDevice* device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    // Create input
    AVCaptureDeviceInput* deviceInput = [AVCaptureDeviceInput deviceInputWithDevice:device error:NULL];

    // Create video output
    NSDictionary* settings = @{(id)kCVPixelBufferPixelFormatTypeKey:[NSNumber numberWithInt:kCVPixelFormatType_32BGRA]};
    AVCaptureVideoDataOutput* dataOutput = [[AVCaptureVideoDataOutput alloc] init];
    dataOutput.videoSettings = settings;
    [dataOutput setSampleBufferDelegate:self queue:dispatch_get_main_queue()];

    // Set up a session
    self.session = [[AVCaptureSession alloc] init];
    [self.session addInput:deviceInput];
    [self.session addOutput:dataOutput];
    self.session.sessionPreset = AVCaptureSessionPreset352x288;

    AVCaptureConnection *videoConnection = NULL;

    // Set up a camera settings
    [self.session beginConfiguration];

    for ( AVCaptureConnection *connection in [dataOutput connections] )
    {
        for ( AVCaptureInputPort *port in [connection inputPorts] )
        {
            if ( [[port mediaType] isEqual:AVMediaTypeVideo] )
            {
                videoConnection = connection;

            }
        }
    }
    if([videoConnection isVideoOrientationSupported]) // **Here it is, its always false**
    {
        [videoConnection setVideoOrientation:AVCaptureVideoOrientationPortrait];
    }

    [self.session commitConfiguration];
    // Start the session
    [self.session startRunning];
}

//delegate method which is called every frame
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
    // render image
    self.imageView.image = [self imageFromSampleBufferRef:sampleBuffer];
}

// Convert CMSampleBufferRef to UIImage
- (UIImage *)imageFromSampleBufferRef:(CMSampleBufferRef)sampleBuffer
{
    // get an image buf
    CVImageBufferRef    buffer;
    buffer = CMSampleBufferGetImageBuffer(sampleBuffer);

    // Lock image buf
    CVPixelBufferLockBaseAddress(buffer, 0);
    // Get info from image buf
    uint8_t*    base;
    size_t      width, height, bytesPerRow;
    base = CVPixelBufferGetBaseAddress(buffer);
    width = CVPixelBufferGetWidth(buffer);
    height = CVPixelBufferGetHeight(buffer);
    bytesPerRow = CVPixelBufferGetBytesPerRow(buffer);

    //  Create a bitmap context
    CGColorSpaceRef colorSpace;
    CGContextRef    cgContext;
    colorSpace = CGColorSpaceCreateDeviceRGB();
    cgContext = CGBitmapContextCreate(
                                      base, width, height, 8, bytesPerRow, colorSpace,
                                      kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
    CGColorSpaceRelease(colorSpace);

    // Create image
    CGImageRef  cgImage;
    UIImage*    image;
    cgImage = CGBitmapContextCreateImage(cgContext);
    image = [UIImage imageWithCGImage:cgImage scale:1.0f
                          orientation:UIImageOrientationUp];
    CGImageRelease(cgImage);
    CGContextRelease(cgContext);

    // Unlock image buf
    CVPixelBufferUnlockBaseAddress(buffer, 0);
    return image;
}

@end
