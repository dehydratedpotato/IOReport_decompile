// half-yolo'd decompile of a portion  of libIOReport.dylib
//
#include <Foundation/Foundation.h>
#include <objc/runtime.h>

#include "IOReport.h"
#include "IOReportTypes.h"
#include "IOKernelReportStructs.h"

/* Macros for hub userclient methods
 */
#define kIOReportUserClientOpen                 0
#define kIOReportUserClientConfigureInterests   2
#define kIOReportUserClientUpdateKernelBuffer   3

/* Missing constants for dictionary stuff */
#define kDriverIdKey CFSTR("DriverID")
#define kDrivernameKey CFSTR("DriverName")
#define kRawElementskey CFSTR("RawElements")
#define kStatenamesKey CFSTR("StateNames")

#define kIOReportRawElementChunkSize 64

/* CFRuntime extern syms
 * IOReportSubscription uses this stuff.
 */
typedef struct __CFRuntimeClass {
    CFIndex version;
    const char *className;
    void (*init)(CFTypeRef cf);
    CFTypeRef (*copy)(CFAllocatorRef allocator, CFTypeRef cf);
    void (*finalize)(CFTypeRef cf);
    Boolean (*equal)(CFTypeRef cf1, CFTypeRef cf2);
    CFHashCode (*hash)(CFTypeRef cf);
    CFStringRef (*copyFormattingDesc)(CFTypeRef cf, CFDictionaryRef formatOptions);
    CFStringRef (*copyDebugDesc)(CFTypeRef cf);
    void (*reclaim)(CFTypeRef cf);
} CFRuntimeClass;

typedef struct __CFRuntimeBase {
    uintptr_t _cfisa;
    uint8_t _cfinfo[4];
#if __LP64__
    uint32_t _rc;
#endif
} CFRuntimeBase;

CFTypeID __CFGenericTypeID(void *cf);

const CFRuntimeClass* _CFRuntimeGetClassWithTypeID(CFTypeID typeID);

CFTypeID _CFRuntimeRegisterClass(const CFRuntimeClass* const cls);
CFTypeRef _CFRuntimeCreateInstance(CFAllocatorRef allocator,
                                   CFTypeID typeID,
                                   CFIndex extraBytes,
                                   unsigned char* category);
/* subscription decompile
 */
static CFRuntimeClass _IOReportSubscriptionClass = { 0, "IOReportSubscription" };
struct IOReportSubscription {
    CFRuntimeBase base;       /* cfruntime base */
    io_connect_t connection;  /* userclient connection */
    uint64_t dwordPtr;        /* dword pointer, seems always empty */
    mach_vm_address_t addr;   /* addr to data from userclient*/
    mach_vm_size_t addrSize;  /* data size */
};

struct _IOReportRawElement {
    int64_t value;
    uint64_t reserved;
    IOReportFormat type;
};

struct _IOReportSimpleInteger {
    int64_t value;
    uint64_t reserved_a;
    IOReportFormat type;
    uint8_t align;
    uint16_t reserved_b;
    uint64_t reserved_c;
    int64_t qword;
};

// MARK: Channel Functions
/* Filter the IOReg for properties with ioreport legends. We reuse this for copying channels in group,
 * then pass NULL to use for copying everything. This is different than libIOReport which reads all and then filters.
 */
