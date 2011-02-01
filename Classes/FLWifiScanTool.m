/*
 *  FLWifiScanTool.m
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

#import "FLWifiScanTool.h"
#import "NSStreamAdditions.h"
#import "FLLogging.h"


#pragma mark -
@implementation FLWifiScanTool


- (void) dealloc {
	[_inputStream release];		
	[_outputStream release];
	[_host release];
	[_cachedWriteData release];
	[super dealloc];
}

- (void) open {
	
	@try {
		[NSStream getIOStreamsToHostNamed:_host 
									 port:_port 
							  inputStream:&_inputStream 
							 outputStream:&_outputStream];
		
		[_inputStream retain];
		[_outputStream retain];
		
		[_inputStream setDelegate:self];			
		[_inputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] 
								forMode:NSDefaultRunLoopMode];
		[_inputStream open];
		

		
		[_outputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] 
								 forMode:NSDefaultRunLoopMode];
		[_outputStream setDelegate:self];
		[_outputStream open];
	}
	@catch (NSException * e) {
		FLEXCEPTION(e);
	}
}


- (void) close {
	
	@try {
		[_inputStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
		[_inputStream setDelegate:nil];
		[_inputStream close];
		
		[_outputStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
		[_outputStream setDelegate:nil];
		[_outputStream close];		
	}
	@catch (NSException * e) {
		FLEXCEPTION(e);
	}	
	@finally {
		_state = STATE_INIT;
	}
}

- (void) sendCommand:(FLScanToolCommand*)command initCommand:(BOOL)initCommand {
	FLTRACE_ENTRY
	if (!_cachedWriteData) {
        _cachedWriteData = [[NSMutableData alloc] init];
    }
	
	FLDEBUG(@"Writing command to cached data", nil)
    [_cachedWriteData appendData:[command data]];
	[self writeCachedData];
}

- (void) getResponse {
	if([_inputStream hasBytesAvailable]) {
		[self stream:_inputStream handleEvent:NSStreamEventHasBytesAvailable];
	}
}

#pragma mark -
#pragma mark NSStream Delegate Methods

- (void)stream:(NSStream*)stream handleEvent:(NSStreamEvent)eventCode {	
	// Abstract method
	[self doesNotRecognizeSelector:_cmd];
}

#pragma mark -
#pragma mark Private Methods

- (void) writeCachedData {
    
	FLTRACE_ENTRY
	
	if (_streamOperation.isCancelled) {
		return;
	}
	
	if (!_cachedWriteData) {
		FLERROR(@"No cached data to write (_cachedWriteData == nil)", nil)
		return;
	}
	
	NSOutputStream* oStream			= _outputStream;
	NSStreamStatus oStreamStatus	= NSStreamStatusError;
	NSInteger bytesWritten			= 0;
	
	FLDEBUG(@"[_cachedWriteData length] = %d", [_cachedWriteData length])
	
    while ([oStream hasSpaceAvailable] && 
		   [_cachedWriteData length] > 0) {
		
		FLDEBUG(@"_cachedWriteData = %@", [_cachedWriteData description])
		
		bytesWritten = [oStream write:[_cachedWriteData bytes]
							maxLength:[_cachedWriteData length]];
		if (bytesWritten == -1) {
			FLERROR(@"Write Error", nil)
			break;
		}
		else if(bytesWritten > 0 && [_cachedWriteData length] > 0) {
			FLDEBUG(@"Wrote %d bytes", bytesWritten)
			[_cachedWriteData replaceBytesInRange:NSMakeRange(0, bytesWritten) 
										withBytes:NULL 
										   length:0];
		}
	}
	
	oStreamStatus = [oStream streamStatus];
	FLDEBUG(@"OutputStream status = %X", oStreamStatus)
	FLINFO(@"Starting write wait")
	do {		
		oStreamStatus = [oStream streamStatus];
	} while (oStreamStatus == NSStreamStatusWriting);
	
	FLTRACE_EXIT
}

@end
