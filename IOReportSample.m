//
//  IOReportSample.m
//  IOReport
//
//  Created by BitesPotatoBacks on 1/19/23.
//

#import <Foundation/Foundation.h>
#import "IOReportPrivate.h"

// TODO: - Find State Names for State Formatted channels
CFDictionaryRef IOReportCreateSamples(IOReportSubscriptionRef iorsub,
                                         CFMutableDictionaryRef subbedChannels,
                                         CFTypeRef a) {
   
    if (iorsub != NULL && subbedChannels != NULL) {
        if (iorsub->connection != 0) {
            kern_return_t kr = IOConnectCallMethod(iorsub->connection, kIOReportUserClientUpdateKernelBuffer, &iorsub->dwordPtr, 1, 0, 0, 0, 0, 0, 0);
            if (kr != KERN_SUCCESS) {
                NSLog(@"_updateKernelBuffer() failed failed with %s", mach_error_string(kr));
                return NULL;
            }
        } else
            return NULL;
        
        CFMutableDictionaryRef channels = CFDictionaryCreateMutableCopy(0, 2, subbedChannels);
        CFMutableArrayRef array = (CFMutableArrayRef)CFDictionaryGetValue(channels, CFSTR("IOReportChannels"));

        CFDataRef deets = CFDataCreateWithBytesNoCopy(0, iorsub->addr, iorsub->addrSize, kCFAllocatorNull);

        int byteIndex = 0;
        
        for (int i = 0; i < IOReportGetChannelCount(subbedChannels); i++) {
            CFMutableDictionaryRef channelArrayDict = (CFMutableDictionaryRef)CFArrayGetValueAtIndex(array, i);
            
            NSNumber * legend_channel_type = (NSNumber*)CFArrayGetValueAtIndex((CFArrayRef)CFDictionaryGetValue(channelArrayDict, CFSTR("LegendChannel")), kIOReportChannelTypeIdx);
            uint64_t channel_type_ptr = legend_channel_type.longValue;
            IOReportChannelType* channel_type = (IOReportChannelType*)&channel_type_ptr;
            
            long size = channel_type->nelements * 64;
            UInt8 buf[size];
            CFRange range = CFRangeMake(byteIndex * 64, size);
            CFDataGetBytes(deets, range, buf);
            CFDataRef bytes = CFDataCreateWithBytesNoCopy(0, buf, size, kCFAllocatorNull);
            
            CFDictionaryAddValue(channelArrayDict, CFSTR("RawElements"), bytes);
            
            CFDictionaryAddValue(channelArrayDict, CFSTR("StateNames"), CFSTR(""));

            CFArraySetValueAtIndex(array, i, channelArrayDict);
            
            CFDictionarySetValue(channels, CFSTR("IOReportChannels"), array);
            
            byteIndex += channel_type->nelements;
            
            CFRelease(bytes);
            channel_type = nil;
        }

        CFDictionarySetValue(channels, CFSTR("IOReportChannels"), array);
        
        CFRelease(deets);
        
        return channels;
    }
    
    return NULL;
}
