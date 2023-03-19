//
//  IOReportIterate.m
//  IOReport
//
//  Created by BitesPotatoBacks on 1/19/23.
//

#import <Foundation/Foundation.h>
#import "IOReportPrivate.h"

//  TODO: Add prune func

void IOReportIterate(CFDictionaryRef samples, IOReportiterateblock handler) {
    if (samples != NULL) {
        uint32_t count = IOReportGetChannelCount(samples);
        CFArrayRef array = (CFArrayRef)CFDictionaryGetValue(samples, CFSTR("IOReportChannels"));
        
        for (int i = 0; i < count; i++) {
            IOReportSampleRef channel = (IOReportSampleRef)CFArrayGetValueAtIndex(array, i);

            int ret = handler(channel);
            
            if (ret == re_kIOReportIterFailed) return;
        }
    }
}
