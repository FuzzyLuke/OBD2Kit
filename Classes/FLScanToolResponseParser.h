/*
 *  FLScanToolResponseParser.h
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

#import "FLScanToolResponse.h"
#import "FLScanTool.h"


typedef struct non_can_response_t {
	unsigned char	priority;
	unsigned char	targetAddress;
	unsigned char	ecuAddress;
	unsigned char	mode;
	unsigned char	pid;
	unsigned char	dataBytes[4];
} ISO9141Response, J1850PWMResponse, J1850VPWResponse, KWP2000Response;

typedef struct can_11bit_response_t {
	unsigned char	header1;
	unsigned char	header2;
	unsigned char	PCI;
	unsigned char	mode;
	unsigned char	dataBytes[5];
} CAN11bitResponse;

typedef struct can_29bit_response_t {
	unsigned char	header1;
	unsigned char	header2;
	unsigned char	destinationAddress;
	unsigned char	sourceAddress;
	unsigned char	PCI;
	unsigned char	mode;
	unsigned char	pid;
	unsigned char	dataBytes[5];
} CAN29BitResponse;


@interface FLScanToolResponseParser : NSObject {
	BOOL					resolveLocation;
	uint8_t*				_bytes;
	NSInteger				_length;
}

@property (nonatomic, assign, readonly) BOOL resolveLocation;

- initWithBytes:(uint8_t*)bytes length:(NSUInteger)length;

- (void) setBytes:(uint8_t*)bytes length:(NSInteger)length;

- (NSArray*) parseResponse:(FLScanToolProtocol)protocol;

@end


//___________________________________________________________________________________________________

@protocol ScanToolResponseParserDelegate<NSObject>

@optional

- (void) parser:(FLScanToolResponseParser*)parser didReceiveResponse:(FLScanToolResponse*)response;
- (void) parser:(FLScanToolResponseParser*)parser didFailWithError:(NSError*)error;

@end