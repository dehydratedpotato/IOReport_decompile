//
//  IOReportSubscription.m
//  IOReport
//
//  Created by BitesPotatoBacks on 1/19/23.
//

#import <Foundation/Foundation.h>
#import "IOReportPrivate.h"

IOReportInterestList* createInterest(CFArrayRef channels, int count) {
    IOReportInterestList * interestList = malloc(count * 0x18 + 8);
    interestList->ninterests = count;
    
    for (int i = 0; i < count; i++) {
        CFDictionaryRef chann = (CFDictionaryRef)CFArrayGetValueAtIndex(channels, i);
        
        NSNumber * legend_channel_id = (NSNumber*)CFArrayGetValueAtIndex((CFArrayRef)CFDictionaryGetValue(chann, CFSTR("LegendChannel")), kIOReportChannelIDIdx);
        uint64_t channel_id = legend_channel_id.longValue;
        
        NSNumber * legend_channel_type = (NSNumber*)CFArrayGetValueAtIndex((CFArrayRef)CFDictionaryGetValue(chann, CFSTR("LegendChannel")), kIOReportChannelTypeIdx);
        uint64_t channel_type_ptr = legend_channel_type.longValue;
        IOReportChannelType channel_type = *(IOReportChannelType*)&channel_type_ptr;
    
        IOReportChannel channel = {
            .channel_id = channel_id,
            .channel_type = channel_type
        };
        
        NSNumber * driver_id = (NSNumber*)CFDictionaryGetValue(chann, CFSTR("DriverID"));
        uint64_t provider_id = driver_id.longValue;
        
        IOReportInterest interest = {
            .provider_id = provider_id,
            .channel = channel
        };
        
        interestList->interests[i] = interest;
        
        /*
        NSLog(@"%llu %llu %p", interestList->interests[i].provider_id,
              interestList->interests[i].channel.channel_id,
              interestList->interests[i].channel.channel_type);
         */
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
    IOReportSubscriptionRef iorepSubscription = NULL;
    kern_return_t              kr;
    io_iterator_t              iter;
    io_service_t               service = 0;
    io_connect_t               connection = 0;
    mach_port_t                port;
    
    if (@available(macOS 12, *))
        port = kIOMainPortDefault;
    else
        port = kIOMasterPortDefault;
    
    count = IOReportGetChannelCount(desiredChannels);
    
    if (count > 0) {
        iorepTypeId       = _CFRuntimeRegisterClass(&IOReportSubscriptionClass);
        iorepSubscription = (IOReportSubscriptionRef)_CFRuntimeCreateInstance(a, iorepTypeId, 0x20, 0);
    
        kr = IOServiceGetMatchingServices(port, IOServiceMatching("IOReportHub"), &iter);
        if (kr != KERN_SUCCESS) {
            NSLog(@"Could not match IOReportHub, failed with %s", mach_error_string(kr));
            return iorepSubscription;
        }
        
        while ((service = IOIteratorNext(iter)) != IO_OBJECT_NULL) {
            kr = IOServiceOpen(service, mach_task_self(), 0, &connection);
            if (kr != KERN_SUCCESS) {
                NSLog(@"Could not open IOReportHub, failed with %s", mach_error_string(kr));
                goto exit;
            }
            break;
        }
        IOObjectRelease(iter);
        
        kr = IOConnectCallScalarMethod(connection, kIOReportUserClientOpen, 0, 0, 0, 0);
        if (kr != KERN_SUCCESS) {
            NSLog(@"kIOReportUserClientOpen failed with %s", mach_error_string(kr));
            goto exit;
        }
        IOObjectRelease(service);

        uint32_t input = count * 0x18 + 8;
        uint32_t output = 1;
        IOReportInterestList* interestList = createInterest((CFArrayRef)CFDictionaryGetValue(desiredChannels, CFSTR("IOReportChannels")), count);
        
        iorepSubscription->connection = connection;
        
        kr = IOConnectCallMethod(iorepSubscription->connection, kIOReportUserClientConfigureInterests, NULL, 0, interestList, input, &iorepSubscription->dwordPtr, &output, NULL, 0);
        if (kr != KERN_SUCCESS) {
            NSLog(@"kIOReportUserClientConfigureInterests failed with %s", mach_error_string(kr));
            
            free(interestList);
            
            goto exit;
        }

        kr = IOConnectMapMemory(iorepSubscription->connection, iorepSubscription->dwordPtr, mach_task_self(), &iorepSubscription->addr, &iorepSubscription->addrSize, 1);
        if (kr != KERN_SUCCESS) {
            NSLog(@"IOConnectMapMemory) failed with %s", mach_error_string(kr));
            
            IOConnectUnmapMemory(connection, iorepSubscription->dwordPtr, mach_task_self(), iorepSubscription->addr);
            
            free(interestList);
            
            goto exit;
        }
        
//        for (int i = 0; i < count; i++) {
//
//        NSLog(@"%llu %llu %p", interestList->interests[i].provider_id,
//              interestList->interests[i].channel.channel_id,
//              interestList->interests[i].channel.channel_type);
//        }
    }
    
exit:
    IOServiceClose(service);
    
    return iorepSubscription;
}

