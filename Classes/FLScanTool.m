/*
 *  FLScanTool.m
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

#import <CoreFoundation/CoreFoundation.h>

#import "FLScanTool.h"
#import "FLLogging.h"
#import "ELM327.h"
#import "GoLink.h"
#import "FLSimScanTool.h"

@interface FLScanTool (Private)
- (unsigned char) nextSensor;
- (FLScanToolCommand*) commandForNextSensor;
@end


#pragma mark -
@implementation FLScanTool

@synthesize supportedSensors	= _supportedSensorList, 
			delegate			= _delegate,
			scanToolState		= _state,
			scanToolProtocol	= _protocol,
			scanToolDeviceType	= _deviceType,
			host				= _host,
			port				= _port,
			useLocation			= _useLocation;


+ (FLScanTool*) scanToolForDeviceType:(FLScanToolDeviceType) deviceType {
	
	FLScanTool* scanTool = nil;
	
	switch (deviceType) {
		case kScanToolDeviceTypeBluTrax:
			break;
		case kScanToolDeviceTypeELM327:
			scanTool = [[ELM327 alloc] init];
			break;
		case kScanToolDeviceTypeGoLink:
			scanTool = [[GoLink alloc] init];
			break;
		case kScanToolDeviceTypeSimulated:
			scanTool = [[FLSimScanTool alloc] init];
		default:
			break;
	}
	
	return [scanTool autorelease];
}

+ (NSString*) stringForProtocol:(FLScanToolProtocol)protocol {
	NSString* protocolString	= nil;
	
	switch (protocol) {		
			
		case kScanToolProtocolISO9141Keywords0808:
			protocolString		= NSLocalizedString(@"ISO 9141-2 Keywords 0808", @"ISO 9141-2 Keywords 0808");
			break;
			
		case kScanToolProtocolISO9141Keywords9494:
			protocolString		= NSLocalizedString(@"ISO 9141-2 Keywords 9494", @"ISO 9141-2 Keywords 9494");
			break;
			
		case kScanToolProtocolKWP2000FastInit:
			protocolString		= NSLocalizedString(@"KWP2000 Fast Init", @"KWP2000 Fast Init");
			break;
			
		case kScanToolProtocolKWP2000SlowInit:
			protocolString		= NSLocalizedString(@"KWP2000 Slow Init", @"KWP2000 Slow Init");
			break;
			
		case kScanToolProtocolJ1850PWM:
			protocolString		= NSLocalizedString(@"J1850 PWM", @"J1850 PWM");
			break;
			
		case kScanToolProtocolJ1850VPW:
			protocolString		= NSLocalizedString(@"J1850 VPW", @"J1850 VPW");
			break;
			
		case kScanToolProtocolCAN11bit250KB:
			protocolString		= NSLocalizedString(@"CAN 11-Bit 250Kbps", @"CAN 11-Bit 250Kbps");
			break;
			
		case kScanToolProtocolCAN11bit500KB:
			protocolString		= NSLocalizedString(@"CAN 11-Bit 500Kbps", @"CAN 11-Bit 500Kbps");
			break;
			
		case kScanToolProtocolCAN29bit250KB:
			protocolString		= NSLocalizedString(@"CAN 29-Bit 250Kbps", @"CAN 29-Bit 250Kbps");
			break;
			
		case kScanToolProtocolCAN29bit500KB:
			protocolString		= NSLocalizedString(@"CAN 29-Bit 500Kbps", @"CAN 29-Bit 500Kbps");
			break;			
		
		case kScanToolProtocolNone:
		default:
			protocolString		= NSLocalizedString(@"Unknown Protocol", @"Unknown Protocol");
			break;
	}
	
	return protocolString;
}


- (void) dealloc {
	
	[self close];
	
	[_priorityCommandQueue release];
	[_commandQueue release];
	[_supportedSensorList release];
	[_sensorScanTargets release];	
	[_locationManager release];
	[_scanOperationQueue release];
	[_streamOperation release];
	[super dealloc];
}


- (NSString*) scanToolName {
	[self doesNotRecognizeSelector:@selector(scanToolName)];
	return nil;
}

- (BOOL) isWifiScanTool {
	return ([self isKindOfClass:[FLWifiScanTool class]]);
}

- (BOOL) isEAScanTool {	
	return ([self isKindOfClass:[FLEAScanTool class]]);
}

- (void) open {	
	// Abstract method
	[self doesNotRecognizeSelector:_cmd];
}

- (void) close {
	// Abstract method
	[self doesNotRecognizeSelector:_cmd];
}


- (NSArray*) sensorScanTargets {
	return _sensorScanTargets;
}

- (void) setSensorScanTargets:(NSArray *)targets {
	[_sensorScanTargets release];	
	_sensorScanTargets	= [[NSArray arrayWithArray:targets] retain];
	
	if (![self isKindOfClass:[GoLink class]] && targets != nil) {
		// The GoLink (GL1) has a heartbeat, so doesn't need an extra push
		// to start scanning once targets have changed
		
		[self sendCommand:[self dequeueCommand] initCommand:NO];
		[self writeCachedData];
	}
}

- (BOOL) scanning {
	
	if(!_streamOperation) {
		return NO;
	}
	else {
		return !(_streamOperation.isCancelled);
	}
}


- (CLLocation*) currentLocation {
	if(_locationManager && _locationManager.locationServicesEnabled) {
		
		// Check the timestamp to make sure it's current enough
		CLLocation* lastKnownLocation = [_locationManager location];
		if(lastKnownLocation) {
			NSTimeInterval decay	= [[NSDate date] timeIntervalSinceDate:lastKnownLocation.timestamp];
			if(decay > LOCATION_DECAY_PERIOD) {
				[_locationManager stopUpdatingLocation];
				[_locationManager startUpdatingLocation];
			}

			return lastKnownLocation;
		}
	}
	
	return nil;
}

- (void) enqueueCommand:(FLScanToolCommand*)command {
	[_priorityCommandQueue addObject:command];
}


- (void) sendCommand:(FLScanToolCommand*)command initCommand:(BOOL)initCommand {
	// Abstract method
	[self doesNotRecognizeSelector:_cmd];
}

- (void) clearCommandQueue {
	[_priorityCommandQueue removeAllObjects];
}

- (void) getResponse {
	// Abstract method
	[self doesNotRecognizeSelector:_cmd];
}


- (FLScanToolCommand*) dequeueCommand {
	FLScanToolCommand* cmd = nil;
	
	if([_priorityCommandQueue count] > 0) {
		cmd = (FLScanToolCommand*)[_priorityCommandQueue objectAtIndex:0];
		[cmd retain];
		[_priorityCommandQueue removeObjectAtIndex:0];
	}
	else if(_sensorScanTargets && [_sensorScanTargets count] > 0) {
		cmd = [self commandForNextSensor];
		[cmd retain];
	}
	
	return [cmd autorelease];
}


#pragma mark -
#pragma mark Sensor Support Methods

- (BOOL) buildSupportedSensorList:(NSData*)data forPidGroup:(NSUInteger)pidGroup {
	
	uint8_t* bytes		= (uint8_t*)[data bytes];
	uint32_t bytesLen	= [data length];
	
	if(bytesLen != 4) {
		return NO;
	}
	
	if(!_supportedSensorList) {
		_supportedSensorList = [[NSMutableArray alloc] initWithCapacity:16];
	}
	
/*	if(pidGroup == 0x00) {
		// If we are re-issuing the PID search command, reset any
		// previously received PIDs		
		[_supportedSensorList removeAllObjects];
		[_sensorScanTargets release];
		_sensorScanTargets = nil;
		FLDEBUG(@"Resetting sensor list: %d", [_supportedSensorList count])
	}
*/	
	
	int pid				= pidGroup + 1;
	BOOL supported		= NO;
	
	for (int i=0; i < 4; i++)
	{
		for (int leftShift=7; leftShift >= 0; leftShift--, pid++)
		{
			supported   = (((1 << leftShift) & bytes[i]) != 0);
			
			if(supported) {
				NSNumber* pidNum = [NSNumber numberWithInt:pid];
				if(NOT_SEARCH_PID(pid) && pid <= 0x4E && ![_supportedSensorList containsObject:pidNum]) {
					[_supportedSensorList addObject:pidNum];
				}			
			}
		}
	}
	
	FLDEBUG(@"Supported Sensors: %@", [_supportedSensorList description])
	FLDEBUG(@"More PIDs: %d", MORE_PIDS_SUPPORTED(bytes))
	
	return MORE_PIDS_SUPPORTED(bytes);
}

