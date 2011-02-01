/*
 *  FLECUSensor.h
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



//------------------------------------------------------------------------------
// Macros

// Macro to test if a given PID, when decoded, is an 
// alphanumeric string instead of a numeric value
#define IS_ALPHA_VALUE(pid)				(pid == 0x03 || pid == 0x12 || pid == 0x13 || pid == 0x1C || pid == 0x1D || pid == 0x1E)

// Macro to test if a given PID has two measurements in the returned data
#define IS_MULTI_VALUE_SENSOR(pid)		(pid >= 0x14 && pid <= 0x1B) || \
										(pid >= 0x24 && pid <= 0x2B) || \
										(pid >= 0x34 && pid <= 0x3B)


#define IS_INT_VALUE(pid, sensor)		((pid >= 0x04 && pid <= 0x13) || \
										 (pid >= 0x1F && pid <= 0x23) || \
										 (pid >= 0x2C && pid <= 0x33) || \
										 (pid >= 0x3C && pid <= 0x3F) || \
										 (pid >= 0x43 && pid <= 0x4E) || \
										 (pid >= 0x14 && pid <= 0x1B && sensor == 2) || \
										 (pid >= 0x24 && pid <= 0x2B && sensor == 2) || \
										 (pid >= 0x34 && pid <= 0x3B && sensor == 2))
										 
	


#define DTC_SYSTEM_MASK					0xC0
#define DTC_DIGIT_0_1_MASK				0x3F
#define DTC_DIGIT_2_3_MASK				0xFF


//------------------------------------------------------------------------------
// Calculation and Convertions Function Pointers

/* A function pointer definition for calculation functions */
typedef float(*pfCalculateValueFunc)(const void*, int);

/* A function pointer definition for conversion functions */
typedef float(*pfConvertFunc)(float);


//------------------------------------------------------------------------------
// Sensor Descriptor Structures

/* A structure to house a description of the type and range of a given sensor */
typedef struct sensor_descriptor_t {
	const char*				description;
	const char*				shortDescription;
	const char*				metricUnit;
	int						minMetricValue;
	int						maxMetricValue;	
	const char*				imperialUnit;
	int						minImperialValue;
	int						maxImperialValue;
	pfCalculateValueFunc	calcFunction;
	pfConvertFunc			convertFunction;
} SensorDescriptor;


/*
 Some PIDs will return two measurements, thus we must take this into
 consideration as we build our decoding table.
 */
typedef struct multi_sensor_t {
	unsigned int				pid;
	struct sensor_descriptor_t	sensorDescriptor1;
	struct sensor_descriptor_t	sensorDescriptor2;
} MultiSensorDescriptor;

typedef struct trouble_code_t {
	unsigned int system		:2;
	unsigned int category	:2;
	unsigned int vehicleArea:4;
	unsigned int codeHigh	:4;
	unsigned int codeLow	:4;
} DiagnosticTroubleCode;


//------------------------------------------------------------------------------
// Sensor

@interface FLECUSensor : NSObject {
	
	NSUInteger				_pid;
	MultiSensorDescriptor*	_sensorDescriptor;
	FLScanToolResponse*		_currentResponse;
	NSMutableArray*			_sensorValueHistory;
	NSUInteger				_valueHistoryHead;
	NSUInteger				_valueHistoryTail;
}


@property(nonatomic, retain) FLScanToolResponse* currentResponse;
@property(nonatomic, readonly) NSArray* valueHistory;
@property(nonatomic, readonly) BOOL isAlphaValue;
@property(nonatomic, readonly) BOOL isMultiValue;
@property(nonatomic, readonly) NSUInteger pid;
@property(nonatomic, readonly) NSData* data;

@property(nonatomic, readonly) NSString* descriptionStringForMeasurement1;
@property(nonatomic, readonly) NSString* shortDescriptionStringForMeasurement1;
@property(nonatomic, readonly) NSString* descriptionStringForMeasurement2;
@property(nonatomic, readonly) NSString* shortDescriptionStringForMeasurement2;
@property(nonatomic, readonly) NSString* metricUnitString;
@property(nonatomic, readonly) NSString* imperialUnitString;
@property(nonatomic, readonly) NSInteger maxValueForMetricMeasurement1;
@property(nonatomic, readonly) NSInteger minValueForMetricMeasurement1;
@property(nonatomic, readonly) NSInteger maxValueForImperialMeasurement1;
@property(nonatomic, readonly) NSInteger minValueForImperialMeasurement1;
@property(nonatomic, readonly) NSInteger maxValueForMetricMeasurement2;
@property(nonatomic, readonly) NSInteger minValueForMetricMeasurement2;
@property(nonatomic, readonly) NSInteger maxValueForImperialMeasurement2;
@property(nonatomic, readonly) NSInteger minValueForImperialMeasurement2;


+ (FLECUSensor*) sensorForPID:(NSUInteger)pid;

+ (NSArray*) troubleCodesForResponse:(FLScanToolResponse*)response;

- initWithDescriptor:(MultiSensorDescriptor*)descriptor;

