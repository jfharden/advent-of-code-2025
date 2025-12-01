package dial

type Dial struct {
	Position    int
	TimesOnZero int
}

func NewDial() Dial {
	return Dial{
		Position:    50,
		TimesOnZero: 0,
	}
}

func (d *Dial) Left(notches int) {
	remainingMovesIgnoringWholeRotations := notches % 100

	d.Position = d.Position - remainingMovesIgnoringWholeRotations

	if d.Position == 0 {
		d.TimesOnZero += 1
	}

	if d.Position >= 0 {
		return
	}

	d.Position = 100 + d.Position
}

func (d *Dial) Right(notches int) {
	d.Position = (d.Position + notches) % 100

	if d.Position == 0 {
		d.TimesOnZero += 1
	}
}