- (BOOL) isService01PIDSupported:(NSUInteger)pid {
	
	BOOL supported = NO;
	
	for (NSNumber* supportedPID in _supportedSensorList) {
		if ([supportedPID unsignedIntegerValue] == pid) {
			supported = YES;
			break;
		}
	}
	
	return supported;
}


- (unsigned char) nextSensor {
	if(!_sensorScanTargets) {
		return 0xFF;
	}
	else {
		NSNumber* number = [_sensorScanTargets objectAtIndex:_currentSensorIndex];
		_currentSensorIndex++;		
		
		if(number) {
			return [number unsignedCharValue];
		}
		else {
			return 0xFF;
		}
	}
}



- (FLScanToolCommand*) commandForNextSensor {
	
	if(!_sensorScanTargets) {
		return nil;
	}
	
	if(_currentSensorIndex >= [_sensorScanTargets count]) {
		_currentSensorIndex		= 0;		
		
		// Put a pending DTC request in the priority queue, to be executed
		// after the battery voltage reading
		//[self getPendingTroubleCodes];
		
		if ([self isKindOfClass:[ELM327 class]]) {
			_waitingForVoltageCommand= YES;
			return [self commandForGetBatteryVoltage];
		}		
	}
	
	unsigned char next = [self nextSensor];
	
	if(next <= 0x4E) {
		return [self commandForGenericOBD:kScanToolModeRequestCurrentPowertrainDiagnosticData 
									  pid:next 
									 data:nil];
	}
	else {
		return nil;
	}
}