- (id) valueForMeasurement1:(BOOL)metric;
- (id) valueForMeasurement2:(BOOL)metric;

- (NSString*) valueStringForMeasurement1:(BOOL)metric;
- (NSString*) valueStringForMeasurement2:(BOOL)metric;
- (NSString*) unitStringForMeasurement1:(BOOL)metric;
- (NSString*) unitStringForMeasurement2:(BOOL)metric;

- (NSInteger) minValueForMeasurement1:(BOOL)metric;
- (NSInteger) minValueForMeasurement2:(BOOL)metric;
- (NSInteger) maxValueForMeasurement1:(BOOL)metric;
- (NSInteger) maxValueForMeasurement2:(BOOL)metric;

- (NSString*) minValueStringForMeasurement1:(BOOL)metric;
- (NSString*) minValueStringForMeasurement2:(BOOL)metric;
- (NSString*) maxValueStringForMeasurement1:(BOOL)metric;
- (NSString*) maxValueStringForMeasurement2:(BOOL)metric;


- (BOOL) isMILActive;
- (NSInteger) troubleCodeCount;
@end

//------------------------------------------------------------------------------
#pragma mark -
#pragma mark Global Calculation Functions


/*!
 @method calcInt
 */
static inline float calcInt(const void* data, int len) {
	unsigned char* dataBytes = (unsigned char*)data;
	return (float)((int)dataBytes[0]);
}

/*!
 @method calcTime
 */
static inline float calcTime(const void* data, int len) {
	unsigned char* dataBytes = (unsigned char*)data;
	return(float)((int)(dataBytes[0] * 256) + dataBytes[1]);
}

/*!
 @method calcTimingAdvance
 */
static inline float calcTimingAdvance(const void*data, int len) {
	unsigned char* dataBytes	= (unsigned char*)data;
	float dataA					= (float)dataBytes[0];
	
	return (dataA / 2) - 64;
}


/*!
 @method calcDistance
 */
static inline float calcDistance(const void* data, int len) {
	unsigned char* dataBytes = (unsigned char*)data;
	return(float)((int)(dataBytes[0] * 256) + dataBytes[1]);
}

/*!
 @method calcPercentage
 */
static inline float calcPercentage(const void* data, int len) {
	unsigned char* dataBytes	= (unsigned char*)data;
	float pct					= (float)(dataBytes[0]);
	return (pct * 100) / 255;
}

/*!
 @method calcAbsoluteLoadValue
 */
static inline float calcAbsoluteLoadValue(const void* data, int len) {
	unsigned char* dataBytes	= (unsigned char*)data;
	float dataA					= (float)dataBytes[0];
	float dataB					= (float)dataBytes[1];
	
	return (((dataA * 256) + dataB) * 100) / 255;
}

/*!
 @method calcTemp
 */
static inline float calcTemp(const void* data, int len) {
	unsigned char* dataBytes	= (unsigned char*)data;
	float temp					= (float)dataBytes[0];
	
	return temp - 40;
}	

/*!
 @method calcCatalystTemp
 */
static inline float calcCatalystTemp(const void* data, int len) {
	unsigned char* dataBytes	= (unsigned char*)data;
	float dataA					= (float)dataBytes[0];
	float dataB					= (float)dataBytes[1];
	
	return (((dataA * 256) + dataB) / 10) - 40;
}

/*!
 @method calcFuelTrimPercentage
 */
static inline float calcFuelTrimPercentage(const void* data, int len) {
	unsigned char* dataBytes	= (unsigned char*)data;
	float value					= (float)dataBytes[0];
	
	return (0.7812 * (value - 128));
}		

/*!
 @method calcFuelTrimPercentage2
 */
static inline float calcFuelTrimPercentage2(const void* data, int len) {
	unsigned char* dataBytes	= (unsigned char*)data;
	float value					= (float)dataBytes[1];
	
	return (0.7812 * (value - 128));
}

/*!
 @method calcEngineRPM
 */
static inline float calcEngineRPM(const void* data, int len) {
	unsigned char* dataBytes	= (unsigned char*)data;
	int dataA					= (int)dataBytes[0];
	int dataB					= (int)dataBytes[1];
	
	return (((dataA * 256) + dataB) / 4);	
}
	
/*!
 @method calcOxygenSensorVoltage
 */
static inline float calcOxygenSensorVoltage(const void* data, int len) {
	unsigned char* dataBytes	= (unsigned char*)data;
	float dataA					= (float)dataBytes[0];
	
	return (dataA * 0.005);
}

/*!
 @method calcControlModuleVoltage
 */
static inline float calcControlModuleVoltage(const void* data, int len) {
	unsigned char* dataBytes	= (unsigned char*)data;
	int dataA					= (int)dataBytes[0];
	int dataB					= (int)dataBytes[1];
	
	return (((dataA * 256) + dataB) / 1000);
}

/*!
 @method calcMassAirFlow
 */
