/*
 *  FLLogging.h
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


#define VERBOSE_DEBUG			1
//#undef VERBOSE_DEBUG

#define CONCAT(s1, s2) s1 s2

/*
 Trace Macro
 */
#define FLTRACE(...) NSLog(__VA_ARGS__);


/*
 Function Entry Macro 
 */
#ifdef VERBOSE_DEBUG
#	define FLTRACE_ENTRY NSLog(@"[ENTRY] %s (%d)", __PRETTY_FUNCTION__, __LINE__);
#else
#	define FLTRACE_ENTRY
#endif


/*
 Function Exit Macro
 */
#ifdef VERBOSE_DEBUG
#	define FLTRACE_EXIT NSLog(@"[EXIT] %s (%d)", __PRETTY_FUNCTION__, __LINE__);
#else
#	define FLTRACE_EXIT
#endif


/*
 Informational Message
 */
#ifdef VERBOSE_DEBUG
#	define FLINFO(msg) FLTRACE(@CONCAT("[INFO] %s (%d): ", msg), __PRETTY_FUNCTION__, __LINE__)
#else
#	define FLINFO(msg)
#endif


/*
 Debug Message
 */
#ifdef VERBOSE_DEBUG
#	define FLDEBUG(fmt, ...) FLTRACE(@CONCAT("[DEBUG] %s (%d): ", fmt), __PRETTY_FUNCTION__, __LINE__, __VA_ARGS__)
#else
#	define FLDEBUG(fmt, ...)
#endif


/*
 Error Message
 */
#define FLERROR(fmt, ...) FLTRACE(@CONCAT("[ERROR] %s (%d): ", fmt), __PRETTY_FUNCTION__, __LINE__, __VA_ARGS__)


/*
 NSError trace
 */
#define FLNSERROR(err) if(err) {						\
	FLTRACE(@"[NSError] %s (%d): (%d:%@) Reason: %@",	\
		__PRETTY_FUNCTION__,							\
		__LINE__,										\
		err.code,										\
		err.domain,										\
		err.localizedDescription)						\
}


/*
 Exception Message
 */
#define FLEXCEPTION(e) if(e) {							\
	FLTRACE(@"[EXCEPTION] %s (%d): %@ (%@ || %@)",		\
		__PRETTY_FUNCTION__,							\
		__LINE__,										\
		e.name,											\
		e.reason,										\
		e.userInfo)										\
}
