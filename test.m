//
//  main.m
//  IOReport
//
//  Created by BitesPotatoBacks on 1/18/23.
//

#import <Foundation/Foundation.h>
#import "IOReport.h"

typedef uint8_t IOReportFormat;
enum {
    kIOReportInvalidFormat = 0,
    kIOReportFormatSimple = 1,
    kIOReportFormatState = 2,
    kIOReportFormatHistogram = 3,
    kIOReportFormatSimpleArray = 4
};

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        NSString * group = @"GPU C-States";
        
        CFMutableDictionaryRef chn = IOReportCopyChannelsInGroup(group, 0, 0, 0, 0); // or IOReportCopyAllChannels(0, 0);
        
        CFMutableDictionaryRef subchn = NULL; // can be omitted, as there seemed to be no use for this param, so I added no logic for it ;)

        IOReportSubscriptionRef sub = IOReportCreateSubscription(NULL, chn, &subchn, 0, 0);
        
        CFDictionaryRef samples = IOReportCreateSamples(sub, chn, NULL);

        IOReportIterate(samples, ^(IOReportSampleRef sample) {
            NSString* subgroup = IOReportChannelGetSubGroup(sample);
            NSString* group = IOReportChannelGetGroup(sample);
            NSString* driver = IOReportChannelGetDriverName(sample);
            NSString* chann_name = IOReportChannelGetChannelName(sample);
            NSString* unit_label = IOReportChannelGetUnitLabel(sample);
            
            int chann_format = IOReportChannelGetFormat(sample);
            if (chann_format == kIOReportFormatState) {
                long state_count = IOReportStateGetCount(sample);
                NSString* idx_name = IOReportStateGetNameForIndex(sample, 0);
                uint64_t  residency = IOReportStateGetResidency(sample, 0);

                NSLog(@"driver: %@ group: %@ subgroup: %@ unit_label: %@, state_name: %@ chann_name: %@ chann_format: %u state_cnt: %ld res: %llu", driver, group, subgroup, unit_label, idx_name, chann_name, chann_format, state_count, residency);
            } else if (chann_format == kIOReportFormatSimple) {
                long state_count = IOReportStateGetCount(sample);
                NSString* idx_name = IOReportStateGetNameForIndex(sample, 0);
                long  residency = IOReportSimpleGetIntegerValue(sample, 0);

                NSLog(@"driver: %@ group: %@ subgroup: %@ unit_label: %@, state_name: %@ chann_name: %@ chann_format: %u state_cnt: %ld integer: %ld", driver, group, subgroup, unit_label, idx_name, chann_name, chann_format, state_count, residency);
            }
            else {
                NSLog(@"driver: %@ group: %@ subgroup: %@ unit_label: %@ chann_name: %@ chann_format: %u value: %llu", driver, group, subgroup, unit_label, chann_name, chann_format, 0llu);
            }

            return re_kIOReportIterOk;
        });

        CFRelease(chn);
        CFRelease(samples);
    }
    return 0;
}
