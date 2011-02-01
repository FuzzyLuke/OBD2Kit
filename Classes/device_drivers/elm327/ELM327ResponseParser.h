/*
 *  ELM327ResponseParser.h
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
#import "FLScanToolResponseParser.h"

extern NSString *const kATError;
extern NSString *const kResponseFinished;
extern NSString *const kOK;
extern NSString *const kNoData;


#define CLEAR_DECODE_BUF()						memset(_decodeBuf, 0x00, sizeof(_decodeBuf)); _decodeBufLength = 0;

#define kResponseFinishedCode					0x3E
#define ELM_READ_COMPLETE(buf, end)				(buf[end] == kResponseFinishedCode)


#define ELM_OK(str)								strncasecmp(str, "OK", 2)
#define ELM_ERROR(str)							!strncasecmp(str, "?", 1)
#define ELM_NO_DATA(str)						!strncasecmp(str, "NO DATA", 7)
#define ELM_SEARCHING(str)						!strncasecmp(str, "SEARCHING...", 12)
#define ELM_DATA_RESPONSE(str)					isdigit((int)*str) || ELM_SEARCHING(str)
#define ELM_AT_RESPONSE(str)					isalpha((int)*str)


@interface ELM327ResponseParser : FLScanToolResponseParser {
	
	// Buffer to hold the decoded ASCII stream from the ELM
	uint8_t							_decodeBuf[256];
	NSInteger						_decodeBufLength;
}

- (NSString*) stringForResponse;

@end
