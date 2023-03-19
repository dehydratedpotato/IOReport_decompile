//
//  IOReport.h
//  IOReport
//
//  Created by BitesPotatoBacks on 1/19/23.
//

#ifndef IOReport_h
#define IOReport_h

#include "CFRuntime.h"

enum {
    re_kIOReportIterOk,
    re_kIOReportIterFailed,
    re_kIOReportIterSkipped
};

struct IOReportSubscription {
    CFRuntimeBase base; // cfruntime reserved
    io_connect_t connection; // ioservice connection (for IOReportHub)
    uint64_t dwordPtr; // idk, seems reserved
    mach_vm_address_t addr; // pointer to actual data from hub
    mach_vm_size_t addrSize; // size of data from hub
};

typedef struct IOReportSubscription* IOReportSubscriptionRef;

typedef CFDictionaryRef IOReportSampleRef;

// done!
IOReportSubscriptionRef IOReportCreateSubscription(void* a,
                                                   CFMutableDictionaryRef desiredChannels,
                                                   CFMutableDictionaryRef* subbedChannels,
                                                   uint64_t channel_id,
                                                   CFTypeRef b);
// done!
CFMutableDictionaryRef IOReportCopyChannelsInGroup(NSString* group,
                                                   NSString* subgroup,
                                                   uint64_t a,
                                                   uint64_t b,
                                                   uint64_t c);
// done!
CFMutableDictionaryRef IOReportCopyAllChannels(uint64_t a,
                                               uint64_t b);
// done!
int IOReportGetChannelCount(CFDictionaryRef a);

// done!
CFDictionaryRef IOReportCreateSamples(IOReportSubscriptionRef iorsub,
                                      CFMutableDictionaryRef subbedChannels,
                                      CFTypeRef a);

typedef int (^IOReportiterateblock)(IOReportSampleRef ch);

// done!
void IOReportIterate(CFDictionaryRef samples, IOReportiterateblock);

int IOReportChannelGetFormat(CFDictionaryRef samples);
NSString* IOReportChannelGetDriverName(CFDictionaryRef a); // d
NSString* IOReportChannelGetChannelName(CFDictionaryRef a); // d
NSString* IOReportChannelGetUnitLabel(CFDictionaryRef a);
NSString* IOReportChannelGetGroup(CFDictionaryRef a); // d
NSString* IOReportChannelGetSubGroup(CFDictionaryRef a); // d

int IOReportStateGetCount(CFDictionaryRef a);
uint64_t IOReportStateGetResidency(CFDictionaryRef a, int b);
NSString* IOReportStateGetNameForIndex(CFDictionaryRef a, int b);

uint64_t IOReportArrayGetValueAtIndex(CFDictionaryRef a, int b);

long IOReportSimpleGetIntegerValue(CFDictionaryRef a, int b);

int IOReportHistogramGetBucketCount(CFDictionaryRef a);
int IOReportHistogramGetBucketMinValue(CFDictionaryRef a, int b);
int IOReportHistogramGetBucketMaxValue(CFDictionaryRef a, int b);
int IOReportHistogramGetBucketSum(CFDictionaryRef a, int b);
int IOReportHistogramGetBucketHits(CFDictionaryRef a, int b);

//typedef uint8_t IOReportFormat;

//enum {
//    kIOReportInvalidFormat = 0,
//    kIOReportFormatSimple = 1,
//    kIOReportFormatState = 2,
//    kIOReportFormatHistogram = 3,
//    kIOReportFormatSimpleArray = 4
//};

#endif /* IOReport_h */
