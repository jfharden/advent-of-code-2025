;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;                   228 colour clocks
;;    <------------------------------------------------>
;;
;;    |================================================|
;;    |            VERTICAL SYNC                       | 3 x VSYNC scanlines
;;    |================================================|
;;    |                                                |
;;    |                                                |
;;    |            VERTICAL BLANK                      | 37 x VBLANK scanlines
;;    |                                                |
;;    |                                                |
;;    |================================================|
;;    |            |                                   |
;;    |            |                                   |
;;    |   HORIZ.   |                                   | 192 x Visible area (NTSC)
;;    |   BLANK    |                                   |       scanlines
;;    |            |                                   |
;;    | <--------> | <-------------------------------> | 242 x Visible area (PAL)
;;    | 68 colour  |        160 colour clocks          |       scanlines
;;    |  clocks    |                                   |
;;    |            |                                   |
;;    |            |                                   |
;;    |            |                                   |
;;    |================================================|
;;    |                                                |
;;    |                                                | 30 x OVERSCAN scanlines
;;    |                                                |
;;    |================================================|
;;
;;    <------------------------------------------------>
;;                      76 CPU cycles
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

  processor 6502

  include "includes/vcs.h"
  include "includes/macro.h"
  include "includes/real_puzzle_input.h"

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Define variables for use in RAM
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  seg.u Variables
  org $80

BankNumber              byte ; Allocate a byte which tells us which bank of memory the input is being read from currently
NextBank                byte ; An indicator to say whether the bank needs to be advanced for more puzzle input 1 means NO, 0 means YES
ScanlineNumber          byte ; Allocate 1 byte to store the current scanline number
NumberHeight            byte ; Allocate 1 byte to store the height of the number
NumberPointer           ds 2 ; Allocate enough space to store the address of a memory location
TotalTimesOnZero        ds 4 ; Allocate space to store total times on zero
CurrentInputPosPointer  ds 2 ; Allocate enough space to store a pointer to the current position in the puzzle input
Direction               byte ; Allocate 1 byte to store the direction (L or R)
NotchesToMove           ds 3 ; Allocate enough bytes to store 3 digits for rotation
CurrentPosition         byte ; Allocate space for the current position of the dial
Complete                byte ; Allocate space for a flag saying that processing the input is complete
IncrementBy             byte ; Allocate space for a variable to store how much to incremnet something by (used by multiple macros)
Temp                    byte ; Allocate some temporary working space

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Start the ROM
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; BANK 1
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  seg code
  org $1000
  rorg $F000

  MAC PREAMBLE
Start:
  BANK_SWITCH_TO_0   ; All banks must contain this as the first instruction, no matter which bank is active at boot we will switch to bank 1
  CLEAN_START

  lda #$0E
  sta COLUP0  ; Set the colour of the player 1 bitmap to white
  lda #$00
  sta COLUBK  ; Set the background colour to black
  lda #11
  sta NumberHeight
  ; lda #50
  lda #%01010000 ; 50 in binary coded decimal
  sta CurrentPosition

  lda #<PuzzleInputBank1
  sta CurrentInputPosPointer
  lda #>PuzzleInputBank1
  sta CurrentInputPosPointer+1

  lda #1
  sta NextBank

