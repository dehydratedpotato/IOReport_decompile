
#ifndef _IOREPORT_H_
#define _IOREPORT_H_

enum {
    re_kIOReportIterOk,
    re_kIOReportIterFailed,
    re_kIOReportIterSkipped
};

typedef struct IOReportSubscription* IOReportSubscriptionRef;
typedef CFDictionaryRef IOReportSampleRef;

IOReportSubscriptionRef IOReportCreateSubscription(void* a,
                                                   CFMutableDictionaryRef desiredChannels,
                                                   CFMutableDictionaryRef* subbedChannels,
                                                   uint64_t channel_id,
                                                   CFTypeRef b);

CFMutableDictionaryRef IOReportCopyChannelsInGroup(NSString* group,
                                                   NSString* subgroup,
                                                   uint64_t a,
                                                   uint64_t b,
                                                   uint64_t c);

CFMutableDictionaryRef IOReportCopyAllChannels(uint64_t a,
                                               uint64_t b);
int IOReportGetChannelCount(CFDictionaryRef a);
CFDictionaryRef IOReportCreateSamples(IOReportSubscriptionRef iorsub,
                                      CFMutableDictionaryRef subbedChannels,
                                      CFTypeRef a);

typedef int (^IOReportiterateblock)(IOReportSampleRef ch);

void IOReportIterate(CFDictionaryRef samples, IOReportiterateblock);

int IOReportChannelGetFormat(CFDictionaryRef samples);
NSString* IOReportChannelGetDriverName(CFDictionaryRef a);
NSString* IOReportChannelGetChannelName(CFDictionaryRef a);
NSString* IOReportChannelGetUnitLabel(CFDictionaryRef a);
NSString* IOReportChannelGetGroup(CFDictionaryRef a);
NSString* IOReportChannelGetSubGroup(CFDictionaryRef a);

long IOReportStateGetCount(CFDictionaryRef a);
uint64_t IOReportStateGetResidency(CFDictionaryRef a, int b);
NSString* IOReportStateGetNameForIndex(CFDictionaryRef a, int b);

uint64_t IOReportArrayGetValueAtIndex(CFDictionaryRef a, int b);

long IOReportSimpleGetIntegerValue(CFDictionaryRef a, int b);

extern int IOReportHistogramGetBucketCount(CFDictionaryRef);
extern int IOReportHistogramGetBucketMinValue(CFDictionaryRef, int);
extern int IOReportHistogramGetBucketMaxValue(CFDictionaryRef, int);
extern int IOReportHistogramGetBucketSum(CFDictionaryRef, int);
extern int IOReportHistogramGetBucketHits(CFDictionaryRef, int);

#endif /* _IOREPORT_H_ */
