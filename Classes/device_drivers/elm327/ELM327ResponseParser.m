/*
 *  ELM327ResponseParser.m
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

#import "ELM327ResponseParser.h"
#import <CoreLocation/CoreLocation.h>
#import "FLLogging.h"

NSString *const kATError						= @"?";
NSString *const kResponseFinished				= @">";
NSString *const kOK								= @"OK";
NSString *const kNoData							= @"NO DATA";

@implementation ELM327ResponseParser


- (NSString*) stringForResponse {
	/*
	const char* test = "41 00 90 18 80 00 \r41 00 BF 9F F9 91 ";
	return [NSString stringWithCString:test encoding:NSASCIIStringEncoding];
	*/
	return [NSString stringWithCString:(const char*)_bytes encoding:NSASCIIStringEncoding];
}

- (FLScanToolResponse*) decodeResponseData:(uint8_t*)data 
								ofLength:(NSInteger)length 
							 forProtocol:(FLScanToolProtocol)protocol {
	
	if(!data) {
		return nil;
	}
	
	FLScanToolResponse* resp	= [[FLScanToolResponse alloc] init];
	int dataIndex			= 0;
	
	resp.scanToolName		= @"ELM327";
	resp.protocol			= protocol;
	resp.rawData			= [NSData dataWithBytes:data length:length];
	resp.mode				= data[dataIndex++];
	
	if(resp.mode == kScanToolModeRequestCurrentPowertrainDiagnosticData) {
		resp.pid			= data[dataIndex++];
	}	
	
	if(length > 2) {
		resp.data				= [NSData dataWithBytes:&data[dataIndex] length:(length-dataIndex)];
	}
	
	if(self.resolveLocation) {
		//CLLocationManager* locationManager = [CLLocationManager description
	}
	
	return [resp autorelease];
}


- (NSArray*) parseResponse:(FLScanToolProtocol)protocol {
	
	NSMutableArray* responseArray		= nil;
	
	/*
	 TODO:
	 
	 41 00 BF 9F F9 91 41 00 90 18 80 00
	 
	 Deal with cases where the ELM327 does not properly insert a CR in between
	 a multi-ECU response packet (real-world example above - Mode $01 PID $00).
	 
	 Need to split on modulo 6 boundary and check to ensure total packet length
	 is a multiple of 6.  If not, we'll have to discard.
	 
	 */
	
	
	// Chop off the trailing space, if it's there
	if(_bytes[_length-1] == 0x20) {
		_bytes[_length-1] = 0x00;
		_length--;
	}
	
	char* asciistr						= (char*)_bytes;	
	
	if(!ELM_ERROR(asciistr) && ELM_DATA_RESPONSE(asciistr)) {
		
		// There may be more than one response, if multiple ECUs responded to
		// a particular query, so split on the '\r' boundary
		NSArray* responseComponents		= [[self stringForResponse] componentsSeparatedByString:@"\r"];
		
		for(NSString* resp in responseComponents) {
			
			CLEAR_DECODE_BUF()
			
			char* respCString		= (char*)[resp cStringUsingEncoding:NSASCIIStringEncoding];
			NSUInteger respLen		= [resp lengthOfBytesUsingEncoding:NSASCIIStringEncoding];
			
			// You'd be surprised
			respCString[respLen]	= 0x00;
			
			// Again, trim any trailing spaces
			if (respCString[respLen-1] == 0x20) {
				respCString[respLen-1]  = 0x00;
			}
			
			if(ELM_SEARCHING(respCString)) {
				// A common reply if PID search occuring for the first time
				// at this drive cycle
				break;
			}
			
			// For each response data string, decode into an integer array for
			// easier processing
			while(*respCString != '\0' && _decodeBufLength < sizeof(_decodeBuf)) {				
				_decodeBuf[_decodeBufLength++] = (uint8_t)strtoul(respCString, (char**)&respCString, 16);				
				FLDEBUG(@"_decodeBuf[%d]: %02x", _decodeBufLength, _decodeBuf[_decodeBufLength-1])
			}
			
			if(!responseArray) {
				responseArray = [[NSMutableArray alloc] initWithCapacity:1];
			}
			
			[responseArray addObject:[self decodeResponseData:_decodeBuf ofLength:_decodeBufLength forProtocol:protocol]];
		}	
	}
	else {
		FLERROR(@"Error in parse string or non-data response: %s", asciistr)
	}
	
	return (NSArray*)[responseArray autorelease];
}

@end
