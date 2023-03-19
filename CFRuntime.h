//
//  CFRuntime.h
//  IOReport
//
//  Created by BitesPotatoBacks on 1/19/23.
//

#ifndef CFRuntime_h
#define CFRuntime_h

#include <CoreFoundation/CoreFoundation.h>
#include <objc/runtime.h>

typedef struct __CFRuntimeClass {
    CFIndex version;
    const char *className;
    void (*init)(CFTypeRef cf);
    CFTypeRef (*copy)(CFAllocatorRef allocator, CFTypeRef cf);
    void (*finalize)(CFTypeRef cf);
    Boolean (*equal)(CFTypeRef cf1, CFTypeRef cf2);
    CFHashCode (*hash)(CFTypeRef cf);
    CFStringRef (*copyFormattingDesc)(CFTypeRef cf, CFDictionaryRef formatOptions);
    CFStringRef (*copyDebugDesc)(CFTypeRef cf);
    void (*reclaim)(CFTypeRef cf);
} CFRuntimeClass;

typedef struct __CFRuntimeBase {
    uintptr_t _cfisa;
    uint8_t _cfinfo[4];
#if __LP64__
    uint32_t _rc;
#endif
} CFRuntimeBase;

 CFTypeID __CFGenericTypeID(void *cf);
const CFRuntimeClass * _CFRuntimeGetClassWithTypeID(CFTypeID typeID);
 CFTypeID _CFRuntimeRegisterClass(const CFRuntimeClass* const cls);
 CFTypeRef _CFRuntimeCreateInstance(CFAllocatorRef allocator,
                                          CFTypeID typeID, CFIndex extraBytes,
                                          unsigned char* category);


#endif /* CFRuntime_h */