CFMutableDictionaryRef _copy_chann(NSString* group) {
    CFMutableDictionaryRef dict = CFDictionaryCreateMutable(kCFAllocatorDefault, 0, NULL, NULL);
    CFMutableArrayRef channels = CFArrayCreateMutable(kCFAllocatorDefault, 0, NULL);
    
    io_iterator_t iter;
    kern_return_t kr;
    io_registry_entry_t entry;
    mach_port_t port;
    
    if (@available(macOS 12, *)) port = kIOMainPortDefault;
    else port = kIOMasterPortDefault;
    
    kr = IORegistryCreateIterator(port, kIOServicePlane, kIORegistryIterateRecursively, &iter);
    if (kr != kIOReturnSuccess) return NULL;
    
    while ((entry = IOIteratorNext(iter)) != IO_OBJECT_NULL) {
        char name[56];
        uint64_t entid;

        CFArrayRef legend = (CFArrayRef) IORegistryEntryCreateCFProperty(entry, CFSTR(kIOReportLegendKey), kCFAllocatorDefault, 0);
        if (legend == NULL) continue;
        
        for (int i = 0; i < CFArrayGetCount(legend); i++) {
            CFDictionaryRef key = CFArrayGetValueAtIndex(legend, i);
            
            if (CFDictionaryContainsValue(key, (CFStringRef) group ) || group == NULL) {
                CFArrayRef chann_array = CFDictionaryGetValue(key, CFSTR(kIOReportLegendChannelsKey));
                
                IORegistryEntryGetName(entry, name);
                IORegistryEntryGetRegistryEntryID(entry, &entid);
                NSString* dname = [[NSString alloc] initWithFormat:@"%s <id: 0x%.2llx>", name, entid];
                
                for (int ii = 0; ii < CFArrayGetCount(chann_array); ii++) {
                    CFMutableDictionaryRef subbdict = CFDictionaryCreateMutable(kCFAllocatorDefault, 0, NULL, NULL);
                    
                    CFDictionaryAddValue(subbdict, kDriverIdKey, CFNumberCreate(kCFAllocatorDefault, kCFNumberLongLongType, &entid));
                    
                    // TODO: uncomment this. for some reason it's value is mutated after the loops are done and turns it into an array???
//                    CFDictionaryAddValue(subbdict, kDrivernameKey, (CFStringRef) dname);
                    
                    CFDictionaryAddValue(subbdict, CFSTR(kIOReportLegendInfoKey), CFDictionaryGetValue(key, CFSTR(kIOReportLegendInfoKey)));
                    CFDictionaryAddValue(subbdict, CFSTR(kIOReportLegendGroupNameKey), CFDictionaryGetValue(key, CFSTR(kIOReportLegendGroupNameKey)));
                    CFDictionaryAddValue(subbdict, CFSTR(kIOReportLegendSubGroupNameKey), CFDictionaryGetValue(key, CFSTR(kIOReportLegendSubGroupNameKey)));
                    CFDictionaryAddValue(subbdict, CFSTR(kIOReportLegendChannelsKey), CFArrayGetValueAtIndex(chann_array, ii));
                    
                    CFArrayAppendValue(channels, subbdict);
                }
            }
        }
    }
    
    IOObjectRelease(iter);
    
    if (CFArrayGetCount(channels) != 0)
        CFDictionarySetValue(dict, CFSTR(kIOReportLegendChannelsKey), channels);
    
    CFDictionarySetValue(dict, CFSTR("QueryOpts"), CFSTR("0"));
    
    return dict;
}

/* Ignoring a,b,c params for now because they just add uneeded complexity to the returned format
 */
CFMutableDictionaryRef IOReportCopyChannelsInGroup(NSString* group, NSString* subgroup, uint64_t a, uint64_t b, uint64_t c) {
    return _copy_chann(group);
}
CFMutableDictionaryRef IOReportCopyAllChannels(uint64_t a, uint64_t b) {
    return _copy_chann(NULL);
}

// MARK: Subscription Functions
/* This helps determine what exactly we want to subscribe to from the hub userclient.
 * Originally this may have been a code block for some reason.
 */
