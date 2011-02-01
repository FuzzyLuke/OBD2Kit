/*
 *  GoLink.m
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

#import "GoLink.h"
#import "GoLinkCommand.h"
#import "GoLinkResponseParser.h"
#import "FLEAController.h"
#import "FLLogging.h"

NSString* const kGoLinkProtocolString	= @"com.goPoint.p1";
NSString* const kGoLinkScanToolName		= @"GoLink";

@interface GoLink (Private)
- (FLScanToolCommand*) commandForInitState:(GoLinkInitState)state;
- (void) handleInitReadData;
- (void) processSystemFrame:(GoLinkSystemFrame*)frame;
- (void) processErrorFrame:(GoLinkErrorFrame*)frame;
- (void) processDataFrame:(uint8_t*)data length:(NSUInteger)length;
- (NSArray*) framesForData:(uint8_t*)data length:(NSUInteger)length;
- (void) commandForDTCCount;
- (void) sendNextCommand;
@end


#pragma mark -
@implementation GoLink

- (id) init {
	if (self = [super init]) {
		_protocolString		= [kGoLinkProtocolString copy];
		_deviceType			= kScanToolDeviceTypeGoLink;
	}
	
	return self;
}

- (NSString*) scanToolName {
	return @"GoLink";
}

#pragma mark -
#pragma mark ScanTool Initialization

- (FLScanToolCommand*) commandForInitState:(GoLinkInitState)state {
	
	FLScanToolCommand* cmd = nil;
	
	switch (state) {
			
		case GOLINK_INIT_STATE_PROTOCOL:
			cmd = [GoLinkCommand commandForReadProtocol];
			break;
			
		case GOLINK_INIT_STATE_PID_SEARCH:
			cmd = [GoLinkCommand commandForMode:kScanToolModeRequestCurrentPowertrainDiagnosticData 
											pid:_currentPIDGroup 
										   data:nil];
			break;
			
		case GOLINK_INIT_STATE_UNKNOWN:
		default:
			break;
	}
	
	return cmd;
}

- (void) initScanTool {
	
	FLINFO(@"*** Initializing GoLink ***")
	_state				= STATE_INIT;
	_initState			= GOLINK_INIT_STATE_PROTOCOL;
	_currentPIDGroup	= 0x00;
	
	CLEAR_GOLINK();
	
	[self sendCommand:[GoLinkCommand commandForReadProtocol] initCommand:YES];
}

#pragma mark -
#pragma mark Data Handlers

- (NSArray*) framesForData:(uint8_t*)data length:(NSUInteger)length {
	FLTRACE_ENTRY
	NSMutableArray *rawFrames		= [NSMutableArray array];
	
	if (length <= sizeof(GoLinkFrameHeader)) {
		FLERROR(@"Incomplete frame, size = %d", length)
		return rawFrames;
	}
	
	NSInteger bytesRemaining		= length;
	GoLinkFrameHeader* frameHeader  = (GoLinkFrameHeader*)data;
	
	do {		
		FLDEBUG(@"bytesRemaining = %d ** dataFrameAddr = %p", bytesRemaining, frameHeader)
		
		if ((sizeof(GoLinkFrameHeader) + frameHeader->length) > bytesRemaining) {
			FLERROR(@"Dropping incomplete frame. Expecting %d, bytesRemaining %d", (sizeof(GoLinkFrameHeader) + frameHeader->length), bytesRemaining)
			break;
		}
		
		NSData *frame				= [NSData dataWithBytes:data length:sizeof(GoLinkFrameHeader) + frameHeader->length];
		[rawFrames addObject:frame];
		
		bytesRemaining				-= sizeof(GoLinkFrameHeader) + frameHeader->length;
		uint8_t* incrPtr			= (uint8_t*)frameHeader;
		frameHeader					= (GoLinkFrameHeader*)(incrPtr + sizeof(GoLinkFrameHeader) + frameHeader->length);
		
	} while(bytesRemaining > 0);
	
	return rawFrames;	
}


- (void) handleReadData {
	FLTRACE_ENTRY
	
	while ([[_session inputStream] hasBytesAvailable] && 
		   _readBufLength < GOLINK_READBUF_SIZE) {
		// TODO: add timeout for this loop		
		_readBufLength += [[_session inputStream] read:&_readBuf[_readBufLength] 
											 maxLength:(GOLINK_READBUF_SIZE - _readBufLength)];
		
		FLDEBUG(@"Read %d bytes from EASession inputStream", _readBufLength)		
		
		if (_readBufLength >= GOLINK_READBUF_SIZE) {
			FLERROR(@"Error, overflow into _readBuf ** _readBufLength=%d", _readBufLength)
			_readBufLength = 0;
			break;
		}
	}

/*** This was here to debug the problem with multiple pid search responses in a single data frame.
 *** Leaving it here, and commented out to add as a test case in the future
	static NSInteger cnt = 0;
	
	cnt++;
	if (cnt==2) {
		_readBufLength = 27;
		
		uint8_t _tmpBuf[27] = {
			0x00, 0xeb, 0x06, 0x41, 
			0x00, 0x80, 0x40, 0x00, 
			0x01, 0x00, 0xe8, 0x06, 
			0x41, 0x00, 0xbf, 0xff, 
			0xb9, 0x93, 0x00, 0xea, 
			0x06, 0x41, 0x00, 0x80,
			0x00, 0x00, 0x01
		};
		
		memcpy(_readBuf, _tmpBuf, _readBufLength);
	}
***/
	
	FLDEBUG(@"_readBufLength = %d  ** _readBuf[] = %@", _readBufLength, [[NSData dataWithBytes:_readBuf length:_readBufLength] description])
	FLDEBUG(@"Frame Type = 0x%04X", GOLINK_FRAME_TYPE(_readBuf))
	
	GoLinkFrameHeader* header = (GoLinkFrameHeader*)_readBuf;
	FLDEBUG(@"header->length = %d", header->length)
	
	if (GOLINK_FRAME_COMPLETE(_readBuf, _readBufLength)) {
		FLINFO(@"GOLINK_FRAME_COMPLETE")
		_state = (STATE_INIT()) ? STATE_INIT : STATE_PROCESSING;
		
		switch (GOLINK_FRAME_TYPE(_readBuf)) {
			case kGLFrameTypeError:
				FLERROR(@"ERROR FRAME", nil)
				GoLinkErrorFrame* errorFrame	= (GoLinkErrorFrame*)_readBuf;
				[self processErrorFrame:errorFrame];		
				break;
				
			case kGLFrameTypeData: 
				FLINFO(@"DATA FRAME")
				[self processDataFrame:_readBuf length:_readBufLength];
				
				break;
				
			case kGLFrameTypeSystem: 
				FLINFO(@"SYSTEM FRAME")
				[self processSystemFrame:(GoLinkSystemFrame*)_readBuf];				
				break;
				
			default:
				FLERROR(@"Received unknown GoLink frame type", nil)
				break;
		}
		
		CLEAR_GOLINK()
		
		if(_initState == GOLINK_INIT_STATE_COMPLETE && STATE_INIT()) {
			FLDEBUG(@"*** Init Complete ***", nil)
			_initState			= GOLINK_INIT_STATE_PROTOCOL;
			_currentPIDGroup	= 0x00;
			FLINFO(@"*** STATE_IDLE ***")
			_state		= STATE_IDLE;
			[self dispatchDelegate:@selector(scanToolDidInitialize:) withObject:nil];
		}
		else if (_initState != GOLINK_INIT_STATE_COMPLETE && STATE_INIT()) {
			[self sendCommand:[self commandForInitState:_initState] initCommand:YES];
		}
		else {
			if (!_streamOperation.isCancelled) {
				FLINFO(@"*** STATE_IDLE ***")
				_state = STATE_IDLE;
				[self sendNextCommand];
			}			
		}		
	}
	else {
		FLERROR(@"Incomplete Frame", nil)
		CLEAR_GOLINK()
		_state = (STATE_INIT()) ? STATE_INIT : STATE_IDLE;		
	}
}


