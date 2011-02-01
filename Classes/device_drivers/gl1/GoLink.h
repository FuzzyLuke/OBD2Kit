/*
 *  GoLink.h
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
#import "FLEAScanTool.h"

extern NSString* const kGoLinkProtocolString;
extern NSString* const kGoLinkScanToolName;

#define GOLINK_READBUF_SIZE		128
#define CLEAR_GOLINK()			memset(_readBuf, 0x00, sizeof(_readBuf)); _readBufLength = 0;

/*
 These are the protocol numbers for the GoLink: 
 
 0 - ISO 15765-4 CAN (11 bit ID, 500 Kbaud) 
 1 - ISO 15765-4 CAN (29 bit ID, 500 Kbaud) 
 2 - ISO 15765-4 CAN (11 bit ID, 250 Kbaud) 
 3 - ISO 15765-4 CAN (29 bit ID, 250 Kbaud) 
 4 - SAE J1850 VPW (10.4 Kbaud) 
 5 - SAE J1850 PWM (41.6 Kbaud) 
 6 - ISO 14230-4 KWP (fast init, 10.4 Kbaud) 
 7 - ISO 14230-4 KWP (5 baud init, 10.4 Kbaud) 
 8 - ISO 9141-2  (5 baud init, 10.4 Kbaud) 
 9 - None
 
 We map these back to our base protocol list, which is itself derived from
 the BluTrax protocol-to-number mapping
 */

typedef enum {
	kGLProtocolISO15765CAN11Bit500				= 0,
	kGLProtocolISO15765CAN29Bit500,
	kGLProtocolISO15765CAN11Bit250,
	kGLProtocolISO15765CAN29Bit250,	
	kGLProtocolSAEJ1850VPW,
	kGLProtocolSAEJ1850PWM,
	kGLProtocolISO14230KWPFastInit,
	kGLProtocolISO14230KWP,
	
	// Note: the GoLink returns the ISO9141-2 keywords separately,
	// so these protocols are determined programmatically, rather than a
	// simple return value.
	kGLProtocolISO9141Keywords0808,	
	kGLProtocolISO9141Keywords9494
} GoLinkProtocol;

const static int golink_protocol_map[]	= {
	kScanToolProtocolCAN11bit500KB,
	kScanToolProtocolCAN29bit500KB,
	kScanToolProtocolCAN11bit250KB,
	kScanToolProtocolCAN29bit250KB,
	kScanToolProtocolJ1850VPW,
	kScanToolProtocolJ1850PWM,
	kScanToolProtocolKWP2000FastInit,
	kScanToolProtocolKWP2000SlowInit,
	kScanToolProtocolISO9141Keywords0808,
	kScanToolProtocolISO9141Keywords9494
};

#define GET_GOLINK_PROTOCOL(golink_proto)	golink_protocol_map[golink_proto]


typedef enum {
	GOLINK_INIT_STATE_UNKNOWN			= 0x0000,
	GOLINK_INIT_STATE_PROTOCOL			= 0x0001,
	GOLINK_INIT_STATE_PID_SEARCH		= 0x0002,
	GOLINK_INIT_STATE_COMPLETE			= 0x0004
} GoLinkInitState;

typedef enum {
	kGLFrameTypeError			= 0x01,
	kGLFrameTypeSystem			= 0x07,
	kGLFrameTypeData			= 0x00
} GoLinkFrameType;

typedef enum {
	kGLErrorMessageSleep		= 0x00,
	kGLErrorMessageOverrun		= 0x01,
	kGLErrorMessageTimeout		= 0x02,
	
	kGLNumErrorMessages
} GoLinkErrorMessageType;

typedef enum {
	kGLSystemMessageProtocol	= 0x01,	
	
	kGLNumSystemMessages
} GoLinkSystemMessageType;


#pragma pack(1)
typedef struct golink_frame_header_t {
	uint8_t			fid;		// Frame ID
	uint8_t			address;	// Frame Address
	uint8_t			length;		// Frame Length
} GoLinkFrameHeader;

#pragma pack(1)
typedef struct golink_request_frame_t {
	GoLinkFrameHeader	header;
	uint8_t				data[8];
} GoLinkRequestFrame;

#pragma pack(1)
typedef struct golink_overrun_frame_t {
	GoLinkFrameHeader	header;
	uint8_t				status;
	GoLinkFrameHeader	requestHeader;
	uint8_t				requestMode;
	uint8_t				requestPid;
} GoLinkErrorFrame;

#pragma pack(1)
typedef struct golink_system_frame_t {
	GoLinkFrameHeader	header;
	uint8_t				requestType;
	uint8_t				data[1];
} GoLinkSystemFrame;

#pragma pack(1)
typedef struct golink_vehicle_bus_frame_t {
	GoLinkFrameHeader	header;
	uint8_t				requestType;
	uint8_t				busType;
	uint8_t				keyword1;
	uint8_t				keyword2;
} GoLinkVehicleBusFrame;

#pragma pack(1)
typedef struct golink_data_frame_t {
	GoLinkFrameHeader	header;
	uint8_t				mode;
	uint8_t				data[1];
	// Data will follow after this, use data as pointer
	// to find the beginning
} GoLinkDataFrame;




#define GOLINK_FRAME_TYPE(buf)			((GoLinkFrameHeader*)buf)->fid

// Error frame macros
#define GOLINK_SLEEP_FRAME(frame)		(((GoLinkErrorFrame*)frame)->status == kGLErrorMessageSleep)
#define GOLINK_OVERRUN_FRAME(frame)		(((GoLinkErrorFrame*)frame)->status == kGLErrorMessageOverrun)
#define GOLINK_TIMEOUT_FRAME(frame)		(((GoLinkErrorFrame*)frame)->status == kGLErrorMessageTimeout)

// System frame macros
#define GOLINK_PROTOCOL_FRAME(frame)	(((GoLinkSystemFrame*)frame)->requestType == kGLSystemMessageProtocol)

// Data frame macros
#define GOLINK_DATA_LENGTH(frame)		(((GoLinkDataFrame*)frame)->header.length - 2) // 2 for mode and pid

// Multi-frame macros
#define GOLINK_FRAME_COMPLETE(buf, len)	(len - sizeof(GoLinkFrameHeader)) >= (((GoLinkFrameHeader*)buf)->length)
#define HAS_MORE_FRAMES(buf, length)	((GoLinkFrameHeader*)buf)->length > (sizeof(GoLinkFrameHeader) + length)
#define NEXT_FRAME(frameHeader)			(uint8_t*)(frameHeader + sizeof(GoLinkFrameHeader) + ((GoLinkFrameHeader*)frameHeader)->length)


@interface GoLink : FLEAScanTool {
	GoLinkInitState		_initState;
	uint8_t				_readBuf[GOLINK_READBUF_SIZE];
	NSUInteger			_readBufLength;	
	BOOL				_bufferOverrun;
	BOOL				_sendRPM;
}

@end
