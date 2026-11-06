all: librt-x64-linux.a

librt-x64-linux.a: rt-x64-linux.s rt.c
	gcc -c -nostdlib -O2 rt-x64-linux.s rt.c
	ar rcs librt-x64-linux.a rt-x64-linux.o rt.o

clean:
	rm -f *.o lib*.a

.PHONY: all clean
