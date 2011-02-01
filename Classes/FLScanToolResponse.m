/*
 *  FLScanToolResponse.m
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

#import "FLScanToolResponse.h"
#import "Base64Extensions.h"


@implementation FLScanToolResponse

@synthesize scanToolName		= _scanToolName,
			protocol			= _protocol,
			timestamp			= _timestamp,
			priority			= _priority,
			targetAddress		= _targetAddress,
			ecuAddress			= _ecuAddress,
			pid					= _pid,
			crc					= _crc,
			responseString		= _responseString,
			latitude			= _latitude,
			longitude			= _longitude,
			altitude			= _altitude,
			horizontalAccuracy	= _locationHorizontalAccuracy,
			verticalAccuracy	= _locationVerticalAccuracy,
			gpsSpeed			= _gpsSpeed;


- (id) init {
	if(self = [super init]) {
		
		_timestamp					= [[NSDate date] retain];
		
		_scanToolName				= nil;
		_protocol					= 0;
		_priority					= 0;
		_targetAddress				= 0;
		_ecuAddress					= 0;
		_pid						= 0;
		_crc						= 0;
		_mode						= 0;
		
		// These may be empty on occasion due to user disabling GPS
		_latitude					= -1;
		_longitude					= -1;
		_altitude					= -1;
		_locationVerticalAccuracy	= -1;
		_locationHorizontalAccuracy	= -1;
		_gpsSpeed					= -1;
	}
	
	return self;
}


- (NSData*) rawData {
	return _responseData;
}

- (void) setRawData:(NSData*)data {
	[_responseData release];
	_responseData = [data retain];
}

- (BOOL) isError {
	return _isError;
}

- (void) setError:(BOOL)error {
	_isError = error;
}

- (NSData*) data {
	return _data;
}

- (void) setData:(NSData*)newData {
	[_data release];
	_data = [newData retain];
}

- (NSUInteger) mode {
	return _mode;
}

- (void) setMode:(NSUInteger)mode {
	_mode = (mode ^ 0x40);
}


- (void) dealloc {
	[_data release];
	[_responseData release];
	[_timestamp release];
	[_scanToolName release];
	[super dealloc];
}

- (void) updateLocation:(CLLocation*)location {
	
	if(location) {
		self.gpsSpeed			= location.speed;
		self.latitude			= location.coordinate.latitude;
		self.longitude			= location.coordinate.longitude;
		self.altitude			= location.altitude;
		self.horizontalAccuracy	= location.horizontalAccuracy;
		self.verticalAccuracy	= location.verticalAccuracy;
	}	
}

#pragma mark -
#pragma mark NSCoding Methods

- (void)encodeWithCoder:(NSCoder *)encoder {
	[encoder encodeObject:_scanToolName forKey:@"ScanToolName"];
	[encoder encodeInt32:_protocol forKey:@"ScanToolProtocol"];
	[encoder encodeDataObject:_responseData];
	[encoder encodeObject:_responseString forKey:@"ResponseString"];
	[encoder encodeBool:_isError forKey:@"IsError"];
	[encoder encodeDouble:[_timestamp timeIntervalSince1970] forKey:@"Timestamp"];
	[encoder encodeInt32:_priority forKey:@"Priority"];
	[encoder encodeInt32:_targetAddress forKey:@"TargetAddress"];
	[encoder encodeInt32:_ecuAddress forKey:@"ECUAddress"];
	[encoder encodeInt32:_mode forKey:@"Mode"];
	[encoder encodeInt32:_pid forKey:@"PID"];
	[encoder encodeInt32:_crc forKey:@"CRC"];
	[encoder encodeDataObject:_data];
	[encoder encodeDouble:_latitude forKey:@"Latitude"];
	[encoder encodeDouble:_longitude forKey:@"Longitude"];
	[encoder encodeDouble:_altitude forKey:@"Altitude"];
	[encoder encodeDouble:_locationHorizontalAccuracy forKey:@"HorizontalAccuracy"];
	[encoder encodeDouble:_locationVerticalAccuracy forKey:@"VerticalAccuracy"];
	[encoder encodeDouble:_gpsSpeed forKey:@"GPSSpeed"];
}


- (id)initWithCoder:(NSCoder*)decoder {
	self.scanToolName			= [decoder decodeObjectForKey:@"ScanToolName"];
	self.protocol				= [decoder decodeIntForKey:@"ScanToolProtocol"];
	self.rawData				= [decoder decodeDataObject];
	self.responseString			= [decoder decodeObjectForKey:@"ResponseString"];
	self.error					= [decoder decodeBoolForKey:@"IsError"];
	_timestamp					= [[NSDate dateWithTimeIntervalSince1970:[decoder decodeDoubleForKey:@"Timestamp"]] retain];
	self.priority				= [decoder decodeInt32ForKey:@"Priority"];
	self.targetAddress			= [decoder decodeInt32ForKey:@"TargetAddress"];
	self.ecuAddress				= [decoder decodeInt32ForKey:@"ECUAddress"];	
	self.mode					= [decoder decodeInt32ForKey:@"Mode"];
	self.pid					= [decoder decodeInt32ForKey:@"PID"];
	self.crc					= [decoder decodeInt32ForKey:@"CRC"];
	self.data					= [decoder decodeDataObject];
	self.latitude				= [decoder decodeDoubleForKey:@"Latitude"];
	self.longitude				= [decoder decodeDoubleForKey:@"Longitude"];
	self.altitude				= [decoder decodeDoubleForKey:@"Altitude"];
	self.horizontalAccuracy		= [decoder decodeDoubleForKey:@"HorizontalAccuracy"];
	self.verticalAccuracy		= [decoder decodeDoubleForKey:@"VerticalAccuracy"];
	self.gpsSpeed				= [decoder decodeDoubleForKey:@"GPSSpeed"];
	
	return self;
}


#pragma mark -
#pragma mark SBJSON Proxy

// Returns an NSDictionary representing this object
- (id) proxyForJson {	
	NSDictionary* responseDict = [NSDictionary dictionaryWithObjectsAndKeys:
								  //@"value", @"key",
								  [NSString stringWithString:_scanToolName], @"scanTool",
								  [NSNumber numberWithUnsignedInt:_protocol], @"protocol",
								  [NSString base64StringFromData:_responseData length:0xFFFFFFFF], @"rawPacket",
								  [NSNumber numberWithDouble:[_timestamp timeIntervalSince1970]], @"timestamp",
								  [NSNumber numberWithUnsignedInteger:_priority], @"priority",
								  [NSNumber numberWithUnsignedInteger:_targetAddress], @"targetAddress",
								  [NSNumber numberWithUnsignedInteger:_ecuAddress], @"ecuAddress",
								  [NSNumber numberWithUnsignedInteger:_mode], @"service",
								  [NSNumber numberWithUnsignedInteger:_pid], @"pid",
								  [NSNumber numberWithUnsignedInteger:_crc], @"crc",
								  [NSString base64StringFromData:_data length:0xFFFFFFFF], @"data",
								  [NSNumber numberWithDouble:_latitude], @"latitude",
								  [NSNumber numberWithDouble:_longitude], @"longitude",
								  [NSNumber numberWithDouble:_altitude], @"altitude",
								  [NSNumber numberWithDouble:_locationHorizontalAccuracy], @"horizontalAccuracy",
								  [NSNumber numberWithDouble:_locationVerticalAccuracy], @"verticalAccuracy",
								  [NSNumber numberWithDouble:_gpsSpeed], @"gpsSpeed",
								  nil];	
	
	return responseDict;
}

@end
