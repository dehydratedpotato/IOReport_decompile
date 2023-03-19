//
//  IOReportState.m
//  IOReport
//
//  Created by BitesPotatoBacks on 1/19/23.
//

#import <Foundation/Foundation.h>
#import "IOReportPrivate.h"

int IOReportStateGetCount(CFDictionaryRef a) {
    if (a != NULL) {
        NSData * d = (NSData*)CFDictionaryGetValue(a, CFSTR("RawElements"));
        
        if (d.length == 0) return 0;
        
        return (int)d.length / 64;
    }
    return 0;
}

uint64_t IOReportStateGetResidency(CFDictionaryRef a, int b) {
    // TODO: Add logic to pull state value
    return 0;
}

NSString* IOReportStateGetNameForIndex(CFDictionaryRef a, int b) {
    // TODO: Add logic to pull unit label(s)
    return NULL;
}