IOReportInterestList* _create_interlist(CFArrayRef channels, int count) {
    IOReportInterestList * interestList = malloc(count * 0x18 + 8);
    interestList->ninterests = count;
    
    for (int i = 0; i < count; i++) {
        uint64_t channel_id = 0;
        uint64_t provider_id = 0;
        uint64_t channel_type_raw = 0;

        CFDictionaryRef chann = (CFDictionaryRef) CFArrayGetValueAtIndex(channels, i);
        CFArrayRef legend_chann = (CFArrayRef) CFDictionaryGetValue(chann, CFSTR(kIOReportLegendChannelsKey));
        
        CFNumberRef legend_channel_id = CFArrayGetValueAtIndex(legend_chann, kIOReportChannelIDIdx);
        CFNumberGetValue(legend_channel_id, kCFNumberLongType, &channel_id);
        
        CFNumberRef legend_channel_type = CFArrayGetValueAtIndex(legend_chann, kIOReportChannelTypeIdx);
        CFNumberGetValue(legend_channel_type, kCFNumberLongType, &channel_type_raw);
        IOReportChannelType channel_type = *(IOReportChannelType*)&channel_type_raw;
    
        IOReportChannel channel = {
            .channel_id = channel_id,
            .channel_type = channel_type
        };
        
        CFNumberRef driver_id = CFDictionaryGetValue(chann, kDriverIdKey);
        CFNumberGetValue(driver_id, kCFNumberLongLongType, &provider_id);
        
        IOReportInterest interest = {
            .provider_id = provider_id,
            .channel = channel
        };
        
        interestList->interests[i] = interest;
    }
    
    return interestList;
}

IOReportSubscriptionRef IOReportCreateSubscription(void* a,
                                                   CFMutableDictionaryRef desiredChannels,
                                                   CFMutableDictionaryRef* subbedChannels,
                                                   uint64_t channel_id,
                                                   CFTypeRef b) {
    uint32_t                   count = 0;
    CFTypeID                   iorepTypeId;
    IOReportSubscriptionRef    iorepSubscription = NULL;
    kern_return_t              kr;
    io_iterator_t              iter;
    io_service_t               service = 0;
    io_connect_t               connection = 0;
    mach_port_t                port;
    
    if (@available(macOS 12, *)) port = kIOMainPortDefault;
    else port = kIOMasterPortDefault;
    
    count = IOReportGetChannelCount(desiredChannels);
    
    if (count <= 0) return NULL;
    uint32_t input = count * 0x18 + 8;
    uint32_t output = 1;
    
    /* Init the subs types
     */
    iorepTypeId       = _CFRuntimeRegisterClass(&_IOReportSubscriptionClass);
    iorepSubscription = (IOReportSubscriptionRef)_CFRuntimeCreateInstance(a, iorepTypeId, 0x20, 0);
    
    /* prep interset list
     */
    CFArrayRef channs = (CFArrayRef) CFDictionaryGetValue(desiredChannels, CFSTR(kIOReportLegendChannelsKey));
    IOReportInterestList* interestList = _create_interlist(channs, count);
    
    /* match IOReportHub and open it up
     */
    kr = IOServiceGetMatchingServices(port, IOServiceMatching("IOReportHub"), &iter);
    if (kr != KERN_SUCCESS) {
        //NSLog(@"Could not match IOReportHub, failed with %s", mach_error_string(kr));
        return NULL;
    }
    while ((service = IOIteratorNext(iter)) != IO_OBJECT_NULL) {
        kr = IOServiceOpen(service, mach_task_self(), 0, &connection);
        if (kr != KERN_SUCCESS) {
            //NSLog(@"Could not open IOReportHub, failed with %s", mach_error_string(kr));
            goto exit;
        }
        break;
    }
    IOObjectRelease(iter);
    
    /* open the userclient for communication
     */
    kr = IOConnectCallScalarMethod(connection, kIOReportUserClientOpen, 0, 0, 0, 0);
    if (kr != KERN_SUCCESS) {
        //NSLog(@"kIOReportUserClientOpen failed with %s", mach_error_string(kr));
        goto exit;
    }
    IOObjectRelease(service);
    
    iorepSubscription->connection = connection;
    
    /* config interests so the hub knows what data to provide
     */
    kr = IOConnectCallMethod(iorepSubscription->connection,
                             kIOReportUserClientConfigureInterests,
                             NULL, 0,
                             interestList,
                             input,
                             &iorepSubscription->dwordPtr,
                             &output,
                             NULL, 0);
    if (kr != KERN_SUCCESS) {
        //NSLog(@"kIOReportUserClientConfigureInterests failed with %s", mach_error_string(kr));
        
        free(interestList);
        goto exit;
    }
    
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wconversion"
    /* map memory from the user client so we may get our datas later
     */
    kr = IOConnectMapMemory(iorepSubscription->connection,
                            iorepSubscription->dwordPtr,
                            mach_task_self(),
                            &iorepSubscription->addr,
                            &iorepSubscription->addrSize, 1);
    
    if (kr != KERN_SUCCESS) {
        //NSLog(@"IOConnectMapMemory) failed with %s", mach_error_string(kr));
        IOConnectUnmapMemory(connection,
                             iorepSubscription->dwordPtr,
                             mach_task_self(),
                             iorepSubscription->addr);
        free(interestList);
        goto exit;
    }
#pragma clang diagnostic pop
    
exit:
    IOServiceClose(service);
    return iorepSubscription;
}

