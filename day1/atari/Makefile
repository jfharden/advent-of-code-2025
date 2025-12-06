build:
	dasm day1.dasm -S -f3 -v0 -ooutput/cart.bin

build-debug:
	dasm day1.dasm -S -f3 -v0 -ooutput/cart.bin -loutput/cart.lst -soutput/cart.sym

run: run-pal

run-pal: build
	stella -format PAL output/cart.bin

run-ntsc: build
	stella -format PAL output/cart.bin

debug: debug-pal
	
debug-pal: build-debug
	stella -format PAL -debug output/cart.bin

debug-ntsc: build-debug
	stella -format NTSC -debug output/cart.bin

clean:
	rm -f output/*.{bin,lst,sym}
