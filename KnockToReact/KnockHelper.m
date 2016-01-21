//
//  KnockHelper.m
//  KnockToReact
//
//  Created by Matheus Cavalca on 10/26/15.
//  Copyright © 2015 Matheus Cavalca. All rights reserved.
//

#import "KnockHelper.h"


@implementation KnockHelper

#pragma mark - LimitDifference handlers
@synthesize limitDifference;

- (void)initializeLimitDifference:(double)limit{
    if(![[NSUserDefaults standardUserDefaults] objectForKey:@"limitDifference"]){
        [self setLimitDifference:2.5];
    }
    else{
        double limit = [[[NSUserDefaults standardUserDefaults] objectForKey:@"limitDifference"] doubleValue];
        limitDifference = limit;
    }
}
- (void)setLimitDifference:(double)limit
{
    limitDifference = limit;
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithDouble: limit] forKey:@"limitDifference"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (double)limitDifference{
    if(limitDifference < 1){
        return 1;
    }
    else{
        return limitDifference;
    }
}

- (void)incrementLimitDifference:(double)incrementValue{
    [self setLimitDifference:[self limitDifference] + incrementValue];
}

- (void)decrementLimitDifference:(double)incrementValue{
    [self setLimitDifference:[self limitDifference] - incrementValue];
}

#pragma mark - High-Pass-Filter methods
- (void)initializeHighPassFilter:(double)x :(double)y{
    self.thresholdX = x;
    self.thresholdY = y;
}

#pragma mark - Singleton Methods

+(KnockHelper *) sharedInstance
{
    static KnockHelper *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc]init];
        
    });
    return instance;
}

- (id)init {
    self = [super init];
    if(self != nil) {
        [self initializeLimitDifference:2.5];
        [self initializeHighPassFilter:5.0 :5.0];
    }
    return self;
}

#pragma mark - Motion Methods

- (void)startMotion{
    self.motionManager = [[CMMotionManager alloc] init];
    NSTimeInterval updateFrequency = 40; // 0.025 -> 40 Hz(40 times a second)
    self.motionManager.accelerometerUpdateInterval = 1.0/updateFrequency;// 40 Hz - 40 times a second
    
    // Initialize High-Pass-Filter
    
    [self startBackgroundInteractionWithMotion];
}

- (void)stopMotion{
    [[UIApplication sharedApplication] endBackgroundTask:self.backgroundAccelerometerTask];
    [self.motionManager stopAccelerometerUpdates];
}

- (void)startBackgroundInteractionWithMotion{
    UIApplication *application = [UIApplication sharedApplication];
    
    self.backgroundAccelerometerTask = [application beginBackgroundTaskWithExpirationHandler:^{
    }];
    
    [self.motionManager startDeviceMotionUpdatesToQueue:[[NSOperationQueue alloc] init]
                                             withHandler:^(CMDeviceMotion *data, NSError *error) {
         dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
             [self methodToBackgroundInteraction:data];
         });
     }];
}

- (void)methodToBackgroundInteraction : (CMDeviceMotion*)data{
    NSTimeInterval seconds = [NSDate timeIntervalSinceReferenceDate];
    double milliseconds = seconds*1000;
    
    // For High-Pass-Filter
    self.prevXVal = self.currentXVal;
    self.currentXVal = data.userAcceleration.x; // X-axis
    self.diffX = self.currentXVal - self.prevXVal;
    
    self.prevYVal = self.currentYVal;
    self.currentYVal = data.userAcceleration.y; // Y-axis
    self.diffY = self.currentYVal - self.prevYVal;
    
    self.prevZVal = self.currentZVal;
    self.currentZVal = data.userAcceleration.z; // Z-axis
    self.diffZ = self.currentZVal - self.prevZVal;
    
    
    //pause between two attempts to give 3 knocks
    //if(milliseconds - self.lastPush > 5000){
    //double diferenceZ = data.userAcceleration.z - self.lastCapturedData.acceleration.z;
    //self.lastCapturedData = [data userAcceleration];
    //NSLog(@"%f", diferenceZ);
    
    double limitDiference = [self limitDifference];
    // Eliminating the other forces(X and Y) below some limit to filter out shaking motions
    if((self.diffX < self.thresholdX && self.diffY < self.thresholdY) &&
       (self.diffZ > limitDiference || self.diffZ < -limitDiference)){
        //NSLog(@"Z: %f",diferenceZ);
        double totalAcceleration = sqrt(pow(data.userAcceleration.x, 2) + pow(data.userAcceleration.y, 2) + pow(data.userAcceleration.z, 2));
        if(milliseconds - self.mlsFirst < 2000 && milliseconds - self.mlsFirst > 300){
            if(milliseconds - self.mlsSecond < 1000 && milliseconds - self.mlsSecond > 300){
                if(milliseconds - self.mlsThird > 300){
                    if(totalAcceleration > 4 && totalAcceleration < 5.5){
                        //self.lastPush = milliseconds;
                        self.mlsThird = milliseconds;
                        NSLog(@"Third knock: %f (operation succeded)",self.diffZ);
                        [self.delegate knockPerformed:3 :self.currentZVal :totalAcceleration];
                    }
                }
            }
            else if(milliseconds - self.mlsSecond > 300){
                if(totalAcceleration > 4 && totalAcceleration < 5.5){
                    NSLog(@"Second knock: %f",self.diffZ);
                    self.mlsSecond = milliseconds;
                    [self.delegate knockPerformed:2 :self.currentZVal :totalAcceleration];
                }
            }
        }
        else if(milliseconds - self.mlsFirst > 300){
            if(totalAcceleration > 4 && totalAcceleration < 5.5){
                self.mlsFirst = milliseconds;
                NSLog(@"First knock: %f",self.diffZ);
                [self.delegate knockPerformed:1 :self.currentZVal :totalAcceleration];
            }
        }
    }
    //}
}

@end
