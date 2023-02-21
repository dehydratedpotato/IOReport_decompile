//
//  re_IOReport.h
//  re_IOReportReverseEngineeringTest
//
//  Created by Taevon Turner on 1/19/23.
//

#ifndef re_IOReport_h
#define re_IOReport_h

#include "CFRuntime.h"

enum {
    re_kIOReportIterOk,
    re_kIOReportIterFailed,
    re_kIOReportIterSkipped
};

struct re_IOReportSubscription {
    CFRuntimeBase base; // cfruntime reserved
    io_connect_t connection; // ioservice connection (for IOReportHub)
    uint64_t dwordPtr; // idk, seems reserved
    mach_vm_address_t addr; // pointer to actual data from hub
    mach_vm_size_t addrSize; // size of data from hub
};

typedef struct re_IOReportSubscription* re_IOReportSubscriptionRef;

typedef CFDictionaryRef re_IOReportSampleRef;

// done!
re_IOReportSubscriptionRef re_IOReportCreateSubscription(void* a,
                                                   CFMutableDictionaryRef desiredChannels,
                                                   CFMutableDictionaryRef* subbedChannels,
                                                   uint64_t channel_id,
                                                   CFTypeRef b);
// done!
CFMutableDictionaryRef re_IOReportCopyChannelsInGroup(NSString* group,
                                                   NSString* subgroup,
                                                   uint64_t a,
                                                   uint64_t b,
                                                   uint64_t c);
// done!
CFMutableDictionaryRef re_IOReportCopyAllChannels(uint64_t a,
                                               uint64_t b);
// done!
int re_IOReportGetChannelCount(CFDictionaryRef a);

// done!
CFDictionaryRef re_IOReportCreateSamples(re_IOReportSubscriptionRef iorsub,
                                      CFMutableDictionaryRef subbedChannels,
                                      CFTypeRef a);

typedef int (^re_IOReportiterateblock)(re_IOReportSampleRef ch);

// done!
void re_IOReportIterate(CFDictionaryRef samples, re_IOReportiterateblock);

int re_IOReportChannelGetFormat(CFDictionaryRef samples);
NSString* re_IOReportChannelGetDriverName(CFDictionaryRef a); // d
NSString* re_IOReportChannelGetChannelName(CFDictionaryRef a); // d
NSString* re_IOReportChannelGetUnitLabel(CFDictionaryRef a);
NSString* re_IOReportChannelGetGroup(CFDictionaryRef a); // d
NSString* re_IOReportChannelGetSubGroup(CFDictionaryRef a); // d

int re_IOReportStateGetCount(CFDictionaryRef a);
uint64_t re_IOReportStateGetResidency(CFDictionaryRef a, int b);
NSString* re_IOReportStateGetNameForIndex(CFDictionaryRef a, int b);

uint64_t re_IOReportArrayGetValueAtIndex(CFDictionaryRef a, int b);

long re_IOReportSimpleGetIntegerValue(CFDictionaryRef a, int b);

int re_IOReportHistogramGetBucketCount(CFDictionaryRef a);
int re_IOReportHistogramGetBucketMinValue(CFDictionaryRef a, int b);
int re_IOReportHistogramGetBucketMaxValue(CFDictionaryRef a, int b);
int re_IOReportHistogramGetBucketSum(CFDictionaryRef a, int b);
int re_IOReportHistogramGetBucketHits(CFDictionaryRef a, int b);

typedef uint8_t re_IOReportFormat;

enum {
    kre_IOReportInvalidFormat = 0,
    kre_IOReportFormatSimple = 1,
    kre_IOReportFormatState = 2,
    kre_IOReportFormatHistogram = 3,
    kre_IOReportFormatSimpleArray = 4
};

#endif /* re_IOReport_h */
