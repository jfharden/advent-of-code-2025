# Advent of Code 2025 Day 1 Part 1 - On the Atari 2600


## Requirements

* The Makefile assumes using [stella emulator](https://stella-emu.github.io/)
* The [dasm assembler](https://dasm-assembler.github.io/).
* The atari 2600 machine macros.h and vcs.h from the dasm assembler to be placed into the `includes/` directory.
* A [bash](https://en.wikipedia.org/wiki/Bash_(Unix_shell)) shell to run the conversion script to turn your puzzle input into a usable include file
* [GNU Make](https://www.gnu.org/software/make/) (or compatible Make system)

The include files, and real puzzle inputs have been added to the .gitignore so I don't accidentally commit them.

The included `includes/input.h` is the example input from the problem description.

The cart has been made for PAL consoles (since I'm in the UK)

## Usage

1. Put your REAL puzzle input in `includes/real_puzzle_input.txt`
2. Execute `Make convert`
3. Execute `Make run`

