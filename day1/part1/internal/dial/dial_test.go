package dial_test

import (
	"fmt"
	"strings"
	"testing"

	"day1_part1/internal/dial"

	"github.com/stretchr/testify/assert"
)

type turnsTestCase struct {
	Turns               []int
	ExpectedPosition    int
	ExpectedTimesOnZero int
}

func TestLeft(t *testing.T) {
	testCases := []turnsTestCase{
		{Turns: []int{1}, ExpectedPosition: 49, ExpectedTimesOnZero: 0},
		{Turns: []int{50}, ExpectedPosition: 0, ExpectedTimesOnZero: 1},
		{Turns: []int{150}, ExpectedPosition: 0, ExpectedTimesOnZero: 1},
		{Turns: []int{250}, ExpectedPosition: 0, ExpectedTimesOnZero: 1},
		{Turns: []int{49}, ExpectedPosition: 1, ExpectedTimesOnZero: 0},
		{Turns: []int{149}, ExpectedPosition: 1, ExpectedTimesOnZero: 0},
		{Turns: []int{249}, ExpectedPosition: 1, ExpectedTimesOnZero: 0},
		{Turns: []int{51}, ExpectedPosition: 99, ExpectedTimesOnZero: 0},
		{Turns: []int{151}, ExpectedPosition: 99, ExpectedTimesOnZero: 0},
		{Turns: []int{251}, ExpectedPosition: 99, ExpectedTimesOnZero: 0},
		{Turns: []int{1, 50}, ExpectedPosition: 99, ExpectedTimesOnZero: 0},
		{Turns: []int{50, 1}, ExpectedPosition: 99, ExpectedTimesOnZero: 1},
	}

	for _, tc := range testCases {
		message := fmt.Sprintf("When turned left %s is in position %d with %d times on zero",
			strings.Join(strings.Fields(fmt.Sprint(tc.Turns)), " then "),
			tc.ExpectedPosition,
			tc.ExpectedTimesOnZero,
		)

		t.Run(message, func(t *testing.T) {
			d := dial.NewDial()

			for _, leftTurns := range tc.Turns {
				d.Left(leftTurns)

			}

			assert.Equal(t, tc.ExpectedPosition, d.Position)
			assert.Equal(t, tc.ExpectedTimesOnZero, d.TimesOnZero)
		})
	}
}

func TestRight(t *testing.T) {
	testCases := []turnsTestCase{
		{Turns: []int{1}, ExpectedPosition: 51, ExpectedTimesOnZero: 0},
		{Turns: []int{50}, ExpectedPosition: 0, ExpectedTimesOnZero: 1},
		{Turns: []int{150}, ExpectedPosition: 0, ExpectedTimesOnZero: 1},
		{Turns: []int{250}, ExpectedPosition: 0, ExpectedTimesOnZero: 1},
		{Turns: []int{49}, ExpectedPosition: 99, ExpectedTimesOnZero: 0},
		{Turns: []int{149}, ExpectedPosition: 99, ExpectedTimesOnZero: 0},
		{Turns: []int{249}, ExpectedPosition: 99, ExpectedTimesOnZero: 0},
		{Turns: []int{51}, ExpectedPosition: 1, ExpectedTimesOnZero: 0},
		{Turns: []int{151}, ExpectedPosition: 1, ExpectedTimesOnZero: 0},
		{Turns: []int{251}, ExpectedPosition: 1, ExpectedTimesOnZero: 0},
		{Turns: []int{1, 50}, ExpectedPosition: 1, ExpectedTimesOnZero: 0},
		{Turns: []int{50, 1}, ExpectedPosition: 1, ExpectedTimesOnZero: 1},
	}

	for _, tc := range testCases {
		message := fmt.Sprintf("When turned left %s is in position %d with %d times on zero",
			strings.Join(strings.Fields(fmt.Sprint(tc.Turns)), " then "),
			tc.ExpectedPosition,
			tc.ExpectedTimesOnZero,
		)

		t.Run(message, func(t *testing.T) {
			d := dial.NewDial()

			for _, leftTurns := range tc.Turns {
				d.Right(leftTurns)

			}

			assert.Equal(t, tc.ExpectedPosition, d.Position)
			assert.Equal(t, tc.ExpectedTimesOnZero, d.TimesOnZero)
		})
	}
}