- (void) dispatchDelegate:(SEL)selector withObject:(id)obj {
	if(_delegate && [_delegate respondsToSelector:selector]) {
		
		// The NSObject cast below removes warning about unrecognized selector
		// for methodSignatureForSelector, since our delegate is of type 'id'
		NSMethodSignature* signature = [(NSObject*)_delegate methodSignatureForSelector:selector];
		
		if(signature) {
			NSInvocation* invocation = [NSInvocation invocationWithMethodSignature:signature];
			
			[invocation setTarget:_delegate];
			[invocation setSelector:selector];
			[invocation setArgument:&self atIndex:2];
			if(obj) {
				[invocation setArgument:&obj atIndex:3];
			}
			
			[invocation retainArguments];
			
			[invocation performSelectorOnMainThread:@selector(invoke) withObject:nil waitUntilDone:NO];
		}	
	}
}

#pragma mark -
#pragma mark Scanning Operation


- (void) initScanTool {
	// Abstract method
	[self doesNotRecognizeSelector:_cmd];
}


- (void) startScan {
	
	[_priorityCommandQueue release];
	[_commandQueue release];
	
	_priorityCommandQueue	= [[NSMutableArray alloc] initWithCapacity:1];
	_commandQueue			= [[NSMutableArray alloc] initWithCapacity:16];
	_state					= STATE_INIT;
	
	[_supportedSensorList removeAllObjects];
	if (_sensorScanTargets) {
		[_sensorScanTargets release];
		_sensorScanTargets = nil;
	}
	
	if(!_locationManager) {
		_locationManager	= [[CLLocationManager alloc] init];
	}
	
	
	if(_locationManager.locationServicesEnabled) {
		_locationManager.desiredAccuracy	= kCLLocationAccuracyBest;
		_locationManager.delegate			= self;
		[_locationManager startUpdatingLocation];
	}	
	
	
	[_scanOperationQueue release];
	
	_streamOperation		= [[NSInvocationOperation alloc] initWithTarget:self 
															 selector:@selector(runStreams) 
															   object:nil];

	_scanOperationQueue		= [[NSOperationQueue alloc] init];
	[_scanOperationQueue addOperation:_streamOperation];
	[_scanOperationQueue setSuspended:NO];
}


- (void) pauseScan {
	FLTRACE_ENTRY
	[_scanOperationQueue setSuspended:YES];
}


- (void) resumeScanFromPause {
	FLTRACE_ENTRY
	[_scanOperationQueue setSuspended:NO];
}


- (void) cancelScan {
	FLINFO("ATTEMPTING SCAN CANCELLATION")
	[_scanOperationQueue cancelAllOperations];	
	[_streamOperation cancel];
	if(_locationManager && _locationManager.locationServicesEnabled) {
		[_locationManager stopUpdatingLocation];
		_locationManager.delegate	= nil;
	}
	
	[_supportedSensorList removeAllObjects];
	
	FLDEBUG(@"_streamOperation.isCancelled = %d", _streamOperation.isCancelled)
}


- (void)updateSafetyCheckState {
	[self doesNotRecognizeSelector:_cmd];
}


- (void) runStreams {
	NSAutoreleasePool * pool	= [[NSAutoreleasePool alloc] init];
	NSRunLoop* currentRunLoop	= [NSRunLoop currentRunLoop];
	NSDate* distantFutureDate	= [NSDate distantFuture];
	
	@try {
		[self open];
		
		[self dispatchDelegate:@selector(scanDidStart:) withObject:nil];	
		[self initScanTool];
		
		if ([self isEAScanTool]) {
			while (!_streamOperation.isCancelled && [currentRunLoop runMode:NSDefaultRunLoopMode beforeDate:distantFutureDate]) {
				;;
			}
		}
		else if([self isWifiScanTool]) {
			while (!_streamOperation.isCancelled && [currentRunLoop runMode:NSDefaultRunLoopMode beforeDate:distantFutureDate]) {
				;;
			}
		}
		
		
		FLINFO(@"*** STREAMS CANCELLED ***")
	}
	@catch (NSException * e) {
		FLEXCEPTION(e)
	}
	@finally {
		[pool release];
		[self close];
		[self dispatchDelegate:@selector(scanDidCancel:) withObject:nil];
	}	
}


