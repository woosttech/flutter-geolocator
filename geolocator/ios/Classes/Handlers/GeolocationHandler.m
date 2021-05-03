//
//  LocationManager.m
//  geolocator
//
//  Created by Maurits van Beusekom on 20/06/2020.
//

#import "GeolocationHandler.h"
#import "PermissionHandler.h"
#import "../Constants/ErrorCodes.h"

@interface GeolocationHandler() <CLLocationManagerDelegate>

@property (strong, nonatomic) CLLocationManager *locationManager;
@property (strong, nonatomic) GeolocatorError errorHandler;
@property (strong, nonatomic) GeolocatorResult resultHandler;

@end

@implementation GeolocationHandler

- (CLLocation *)getLastKnownPosition {
    return [self.locationManager location];
}

- (void)startListeningWithDesiredAccuracy:(CLLocationAccuracy)desiredAccuracy
                           distanceFilter:(CLLocationDistance)distanceFilter
                            resultHandler:(GeolocatorResult _Nonnull )resultHandler
                             errorHandler:(GeolocatorError _Nonnull)errorHandler {
    
    self.errorHandler = errorHandler;
    self.resultHandler = resultHandler;
    
    CLLocationManager *locationManager = self.locationManager;
    locationManager.desiredAccuracy = desiredAccuracy;
    locationManager.distanceFilter = distanceFilter == 0 ? kCLDistanceFilterNone : distanceFilter;
    if (@available(iOS 9.0, *)) {
        locationManager.allowsBackgroundLocationUpdates = [GeolocationHandler shouldEnableBackgroundLocationUpdates];
    }
    
    [locationManager startUpdatingLocation];
}

- (void)startListeningForSignificantChangesWithResultHandler:(GeolocatorResult _Nonnull)resultHandler
                                                errorHandler:(GeolocatorError _Nonnull)errorHandler {
    
    if (![CLLocationManager significantLocationChangeMonitoringAvailable]) {
        // The device does not support this service.
        self.errorHandler(GeolocatorErrorSignificantChangesNotAvailable, @"Significant location changes are not available on this device.");
        return;
    }
    
    self.errorHandler = errorHandler;
    self.resultHandler = resultHandler;
    
    CLLocationManager *locationManager = self.locationManager;
    [locationManager startMonitoringSignificantLocationChanges];
}

- (void)stopListening {
    [self.locationManager stopUpdatingLocation];
    [self.locationManager stopMonitoringSignificantLocationChanges];
    
    self.errorHandler = nil;
    self.resultHandler = nil;
}

- (BOOL)isBackgroundUpdatesEnabled {
    if (@available(iOS 9.0, *)) {
        return self.locationManager.allowsBackgroundLocationUpdates;
    } else {
        return NO;
    }
}

- (void)setBackgroundUpdates:(BOOL)wantsBackgroundUpdates {
    if (@available(iOS 9.0, *)) {
        self.locationManager.allowsBackgroundLocationUpdates = wantsBackgroundUpdates;
    }
    if (@available(iOS 11.0, *)) {
        self.locationManager.showsBackgroundLocationIndicator = wantsBackgroundUpdates;
    }
}

- (CLLocationManager *) locationManager {
    if (!_locationManager) {
        _locationManager = [[CLLocationManager alloc] init];
        _locationManager.delegate = self;
    }
    return _locationManager;
}

- (void)locationManager:(CLLocationManager *)manager
     didUpdateLocations:(NSArray<CLLocation *> *)locations {
    if (!self.resultHandler) return;
    
    if ([locations lastObject]) {
        self.resultHandler([locations lastObject]);
    }
}

- (void)locationManager:(CLLocationManager *)manager
       didFailWithError:(nonnull NSError *)error {
    NSLog(@"LOCATION UPDATE FAILURE:"
          "Error reason: %@"
          "Error description: %@", error.localizedFailureReason, error.localizedDescription);
    
    if([error.domain isEqualToString:kCLErrorDomain] && error.code == kCLErrorLocationUnknown) {
        return;
    }
    
    [self stopListening];
    
    if (self.errorHandler) {
        self.errorHandler(GeolocatorErrorLocationUpdateFailure, error.localizedDescription);
    }
}

+ (BOOL) shouldEnableBackgroundLocationUpdates {
    if (@available(iOS 9.0, *)) {
        return [[NSBundle.mainBundle objectForInfoDictionaryKey:@"UIBackgroundModes"] containsObject: @"location"];
    } else {
        return NO;
    }
}
@end
