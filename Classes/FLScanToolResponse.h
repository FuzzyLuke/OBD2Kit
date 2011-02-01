/*
 *  FLScanToolResponse.h
 *  OBD2Kit
 *
 *  Copyright (c) 2009-2011 FuzzyLuke Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 * 
 * http://www.apache.org/licenses/LICENSE-2.0
 * 
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *
 */

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

typedef struct pid_support_map_t {

	// DATA A
	unsigned int		pid07 : 1;
	unsigned int		pid06 : 1;
	unsigned int		pid05 : 1;
	unsigned int		pid04 : 1;
	unsigned int		pid03 : 1;
	unsigned int		pid02 : 1;
	unsigned int		pid01 : 1;
	unsigned int		pid00 : 1;	
	
	// DATA B
	unsigned int		pid0F : 1;
	unsigned int		pid0E : 1;
	unsigned int		pid0D : 1;
	unsigned int		pid0C : 1;
	unsigned int		pid0B : 1;
	unsigned int		pid0A : 1;
	unsigned int		pid09 : 1;
	unsigned int		pid08 : 1;
	
	// DATA C
	unsigned int		pid17 : 1;
	unsigned int		pid16 : 1;
	unsigned int		pid15 : 1;
	unsigned int		pid14 : 1;
	unsigned int		pid13 : 1;
	unsigned int		pid12 : 1;
	unsigned int		pid11 : 1;
	unsigned int		pid10 : 1;
	
	// DATA D
	unsigned int		pid1F : 1;
	unsigned int		pid1E : 1;
	unsigned int		pid1D : 1;
	unsigned int		pid1C : 1;
	unsigned int		pid1B : 1;
	unsigned int		pid1A : 1;
	unsigned int		pid19 : 1;
	unsigned int		pid18 : 1;

} SupportedPIDMap;


#define MORE_PIDS_SUPPORTED(data)					((data[3] & 1) != 0)
//#define MORE_PIDS_SUPPORTED(pSupportMap)			(pSupportMap->pid1F != 0)


@interface FLScanToolResponse : NSObject<NSCoding> {
	
	NSString*				_scanToolName;
	NSInteger				_protocol;
	
	NSData*					_responseData;
	NSString*				_responseString;
	
	BOOL					_isError;
	
	NSDate*					_timestamp;
	NSUInteger				_priority;
	NSUInteger				_targetAddress;
	NSUInteger				_ecuAddress;
	NSData*					_data;
	NSUInteger				_mode;
	NSUInteger				_pid;
	NSUInteger				_crc;	

	double					_latitude;
	double					_longitude;
	double					_altitude;
	double					_locationHorizontalAccuracy;
	double					_locationVerticalAccuracy;
	double					_gpsSpeed;
}

@property (nonatomic, retain) NSString* scanToolName;
@property (nonatomic, assign) NSInteger protocol;
@property (nonatomic, retain) NSData* rawData;
@property (nonatomic, retain) NSString* responseString;
@property (nonatomic, getter=isError) BOOL error;
@property (nonatomic, retain, readonly) NSDate* timestamp;
@property (nonatomic, assign) NSUInteger priority;
@property (nonatomic, assign) NSUInteger targetAddress;
@property (nonatomic, assign) NSUInteger ecuAddress;
@property (nonatomic, assign) NSUInteger mode;
@property (nonatomic, assign) NSUInteger pid;
@property (nonatomic, assign) NSUInteger crc;
@property (nonatomic, retain) NSData* data;
@property (nonatomic, assign) double latitude;
@property (nonatomic, assign) double longitude;
@property (nonatomic, assign) double altitude;
@property (nonatomic, assign) double horizontalAccuracy;
@property (nonatomic, assign) double verticalAccuracy;
@property (nonatomic, assign) double gpsSpeed;


- (void) updateLocation:(CLLocation*)location;
- (id) proxyForJson;

@end
