/*
 *  ELM327.h
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
#import "FLWifiScanTool.h"
#import "ELM327ResponseParser.h"


#define CLEAR_READBUF()				memset(_readBuf, 0x00, sizeof(_readBuf)); _readBufLength = 0;
#define INIT_COMPLETE(state)		(state == ELM327_INIT_STATE_COMPLETE)


typedef enum {
	ELM327_INIT_STATE_UNKNOWN			= 0x0000,	
	ELM327_INIT_STATE_RESET				= 0x0001,
	ELM327_INIT_STATE_ECHO_OFF			= 0x0002,
	ELM327_INIT_STATE_VERSION			= 0x0004,
	ELM327_INIT_STATE_PID_SEARCH		= 0x0008,
	ELM327_INIT_STATE_PROTOCOL			= 0x0010,
	ELM327_INIT_STATE_COMPLETE			= 0x0020
} ELM327InitState;


/*
 These are the protocol numbers for the ELM327: 
 
 0 - Automatic 
 1 - SAE J1850 PWM (41.6 Kbaud) 
 2 - SAE J1850 VPW (10.4 Kbaud) 
 3 - ISO 9141-2  (5 baud init, 10.4 Kbaud) 
 4 - ISO 14230-4 KWP (5 baud init, 10.4 Kbaud) 
 5 - ISO 14230-4 KWP (fast init, 10.4 Kbaud) 
 6 - ISO 15765-4 CAN (11 bit ID, 500 Kbaud) 
 7 - ISO 15765-4 CAN (29 bit ID, 500 Kbaud) 
 8 - ISO 15765-4 CAN (11 bit ID, 250 Kbaud) 
 9 - ISO 15765-4 CAN (29 bit ID, 250 Kbaud) 
 A - SAE J1939 CAN (29 bit ID, 250* Kbaud) 
 B - USER1 CAN (11* bit ID, 125* Kbaud) 
 C - USER2 CAN (11* bit ID, 50* Kbaud) 
 
 
 We map these back to our base protocol list, which is itself derived from
 the BluTrax protocol-to-number mapping
 */

typedef enum {
	kELMAutomatic						= 0,
	kSAEJ1850PWM,
	kSAEJ1850VPW,
	kISO9141,
	kISO14230KWP,
	kISO14230KWPFastInit,
	kISO15765CAN11Bit500,
	kISO15765CAN29Bit500,
	kISO15765CAN11Bit250,
	kISO15765CAN29Bit250,
	kSAEJ1939CAN29Bit250,
	kUser1CAN11Bit125,
	kUser2CAN11Bit50	
} ELM327Protocol;

const static int elm_protocol_map[] = {
	kScanToolProtocolNone,
	kScanToolProtocolJ1850PWM,
	kScanToolProtocolJ1850VPW,
	kScanToolProtocolISO9141Keywords0808,
	kScanToolProtocolKWP2000SlowInit,
	kScanToolProtocolKWP2000FastInit,
	kScanToolProtocolCAN11bit500KB,
	kScanToolProtocolCAN29bit500KB,
	kScanToolProtocolCAN11bit250KB,
	kScanToolProtocolCAN29bit250KB,
	kScanToolProtocolCAN29bit250KB,
	kScanToolProtocolNone,
	kScanToolProtocolNone
};


#define GET_PROTOCOL(elm_proto)			elm_protocol_map[elm_proto]


@interface ELM327 : FLWifiScanTool {
	ELM327InitState					_initState;
	ELM327ResponseParser*			_parser;
	NSMutableArray*					_initOperations;
	uint8_t							_readBuf[512];
	NSUInteger						_readBufLength;
}

@property (nonatomic, readonly) ELM327InitState initState;

@end
