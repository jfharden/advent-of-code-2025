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
	oldPosition := d.Position

	d.addFullRotations(notches)

	remainingMovesIgnoringWholeRotations := notches % 100

	d.Position = d.Position - remainingMovesIgnoringWholeRotations

	if d.Position == 0 {
		d.TimesOnZero += 1
	}

	if d.Position >= 0 {
		return
	}

	// We crossed zero
	if oldPosition > 0 {
		d.TimesOnZero += 1
	}

	d.Position = 100 + d.Position
}

func (d *Dial) Right(notches int) {
	d.addFullRotations(notches)

	remainingMovesIgnoringWholeRotations := notches % 100

	// We cross zero
	if d.Position+remainingMovesIgnoringWholeRotations > 100 {
		d.TimesOnZero += 1
	}

	d.Position = (d.Position + notches) % 100

	if d.Position == 0 {
		d.TimesOnZero += 1
	}

}

func (d *Dial) addFullRotations(notches int) {
	fullRotations := notches / 100
	d.TimesOnZero += fullRotations
}