// MARK: Sampling Functions
// TODO: - Find State Names for State Formatted channels

CFDictionaryRef IOReportCreateSamples(IOReportSubscriptionRef iorsub, CFMutableDictionaryRef subbedChannels, CFTypeRef a) {
    if (iorsub == NULL && subbedChannels == NULL) return NULL;
    if (iorsub->connection == 0) return NULL;
    
    /* get datas
     */
    kern_return_t kr = IOConnectCallMethod(iorsub->connection, kIOReportUserClientUpdateKernelBuffer,
                                           &iorsub->dwordPtr, 1, 0, 0, 0, 0, 0, 0);
    if (kr != KERN_SUCCESS) {
        //NSLog(@"_updateKernelBuffer() failed failed with %s", mach_error_string(kr));
        return NULL;
    }
    
//    IOServiceClose(iorsub->connection);
    
    CFMutableDictionaryRef channels = CFDictionaryCreateMutableCopy(0, 2, subbedChannels);
    CFMutableArrayRef array = (CFMutableArrayRef) CFDictionaryGetValue(channels, CFSTR(kIOReportLegendChannelsKey));

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wconversion"
    CFDataRef deets = CFDataCreateWithBytesNoCopy(0, iorsub->addr, iorsub->addrSize, kCFAllocatorNull);
#pragma clang diagnostic pop
    
    int byteIndex = 0;
    
    for (int i = 0; i < IOReportGetChannelCount(subbedChannels); i++) {
        CFMutableDictionaryRef channelArrayDict = (CFMutableDictionaryRef) CFArrayGetValueAtIndex(array, i);
        uint64_t channel_type_ptr = 0;
        
        CFArrayRef legend_chann = (CFArrayRef) CFDictionaryGetValue(channelArrayDict, CFSTR(kIOReportLegendChannelsKey));
        CFNumberRef legend_chann_type = CFArrayGetValueAtIndex(legend_chann, kIOReportChannelTypeIdx);
        CFNumberGetValue(legend_chann_type, kCFNumberLongType, &channel_type_ptr);
        IOReportChannelType* channel_type = (IOReportChannelType*)&channel_type_ptr;
        
        long size = channel_type->nelements * 64;
        UInt8 buf[size];
        CFRange range = CFRangeMake(byteIndex * 64, size);
        CFDataGetBytes(deets, range, buf);
        CFDataRef bytes = CFDataCreateWithBytesNoCopy(0, buf, size, kCFAllocatorNull);
        
        CFDictionaryAddValue(channelArrayDict, kRawElementskey, bytes);
        
        CFDictionaryAddValue(channelArrayDict, kStatenamesKey, CFSTR("")); // TODO: Setup
        
        CFArraySetValueAtIndex(array, i, channelArrayDict);
        
//        CFDictionarySetValue(channels, kIOReportChannelsKey, array);
        
        byteIndex += channel_type->nelements;
        
//        CFRelease(bytes);
        channel_type = nil;
    }
    
    CFDictionarySetValue(channels, CFSTR(kIOReportLegendChannelsKey), array);
    
//    CFRelease(deets);
    
    return channels;
}

// MARK: Iterating Functions

