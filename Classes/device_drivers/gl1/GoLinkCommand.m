/*
 *  GoLinkCommand.m
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

#import "GoLinkCommand.h"
#import "FLScanTool.h"
#import "FLLogging.h"

const GoLinkRequestFrame g_VehicleBusTypeRequestFrame = {
	{	
		// GoLinkFrameHeader
		0x07,	// System Message
		0x00,	// Request vehicle bus type
		0x01	// Length
	},	
	0x01,		// Bus Type Request
	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00// Unused
};

@interface GoLinkCommand (Private)
- (NSData*) serializeGoLinkRequestFrame;
@end


#pragma mark -
@implementation GoLinkCommand

- (NSData*) data {	
	NSInteger requestLength = _requestFrame.header.length + sizeof(GoLinkFrameHeader);
	
	if (requestLength > sizeof(GoLinkFrameHeader)) {
		FLINFO(@"*********** NEW COMMAND CREATED **************")
		FLDEBUG(@"Flushing length=%d", requestLength)
		NSData* requestData		= [[NSData alloc] initWithBytes:&_requestFrame length:requestLength];
		FLDEBUG(@"Flushing data %@", [requestData description])
		FLINFO(@"**********************************************")
		return [requestData autorelease];
	}
	else {
		FLERROR(@"Request frame contains no data (requestLength=%d)", requestLength)
		return nil;
	}	
}

- (void) setRequestFrame:(GoLinkRequestFrame*)request {	
	if (request) {
		memcpy(&_requestFrame, request, sizeof(GoLinkRequestFrame));
	}
}


+ (FLScanToolCommand*) commandForMode:(int)mode pid:(NSUInteger)pid data:(NSData *)data {
	
	FLDEBUG(@"Mode=%02X **PID=%02X", mode, pid)
	
	GoLinkCommand* cmd	= [[GoLinkCommand alloc] init];
	cmd.mode			= (mode >= 0x01 && mode <= 0x0B) ? mode : 0x01;
	cmd.pid				= (pid >= 0x00 && pid <= 0x4E) ? pid : 0x01;
	cmd.data			= data;
	
	GoLinkRequestFrame frame	= {
		{
			// GoLinkFrameHeader
			0x07,							
			0xDF,				
			0x01
		},
		0x00, // Mode
		0x00, // PID
		0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	};
	
	
	frame.data[0]		= mode;
	
	if (pid >= 0x00 && pid <= 0x4E) {
		frame.data[1]		= pid;
		frame.header.length	= 2;
		
		if (cmd.data) {
			const uint8_t* dataBytes= [cmd.data bytes];
			NSInteger dataLength	= [cmd.data length];
			
			if (dataLength <= 0x06) {
				frame.header.length += dataLength;
				memcpy(&(frame.data[2]), dataBytes, dataLength);
			}
			else {
				FLERROR(@"Invalid command data specified", nil)
				[cmd release];
				return nil;
			}
		}
	}
	
	[cmd setRequestFrame:&frame];
	
	return [cmd autorelease];
}

+ (GoLinkCommand*) commandForReadProtocol {
	GoLinkCommand* cmd	= [[GoLinkCommand alloc] init];
	cmd.mode			= 0xFF;
	cmd.pid				= 0xFF;
	cmd.data			= nil;
	
	[cmd setRequestFrame:(GoLinkRequestFrame*)&g_VehicleBusTypeRequestFrame];
	
	return [cmd autorelease];
}


#pragma mark -
#pragma mark Private Methods

- (NSData*) serializeGoLinkRequestFrame {
	return nil;
}

@end
