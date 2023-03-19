# (WIP) IOReportReverseEngineer 
This repo is an attempt at reverse engineering the private IOReport framework for MacOS, using Objective-C.

The IOReport system is a means of logging power and performance metrics of system drivers and peripherals. It's private framework is a means of reading such data, and is used by Mac commands like [`powermetrics`](https://www.unix.com/man-page/osx/1/powermetrics/) and [`pmset`](https://en.wikipedia.org/wiki/Pmset#:~:text=On%20Apple%20computers%2C%20pmset%20is%20a%20command%20line,Darwin%206.0.1%20and%20Mac%20OS%20X%2010.2%20%22Jaguar%22.), as well as my own project, the [SocPowerBuddy](https://github.com/BitesPotatoBacks/SocPowerBuddy).
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
- Actually get simple int, array, and residency from a channel
- Histogram support
- Support for ctate channel index names
- Convert from Objective-C to C (for completion)