void IOReportIterate(CFDictionaryRef samples, IOReportiterateblock handler) {
    if (samples == NULL) return;
    
    uint32_t count = IOReportGetChannelCount(samples);
    CFArrayRef array = (CFArrayRef) CFDictionaryGetValue(samples, CFSTR(kIOReportLegendChannelsKey));
    
    for (int i = 0; i < count; i++) {
        IOReportSampleRef channel = (IOReportSampleRef) CFArrayGetValueAtIndex(array, i);

        int ret = handler(channel);
        if (ret == re_kIOReportIterFailed) return;
    }
}

// MARK: Iteration exclusive functions for samples

int IOReportGetChannelCount(CFDictionaryRef a) {
    if (a == NULL) return 0;
    CFArrayRef channArray = CFDictionaryGetValue(a, CFSTR(kIOReportLegendChannelsKey));
    int count =  (int) CFArrayGetCount(channArray);
    return count;
}

NSString* IOReportChannelGetChannelName(CFDictionaryRef a) {
    if (a == NULL) return NULL;
    CFArrayRef arr = (CFArrayRef) CFDictionaryGetValue(a, CFSTR(kIOReportLegendChannelsKey));
    NSString * str = (NSString*) CFArrayGetValueAtIndex(arr, kIOReportChannelNameIdx);
    return str;
}

NSString* IOReportChannelGetGroup(CFDictionaryRef a) {
    if (a == NULL) return NULL;
    NSString * str = (NSString*) CFDictionaryGetValue(a,CFSTR(kIOReportLegendGroupNameKey));
    return str;
}

NSString* IOReportChannelGetSubGroup(CFDictionaryRef a) {
    if (a == NULL) return NULL;
    NSString * str = (NSString*) CFDictionaryGetValue(a,CFSTR(kIOReportLegendSubGroupNameKey));
    return str;
}

NSString* IOReportChannelGetDriverName(CFDictionaryRef a) {
    if (a == NULL) return NULL;
    NSString * str = (NSString*) CFDictionaryGetValue(a, kDrivernameKey);
    
    return str;
}

int IOReportChannelGetFormat(CFDictionaryRef samples) {
    if (samples == NULL) return 0;
    
    uint64_t channel_type_ptr = 0;

    CFArrayRef legend_chann = (CFArrayRef) CFDictionaryGetValue(samples, CFSTR(kIOReportLegendChannelsKey));
    CFNumberRef legend_chann_type = CFArrayGetValueAtIndex(legend_chann, kIOReportChannelTypeIdx);
    CFNumberGetValue(legend_chann_type, kCFNumberLongLongType, &channel_type_ptr);
    IOReportChannelType* channel_type = (IOReportChannelType*)&channel_type_ptr;

    return (int)channel_type->report_format;
}

NSString* IOReportChannelGetUnitLabel(CFDictionaryRef a) {
    if (a == NULL) return NULL;

    uint64_t unit_label_qword = 0;
    
    CFDictionaryRef chann_inf = (CFDictionaryRef) CFDictionaryGetValue(a, CFSTR(kIOReportLegendInfoKey));
    CFNumberRef unit_label = CFDictionaryGetValue(chann_inf, CFSTR(kIOReportLegendUnitKey));
    
    CFNumberGetValue(unit_label, kCFNumberLongLongType, &unit_label_qword);
    
    switch (unit_label_qword) {
        case kIOReportUnit1GHzTicks:
            return @"1GTicks";
        case kIOReportUnit24MHzTicks:
            return @"24MTicks";
        case kIOReportUnitHWTicks:
            return @"HWTicks";
        case kIOReportUnitPackets:
            return @"packets";
        case kIOReportUnitInstrs:
            return @"instrs";
        case kIOReportUnitEvents:
            return @"events";
        case kIOReportUnitBits:
            return @"bits";
        case kIOReportUnitBytes:
            return @"bytes";
        case kIOReportUnit_GI:
            return @"gi";
        case kIOReportUnit_KI:
            return @"ki";
        case kIOReportUnit_MI:
            return @"mi";
        case kIOReportUnit_ms:
            return @"ms";
        case kIOReportUnit_ns:
            return @"ns";
        case kIOReportUnit_s:
            return @"s";
        case kIOReportUnit_J:
            return @"j";
        case kIOReportUnit_mJ:
            return @"mj";
        case kIOReportUnit_pJ:
            return @"pj";
        case kIOReportUnit_uJ:
            return @"uj";
        case kIOReportUnit_nJ:
            return @"nj";
        case kIOReportUnit_GiB:
            return @"gib";
        case kIOReportUnit_MiB:
            return @"mib";
        case kIOReportUnit_KiB:
            return @"kib";
        case kIOReportUnitNone:
        default:
            return NULL;
    }
}

