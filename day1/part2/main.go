package main

import (
	"bufio"
	"fmt"
	"log"
	"os"
	"strconv"

	"day1_part2/internal/dial"
)

func main() {
	d := dial.NewDial()

	file, err := os.Open("../input.txt")
	if err != nil {
		log.Fatalf("Couldn't open input.txt with error: %s", err)
	}
	defer func() {
		err = file.Close()
		if err != nil {
			log.Fatalf("Couldn't close input file")
		}
	}()

	scanner := bufio.NewScanner(file)
	for scanner.Scan() {
		line := scanner.Text()
		notches, err := strconv.Atoi(line[1:])
		if err != nil {
			log.Fatalf("Couldn't parse number on line with content '%s'", line)
		}

		switch line[0] {
		case 'L':
			d.Left(notches)
		case 'R':
			d.Right(notches)
		default:
			log.Fatalf("Couldn't understand direction on line with content '%s'", line)
		}
	}

	fmt.Printf("The dial ended on position %d with %d on zero\n", d.Position, d.TimesOnZero)
}
