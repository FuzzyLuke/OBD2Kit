/*
 *  FLSimScanTool.m
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

#import "FLSimScanTool.h"
#import "FLLogging.h"

@implementation FLSimScanTool


- (void) initScanTool {
	
	FLINFO(@"*** Initializing Simulated ScanTool ***")
	_state				= STATE_IDLE;
	
	_supportedSensorList = [[NSMutableArray alloc] initWithCapacity:2];

	//Add RPM pid
	[_supportedSensorList addObject:[NSNumber numberWithInt:0x0C]];
	//Add Speed pid
	[_supportedSensorList addObject:[NSNumber numberWithInt:0x0D]];

	[self dispatchDelegate:@selector(scanToolDidInitialize:) withObject:nil];
	[self dispatchDelegate:@selector(scanToolDidConnect:) withObject:nil];
}


- (void) runStreams {
	NSAutoreleasePool * pool	= [[NSAutoreleasePool alloc] init];
	FLScanToolResponse* rpmResp		= [[FLScanToolResponse alloc] init];
	FLScanToolResponse* spdResp		= [[FLScanToolResponse alloc] init];
	FLScanToolResponse* dtcResp		= [[FLScanToolResponse alloc] init];

	@try {
		[self initScanTool];

		rpmResp.scanToolName			= @"Simulated";
		rpmResp.protocol				= kScanToolProtocolCAN29bit500KB;
		rpmResp.mode					= 0x40 + kScanToolModeRequestCurrentPowertrainDiagnosticData;
		rpmResp.pid						= 0x0C;
		rpmResp.data					= [NSData dataWithBytes:"0FFF" length:4];
		
		spdResp.scanToolName			= @"Simulated";
		spdResp.protocol				= kScanToolProtocolCAN29bit500KB;
		spdResp.mode					= 0x40 + kScanToolModeRequestCurrentPowertrainDiagnosticData;
		spdResp.pid						= 0x0D;
		spdResp.data					= [NSData dataWithBytes:"0040" length:4];
		
		dtcResp.scanToolName			= @"Simulated";
		dtcResp.protocol				= kScanToolProtocolCAN29bit500KB;
		dtcResp.mode					= 0x40 + kScanToolModeRequestEmissionRelatedDiagnosticTroubleCodes;
		dtcResp.pid						= 0x03;
		dtcResp.data					= [NSData dataWithBytes:"41030200" length:8];
		
		
		int state = 0;
		//Simulated ScanTool does not need to do anything
		while (!_streamOperation.isCancelled) {
			NSMutableArray* responses = [NSMutableArray arrayWithCapacity:0];
			
			switch (state) {
				case 0:
					[responses addObject:rpmResp];
					break;
				case 1:
					[responses addObject:spdResp];
					break;
				case 2:
					[responses addObject:dtcResp];
					break;
				default:
					break;
			}

			if (state < 2) {
				state++;
			} else {
				state = 0;
			}

			[self dispatchDelegate:@selector(scanTool:didReceiveResponse:) withObject:responses];
			[NSThread sleepForTimeInterval:0.5];

		}

		FLINFO(@"*** STREAMS CANCELLED ***")
	}
	@catch (NSException * e) {
		FLEXCEPTION(e)
	}
	@finally {
		[rpmResp release];
		[spdResp release];
		[pool release];
		[self dispatchDelegate:@selector(scanDidCancel:) withObject:nil];
	}	
}


@end
