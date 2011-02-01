/*
 *  FLEAScanTool.m
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

#import "FLEAScanTool.h"
#import "FLEAController.h"
#import "FLLogging.h"

#pragma mark -
@implementation FLEAScanTool

@synthesize accessory		= _accessory,
			protocolString	= _protocolString;


- (void) dealloc {
	[_accessory release];
	[_protocolString release];
	[_cachedWriteData release];	
	[super dealloc];
}

- (void) configureScanToolAccessory:(EAAccessory*)accessory 
						forProtocol:(NSString*)protocol {
    
	[_accessory release];
    _accessory		= [accessory retain];
    
	[_protocolString release];
    _protocolString	= [[NSString alloc] initWithString:protocol];
}

- (void) open {
	
	@try {		
		_accessory	= [[[FLEAController sharedController] accessoryForProtocol:_protocolString] retain];
		FLDEBUG(@"_protocolString = %@  **_accessory.name = %@", _protocolString, _accessory.name);
		[self openSession];
	}
	@catch (NSException * e) {
		FLEXCEPTION(e);
	}
}


- (void) close {
	
	@try {
		[self closeSession];
	}
	@catch (NSException * e) {
		FLEXCEPTION(e);
	}	
	@finally {
		_state = STATE_INIT;
	}
}

- (BOOL) openSession {
	
    [_accessory setDelegate:self];
    
	
	if (!_session) {
		_session		= [[EASession alloc] initWithAccessory:_accessory 
												   forProtocol:_protocolString];
	}	
	
    if (_session) {
		
        [[_session inputStream] setDelegate:self];
        [[_session inputStream] scheduleInRunLoop:[NSRunLoop currentRunLoop] 
										  forMode:NSDefaultRunLoopMode];
        
		[[_session inputStream] open];
		
		
        [[_session outputStream] setDelegate:self];
        [[_session outputStream] scheduleInRunLoop:[NSRunLoop currentRunLoop] 
										   forMode:NSDefaultRunLoopMode];
        		
		[[_session outputStream] open];
    }
    else     {
        FLERROR(@"creating session failed", nil)
    }
	
    return (_session != nil);
}

- (void) closeSession {
    
	FLINFO(@"-------------------------------------------->>>> CLOSING EASESSION")
	
	
    [[_session inputStream] removeFromRunLoop:[NSRunLoop currentRunLoop] 
									  forMode:NSDefaultRunLoopMode];
    [[_session inputStream] setDelegate:nil];	
	[[_session inputStream] close];
    
	
    [[_session outputStream] removeFromRunLoop:[NSRunLoop currentRunLoop] 
									   forMode:NSDefaultRunLoopMode];
    [[_session outputStream] setDelegate:nil];	 
	[[_session outputStream] close];
	
    [_session release];
    _session	= nil;
	
	[_accessory setDelegate:nil];
	[_accessory release];
	_accessory	= nil;
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
	FLTRACE_ENTRY
	;
}

- (void) handleReadData {
	// Abstract method
	[self doesNotRecognizeSelector:_cmd];
}

#pragma mark -
#pragma mark EAAccessoryDelegate Methods

- (void) accessoryDidDisconnect:(EAAccessory *)accessory {
    FLDEBUG(@"the accessory was disconnected", nil)
	[self dispatchDelegate:@selector(scanToolDidDisconnect:) withObject:nil];
}


#pragma mark -
#pragma mark NSStream Delegate Methods

- (void)stream:(NSStream *)theStream handleEvent:(NSStreamEvent)streamEvent {
	switch (streamEvent) {
		case NSStreamEventNone:
			FLDEBUG(@"stream %@ event none", theStream);
			break;
		case NSStreamEventOpenCompleted:
			FLDEBUG(@"stream %@ event open completed", theStream);
			break;
		case NSStreamEventHasBytesAvailable:
			FLDEBUG(@"stream %@ event bytes available", theStream);
			[self handleReadData];
			break;
		case NSStreamEventHasSpaceAvailable:
			FLDEBUG(@"stream %@ event space available", theStream);
			//[self writeCachedData];
			break;
		case NSStreamEventErrorOccurred:
			FLDEBUG(@"stream %@ event error", theStream);
			break;
		case NSStreamEventEndEncountered:
			FLDEBUG(@"stream %@ event end encountered", theStream);
			break;
		default:
			FLERROR(@"Received unknown NSStreamEvent: %0x04X", streamEvent);
			break;
	}
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
	
	NSOutputStream* oStream			= [_session outputStream];
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