static inline float calcMassAirFlow(const void* data, int len) {
	unsigned char* dataBytes	= (unsigned char*)data;
	float dataA					= (float)dataBytes[0];
	float dataB					= (float)dataBytes[1];
	
	return (((dataA * 256) + dataB) / 100);	
}


/*!
 @method calcPressure
 */
static inline float calcPressure(const void* data, int len) {
	unsigned char* dataBytes	= (unsigned char*)data;
	float dataA					= (float)dataBytes[0];
	float dataB					= (float)dataBytes[1];
	
	return (((dataA * 256) + dataB) * 0.079f);
}

/*!
 @method calcPressureDiesel
 */
static inline float calcPressureDiesel(const void* data, int len) {
	unsigned char* dataBytes	= (unsigned char*)data;
	float dataA					= (float)dataBytes[0];
	float dataB					= (float)dataBytes[1];
	
	return (((dataA * 256) + dataB) * 10);
}

/*!
 @method calcVaporPressure
 */
static inline float calcVaporPressure(const void* data, int len) {
	unsigned char* dataBytes	= (unsigned char*)data;
	float dataA					= (float)dataBytes[0];
	float dataB					= (float)dataBytes[1];
	
	return ((((dataA * 256) + dataB) / 4) - 8192);
}

/*!
 @method calcEquivalenceRatio
 */
static inline float calcEquivalenceRatio(const void* data, int len) {
	unsigned char* dataBytes	= (unsigned char*)data;
	float dataA					= (float)dataBytes[0];
	float dataB					= (float)dataBytes[1];
	
	return (((dataA * 256) + dataB) * 0.0000305f);	
}

/*!
 @method calcEquivalenceVoltage
 */
static inline float calcEquivalenceVoltage(const void* data, int len) {
	unsigned char* dataBytes	= (unsigned char*)data;
	float dataC					= (float)dataBytes[2];
	float dataD					= (float)dataBytes[3];
	
	return (((dataC * 256) + dataD) * 0.000122f);
}

/*!
 @method calcEquivalenceCurrent
 */
static inline float calcEquivalenceCurrent(const void* data, int len) {
	unsigned char* dataBytes	= (unsigned char*)data;
	float dataC					= (float)dataBytes[2];
	float dataD					= (float)dataBytes[3];
	
	return (((dataC * 256) + dataD) * 0.00390625f) - 128;
}

/*!
 @method calcEGRError
 */
static inline float calcEGRError(const void* data, int len) {
	unsigned char* dataBytes	= (unsigned char*)data;
	float dataA					= (float)dataBytes[0];
	
	return ((dataA*0.78125f) - 100);
}

/*!
 @method calcInstantMPG
 */
static inline double calcInstantMPG(double vss, double maf) {
	 
	if(vss > 255) {
		vss = 255;
	}
	 
	if(vss < 0) {
		vss = 0;
	}
		 
	 
	if(maf <= 0) {
		maf = 0.1;
	}
	 
	double mpg	= 0.0;
	double mph	= (vss * 0.621371); // convert KPH to MPH
	
	mpg			= ((14.7 * 6.17 * 454 * mph) / (3600 * maf));
	
	return mpg;
}


static inline int calcMILActive (const void* data, int len) {
	unsigned char* dataBytes	= (unsigned char*)data;	
	if(dataBytes == NULL || len < 4) {
		return 0;
	}
	
	return ((dataBytes[0] & 0x80) != 0) ? 1 : 0;
}


static inline int calcNumTroubleCodes (const void* data, int len) {
	unsigned char* dataBytes	= (unsigned char*)data;
	if(dataBytes == NULL || len < 4) {
		return 0;
	}
	
	int dataA = dataBytes[0] & 0x7F; // mask bit 7
	
	return dataA;
}


//------------------------------------------------------------------------------
#pragma mark -
#pragma mark Global Conversion Functions

/*
 @method convertTemp
 @param value: the temperature in degress Celsius (C)
 @return: the temperature in degrees Fahrenheit (F)
 */
static inline float convertTemp(float value) {
	return ((value * 9) / 5) + 32;
}


/*
 @method convertPressure
 @param value: the pressure in kiloPascals (kPa)
 @return: the pressure in inches of Mercury (inHg)
 */
static inline float convertPressure(float value) {
	return (value / 3.38600);
}


/*
 @method convertPressure2
 @param value: the pressure in Pascals (Pa)
 @return: the pressure in inches of Mercury (inHg)
 */
static inline float convertPressure2(float value) {
	return (value / 3386);
}


/*
 @method convertSpeed
 @param value: the speed in kilometers per hour (km/h)
 @return: the speed in miles per hour (mph)
 */
static inline float convertSpeed(float value) {
	return (value * 62) / 100.0;
}


/*
 @method convertAir
 @param value: the air flow in grams per second (g/s)
 @return: the air flow in pounds per minute (lb/min)
 */
static inline float convertAir(float value) {
	return (value * 132) / 1000.0;
}

/*
 @method convertDistance
 @param value: the distance in Km
 @return: the distance in Miles
 */
static inline float convertDistance(float value) {
	return (value * 0.6213);
}