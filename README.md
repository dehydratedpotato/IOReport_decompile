# (WIP) IOReport decompile
## About
The **IOReport** is another undocumented thingamajig, a part of IOKit and whatnot. 

- **The IOReport kext** serves as a space for different parts of the system to report various metrics and counters on things, especially on Apple Silicon machines. Some data includes CPU and GPU voltage states, random Interrupt Statistics, and stinkin' histograms of stuff. This isn't a decompile of the kext, but the dylib.

- **The IOReport library** is a dylib with all the calls for reading reports and stuff.

I've done a whole lot of exploring with this thing, first learned about it from [freedomtan/test-ioreport](https://github.com/freedomtan/test-ioreport).

I then later disassimbled [powermetrics](https://www.unix.com/man-page/osx/1/powermetrics/) (made a project from that work too). Powermetrics is a cool MacOS utility that uses IOReport on Apple Silicon for fetching CPU frequencies and I learned a lot from that.

Then I took the plunge to try I decompile the dylib which got me to dig more into the kext for deeper understanding. I mostly get how it works at this point but there are certain aspects I just haven't gotten around to solving yet. 

You can find references to the IOReport in source files in some [power management things](https://github.com/minombreesjeff/darwin_env/blob/142f2158ce2eb4d92b0ca9f98275ff73ea67ec0a/PowerManagement/pmconfigd/AggdDailyReport.h#L64) and you can see it's symbols in it's tbd file.

## Building to test
The test.m file is for testing the thing, obviously. Build it with the makefile. The file is pretty much just for me, but if you wanna experiment or something there ya go!