- (void) commandForDTCCount {
	if(!_priorityCommandQueue) {
		_priorityCommandQueue = [NSMutableArray arrayWithCapacity:8];
		[_priorityCommandQueue retain];
	}
	
	[self enqueueCommand:[self commandForGenericOBD:kScanToolModeRequestCurrentPowertrainDiagnosticData 
												pid:0x01
											   data:nil]];
}


- (void) sendNextCommand {
	FLScanToolCommand* cmd = [self dequeueCommand];	
	if(cmd) {
		if (cmd.pid == 0x0C) {
			// We do not need to query RPM as often, since the GoLink
			// uses RPM as a heartbeat
			cmd			= (_sendRPM) ? cmd : [self dequeueCommand];
			_sendRPM	= !_sendRPM; 
		}
		[self sendCommand:cmd initCommand:NO];
	}	
}


- (void) handleInitReadData {
	
}

- (void) processSystemFrame:(GoLinkSystemFrame*)frame {	
	FLDEBUG(@"systemFrame->requestType = 0x%02X", frame->requestType)
	
	switch (frame->requestType) {
		case kGLSystemMessageProtocol:
			FLINFO(@"PROTOCOL MESSAGE")
			
			if (STATE_INIT()) {
				GoLinkVehicleBusFrame* busFrame = (GoLinkVehicleBusFrame*)frame;
				_protocol	= GET_GOLINK_PROTOCOL(busFrame->busType);
				FLDEBUG(@"Found protocol: %@", [FLScanTool stringForProtocol:_protocol]) 
				_initState	= GOLINK_INIT_STATE_PID_SEARCH;
			}
			
			break;
		default:
			FLERROR(@" *** UNKNOWN GOLINK SYSTEM STATUS ***", nil)
			break;
	}
}


