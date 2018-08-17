//
//  OpenCVWrapper.m
//  OpenCVTest
//
//  Created by Andre on 8/15/18.
//  Copyright © 2018 3DRobotics. All rights reserved.
//

#import <opencv2/opencv.hpp>
#import <opencv2/xfeatures2d.hpp>
#import <opencv2/xfeatures2d/nonfree.hpp>

#import "OpenCVWrapper.h"
#import <UIKit/UIKit.h>

using namespace cv;
using namespace cv::xfeatures2d;
using namespace std;

static cv::Mat cvMatFromUIImage(UIImage *image) {
    CGColorSpaceRef colorSpace = CGImageGetColorSpace(image.CGImage);
    CGFloat cols = image.size.width;
    CGFloat rows = image.size.height;
    
    cv::Mat cvMat(rows, cols, CV_8UC4); // 8 bits per component, 4 channels (color channels + alpha)
    
    CGContextRef contextRef = CGBitmapContextCreate(cvMat.data,                 // Pointer to  data
                                                    cols,                       // Width of bitmap
                                                    rows,                       // Height of bitmap
                                                    8,                          // Bits per component
                                                    cvMat.step[0],              // Bytes per row
                                                    colorSpace,                 // Colorspace
                                                    kCGImageAlphaNoneSkipLast |
                                                    kCGBitmapByteOrderDefault); // Bitmap info flags
    
    CGContextDrawImage(contextRef, CGRectMake(0, 0, cols, rows), image.CGImage);
    CGContextRelease(contextRef);
    
    return cvMat;
}



static UIImage *UIImageFromCVMat(cv::Mat &cvMat)
{
    NSData *data = [NSData dataWithBytes:cvMat.data length:cvMat.elemSize()*cvMat.total()];
    CGColorSpaceRef colorSpace;
    
    if (cvMat.elemSize() == 1) {
        colorSpace = CGColorSpaceCreateDeviceGray();
    } else {
        colorSpace = CGColorSpaceCreateDeviceRGB();
    }
    
    CGDataProviderRef provider = CGDataProviderCreateWithCFData((__bridge CFDataRef)data);
    
    // Creating CGImage from cv::Mat
    CGImageRef imageRef = CGImageCreate(cvMat.cols,                                 //width
                                        cvMat.rows,                                 //height
                                        8,                                          //bits per component
                                        8 * cvMat.elemSize(),                       //bits per pixel
                                        cvMat.step[0],                            //bytesPerRow
                                        colorSpace,                                 //colorspace
                                        kCGImageAlphaNone|kCGBitmapByteOrderDefault,// bitmap info
                                        provider,                                   //CGDataProviderRef
                                        NULL,                                       //decode
                                        false,                                      //should interpolate
                                        kCGRenderingIntentDefault                   //intent
                                        );
    
    
    // Getting UIImage from CGImage
    UIImage *finalImage = [UIImage imageWithCGImage:imageRef];
    CGImageRelease(imageRef);
    CGDataProviderRelease(provider);
    CGColorSpaceRelease(colorSpace);
    
    return finalImage;
}

@implementation OpenCVImageAlignment

    Mat storedImage;

-(id) init {
    return self;
}

-(UIImage *) getImage {
    return UIImageFromCVMat(storedImage);
}


-(UIImage *) findHomographyOfReferenceImage: (UIImage *)referenceImage andFloatingImage: (UIImage *)floatingImage  {

    Mat matReferenceImage = cvMatFromUIImage(referenceImage);
    Mat matFloatingImage = cvMatFromUIImage(floatingImage);
    cv::Size size(1024,780);
    
    resize(matReferenceImage,matReferenceImage,size);
    resize(matFloatingImage,matFloatingImage,size);
    
    Mat gray_image1;
    Mat gray_image2;
    
    cvtColor( matFloatingImage, gray_image1, CV_RGB2GRAY );
    cvtColor( matReferenceImage, gray_image2, CV_RGB2GRAY );
    
    
    //--Step 1 : Detect the keypoints using SURF Detector
    int minHessian = 400;
    
    Ptr<SURF> detector = SURF::create(minHessian);
    vector< KeyPoint > keypoints_object, keypoints_scene;
    
    detector->detect( gray_image1, keypoints_object );
    detector->detect( gray_image2, keypoints_scene );
    
    
    //--Step 2 : Calculate Descriptors (feature vectors)
    Ptr<SURF> extractor = SURF::create();
    
    Mat descriptors_object,descriptors_scene;
    
    extractor->compute( gray_image1, keypoints_object, descriptors_object );
    extractor->compute( gray_image2, keypoints_scene, descriptors_scene );
    
    //--Step 3 : Matching descriptor vectors using FLANN matcher
    FlannBasedMatcher matcher;
    vector< DMatch > matches;
    matcher.match( descriptors_object, descriptors_scene, matches );
    
    double max_dist = 0;
    double min_dist = 100;
    
    //--Quick calculation of min-max distances between keypoints
    for(int i =0; i < descriptors_object.rows ; i++)
    {
        double dist = matches[i].distance;
        if( dist < min_dist ) min_dist = dist;
        if( dist > max_dist ) max_dist = dist;
    }
    
    printf("-- Max dist : %f \n", max_dist );
    printf("-- Min dist : %f \n", min_dist );
    
    //--Use only "good" matches (i.e. whose distance is less than 3 X min_dist )
    vector< DMatch > good_matches;
    
    for(int i =0 ; i < descriptors_object.rows ; i++)
    {
        if( matches[i].distance < 3*min_dist )
        {
            good_matches.push_back( matches[i] );
        }
    }
    vector< Point2f > obj;
    vector< Point2f > scene;
    
    for( int i = 0; i < good_matches.size(); i++)
    {
        //--Get the keypoints from the good matches
        obj.push_back( keypoints_object[good_matches[i].queryIdx].pt );
        scene.push_back( keypoints_scene[good_matches[i].trainIdx].pt );
    }
    
    //Find the Homography Matrix
    Mat H = findHomography( obj, scene, CV_RANSAC );
    
    // Use the homography Matrix to warp the images
    Mat result;
    
    //print();
    
    
    double heightAdd = abs(H.at<double>(0,5 ));
    double widthAdd = abs(H.at<double>(0,2 ));
    
    H.at<double>(0,2 ) = 0;
    
    print(H);
    
    warpPerspective( matFloatingImage, result, H, cv::Size( matFloatingImage.cols + widthAdd, matFloatingImage.rows + heightAdd    ) );
    Mat half(result, cv::Rect(widthAdd, 0, matReferenceImage.cols, matReferenceImage.rows) );
    matReferenceImage.copyTo(half);


    
    

    UIImage *returnImage = UIImageFromCVMat( result );
    storedImage = result;
    
    return returnImage;
}



//// vector with all non-black point positions
//vector<cv::Point> nonBlackList;
//nonBlackList.reserve(result.rows*result.cols);
//
//// add all non-black points to the vector
//// there are more efficient ways to iterate through the image
//for(int j=0; j<result.rows; ++j)
//for(int i=0; i<result.cols; ++i)
//{
//    // if not black: add to the list
//    if(result.at<Vec3b>(j,i) != Vec3b(0,0,0))
//    {
//        nonBlackList.push_back(cv::Point(i,j));
//    }
//}
//
//// create bounding rect around those points
////cv::Rect bb = boundingRect(nonBlackList);
//
////    // display result and save it
////    cv::imshow("Reult", result(bb));
////    cv::imwrite("./Result.jpg", result(bb));
////
////    //imshow( "Result", result );
////    //imwrite( "./Result.jpg", result );
////
////
////    cv::waitKey(0);




@end







