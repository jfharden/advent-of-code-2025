build:
	dasm day1.asm -f3 -v0 -ocart.bin

run: run-pal

run-pal: build
	stella -format PAL cart.bin

run-ntsc: build
	stella -format PAL cart.bin

debug: debug-pal
	
debug-pal: build
	stella -format PAL -debug cart.bin

debug-ntsc: build
	stella -format NTSC -debug cart.bin

clean:
	rm -f cart.bin
