//
//  main.m
//  IOReport
//
//  Created by BitesPotatoBacks on 1/18/23.
//

#import <Foundation/Foundation.h>
#import "IOReportPrivate.h"

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        NSString * group = @"Channel";
        
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
                int state_count = IOReportStateGetCount(sample);
                NSString* idx_name = IOReportStateGetNameForIndex(sample, 0);
                uint64_t  residency = IOReportSimpleGetIntegerValue(sample, 0);
                
                NSLog(@"driver: %@ group: %@ subgroup: %@ unit_label: %@, state_name: %@ chann_name: %@ chann_format: %u state_cnt: %u res: %llu", driver, group, subgroup, unit_label, idx_name, chann_name, chann_format, state_count, residency);
            } else {
                NSLog(@"driver: %@ group: %@ subgroup: %@ unit_label: %@ chann_name: %@ chann_format: %u value: %llu", driver, group, subgroup, unit_label, chann_name, chann_format, 0llu);
            }

            return re_kIOReportIterOk;
        });
        
        CFRelease(chn);
        CFRelease(samples);
    }
    return 0;
}