- (void) getTroubleCodes {

	if(!_priorityCommandQueue) {
		_priorityCommandQueue = [NSMutableArray arrayWithCapacity:8];
		[_priorityCommandQueue retain];
	}
	
	[self enqueueCommand:[self commandForGenericOBD:kScanToolModeRequestEmissionRelatedDiagnosticTroubleCodes 
												pid:-1 
											   data:nil]];
}


- (void) getPendingTroubleCodes {
	if(!_priorityCommandQueue) {
		_priorityCommandQueue = [NSMutableArray arrayWithCapacity:8];
		[_priorityCommandQueue retain];
	}
	
	[self enqueueCommand:[self commandForGenericOBD:kScanToolModeRequestEmissionRelatedDiagnosticTroubleCodesDetected
												pid:-1 
											   data:nil]];
}


- (void) clearTroubleCodes {
	if(!_priorityCommandQueue) {
		_priorityCommandQueue = [NSMutableArray arrayWithCapacity:8];
		[_priorityCommandQueue retain];
	}
	
	[self enqueueCommand:[self commandForGenericOBD:kScanToolModeClearResetEmissionRelatedDiagnosticInfo 
												pid:-1 
											   data:nil]];
	
	//send Mode 0x01 Pid 0x01 cmd after clear to update sensor trouble code count
	[self enqueueCommand:[self commandForGenericOBD:kScanToolModeRequestCurrentPowertrainDiagnosticData 
												pid:0x01
											   data:nil]];
}

- (void) getBatteryVoltage {
	if(!_priorityCommandQueue) {
		_priorityCommandQueue = [NSMutableArray arrayWithCapacity:8];
		[_priorityCommandQueue retain];
	}
	
	[self enqueueCommand:[self commandForGetBatteryVoltage]];
}

- (void) writeCachedData {
	// Abstract method
	[self doesNotRecognizeSelector:_cmd];
}

#pragma mark -
#pragma mark ScanToolCommand Generators

- (FLScanToolCommand*) commandForPing {
	// Abstract method
	[self doesNotRecognizeSelector:_cmd];
	return nil;
}


- (FLScanToolCommand*) commandForGenericOBD:(FLScanToolMode)mode pid:(unsigned char)pid data:(NSData*)data {
	// Abstract method
	[self doesNotRecognizeSelector:_cmd];
	return nil;
}

- (FLScanToolCommand*) commandForReadSerialNumber {
	// Abstract method
	[self doesNotRecognizeSelector:_cmd];
	return nil;
}

- (FLScanToolCommand*) commandForReadVersionNumber {
	// Abstract method
	[self doesNotRecognizeSelector:_cmd];
	return nil;
}


- (FLScanToolCommand*) commandForReadProtocol {
	// Abstract method
	[self doesNotRecognizeSelector:_cmd];
	return nil;
}


- (FLScanToolCommand*) commandForReadChipID {
	// Abstract method
	[self doesNotRecognizeSelector:_cmd];
	return nil;
}


- (FLScanToolCommand*) commandForSetAutoSearchMode {
	// Abstract method
	[self doesNotRecognizeSelector:_cmd];
	return nil;
}

- (FLScanToolCommand*) commandForSetSerialNumber {
	// Abstract method
	[self doesNotRecognizeSelector:_cmd];
	return nil;
}

- (FLScanToolCommand*) commandForTestForMultipleECUs {
	// Abstract method
	[self doesNotRecognizeSelector:_cmd];
	return nil;
}

- (FLScanToolCommand*) commandForStartProtocolSearch {
	// Abstract method
	[self doesNotRecognizeSelector:_cmd];
	return nil;
}

- (FLScanToolCommand*) commandForGetBatteryVoltage {
	// Abstract method
	[self doesNotRecognizeSelector:_cmd];
	return nil;
}


#pragma mark -
#pragma mark NSStream Event Handling Methods

- (void)stream:(NSStream*)stream handleEvent:(NSStreamEvent)eventCode {
	
	// Abstract method
	[self doesNotRecognizeSelector:_cmd];
}


#pragma mark -
#pragma mark CLLocationManagerDelegate Methods

- (void)locationManager:(CLLocationManager *)manager 
	   didFailWithError:(NSError *)error {
	
	FLNSERROR(error)	
}

- (void)locationManager:(CLLocationManager *)manager 
	didUpdateToLocation:(CLLocation *)newLocation 
		   fromLocation:(CLLocation *)oldLocation {
	
	FLTRACE_ENTRY	
	FLDEBUG(@"Updated to %@ from %@", [newLocation description], [oldLocation description])
}
@end
