CC=clang
CFLAGS=-framework CoreFoundation -framework Foundation -framework IOKit -fobjc-arc
test: *.m
	$(CC) *.m -o test ${CFLAGS}
