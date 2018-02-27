//
//  ViewController.mm
//  ObjCCamera
//
//  Created by Chihiro on 2018/02/16.
//  Copyright © 2018 Chihiro. All rights reserved.
//

#include "opencv2/opencv.hpp"

#import "ViewController.h"

using namespace std;

@interface ViewController ()
<AVCaptureVideoDataOutputSampleBufferDelegate>

@end

@implementation ViewController
{
    AVCaptureSession *session;
    dispatch_queue_t faceQueue;

    AVSampleBufferDisplayLayer *displayLayer;

    NSMutableArray<AVMetadataFaceObject *>* faceObjects;
}

- (void)dealloc
{
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    displayLayer = [AVSampleBufferDisplayLayer new];

    [self initCamera];

}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    displayLayer.frame = self.view.bounds;
    [self.view.layer addSublayer:displayLayer];
    [self.view layoutIfNeeded];
}

#pragma mark - Camera

- (void)initCamera
{
    NSError *error;

    faceQueue = dispatch_queue_create("com.f.faceQueue", DISPATCH_QUEUE_SERIAL);

    AVCaptureDevice *captureDevice;  // Get the device
    for (AVCaptureDevice *device in [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo]) {
        if (device.position == AVCaptureDevicePositionFront) {
            captureDevice = device;
        }
    }

    if(captureDevice == nil) {
        [NSException raise:@"" format:@"AVCaptureDevicePositionBack not found"];
    }

    session = [[AVCaptureSession alloc] init];  // Create a session

    [session beginConfiguration];  // Configure the session
    session.sessionPreset = AVCaptureSessionPreset352x288;

    AVCaptureDeviceInput *deviceInput = [AVCaptureDeviceInput deviceInputWithDevice:captureDevice error:&error];  // Create and add the input
    if (error) {
        [NSException raise:@"" format:@"AVCaptureDeviceInput not found"];
    }
    [session addInput:deviceInput];

    AVCaptureVideoDataOutput *videoOutput = [[AVCaptureVideoDataOutput alloc] init];  // Create an output and add
    videoOutput.videoSettings = @{(id)kCVPixelBufferPixelFormatTypeKey : @(kCVPixelFormatType_32BGRA) }; // Config
    [videoOutput setSampleBufferDelegate:self queue:dispatch_get_main_queue()]; // output
    [session addOutput:videoOutput];

    [session commitConfiguration];

    // Start getting input from the camera
    [session startRunning];

    // Set where the input come from
    for(AVCaptureConnection *connection in videoOutput.connections)
    {
        if(connection.supportsVideoOrientation)
        {
            connection.videoOrientation = AVCaptureVideoOrientationPortrait;
        }
    }
}

#pragma mark - AVCaptureVideoDataOutputSampleBufferDelegate

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
    CVImageBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);

    CVPixelBufferLockBaseAddress(pixelBuffer, kCVPixelBufferLock_ReadOnly);

    int width = static_cast<int>(CVPixelBufferGetWidth(pixelBuffer));
    int height = static_cast<int>(CVPixelBufferGetHeight(pixelBuffer));
    int bytesPerRow = static_cast<int>(CVPixelBufferGetBytesPerRow(pixelBuffer));
    unsigned char *baseBuffer = (unsigned char *)CVPixelBufferGetBaseAddress(pixelBuffer);

    // Prepare image for mtcnn
    cv::Mat img = cv::Mat(height, width, CV_8UC4, baseBuffer, bytesPerRow); //put buffer in open cv, no memory copied
    if(!img.data){
        cerr << "Reading video failed" << endl;
        return;
    }

    CVPixelBufferUnlockBaseAddress(pixelBuffer, kCVPixelBufferLock_ReadOnly);

    cv::cvtColor(img, img, CV_BGRA2BGR);
    if(!img.data) cout<<"Reading video failed!"<<endl;


    // Prepare mtcnn face detection
    vector<cv::Rect> rects;
    vector<float> confidences;
    std::vector<std::vector<cv::Point>> alignment;

    NSDate *startDate = [NSDate new];

    // write processes here

    NSTimeInterval interval = [[NSDate date] timeIntervalSinceDate:startDate];
    NSLog(@"inerval: %fms", interval * 1000 );


    // Switch from BGR to RGB and put them back to the pixel buffer
    long location = 0;
    uint8_t* pixel_ptr = (uint8_t*)img.data;
    int cn = img.channels();
    cv::Scalar_<uint8_t> rgb_pixel;
    for(int i = 0; i < img.rows; i++) {
        for(int j = 0; j < img.cols; j++) {
            long bufferLocation = location * 4; // 4: RBGA
            rgb_pixel.val[0] = pixel_ptr[i*img.cols*cn + j*cn + 2]; // R
            rgb_pixel.val[1] = pixel_ptr[i*img.cols*cn + j*cn + 1]; // G
            rgb_pixel.val[2] = pixel_ptr[i*img.cols*cn + j*cn + 0]; // B
            baseBuffer[bufferLocation] = rgb_pixel.val[2];
            baseBuffer[bufferLocation + 1] = rgb_pixel.val[1];
            baseBuffer[bufferLocation + 2] = rgb_pixel.val[0];
            location++;
        }
    }

    [displayLayer enqueueSampleBuffer:sampleBuffer];
}
@end

