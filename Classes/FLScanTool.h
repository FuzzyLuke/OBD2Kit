/*
 *  FLScanTool.h
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
#import "FLScanToolCommand.h"
#import "FLScanToolResponse.h"

typedef enum  {
	STATE_INIT		=0,
	STATE_IDLE,
	STATE_WAITING,
	STATE_PROCESSING,
	STATE_ERROR,
	
	NUM_STATES
} FLScanToolState;


typedef enum {
	kScanToolDeviceTypeBluTrax = 0,
	kScanToolDeviceTypeELM327,
	kScanToolDeviceTypeOBDKey,
	kScanToolDeviceTypeGoLink,
	kScanToolDeviceTypeSimulated,

	kNumScanToolDeviceTypes
} FLScanToolDeviceType;

typedef enum {
	kScanToolModeRequestCurrentPowertrainDiagnosticData = 1,
	kScanToolModeRequestPowertrainFreezeFrameData,
	kScanToolModeRequestEmissionRelatedDiagnosticTroubleCodes,
	kScanToolModeClearResetEmissionRelatedDiagnosticInfo,
	kScanToolModeRequestOxygenSensorMonitoringTestResults,
	kScanToolModeRequestOnboardMonitoringTestResultsForSMS,
	kScanToolModeRequestEmissionRelatedDiagnosticTroubleCodesDetected,
	kScanToolModeRequestControlOfOnboardSystemTestOrComponent,
	kScanToolModeRequestVehicleInfo
} FLScanToolMode;

typedef enum {
	kScanToolProtocolNone					= 0x0000,
	kScanToolProtocolISO9141Keywords0808	= 0x0001,
	kScanToolProtocolISO9141Keywords9494	= 0x0002,
	kScanToolProtocolKWP2000FastInit		= 0x0004,
	kScanToolProtocolKWP2000SlowInit		= 0x0008,
	kScanToolProtocolJ1850PWM				= 0x0010,
	kScanToolProtocolJ1850VPW				= 0x0020,
	kScanToolProtocolCAN11bit250KB			= 0x0040,
	kScanToolProtocolCAN11bit500KB			= 0x0080,
	kScanToolProtocolCAN29bit250KB			= 0x0100,
	kScanToolProtocolCAN29bit500KB			= 0x0200
} FLScanToolProtocol;


#define VOLTAGE_TIMEOUT		10.0f
#define INIT_TIMEOUT		10.0f
#define PENDING_DTC_TIMEOUT	10.0f


#define STATE_INIT()		(_state == STATE_INIT)
#define STATE_IDLE()		(_state == STATE_IDLE)
#define STATE_WAITING()		(_state == STATE_WAITING)
#define STATE_PROCESSING()	(_state == STATE_PROCESSING)
#define STATE_ERROR()		(_state == STATE_ERROR)


#define MODE_IN_RANGE(mode)	((mode ^ 0x40) >= kScanToolModeRequestCurrentPowertrainDiagnosticData && \
							 (mode ^ 0x40) <= kScanToolModeRequestVehicleInfo)


#define NOT_SEARCH_PID(pid) (pid != 0x00 && pid != 0x20 && \
							 pid != 0x40 && pid != 0x60 && \
							 pid != 0x80 && pid != 0xA0 && \
							 pid != 0xC0 && pid != 0xE0)


// The time, in seconds, after which a location is considered stale
#define LOCATION_DECAY_PERIOD				5.0f


@protocol FLScanToolDelegate;

@interface FLScanTool : NSObject <CLLocationManagerDelegate> {

	NSMutableArray*				_supportedSensorList;
	
	NSArray*					_sensorScanTargets;
	NSInteger					_currentSensorIndex;
	
	id<FLScanToolDelegate>		_delegate;
	NSOperation*				_streamOperation;
	NSOperationQueue*			_scanOperationQueue;

	NSMutableArray*				_priorityCommandQueue;
	NSMutableArray*				_commandQueue;
	
	FLScanToolState				_state;
	FLScanToolProtocol			_protocol;
	FLScanToolDeviceType		_deviceType;
	BOOL						_waitingForVoltageCommand;
	BOOL						_useLocation;
	CLLocationManager*			_locationManager;
	
	NSTimer*					_batteryTimer;
	NSTimer*					_pendingCodesTimer;
	NSTimer*					_deadmanTimer;
	
	NSUInteger					_currentPIDGroup;
	
	NSString*					_host;
	NSInteger					_port;
}

@property(readonly) NSArray* supportedSensors;
@property(nonatomic, retain) NSArray* sensorScanTargets;
@property(assign) id<FLScanToolDelegate> delegate;
@property(nonatomic, readonly) BOOL scanning;
@property(nonatomic, assign) BOOL useLocation;
@property(nonatomic, retain, readonly) CLLocation* currentLocation;
@property(nonatomic, retain, readonly) NSString* scanToolName;
@property(nonatomic, readonly) FLScanToolState scanToolState;
@property(nonatomic, readonly) FLScanToolProtocol scanToolProtocol;
@property(nonatomic, readonly) FLScanToolDeviceType scanToolDeviceType;
@property(nonatomic, readonly, getter=isWifiScanTool) BOOL wifiScanTool;
@property(nonatomic, readonly, getter=isEAScanTool) BOOL eaScanTool;
@property (nonatomic, copy) NSString* host;		//For WiFi ScanTool
@property (nonatomic, assign) NSInteger port;	//For WiFi ScanTool


+ (FLScanTool*) scanToolForDeviceType:(FLScanToolDeviceType) deviceType;
+ (NSString*) stringForProtocol:(FLScanToolProtocol)protocol;

//
// These methods are based off of the BluTraxWifi command set, so they may
// not necessarily have couterparts on other OBD-2 decoder chips.
// More commands may be added in the future to support custom commands provided
// by other decoder chip manufacturers.
//
- (FLScanToolCommand*) commandForPing;
- (FLScanToolCommand*) commandForGenericOBD:(FLScanToolMode)mode pid:(unsigned char)pid data:(NSData*)data;
- (FLScanToolCommand*) commandForReadSerialNumber;
- (FLScanToolCommand*) commandForReadVersionNumber;
- (FLScanToolCommand*) commandForReadProtocol;
- (FLScanToolCommand*) commandForReadChipID;
- (FLScanToolCommand*) commandForSetAutoSearchMode;
- (FLScanToolCommand*) commandForSetSerialNumber;
- (FLScanToolCommand*) commandForTestForMultipleECUs;
- (FLScanToolCommand*) commandForStartProtocolSearch;
- (FLScanToolCommand*) commandForGetBatteryVoltage;


- (void) enqueueCommand:(FLScanToolCommand*)command;
- (FLScanToolCommand*) dequeueCommand;
- (void) clearCommandQueue;

- (void) sendCommand:(FLScanToolCommand*)command initCommand:(BOOL)initCommand;
- (void) getResponse;

- (void) open;
- (void) close;
- (void) initScanTool;
- (void) startScan;
- (void) pauseScan;
- (void) resumeScanFromPause;
- (void) cancelScan;
- (void) dispatchDelegate:(SEL)selector withObject:(id)obj;
- (void) updateSafetyCheckState;
- (BOOL) buildSupportedSensorList:(NSData*)data forPidGroup:(NSUInteger)pidGroup;
- (BOOL) isService01PIDSupported:(NSUInteger)pid;
- (void) getTroubleCodes;
- (void) getPendingTroubleCodes;
- (void) clearTroubleCodes;
- (void) getBatteryVoltage;
- (void) stream:(NSStream*)stream handleEvent:(NSStreamEvent)eventCode;
- (void) writeCachedData;

@end

//___________________________________________________________________________________________________

@protocol FLScanToolDelegate <NSObject>
@optional
- (void)scanDidStart:(FLScanTool*)scanTool;
- (void)scanDidPause:(FLScanTool*)scanTool;
- (void)scanDidCancel:(FLScanTool*)scanTool;
- (void)scanToolWillSleep:(FLScanTool*)scanTool;
- (void)scanToolDidConnect:(FLScanTool*)scanTool;
- (void)scanToolDidDisconnect:(FLScanTool*)scanTool;
- (void)scanToolDidInitialize:(FLScanTool*)scanTool;
- (void)scanToolDidFailToInitialize:(FLScanTool*)scanTool;
- (void)scanTool:(FLScanTool*)scanTool didSendCommand:(FLScanToolCommand*)command;
- (void)scanTool:(FLScanTool*)scanTool didReceiveResponse:(NSArray*)responses;
- (void)scanTool:(FLScanTool*)scanTool didReceiveVoltage:(NSString*)voltage;
- (void)scanTool:(FLScanTool*)scanTool didTimeoutOnCommand:(FLScanToolCommand*)command;
- (void)scanTool:(FLScanTool*)scanTool didReceiveError:(NSError*)error;
@end

