//
//  re_IOReportSample.m
//  re_IOReportReverseEngineeringTest
//
//  Created by Taevon Turner on 1/19/23.
//

#import <Foundation/Foundation.h>
#import "IOReportPrivate.h"

// TODO: - Find Unit Label and State Names for State Formatted channels, support byte lengths >64 for each channel
CFDictionaryRef re_IOReportCreateSamples(re_IOReportSubscriptionRef iorsub,
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
        
        long size = CFDataGetLength(deets);
        uint32_t count = re_IOReportGetChannelCount(subbedChannels);

        if (size / 64 == count) {
            
            for (long i = 0; i < count; i++) {
                CFMutableDictionaryRef chann = (CFMutableDictionaryRef)CFArrayGetValueAtIndex(array, i);
                CFRange range = CFRangeMake(i * 64, 64);
                UInt8 buf[size];

                CFDataGetBytes(deets, range, buf);
                CFDataRef bytes = CFDataCreateWithBytesNoCopy(0, buf, 64, kCFAllocatorNull);
                
                CFDictionaryAddValue(chann, CFSTR("RawElements"), bytes);
//                CFDictionaryAddValue(chann, CFSTR("UnitLabel"), nil);
//                CFDictionaryAddValue(chann, CFSTR("StateNames"), nil);
                CFArraySetValueAtIndex(array, i, chann);
            }
            
            CFDictionarySetValue(channels, CFSTR("IOReportChannels"), array);
            
            return channels;
        } else
            return NULL;
    }
    
    return NULL;
}
