# Advent of Code 2025 - With an atari twist

This repo contains my attempt to implement day 1 of advent of code to be solved by an Atari 2600.

It also contains an initial solve in go which was to let me get my head around the problem before jumping
into 6502 assembly.

I'm only hoping to solve day 1 (part 2).

Constraints:

* A standard 2600 cart is only 4kb of ROM and my puzzle input is 16.7kb, which in theory means bank switching, but I think before I go down that path I'll try to solve for a short puzzle input.
* There's only 128 bytes of ram by default, I shouldn't need more, so a bank switching scheme which only increases ROM is fine.
* There's no print to screen routines, which means writing a simple numeric character set, and writing the code to display it.
* It's only an 8bit wide instruction set, which means a single mathmatical operation has to be performed in multiple stages using add/subtract with carry flag.
* No multiply, divide, modulo, or remainder operations
