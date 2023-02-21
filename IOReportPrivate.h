//
//  IOReportPrivate.h
//  IOReportReverseEngineeringTest
//
//  Created by Taevon Turner on 2/20/23.
//

#ifndef IOReportPrivate_h
#define IOReportPrivate_h

#include "IOReport.h"

#define kIOReportUserClientOpen 0
#define kIOReportUserClientConfigureInterests 2
#define kIOReportUserClientUpdateKernelBuffer 3

// categories (IOReportTypes.h)
#define kIOReportCategoryPower           (1 << 1)       // and energy
#define kIOReportCategoryTraffic         (1 << 2)       // I/O at any level
#define kIOReportCategoryPerformance     (1 << 3)       // e.g. cycles/byte
#define kIOReportCategoryPeripheral      (1 << 4)       // not built-in
#define kIOReportCategoryField           (1 << 8)       // consider logging

// legend channel macros (IOKernelReportStructs.h)
#define kIOReportChannelIDIdx           0       // required
#define kIOReportChannelTypeIdx         1       // required
#define kIOReportChannelNameIdx         2       // optional

// categories (IOReportTypes.h)
typedef struct {
    uint8_t     report_format;  // Histogram, StateResidency, etc.
    uint8_t     reserved;       // must be zero
    uint16_t    categories;     // power, traffic, etc (omnibus obs.)
    uint16_t    nelements;      // internal size of channel

    // only meaningful in the data pipeline
    int16_t     element_idx;    // 0..nelements-1
                                // -1..-(nelements) = invalid (13127884)
} __attribute((packed)) IOReportChannelType;

typedef struct {
    uint64_t                channel_id;
    IOReportChannelType     channel_type;
} IOReportChannel;

typedef struct {
    uint64_t                provider_id;
    IOReportChannel         channel;
} IOReportInterest;

typedef struct {
    uint32_t                ninterests;
    IOReportInterest        interests[];
} IOReportInterestList;

// formats (IOReportTypes.h)
typedef uint8_t IOReportFormat;
enum {
    kIOReportInvalidFormat = 0,
    kIOReportFormatSimple = 1,
    kIOReportFormatState = 2,
    kIOReportFormatHistogram = 3,
    kIOReportFormatSimpleArray = 4
};


// class for sub
static CFRuntimeClass re_IOReportSubscriptionClass = {
    0,
    "re_IOReportSubscription"
};

#endif /* IOReportPrivate_h */
