/*
 *  GoLinkResponseParser.m
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


#import "GoLinkResponseParser.h"
#import "FLLogging.h"

@implementation GoLinkResponseParser

- (GoLinkSystemFrame*) parseSystemResponse {
	
	if (_length <= sizeof(GoLinkFrameHeader)) {
		FLERROR(@"Incomplete frame, size = %d", _length)
		return nil;
	}
	
	NSInteger bytesRemaining		= _length;
	GoLinkSystemFrame* systemFrame	= (GoLinkSystemFrame*)_bytes;	
	
	do {		
		FLDEBUG(@"bytesRemaining = %d ** dataFrameAddr = %p", bytesRemaining, systemFrame)
		FLDEBUG(@"Parsing response %@", [[NSData dataWithBytes:(const void*)&(systemFrame->requestType) length:systemFrame->header.length] description])
		
		if ((sizeof(GoLinkFrameHeader) + systemFrame->header.length) > bytesRemaining) {
			FLERROR(@"Dropping incomplete frame. Expecting %d, bytesRemaining %d", (sizeof(GoLinkFrameHeader) + systemFrame->header.length), bytesRemaining)
			break;
		}

		if (systemFrame->requestType == kGLSystemMessageProtocol) {
			FLINFO(@"PROTOCOL MESSAGE FOUND")
			return systemFrame;
		}
		
		bytesRemaining				-= sizeof(GoLinkFrameHeader) + systemFrame->header.length;
		uint8_t* incrPtr			= (uint8_t*)systemFrame;
		systemFrame					= (GoLinkSystemFrame*)(incrPtr + sizeof(GoLinkFrameHeader) + systemFrame->header.length);
		
	} while(bytesRemaining > 0);
	
	return NULL;
}


- (NSArray*) parseResponse:(FLScanToolProtocol)protocol {
	
	if (_length <= sizeof(GoLinkFrameHeader)) {
		FLERROR(@"Incomplete frame, size = %d", _length)
		return nil;
	}
	
	NSMutableArray* responseArray	= [[NSMutableArray alloc] initWithCapacity:1];
	NSInteger bytesRemaining		= _length;
	GoLinkDataFrame* dataFrame		= (GoLinkDataFrame*)_bytes;	
	
	do {		
		FLDEBUG(@"bytesRemaining = %d ** dataFrameAddr = %p", bytesRemaining, dataFrame)
		FLDEBUG(@"Parsing response %@", [[NSData dataWithBytes:(const void*)&(dataFrame->mode) length:dataFrame->header.length] description])
		
		if ((sizeof(GoLinkFrameHeader) + dataFrame->header.length) > bytesRemaining) {
			FLERROR(@"Dropping incomplete frame. Expecting %d, bytesRemaining %d", (sizeof(GoLinkFrameHeader) + dataFrame->header.length), bytesRemaining)
			break;
		}
		
		FLScanToolResponse* resp	= [[FLScanToolResponse alloc] init];
		resp.scanToolName			= kGoLinkScanToolName;
		resp.protocol				= protocol;		
		resp.rawData				= [NSData dataWithBytes:dataFrame length:sizeof(GoLinkFrameHeader) + dataFrame->header.length];
		resp.mode					= dataFrame->mode;
		
		if(resp.mode == kScanToolModeRequestCurrentPowertrainDiagnosticData) {
			resp.pid				= dataFrame->data[0];
			
			if(dataFrame->header.length > 2) {
				resp.data			= [NSData dataWithBytes:&dataFrame->data[1] length:(dataFrame->header.length - 2)];
			}
		}
		else if(resp.mode == kScanToolModeRequestEmissionRelatedDiagnosticTroubleCodes) {
			resp.data				= [NSData dataWithBytes:dataFrame->data length:(dataFrame->header.length - 1)];
		}
				
		[responseArray addObject:resp];
		[resp release];
		
		bytesRemaining				-= sizeof(GoLinkFrameHeader) + dataFrame->header.length;
		uint8_t* incrPtr			= (uint8_t*)dataFrame;
		dataFrame					= (GoLinkDataFrame*)(incrPtr + sizeof(GoLinkFrameHeader) + dataFrame->header.length);
		
	} while(bytesRemaining > 0);
	
	return [responseArray autorelease];
}


@end
