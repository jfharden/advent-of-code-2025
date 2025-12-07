; The puzzle input should be written into the macros below
; Each line needs to be printed as a series of ascii bytes:
;    dc.b "<LINE>"
;
; A bank needs to end with an ASCII N if the data is to continue in the next bank
;    byte "N"
;
; The end of the entire input, irrespective of bank, needs to be an ascii Z
;    byte "Z"
;
  MAC PUZZLE_INPUT_BANK_1
    dc.b "L68"
    dc.b "L30"
    dc.b "R48"
    dc.b "N"
  ENDM

  MAC PUZZLE_INPUT_BANK_2
    dc.b "L5"
    dc.b "R60"
    dc.b "N"
  ENDM

  MAC PUZZLE_INPUT_BANK_3
    dc.b "L55"
    dc.b "L1"
    dc.b "N"
  ENDM

  MAC PUZZLE_INPUT_BANK_4
    dc.b "L99"
    dc.b "N"
  ENDM

  MAC PUZZLE_INPUT_BANK_5
    dc.b "R14"
    dc.b "N"
  ENDM

  MAC PUZZLE_INPUT_BANK_6
    dc.b "L82"
    dc.b "Z"
  ENDM

  MAC PUZZLE_INPUT_BANK_7
  ENDM

  MAC PUZZLE_INPUT_BANK_8
  ENDM