long IOReportStateGetCount(CFDictionaryRef a) {
    if (a == NULL) return 0;
    
    CFDataRef data = CFDictionaryGetValue(a, kRawElementskey);
    long length = CFDataGetLength(data);
    
    if (length == 0) return 0;
    return length / 64;
}

/* private func for reading raw elements */
struct _IOReportRawElement* _get_raw_elements(CFDictionaryRef a,
                                              int index,
                                              uint8_t type) {
    if (a == NULL) return NULL;
    
    CFDataRef data = CFDictionaryGetValue(a, kRawElementskey);
    CFMutableDataRef mutable_data;
    
    long length = CFDataGetLength(data);

    if (length != 0)
        if (length > kIOReportRawElementChunkSize) {
            
            UInt8 buf[kIOReportRawElementChunkSize];
            CFRange range = CFRangeMake(index * kIOReportRawElementChunkSize, kIOReportRawElementChunkSize);
            CFDataGetBytes(data, range, buf);
            CFDataRef bytes = CFDataCreateWithBytesNoCopy(0, buf, kIOReportRawElementChunkSize, kCFAllocatorNull);
            
            mutable_data = CFDataCreateMutableCopy(kCFAllocatorDefault, kIOReportRawElementChunkSize, bytes);
        } else {
            mutable_data = CFDataCreateMutableCopy(kCFAllocatorDefault, kIOReportRawElementChunkSize, data);
        }
    else {
        return 0;
    }
    
    struct _IOReportRawElement* raw = (struct _IOReportRawElement*)CFDataGetMutableBytePtr(mutable_data);

    raw->type = type;
    
    return raw;
}

long IOReportSimpleGetIntegerValue(CFDictionaryRef a, int b) {
    if (a == NULL) return 0;
    
    struct _IOReportSimpleInteger * simple_struct = (struct _IOReportSimpleInteger *)_get_raw_elements(a, b, 1 /* kIOReportFormatSimple */);

    if (simple_struct != NULL && simple_struct->type == 1 /* kIOReportFormatSimple */)
        return simple_struct->qword;

    return 0;
}

uint64_t IOReportStateGetResidency(CFDictionaryRef a, int b) {
//    if (a == NULL) return 0;
//
//    struct _IOReportSimpleInteger * simple_struct = (struct _IOReportSimpleInteger *)_get_raw_elements(a, b, 2 /* kIOReportFormatState */);
//
//    if (simple_struct != NULL && simple_struct->type == 2 /* kIOReportFormatState */)
//        return simple_struct->qword;

    return 0;
}

NSString* IOReportStateGetNameForIndex(CFDictionaryRef a, int b) {
    if (a == NULL) return NULL;
    return NULL;
}

// TODO: I haven't gotten around to decompiling this stuff
uint64_t IOReportArrayGetValueAtIndex(CFDictionaryRef a, int b) { return 0; }
int IOReportHistogramGetBucketCount(CFDictionaryRef a) { return 0; }
int IOReportHistogramGetBucketMinValue(CFDictionaryRef a, int b) { return 0; }
int IOReportHistogramGetBucketMaxValue(CFDictionaryRef a, int b) { return 0; }
int IOReportHistogramGetBucketSum(CFDictionaryRef a, int b) { return 0; }
int IOReportHistogramGetBucketHits(CFDictionaryRef a, int b) { return 0; }
