//
//  re_IOReportChannel.m
//  re_IOReportReverseEngineeringTest
//
//  Created by Taevon Turner on 1/19/23.
//

#import <Foundation/Foundation.h>
#import "IOReportPrivate.h"

// TODO: - Add IOReportCopyChannelsForDrivers,_IOReportCopyChannelsInCategories, IOReportCopyChannelsOfFormat, IOReportCopyChannelsWithID, IOReportCopyChannelsWithUnit

CFMutableDictionaryRef copyChannel(NSString* group) {
    CFMutableDictionaryRef dict = CFDictionaryCreateMutable(kCFAllocatorDefault, 0, nil, nil);
    NSMutableArray* channels = [[NSMutableArray alloc] init];
    
    io_iterator_t iter;
    kern_return_t kr;
    io_registry_entry_t entry;
    mach_port_t port;
    
    if (@available(macOS 12, *))
        port = kIOMainPortDefault;
    else
        port = kIOMasterPortDefault;
    
    kr = IORegistryCreateIterator(port, kIOServicePlane, kIORegistryIterateRecursively, &iter);
    
    if (kr != kIOReturnSuccess) return nil;
    
    while ((entry = IOIteratorNext(iter)) != IO_OBJECT_NULL) {
        char    name[56];
        uint64_t entid;

        CFTypeRef property = IORegistryEntryCreateCFProperty(entry, CFSTR("IOReportLegend"), kCFAllocatorDefault, 0);
        NSArray* legend = (NSArray*)CFBridgingRelease(property);
        
        if (legend != nil) {
            bool matched = false;
            
            for (int i = 0; i < [legend count]; i++) {
                NSDictionary* key = legend[i];
                
                if ([[key allValues] containsObject:group] || group == nil) {
                    matched = true;
                    
                    IORegistryEntryGetName(entry, name);
                    IORegistryEntryGetRegistryEntryID(entry, &entid);
                    
                    NSNumber* eid = [[NSNumber alloc] initWithLong: entid];
                    NSString* dname = [[NSString alloc] initWithFormat:@"%s <id: 0x%.2llx>",  name, entid];
                    NSDictionary* driverstub = [[NSDictionary alloc] initWithObjects:@[eid, dname] forKeys:@[@"DriverID", @"DriverName"]];
                    
                    NSArray* channelArray = [key valueForKey:@"IOReportChannels"];
                    
                    for (int ii = 0; ii < channelArray.count; ii++) {
                        NSDictionary* subDict = [NSMutableDictionary dictionaryWithDictionary:driverstub];

                        [subDict setValue:[key valueForKey:@"IOReportChannelInfo"] forKey:@"IOReportChannelInfo"];
                        [subDict setValue:[key valueForKey:@"IOReportGroupName"] forKey:@"IOReportGroupName"];
                        [subDict setValue:[key valueForKey:@"IOReportSubGroupName"] forKey:@"IOReportSubGroupName"];
                        [subDict setValue:channelArray[ii] forKey:@"LegendChannel"];
                    
                        [channels addObject:subDict];
                    }
                    
                    eid = nil;
                    dname = nil;
                }
            }
        }
    }
    
    IOObjectRelease(iter);
    
    if (channels.count != 0)
        CFDictionarySetValue(dict, CFSTR("IOReportChannels"), CFBridgingRetain(channels));
    
    CFDictionarySetValue(dict, CFSTR("QueryOpts"), CFSTR("0"));
    
    return dict;
}

// The a, b, c parameters currently don't do anyhing, as they seem to originally have no purpose but add extra formatting to the returned dict...
CFMutableDictionaryRef re_IOReportCopyChannelsInGroup(NSString* group,
                                                   NSString* subgroup,
                                                   uint64_t a,
                                                   uint64_t b,
                                                   uint64_t c) {
    return copyChannel(group);
}

// Same here!
CFMutableDictionaryRef re_IOReportCopyAllChannels(uint64_t a, uint64_t b) {
    return copyChannel(nil);
}

int re_IOReportGetChannelCount(CFDictionaryRef channels) {
    if (channels != NULL) {
        CFArrayRef channArray = CFDictionaryGetValue(channels, CFSTR("IOReportChannels"));
        return (int) CFArrayGetCount(channArray);
    }
    return 0;
}

NSString* re_IOReportChannelGetChannelName(CFDictionaryRef a) {
    if (a != NULL) {
        CFArrayRef arr = (CFArrayRef)CFDictionaryGetValue(a, CFSTR("LegendChannel"));
        NSString * str = (NSString*)CFArrayGetValueAtIndex(arr, kIOReportChannelNameIdx);
        return str;
    }
    return NULL;
}

NSString* re_IOReportChannelGetGroup(CFDictionaryRef a) {
    if (a != NULL) {
        NSString * str = (NSString*)CFDictionaryGetValue(a, CFSTR("IOReportGroupName"));
        return str;
    }
    return NULL;
}

NSString* re_IOReportChannelGetSubGroup(CFDictionaryRef a) {
    if (a != NULL) {
        NSString * str = (NSString*)CFDictionaryGetValue(a, CFSTR("IOReportSubGroupName"));
        return str;
    }
    return NULL;
}

NSString* re_IOReportChannelGetDriverName(CFDictionaryRef a) {
    if (a != NULL) {
        NSString * str = (NSString*)CFDictionaryGetValue(a, CFSTR("DriverName"));
        return str;
    }
    return NULL;
}

// TODO: - Add after updates put in place for IOReportSample stuff

NSString* re_IOReportChannelGetUnitLabel(CFDictionaryRef a) {
    if (a != NULL) {

    }
    return NULL;
}

int re_IOReportChannelGetFormat(CFDictionaryRef samples) {
    if (samples != NULL) {
        
    }
    return NULL;
}