- (void) processErrorFrame:(GoLinkErrorFrame*)frame {
	
	switch (frame->status) {
		case kGLErrorMessageSleep:
			FLINFO(@"*** SLEEP IN 2-SECONDS ***")
			[self dispatchDelegate:@selector(scanToolWillSleep:) withObject:nil];
			break;
			
		case kGLErrorMessageOverrun:
			FLERROR(@"*** BUFFER REQUEST OVERRUN FOR PID %d ***", frame->requestPid)
			_bufferOverrun = YES;
			break;
			
		case kGLErrorMessageTimeout:
			FLERROR(@"*** NO RESPONSE FOR PID %d ***", frame->requestPid)
			[self dispatchDelegate:@selector(scanTool:didTimeoutOnCommand:) 
						withObject:[GoLinkCommand commandForMode:frame->requestMode 
															 pid:frame->requestPid 
															data:nil]];
		default:
			FLERROR(@"*** UNKNOWN GOLINK ERROR STATUS ***", nil)
			break;
	}
}


- (void) processDataFrame:(uint8_t*)data length:(NSUInteger)length {
	
	//GoLinkDataFrame* frame			= (GoLinkDataFrame*)data;
	GoLinkResponseParser* parser	= [[GoLinkResponseParser alloc] initWithBytes:data length:length];
	NSArray* responses				= [parser parseResponse:_protocol];
	
	@try {
		if(responses && [responses count] > 0) {
			FLDEBUG(@"Received %d responses", [responses count])
			
			
			if(self.useLocation) {
				[responses makeObjectsPerformSelector:@selector(updateLocation:) withObject:self.currentLocation];
			}
			
			if (STATE_INIT() && _initState == GOLINK_INIT_STATE_PID_SEARCH) {
				
				//uint8_t pid = frame->data[0];
				
				//if (pid != 0x00 && pid != 0x20 && pid != 0x40) {
				//	FLERROR(@"Received erroneous PID during init search ($%02X)", pid)
				//	return;
				//}
				
				[self dispatchDelegate:@selector(scanToolDidConnect:) withObject:nil];
				
				BOOL morePIDs = NO;
				BOOL goodPIDsFound = NO;
				for (FLScanToolResponse* resp in responses) {
					FLDEBUG(@"resp.rawData: %@", resp.rawData)
					
					GoLinkDataFrame frame[[resp.rawData length]];
					[resp.rawData getBytes:frame];
					
					uint8_t pid = frame->data[0];
					
					FLDEBUG(@"pid: %d", pid)
					if (pid != 0x00 && pid != 0x20 && pid != 0x40) {
						FLERROR(@"Received erroneous PID during init search ($%02X)", pid)
						continue;
					}
					
					BOOL tmpMorePIDs = [self buildSupportedSensorList:resp.data forPidGroup:_currentPIDGroup];
					if (!morePIDs && tmpMorePIDs) {
						morePIDs = YES;
					}
					goodPIDsFound = YES;
				}
				FLDEBUG(@"More PIDs: %@", (morePIDs) ? @"YES" : @"NO")
				
				BOOL extendPIDSearch	= NO;
				if (!extendPIDSearch && morePIDs) {
					extendPIDSearch	= YES;
				}				
				
				if (extendPIDSearch) {
					_currentPIDGroup		+= (extendPIDSearch) ? 0x20 : 0x00;
					
					if (_currentPIDGroup > 0x40) {
						_initState			<<= 1;
						_currentPIDGroup	= 0x00;
					}
				}
				else {
					if(goodPIDsFound) { //keep the scantool in init state until it gets good PID responses
						_initState				<<= 1;
					}
					_currentPIDGroup		= 0x00;
				}
			}
			else {
				[self dispatchDelegate:@selector(scanTool:didReceiveResponse:) withObject:responses];
			}
		}
	}
	@catch (NSException * e) {
		FLEXCEPTION(e)
	}
	@finally {
		[parser release];
	}
}

#pragma mark -
#pragma mark ScanToolCommand Generators

- (FLScanToolCommand*) commandForGenericOBD:(FLScanToolMode)mode pid:(unsigned char)pid data:(NSData*)data {	
	return [GoLinkCommand commandForMode:mode pid:pid data:data];
}

- (FLScanToolCommand*) commandForReadVersionNumber {
	return (FLScanToolCommand*)nil;
}


- (FLScanToolCommand*) commandForReadProtocol {
	return (FLScanToolCommand*)nil;
}

- (FLScanToolCommand*) commandForGetBatteryVoltage {
	// GoLink (ne GL1) does not currently support this
	return (FLScanToolCommand*)nil;
}

@end
