# IOReportReverseEngineer 
### ⚠️ In Progress! ⚠️
This repo is an attempt at reverse engineering the private IOReport framework for MacOS, using Objective-C.

The IOReport is a means of logging power and performance metrics of system drivers and peripherals. It is used by tools such as [`powermetrics`](https://www.unix.com/man-page/osx/1/powermetrics/), as well as my own tool based on `powermetrics`, the [SocPowerBuddy](https://github.com/BitesPotatoBacks/SocPowerBuddy).
___
This work is based from decompilation of closed source system binaries:
- IOReportFamily.kext (decompiled with [Ghidra]())
- libIOReport.dylib (decompiled with [Ghidra]())

And also public headers:
- [IOReportTypes.h](https://github.com/apple/darwin-xnu/blob/main/iokit/IOKit/IOReportTypes.h)
- [IOKernelReportStructs.h](https://github.com/apple/darwin-xnu/blob/main/iokit/IOKit/IOKernelReportStructs.h)
- [IOReportHub.h](https://github.com/acidanthera/MacKernelSDK/blob/39336fd35fc3721733de156e7437b3fd27949a3a/Headers/IOKit/IOReportHub.h)
- [IOReportUserClient.h](https://github.com/acidanthera/MacKernelSDK/blob/39336fd35fc3721733de156e7437b3fd27949a3a/Headers/IOKit/IOReportUserClient.h)

# TODOS
- Retrive Unit Labels and State Names for channels with `IOReportFormatState` formats
- Support channels that have more than 64 bytes in raw elements (like for `IOReportFormatState`)
- Recreate logic for calls to retrieve values channel values (such as those prefixed by `IOReportChannelGet...`, `IOReportStateGet...`, etc.)
