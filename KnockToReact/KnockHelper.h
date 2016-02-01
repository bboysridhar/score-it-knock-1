//
//  KnockHelper.h
//  KnockToReact
//
//  Created by Matheus Cavalca on 10/26/15.
//  Copyright © 2015 Matheus Cavalca. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CoreMotion/CoreMotion.h"
#import <CoreLocation/CoreLocation.h>
#import <UIKit/UIKit.h>

@protocol KnockHelperProtocol <NSObject>

- (void)knockPerformed:(double)knockCount z:(double)z totalAcceleration:(double)totalAcceleration pTotalAcceleration:(double)pTotalAcceleration;

@end

@interface KnockHelper : NSObject <UIAccelerometerDelegate>

@property (nonatomic) double limitDifference;
@property(nonatomic, weak) id<KnockHelperProtocol> delegate;
+(KnockHelper *) sharedInstance;

@property (nonatomic, strong) CMMotionManager *motionManager;

- (void)startMotion;
- (void)stopMotion;
- (void)incrementLimitDifference:(double)incrementValue;
- (void)decrementLimitDifference:(double)incrementValue;
@end
