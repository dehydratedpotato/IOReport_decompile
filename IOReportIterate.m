//
//  re_IOReportIterate.m
//  re_IOReportReverseEngineeringTest
//
//  Created by Taevon Turner on 1/19/23.
//

#import <Foundation/Foundation.h>
#import "IOReportPrivate.h"

void re_IOReportIterate(CFDictionaryRef samples, re_IOReportiterateblock handler) {
    if (samples != NULL) {
        uint32_t count = re_IOReportGetChannelCount(samples);
        CFArrayRef array = (CFArrayRef)CFDictionaryGetValue(samples, CFSTR("IOReportChannels"));
        
        for (int i = 0; i < count; i++) {
            re_IOReportSampleRef channel = (re_IOReportSampleRef)CFArrayGetValueAtIndex(array, i);

            int ret = handler(channel);
            
            if (ret == re_kIOReportIterFailed) return;
        }
    }
}
