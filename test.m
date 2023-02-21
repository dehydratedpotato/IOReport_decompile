//
//  main.m
//  re_IOReportReverseEngineeringTest
//
//  Created by Taevon Turner on 1/18/23.
//

#import <Foundation/Foundation.h>
#import "IOReportPrivate.h"

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        NSString * group = @"GPU C-States";
        
        CFMutableDictionaryRef chn = re_IOReportCopyChannelsInGroup(group, 0, 0, 0, 0);
//        CFMutableDictionaryRef chn = re_IOReportCopyAllChannels(0, 0);
        
        // can be omitted, as there seemed to be no use for this param, so I added no logic for it ;)
        CFMutableDictionaryRef subchn = NULL;
        
        re_IOReportSubscriptionRef sub = re_IOReportCreateSubscription(NULL, chn, &subchn, 0, 0);
        
        CFDictionaryRef samples = re_IOReportCreateSamples(sub, chn, NULL);

        re_IOReportIterate(samples, ^(re_IOReportSampleRef sample) {
            NSString* subgroup = re_IOReportChannelGetSubGroup(sample);
            NSString* group = re_IOReportChannelGetGroup(sample);
            NSString* driver = re_IOReportChannelGetDriverName(sample);
//            NSString* idx_name = re_IOReportStateGetNameForIndex(sample, 0);
            NSString* chann_name = re_IOReportChannelGetChannelName(sample);
//            uint64_t  residency = re_IOReportSimpleGetIntegerValue(sample, 0);
//
            NSLog(@"%@ %@ %@ %@ %@ %llu", driver, group, subgroup, NULL, chann_name, NULL);

            return re_kIOReportIterOk;
        });
        
//        CFRelease(subchn);
        CFRelease(chn);
        CFRelease(samples);
    }
    return 0;
}
