//
//  OpenCVWrapper.h
//  OpenCVTest
//
//  Created by Andre on 8/15/18.
//  Copyright © 2018 3DRobotics. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@protocol MainViewDelegate <NSObject>

- (void)foundHomography;

@end

@interface OpenCVImageAlignment : NSObject

    -(id) init;
    -(UIImage *) getImage;
    -(UIImage *) findHomographyOfReferenceImage: (UIImage *)referenceImage andFloatingImage: (UIImage *)floatingImage;


@end