NextFrame:
  ;; Set register a to value 2
  lda #2
  ;; Store value of register a (#2) to the TIA VBLANK to enable the VBLANK
  sta VBLANK
  ;; Store value of register a (#2) to the TIA VSYNC memory address to enable VSYNC
  sta VSYNC

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Generate the 3 lines of empty VSYNC
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  REPEAT 3
    sta WSYNC
  REPEND

  lda #0
  sta VSYNC   ; We have now rendered the VSYNC

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Generate the 37 lines of VBLANK
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  lda #37                           ; 2   - 2
  sta ScanlineNumber                ; 3   - 5

  lda Complete                      ; 3   - 8
  beq NotComplete                   ; 2+1 - 12/13
  jmp LoopVBlank                    ; 3   - 15
  ENDM ; PREAMBLE
  PREAMBLE

NotComplete:
  READ_LINE_INTO_RAM    ; 4 scanlines - 9/39 - 9/39

  lda Complete
  beq ContinueToCountNotches
  jmp LoopVBlank

ContinueToCountNotches:
  NEXT_SCANLINE         ; 2 previous scanline, 5 next scanline

  ; Direction doesn't matter, add whole rotations
  ADD_WHOLE_ROTATIONS   ; 10 to 66

  NEXT_SCANLINE         ; 2 previous scanline, 5 next scanline

  CALCULATE_NUMBER_OF_TENS_AND_UNITS  ; 23/31 - 28/36 (incl 5 from next scaline above) - Load the BCD tens and units from the current line
  cmp #0                              ; 2     - 38 (worst case only) - If the number of notches is 0 then just finish, direction doesn't matter
  bne CheckDirection                  ; 2+1   - 40/41
  jmp LoopVBlank                      ; 3     - 43

CheckDirection:
  ; Left or right - cycles only counting worst case from CALCULATE_NUMBER_OF_TENS_AND_UNITS
  ldx Direction                       ; 3   - 44
  cpx #$4c                            ; 2   - 46    - L in ascii
  beq LeftTurn                        ; 2+1 - 48/49
  jmp RightTurn                       ; 3   - 51    - If it wasn't left, it must be right so just jump

; Arrive here at 48 cycles
; The accumulator contains the number of tens and units in BCD
LeftTurn:
  sta Temp                            ; 3     - 52
  lda CurrentPosition                 ; 3     - 55
  cmp #0                              ; 2     - 57     - If the current position is 0 it has already been accounted for
  beq JustSubtractLeftTurn            ; 2+1   - 59/60  - so just do the subtraction, but don't increment the counter for having passed 0

  ; Left turn means subtract                  ; No tens/some tens
  SUBTRACT_CURRENT_POSITION_LEFT_TURN ; 12    - 58
  bcc LandedOnOrPassedZeroTurningLeft ; 2+1   - 60/61 - If the carry flag was unset by the subtraction then we rolled over and passed zero
  cmp #0                              ; 2     - 62    - but did we land on 0
  beq LandedOnOrPassedZeroTurningLeft ; 2+1   - 64/65 - If we didn't land on zero then skip
  jmp LoopVBlank                      ; 3     - 67

; When we get here it's either 60 or 64 cycles, will assume worst case of 64
LandedOnOrPassedZeroTurningLeft:
  lda #1                              ; 2   - 66
  sta IncrementBy                     ; 3   - 69
  NEXT_SCANLINE                       ; 2 previous scanline, 5 next scanline
  LANDED_ON_ZERO                      ; 16 to 56 - 16-56
  jmp LoopVBlank                      ; 3        - 59

; Arrive here at 59 cycles
JustSubtractLeftTurn:
  SUBTRACT_CURRENT_POSITION_LEFT_TURN ; 12  - 71
  jmp LoopVBlank                      ; 3   - 74

; Arrive here at 50 cycles
; The accumulator contains the number of tens and units in BCD
RightTurn:
  sta Temp              ; 3   - 53
  lda CurrentPosition   ; 3   - 56
  sed                   ; 2   - 58
  clc                   ; 2   - 60
  adc Temp              ; 3   - 63
  sta CurrentPosition   ; 3   - 66
  cld                   ; 2   - 68
  bcc LoopVBlank        ; 2+1 - 70/71 ; No carry meaning we didn't go from 99 to 0, so no landing on 0

  NEXT_SCANLINE         ; 2 from previous scanline, 5 from next scanline
  lda #1                ; 2   - 7  (including 5 from NEXT_SCANLINE)
  sta IncrementBy       ; 3   - 10
  LANDED_ON_ZERO        ; 16 to 54 - 26 to 64

; Arrive here at: 74 cycles worst case from left turn
LoopVBlank:
  ; Loop away the remaining scanlines until the visible portion of the display
  NEXT_SCANLINE  ; 2 previous scanline, 5 next scanline
  bne LoopVBlank ; 3

  ldx #0          ; 2
  stx VBLANK      ; 3 Disable VBLANK (x is currently 0 from the loop above)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Draw the play field
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  lda #242
  sta ScanlineNumber

LoopVisible:
  lda #0

PrintNextTwoNumbers:
  pha                  ; Push the accumulator, which represents the byte offset for the number of times on zero
  tay                  ; Transfer the accumulator to Y so we can use it as a byte offset to LDA
  lda TotalTimesOnZero,Y
  pha                  ; push the accumulator onto the stack, we will need it again soon
  lsr                  ; Shift left 4 times to make the high nibble the low nibble
  lsr
  lsr
  lsr
  tax                  ; Put the accumulator into X ready for setting the number pointer

  SET_NUMBER_POINTER_TO_X
  jsr PrintNumber

  REPEAT 5
    NEXT_SCANLINE      ; 2 previous scanline, 5 next scanline
  REPEND

  pla                 ; Pop the stack into the accumulator
  and #$0f            ; Mask so we only have the low nibble
  tax                 ; Put the accumulator into X ready for setting the number pointer
  SET_NUMBER_POINTER_TO_X
  jsr PrintNumber

  REPEAT 5
    NEXT_SCANLINE     ; 2 previous scanline, 5 next scanline
  REPEND

  pla                 ; Pop the stack into the accumulator, this is the previously pushed byte offset for our total times on zero number
  clc
  adc #1              ; Increment the accumulator so we move onto the next byte in the total times on zero number
  cmp #4
  bne PrintNextTwoNumbers



ScanToEndOfVisible:
  NEXT_SCANLINE           ; 2 previous scanline, 5 next scanline
  bne ScanToEndOfVisible  ; 2+1

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Draw the Overscan - turn on vertical blank first
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  lda #2
  sta VBLANK

  ldx #30
LoopOverscan:
  sta WSYNC
  dex
  bne LoopOverscan

  jmp NextFrame

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Print a single number to the screen over 7 lines
;; Registers:
;;   y: Memory location of the number to render
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
PrintNumber:
  NEXT_SCANLINE
  ldy #0

LoopNumber:
  lda (NumberPointer),Y    ; Load the byte of the bitmap into the accumulator
  sta GRP0                 ; Store the accumulator in the graphics register for player 0

  NEXT_SCANLINE

  iny                      ; Increment the y register which is counting if we are at the end of the bitmap

  cpy NumberHeight         ; Compare y to see if it has reached the bitmap height
  bne LoopNumber           ; Go to the next line

  lda #0
  sta GRP0                 ; Change to drawing a blank line

  rts                      ; return to the caller

NumbersHighByte:
  byte #<Number0
  byte #<Number1
  byte #<Number2
  byte #<Number3
  byte #<Number4
  byte #<Number5
  byte #<Number6
  byte #<Number7
  byte #<Number8
  byte #<Number9

NumbersLowByte:
  byte #>Number0
  byte #>Number1
  byte #>Number2
  byte #>Number3
  byte #>Number4
  byte #>Number5
  byte #>Number6
  byte #>Number7
  byte #>Number8
  byte #>Number9

Number0:
  byte #%01111110 ;  ######
  byte #%10000001 ; #      #
  byte #%10000001 ; #      #
  byte #%10000001 ; #      #
  byte #%10000001 ; #      #
  byte #%10000001 ; #      #
  byte #%10000001 ; #      #
  byte #%10000001 ; #      #
  byte #%10000001 ; #      #
  byte #%10000001 ; #      #
  byte #%01111110 ;  ######

Number1:
  byte #%00000001 ;        #
  byte #%00000001 ;        #
  byte #%00000001 ;        #
  byte #%00000001 ;        #
  byte #%00000001 ;        #
  byte #%00000001 ;        #
  byte #%00000001 ;        #
  byte #%00000001 ;        #
  byte #%00000001 ;        #
  byte #%00000001 ;        #
  byte #%00000001 ;        #
  byte #%00000001 ;        #

Number2:
  byte #%11111111 ; ########
  byte #%00000001 ;        #
  byte #%00000001 ;        #
  byte #%00000001 ;        #
  byte #%00000001 ;        #
  byte #%11111111 ; ########
  byte #%10000000 ; #
  byte #%10000000 ; #
  byte #%10000000 ; #
  byte #%10000000 ; #
  byte #%11111111 ; ########

Number3:
  byte #%11111111 ; ########
  byte #%00000001 ;        #
  byte #%00000001 ;        #
  byte #%00000001 ;        #
  byte #%00000001 ;        #
  byte #%11111111 ; ########
  byte #%00000001 ;        #
  byte #%00000001 ;        #
  byte #%00000001 ;        #
  byte #%00000001 ;        #
  byte #%11111111 ; ########

Number4:
  byte #%10000001 ; #      #
  byte #%10000001 ; #      #
  byte #%10000001 ; #      #
  byte #%10000001 ; #      #
  byte #%10000001 ; #      #
  byte #%11111111 ; ########
  byte #%00000001 ;        #
  byte #%00000001 ;        #
  byte #%00000001 ;        #
  byte #%00000001 ;        #
  byte #%00000001 ;        #

Number5:
  byte #%11111111 ; ########
  byte #%10000000 ; #
  byte #%10000000 ; #
  byte #%10000000 ; #
  byte #%10000000 ; #
  byte #%11111111 ; ########
  byte #%00000001 ;        #
  byte #%00000001 ;        #
  byte #%00000001 ;        #
  byte #%00000001 ;        #
  byte #%11111111 ; ########

Number6:
  byte #%11111111 ; ########
  byte #%10000000 ; #
  byte #%10000000 ; #
  byte #%10000000 ; #
  byte #%10000000 ; #
  byte #%11111111 ; ########
  byte #%10000001 ; #      #
  byte #%10000001 ; #      #
  byte #%10000001 ; #      #
  byte #%10000001 ; #      #
  byte #%11111111 ; ########

Number7:
  byte #%11111111 ; ########
  byte #%00000001 ;        #
  byte #%00000001 ;        #
  byte #%00000001 ;        #
  byte #%00000001 ;        #
  byte #%00000001 ;        #
  byte #%00000001 ;        #
  byte #%00000001 ;        #
  byte #%00000001 ;        #
  byte #%00000001 ;        #
  byte #%00000001 ;        #

Number8:
  byte #%11111111 ; ########
  byte #%10000001 ; #      #
  byte #%10000001 ; #      #
  byte #%10000001 ; #      #
  byte #%10000001 ; #      #
  byte #%11111111 ; ########
  byte #%10000001 ; #      #
  byte #%10000001 ; #      #
  byte #%10000001 ; #      #
  byte #%10000001 ; #      #
  byte #%11111111 ; ########

Number9:
  byte #%11111111 ; ########
  byte #%10000001 ; #      #
  byte #%10000001 ; #      #
  byte #%10000001 ; #      #
  byte #%10000001 ; #      #
  byte #%11111111 ; ########
  byte #%00000001 ;        #
  byte #%00000001 ;        #
  byte #%00000001 ;        #
  byte #%00000001 ;        #
  byte #%11111111 ; ########

  org $1400
  rorg $F400

PuzzleInputBank1;
  PUZZLE_INPUT_BANK_1

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Fill ROM to 4KB and set reset and interrupt vectors
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  org $1FFC
  rorg $FFFC
  .word Start ; RESET
  .word Start ; BREAK

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Other memory banks - ONLY used for storing puzzle input. The initial 
;; segment will load it line by line into RAM and is replicated in every bank
;; to simplify the bank switching process and negate the need for a trampoline
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; BANK 2
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  seg code
  org $2000
  rorg $F000

  PREAMBLE
  READ_LINE_INTO_RAM ; This will switch back to bank 1

  org $2400
  rorg $F400

PuzzleInputBank2;
  PUZZLE_INPUT_BANK_2

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Fill ROM to 4KB and set reset and interrupt vectors
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  org $2FFC
  rorg $FFFC
  .word Start ; RESET
  .word Start ; BREAK

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; BANK 3
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  seg code
  org $3000         ; This is bank 3
  rorg $F000

  PREAMBLE
  READ_LINE_INTO_RAM

  org $3400
  rorg $F400

PuzzleInputBank3;
  PUZZLE_INPUT_BANK_3

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Fill ROM to 4KB and set reset and interrupt vectors
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  org $3FFC
  rorg $FFFC
  .word Start ; RESET
  .word Start ; BREAK

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; BANK 4
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  seg code
  org $4000
  rorg $F000

  PREAMBLE
  READ_LINE_INTO_RAM ; This will switch back to bank 1

  org $4400
  rorg $F400

PuzzleInputBank4;
  PUZZLE_INPUT_BANK_4

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Fill ROM to 4KB and set reset and interrupt vectors
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  org $4FFC
  rorg $FFFC
  .word Start ; RESET
  .word Start ; BREAK

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; BANK 5
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  seg code
  org $5000
  rorg $F000

  PREAMBLE
  READ_LINE_INTO_RAM ; This will switch back to bank 1

  org $5400
  rorg $F400

PuzzleInputBank5;
  PUZZLE_INPUT_BANK_5

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Fill ROM to 4KB and set reset and interrupt vectors
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  org $5FFC
  rorg $FFFC
  .word Start ; RESET
  .word Start ; BREAK

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; BANK 6
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  seg code
  org $6000
  rorg $F000

  PREAMBLE
  READ_LINE_INTO_RAM ; This will switch back to bank 1

  org $6400
  rorg $F400

PuzzleInputBank6;
  PUZZLE_INPUT_BANK_6

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Fill ROM to 4KB and set reset and interrupt vectors
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  org $6FFC
  rorg $FFFC
  .word Start ; RESET
  .word Start ; BREAK

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; BANK 7
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  seg code
  org $7000         ; This is bank 2
  rorg $F000

  PREAMBLE
  READ_LINE_INTO_RAM ; This will switch back to bank 1

  org $7400
  rorg $F400

PuzzleInputBank7;
  PUZZLE_INPUT_BANK_7

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Fill ROM to 4KB and set reset and interrupt vectors
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  org $7FFC
  rorg $FFFC
  .word Start ; RESET
  .word Start ; BREAK

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; BANK 8
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  seg code
  org $8000         ; This is bank 2
  rorg $F000

  PREAMBLE
  READ_LINE_INTO_RAM ; This will switch back to bank 1

  org $8400
  rorg $F400

PuzzleInputBank8;
  PUZZLE_INPUT_BANK_8

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Fill ROM to 4KB and set reset and interrupt vectors
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  org $8FFC
  rorg $FFFC
  .word Start ; RESET
  .word Start ; BREAK

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Some useful macros
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

  ; Takes 7 cycles
  MAC NEXT_SCANLINE
.NextScanline
                            ; Cycles - Total - Notes
    sta WSYNC               ; 2      - 2
    dec ScanlineNumber      ; 5      - 7
  ENDM

  ; Takes 7 cycles 
  MAC BANK_SWITCH
.BankSwitch
    ldx BankNumber ; 3
    ldy $FFF4,X    ; 4
  ENDM

  ; Takes 4 cycles
  MAC BANK_SWITCH_TO_0
.BankSwitchTo0
    ldy $FFF4      ; 4
  ENDM

  MAC READ_LINE_INTO_RAM
  BANK_SWITCH ; 7

.ReadNextLine:
  ; Zero out the number of notches to move
  lda #0                            ; 2   - 2 
  sta NotchesToMove                 ; 3   - 5
  sta NotchesToMove+1               ; 3   - 8
  sta NotchesToMove+2               ; 3   - 11

  ; Read the next line of puzzle input
  ldy #0                            ; 2   - 13

  ; Read the direction (if it's a binary 0 then we have reached the end of the puzzlue input)
  lda (CurrentInputPosPointer),Y    ; 5   - 18 - y is always 0 here so we cannot cross a page boundary
  cmp #90                           ; 2   - 20     - An ascii Z
  bne .Incomplete                   ; 2+1 - 22 (Complete) /23 (Incomplete)
  lda #1                            ; 2   - 24
  sta Complete                      ; 3   - 27
  jmp .InputReadTotallyComplete     ; 3   - 30

; Reach here at 23
.Incomplete:
  sta Direction                     ; 3   - 26

  NEXT_SCANLINE ; 1 SCANLINES USED
.FindEndOfNumber:
  ; Read forward until we hit an ascii char which is above the number range
                                    ; NOTE All cycle times recorded without a page boundary cross. Need to add 1-4 for potential page boundary crosses
                                    ; C   - C in loop 1st::1d::2d::3d - C in total incl pre-loop - Notes
  iny                               ; 2   -  2 :: 16 :: 30 :: 43 -  :: ::
  lda (CurrentInputPosPointer),Y    ; 5/6 -  7 :: 21 :: 35 :: 48 -  :: :: (If the earlier LDA was across a boundary this one cannot be) - Load the character at the new read position
  cmp #58                           ; 2   -  9 :: 23 :: 37 :: 50 -       :: :: - If the char is higher in the ascii table than the numbers (one of L R or N in our case)
  bpl .EndOfNumberFound             ; 2+1 - 11 :: 25 :: 38 :: 52 -       :: :: - then number end found - First time through this CANNOT be the end
  jmp .FindEndOfNumber              ; 3   - 14 :: 28 :: 41 :: __ -       :: :: - 

; Can reach here at one of (add between 1 and 4 if any page boundary was crossed) PLES 5 from next_scanline
; If 1 digits 26/27-28 (without page boundary cross/with page boundary cross(es)) 
; If 2 digits 38/39-41 (without page boundary cross/with page boundary cross(es))
; If 3 digits 53/54-57 (without page boundary cross/with page boundary cross(es))

; 62 is the Worst case with max page boundarys and 5 from NEXT_SCANLINE
.EndOfNumberFound
  NEXT_SCANLINE              ; 5 -  5 - 2 SCANLINES USED
  cmp #78                    ; 2 -  7 - If the char is a carriage return, then next bank advance needs to happen later
  bne .ContinueReadingNumber ; 2 -  9
  lda #0                     ; 2 - 11
  sta NextBank               ; 3 - 14 - Set the indicator that the next bank needs to be advanced to

; Here in 10 if no next bank indication
; Here in 14 if next bank indicated
.ContinueReadingNumber
  ; This is a VERY unsafe assumption that there can't be more than 3 digits in the input line
  ; But there isn't in mine, so it will do
  ;                                 ; C - Total if no next bank/Total if next bank - Notes
  sty IncrementBy                   ; 3 - 13/17 - Will be used later to increment the CurrentInputPosPointer to the start of the next input 
  dey                               ; 2 - 15/19 - Y is currently pointing to the char after the number, move it to the last digit

  ldx #2                            ; 2 - 17/21  


  NEXT_SCANLINE                     ; 3 SCALINES USED
  ; Total cycles in worst case is 56 from the loop below
  ; Cycles for this loop (totals include the 14 from above):
  ;    1 Digits Read - 33 - 47
  ;    2 Digits Read - 55 - 69
  ;    3 Digits Read - 77 - 91
.ReadNumber:
                                    ; C   - C in loop 1d::2d::3d - C in total incl pre-loop - Notes
                                    ; Note all recorded without page boundary cross, need to add between 1 and 3 if there was a page boundary cross
  lda (CurrentInputPosPointer),Y    ; 5/6 -  5 :: 24 :: 43 - Load the character at the new read position
  sta NotchesToMove,X               ; 5   - 10 :: 29 :: 48 -
  dey                               ; 2   - 12 :: 31 :: 50 - Move read position back 1 (beq sets Z flag)
  beq .NumberReadComplete            ; 2+1 - 14 :: 33 :: 53 - If read position is now 0, read is complete
  dex                               ; 2   - 16 :: 35 :: __ - Decrease the storage position
  jmp .ReadNumber                   ; 3   - 19 :: 38 :: __

; Can reach here at one of (add between 1 and 3 if any page boundary was crossed) PLUS 5 from next scanline above
; If 1 digits 14/15 (without page boundary cross/with page boundary cross(es)) 
; If 2 digits 33/34-35 (without page boundary cross/with page boundary cross(es))
; If 3 digits 53/54-56 (without page boundary cross/with page boundary cross(es))
; Worst case 63 cycles: 56 if 3 digits and 3 page broundary crosses + 5 from previous NEXT_SCANLINE + 2 from following NEXT_SCANLINE = 63
.NumberReadComplete:
  NEXT_SCANLINE                 ; 5   - 5  - 4 SCANLINES USED

  lda NextBank                  ; 3   - 8  - Load next bank indicator
  bne .IncrementPointer         ; 2+1 - 10 - If it's not zero then skip to increment the pointer

  inc NextBank                  ; 5   - 15 - Set NextBank indicator back to 1 to indicate we don't need to increment
  inc BankNumber                ; 5   - 20
  lda #<PuzzleInputBank1        ; 3   - 23
  sta CurrentInputPosPointer    ; 3   - 26
  lda #>PuzzleInputBank1        ; 3   - 29
  sta CurrentInputPosPointer+1  ; 3   - 32
  jmp .MacroOver                ; 3   - 35

; Reach here in 11 cycles
.IncrementPointer
  clc                             ; 2      - 11
  lda CurrentInputPosPointer      ; 3      - 14
  adc IncrementBy                 ; 3      - 17
  sta CurrentInputPosPointer      ; 3      - 20
  bcc .MacroOver                  ; 2+1    - 22/23

  clc                             ; 2      - 24 
  lda CurrentInputPosPointer+1    ; 3      - 27
  adc #1                          ; 2      - 29
  sta CurrentInputPosPointer+1    ; 3      - 32
  jmp .MacroOver                  ; 3      - 35


; Reached here at 0 SCANLINES and 30 cycles:
.InputReadTotallyComplete ; If the input is exhausted we reach here With either 30 or 31 scanlines used
  REPEAT 4
    NEXT_SCANLINE
  REPEND

; Reached here in 4 Scanlines AND
;   23 cycles if input has not been totally exhausted, and incrementing the pointer does not require a carry
;   35 cycles if input has not been totally exhausted, and incrementing the pointer does require a carry
;    5 cycles if input has not been totally exhausted
.MacroOver
  BANK_SWITCH_TO_0 ; 4
  ENDM

; Takes from 10 to 66 cycles
  MAC ADD_WHOLE_ROTATIONS

    lda NotchesToMove           ; 3        - 3
    sec                         ; 2        - 5
    sbc #48                     ; 2        - 7        - Subtract 48 from the ascii value to get the corrent binary number
    bmi .WholeRotationsFinished ; 2 + 1    - 9/10     - If it's negative then it was binary 0 meaning no digit
    sta IncrementBy             ; 3        - 12       - Set up LANDED_ON_ZERO to add the number of hundreds

    LANDED_ON_ZERO              ; 16 to 54 - 28 to 66
.WholeRotationsFinished:
  ENDM

  ; Leaves the total number of notches in BCD in A, as loaded from the tens and units columns
  ; Takes either 23 cycles if there are no tens, or 31 if there are
  MAC CALCULATE_NUMBER_OF_TENS_AND_UNITS
    ; Load the numbers of 10s
    lda NotchesToMove+1           ; 3         - 3    - Load the number of 10s (in ascii) into the accumulator
    sec                           ; 2         - 5
    sbc #48                       ; 2         - 7    - Subtract 48 from the ascii value to get the corrent binary number
    bpl .SomeTens                 ; 2 + 1     - 9/10 - If it's negative then it was binary 0 meaning no digit
    lda #0                        ; 2         - 11
    jmp .LoadUnits                ; 3         - 14

.SomeTens
    ; Convert to BCD by shifting our single digit 4 left to put it in the left most nibble
    asl                           ; 2         - 12
    asl                           ; 2         - 14
    asl                           ; 2         - 16
    asl                           ; 2         - 18

.LoadUnits                                    ; Cycles if no tens/Cycles if tens
    sta Temp                      ; 3         - 13/21 - Save the tens
    ; Now load the units
    lda NotchesToMove+2           ; 3         - 16/24
    sec                           ; 2         - 18/26
    sbc #48                       ; 2         - 20/28
    ; The units of the number cannot be missing (i.e. binary 0) so just use it at face value
    ora Temp                      ; 3        -  23/31 - OR the units in the accumulator (which can only be in the low nibble)
                                  ;          -        - with the tens in the Temp location which can only be in the high nibble
  ENDM

  ; Takes 12 cycles
  MAC SUBTRACT_CURRENT_POSITION_LEFT_TURN
    sed                                 ; 2   -  2 - Enable binary coded deciman
    sec                                 ; 2   -  4 -
    sbc Temp                            ; 3   -  7 - Subtract the tens from the current position
    sta CurrentPosition                 ; 3   - 10
    cld                                 ; 2   - 12 - Disable binary coded decimal
  ENDM

  ; Takes 14 cycles
  MAC SET_NUMBER_POINTER_TO_X ; Set X register to the number to display 0-9
                            ; Cycles - Total - Notes
    lda NumbersHighByte,X   ; 4      - 4
    sta NumberPointer       ; 3      - 7
    lda NumbersLowByte,X    ; 4      - 11
    sta NumberPointer+1     ; 3      - 14
  ENDM

  ; Takes between 16 and 54 cycles depending how many bytes overflow when added
  MAC LANDED_ON_ZERO
                                ; CYCLES - RUNNING TOTAL - Note
    sed                         ; 2     -  2 - Set binary coded decimal addition
    clc                         ; 2     -  3 - Clear the carry flag
    lda TotalTimesOnZero+3      ; 3     -  5 - Load the least significant byte into A
    adc IncrementBy             ; 3     -  8
    sta TotalTimesOnZero+3      ; 3     - 11 - Store the result
    bcc .IncComplete            ; 2 + 1 - 14 - If there was no overflow (no carry flag) then we are done

    clc                         ; 2     - 16 - Clear the carry flag
    lda TotalTimesOnZero+2      ; 3     - 18 - Given there was overflow, carry the addition to the next least significant byte
    adc #1                      ; 2     - 20
    sta TotalTimesOnZero+2      ; 3     - 23 - Store the result
    bcc .IncComplete            ; 2 + 1 - 26 - If there was no overflow (no carry flag) we are done

    clc                         ; 2     - 28 - Clear the carry flag
    lda TotalTimesOnZero+1      ; 3     - 31 - Given there was overflow, carry the addition to the next least significant byte
    adc #1                      ; 2     - 33 -
    sta TotalTimesOnZero+1      ; 3     - 36 - Store the result
    bcc .IncComplete            ; 2 + 1 - 39 - If there was no overflow (no carry flag) we are done

    clc                         ; 2     - 41 - Clear the carry flag
    lda TotalTimesOnZero        ; 3     - 44 - Given there was overflow, carry the addition to the next least significant byte
    adc #1                      ; 2     - 46 -
    sta TotalTimesOnZero        ; 3     - 49 - Store the result
    bcc .IncComplete            ; 2 + 1 - 52 - If there was no overflow (no carry flag) we are done
                                ; If there was an overflow.....oops, we exceeded our max of 8 digits
.IncComplete:
    cld                         ; 2      - 16 / 28 / 41 / 54 - Disable binary coded decimal addition
  ENDM
