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
TotalTimesOnZero           ds 3 ; Allocate space to store total times on zero
DigitBitmapPointer1        word ; Store pointer to the bitmap graphic of the value of digit 1 of the times on zero
DigitBitmapPointer2        word ; Store pointer to the bitmap graphic of the value of digit 2 of the times on zero
DigitBitmapPointer3        word ; Store pointer to the bitmap graphic of the value of digit 3 of the times on zero
DigitBitmapPointer4        word ; Store pointer to the bitmap graphic of the value of digit 4 of the times on zero
DigitBitmapPointer5        word ; Store pointer to the bitmap graphic of the value of digit 5 of the times on zero
DigitBitmapPointer6        word ; Store pointer to the bitmap graphic of the value of digit 6 of the times on zero
SixDigitDisplayLoopCount   byte ; Used for counting which line of the 6 digit display loop we are in
Temp                       byte ; Allocate some temporary working space

BankNumber              byte ; Allocate a byte which tells us which bank of memory the input is being read from currently
NextBank                byte ; An indicator to say whether the bank needs to be advanced for more puzzle input 1 means NO, 0 means YES
ScanlineNumber          byte ; Allocate 1 byte to store the current scanline number
CurrentInputPosPointer  ds 2 ; Allocate enough space to store a pointer to the current position in the puzzle input
Direction               byte ; Allocate 1 byte to store the direction (L or R)
NotchesToMove           ds 3 ; Allocate enough bytes to store 3 digits for rotation
CurrentPosition         byte ; Allocate space for the current position of the dial
Complete                byte ; Allocate space for a flag saying that processing the input is complete
IncrementBy             byte ; Allocate space for a variable to store how much to incremnet something by (used by multiple macros)

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

  jmp BeginProper

; Note: This subroutine needs to be in the preamble since it will switch banks back and forward
; Takes 4 Scanlines AND (including RTS)
;   32 cycles if input has not been totally exhausted, and incrementing the pointer does not require a carry
;   44 cycles if input has not been totally exhausted, and incrementing the pointer does require a carry
;   12 cycles if input has not been totally exhausted
ReadLineIntoRam:
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
  iny                               ; 2   -  2 :: 16 :: 30 :: 43 -
  lda (CurrentInputPosPointer),Y    ; 5/6 -  7 :: 21 :: 35 :: 48 - (If the earlier LDA was across a boundary this one cannot be) - Load the character at the new read position
  cmp #58                           ; 2   -  9 :: 23 :: 37 :: 50 - If the char is higher in the ascii table than the numbers (one of L R or N in our case)
  bpl .EndOfNumberFound             ; 2+1 - 11 :: 25 :: 38 :: 52 - then number end found - First time through this CANNOT be the end
  jmp .FindEndOfNumber              ; 3   - 14 :: 28 :: 41 :: __ -

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
  clc                             ; 2      - 13
  lda CurrentInputPosPointer      ; 3      - 16
  adc IncrementBy                 ; 3      - 19
  sta CurrentInputPosPointer      ; 3      - 22
  bcc .MacroOver                  ; 2+1    - 24/25

  clc                             ; 2      - 26
  lda CurrentInputPosPointer+1    ; 3      - 29
  adc #1                          ; 2      - 31
  sta CurrentInputPosPointer+1    ; 3      - 34
  jmp .MacroOver                  ; 3      - 37


; Reached here at 0 SCANLINES and 30 cycles:
.InputReadTotallyComplete ; If the input is exhausted we reach here With either 30 or 31 scanlines used
  BANK_SWITCH_TO_0                ; 4      - 34
  rts

; Reached here in 4 Scanlines AND
;   25 cycles if input has not been totally exhausted, and incrementing the pointer does not require a carry
;   37 cycles if input has not been totally exhausted, and incrementing the pointer does require a carry
;    5 cycles if input has not been totally exhausted
.MacroOver
  BANK_SWITCH_TO_0 ; 4
  rts              ; 3

BeginProper:
  lda #$0E
  sta COLUP0  ; Set the colour of the player 1 bitmap to white
  sta COLUP1  ; Set the colour of the player 2 bitmap to white
  lda #$00
  sta COLUBK  ; Set the background colour to black
  lda #8
  ; lda #50
  lda #%01010000 ; 50 in binary coded decimal
  sta CurrentPosition

  lda #<PuzzleInputBank1
  sta CurrentInputPosPointer
  lda #>PuzzleInputBank1
  sta CurrentInputPosPointer+1

  lda #1
  sta NextBank

  ; The high byte of the digit bitmap pointers will never change, it's always the same location in
  ; the ROM, so lets set them all now and we never need to use cycles on it when running
  lda #>Number0                 ; 3 -  3 - Load the high byte of the memory address of the Number graphics
  sta DigitBitmapPointer1+1     ; 4 -  7 - Store it in the high byte of every digit bitmap pointer
  sta DigitBitmapPointer2+1     ; 4 - 11 - Store it in the high byte of every digit bitmap pointer
  sta DigitBitmapPointer3+1     ; 4 - 15 - Store it in the high byte of every digit bitmap pointer
  sta DigitBitmapPointer4+1     ; 4 - 19 - Store it in the high byte of every digit bitmap pointer
  sta DigitBitmapPointer5+1     ; 4 - 23 - Store it in the high byte of every digit bitmap pointer
  sta DigitBitmapPointer6+1     ; 4 - 27 - Store it in the high byte of every digit bitmap pointer

  ; The six digit display is the only thing we are ever displaying, so we can just set it's position once and never again
  sta WSYNC     ; 3  - 3
  SLEEP 32      ; 32 - 35

  lda #3        ; 2  - 37
  ldx #$f0      ; 2  - 39
  stx RESP0     ; 3  - 42 - Position P0 at 42 cycles = 126 Colour clocks = 58 pixels (but 1 more from the stx HMP0 below, so actually 59 pixels)
  stx RESP1     ; 3  - 45 - Position P1 at 45 cycles = 135 Colour Clocks = 67 pixels
  stx HMP0      ; 3  - 48 - Store F0 in HMP0 which sets Player 0 to move right 1 colour clock 
  sta NUSIZ0    ; 3  - 51 - Set Player 0 to repeat the graphic 3 times "close" (with 8 pixel gaps). Changing the value of GRP0 between the display of these 3 copies is the key to getting 6 digits displayed)
  sta NUSIZ1    ; 3  - 54 - Set Player 1 to repeat the graphic 3 times "close" (with 8 pixel gaps). Changing the value of GRP1 between the display of these 3 copies is the key to getting 6 digits displayed)
  lda #1           
  sta VDELP0  ; This means when we write to GRP0 it is placed into a buffer, and only written when we write to GRP1, and vice versa
  sta VDELP1  ; GRP1 will not be written after we set it until we write to GRP0. These were intended to shift a graphic down a scanline
  sta WSYNC   ; Start a new Scanline
  sta HMOVE   ; Move the player graphics to the positions specified above

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
  jsr SetGraphicsPointers ; 6 + 88
  sta WSYNC
  sta WSYNC

  lda #0
  sta VSYNC   ; We have now rendered the VSYNC

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Generate the 37 lines of VBLANK
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  lda #37                           ; 2   - 2
  sta ScanlineNumber                ; 3   - 5

  lda Complete                      ; 3   - 8
  beq ProcessInput                  ; 2+1 - 12/13
  jmp LoopVBlank                    ; 3   - 15
  ENDM ; PREAMBLE
  PREAMBLE

ProcessInput:
  lda ScanlineNumber
  cmp #10               ; If we have at least 10 scanlines left we can process more input
  bmi LoopVBlank        ; Otherwise just exhaust the rest of the scanlines

  jsr ReadLineIntoRam   ; 4 scanlines - 12/44 - 12/44
  NEXT_SCANLINE         ; 2 previous scanline, 5 next scanline
  jsr ProcessLine       ; 4 scanlines
  jmp ProcessInput

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

; This 6 digit score display is heavily inspired by a combination for the following books:
; "Programming Games for Atari 2600" by Oscar Toledo G. First published in 2022. ISBN 978-1-387-80996-7
; "Making Games for the Atari 2600" by Steven Hugg. Second Printing in 2018. ISBN 978-1-541-02130-3
HorizontalScore:
  sta WSYNC
  lda #7
  sta SixDigitDisplayLoopCount

SixDigitDisplayLoop:
  ; On the end of the scanline prior to the score, store the graphics for P0 and P1 (which will be the line of digit 1 and 2)
  ldy SixDigitDisplayLoopCount                   
  lda (DigitBitmapPointer1),Y
  sta GRP0                      ; Store line of digit 1 in the TIA graphics buffer read to write to GRP0 (since VDELP0 is enabled)
  sta WSYNC                     ; Next scanline
  lda (DigitBitmapPointer2),Y
  sta GRP1                      ; Store line of digit 2 in the TIA graphics buffer (and therefore also write the previous entry in the buffer to GRP0)
  lda (DigitBitmapPointer3),Y   
  sta GRP0                      ; Store line of digit 3 into the TIA graphics buffer (and therefore also write the previous entry in the buffer to GRP1)
  lda (DigitBitmapPointer4),Y
  sta Temp                      ; Store line of digit 4 into the Temp memory address
  lda (DigitBitmapPointer5),Y
  tax                           ; Store line of digit 5 into the X register
  lda (DigitBitmapPointer6),Y
  tay                           ; Store line of digit 6 into the Y register
  lda Temp
  ; At this point:
  ;   * GRP0 contains line of digit 1
  ;   * GRP1 contains line of digit 2
  ;   * GRP0 BUFFER contains line of digit 3
  ;   * A contains line of digit 4
  ;   * X contains line of digit 5
  ;   * Y contains line of digit 6
  ;   * Digit 1 (GRP0) should have displayed
  ;   * Digit 2 (GRP1) should be displaying
  sta GRP1 ; Digit 3 from buffer into GRP0, Line of digit 4 into GRP1 buffer
  stx GRP0 ; Digit 4 from buffer into GRP1, Line of digit 5 into GRP0 buffer
  sty GRP1 ; Digit 5 from buffer into GRP0, Line of digit 6 into GRP1 buffer
  sta GRP0 ; Digit 6 from buffer into GRP1, Doesn't matter what we STA into GRP0 here, we just need to trigger the vertical delay buffer write
  dec SixDigitDisplayLoopCount
  bpl SixDigitDisplayLoop

  NEXT_SCANLINE

  ; Reset all the graphics so they stop being drawn
  lda #0
  sta GRP0
  sta GRP1
  sta GRP0
  sta GRP1

  ; We have used up some scanlines above which are unaccounted for, so deduct them from the ScanlineNumber
  lda ScanlineNumber
  sec
  sbc #9             ; 8 lines of graphics, 1 lines of WSYNC prior to graphics
  sta ScanlineNumber

ScanToEndOfVisible:
  NEXT_SCANLINE           ; 2 previous scanline, 5 next scanline
  bne ScanToEndOfVisible  ; 2+1

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Draw the Overscan - turn on vertical blank first
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  lda #2
  sta VBLANK

  lda #30
  sta ScanlineNumber

  lda Complete
  beq FinishOverscan

ProcessInputInOverscan:
  lda ScanlineNumber
  cmp #10
  bmi FinishOverscan

  jsr ReadLineIntoRam   ; 4 scanlines - 12/44 - 12/44
  NEXT_SCANLINE         ; 2 previous scanline, 5 next scanline
  jsr ProcessLine       ; 4 scanlines
  jmp ProcessInputInOverscan

FinishOverscan:
  lda ScanlineNumber
  beq OverscanComplete
  NEXT_SCANLINE
  jmp FinishOverscan
  
OverscanComplete:
  jmp NextFrame

; Takes 88 cycles including RTS
SetGraphicsPointers:
  ; Digit 1
  lda TotalTimesOnZero          ; 3 -  3
  and #$F0                      ; 2 -  5 - Isolate the upper nibble
  ; To move the upper nibble to the bottom nibble is 4 right shifts,
  ; then to multiple the BCD digit by 8 (which gets us the offset from the
  ; Number0 label that our number actually starts) is left shift 3 times,
  ; So overall we can just right shift once
  lsr                           ; 2 -  7
  sta DigitBitmapPointer1       ; 3 - 10 - Store Pointer to the low byte

  ; Digit 2
  lda TotalTimesOnZero          ; 3 - 13
  and #$0F                      ; 2 - 15 - Isolate the low nibble
  asl                           ; 2 - 17 - Multiple the BCD digit by 8 to get the offset
  asl                           ; 2 - 19 - from the Number0 label that our number actually
  asl                           ; 2 - 21 - starts
  sta DigitBitmapPointer2       ; 3 - 34

  ; Digit 3
  lda TotalTimesOnZero+1        ; 3 - 37
  and #$F0                      ; 2 - 39 - Isolate the upper nibble
  lsr                           ; 2 - 41
  sta DigitBitmapPointer3       ; 3 - 44 - Store Pointer to the low byte

  ; Digit 4
  lda TotalTimesOnZero+1        ; 3 - 47
  and #$0F                      ; 2 - 49 - Isolate the low nibble
  asl                           ; 2 - 51 - Multiple the BCD digit by 8 to get the offset
  asl                           ; 2 - 53 - from the Number0 label that our number actually
  asl                           ; 2 - 55 - starts
  sta DigitBitmapPointer4       ; 3 - 58

  ; Digit 5
  lda TotalTimesOnZero+2        ; 3 - 61
  and #$F0                      ; 2 - 63 - Isolate the upper nibble
  ; To move the upper nibble to the bottom nibble is 4 right shifts,
  ; then to multiple the BCD digit by 8 (which gets us the offset from the
  ; Number0 label that our number actually starts) is left shift 3 times,
  ; So overall we can just right shift once
  lsr                           ; 2 - 65
  sta DigitBitmapPointer5       ; 3 - 68 - Store Pointer to the low byte

  ; Digit 6
  lda TotalTimesOnZero+2        ; 3 - 71
  and #$0F                      ; 2 - 73 - Isolate the low nibble
  asl                           ; 2 - 75 - Multiple the BCD digit by 8 to get the offset
  asl                           ; 2 - 77 - from the Number0 label that our number actually
  asl                           ; 2 - 79 - starts
  sta DigitBitmapPointer6       ; 3 - 82

  rts

; Takes  1 - 4 Scanlines & 8 cycles (including 3 for the RTS)
ProcessLine:
  lda Complete                 ; 3   - 3
  beq .ContinueToCountNotches  ; 2+1 - 5
  jmp .EndLineProcessing       ; 3   - 8

; Addive here at 6 cycles
.ContinueToCountNotches:
  NEXT_SCANLINE         ; 2 previous, 5 next - 1 SCANLINES - Such a waste, but it's the only sane way to cope with ADD_WHOLE_ROTATIONS wide variance

  ADD_WHOLE_ROTATIONS   ; 10 to 66 - Direction doesn't matter, add whole rotations

  NEXT_SCANLINE         ; 2 previous, 5 next - 2 SCANLINES

  CALCULATE_NUMBER_OF_TENS_AND_UNITS    ; 23/31 - 28/36 (incl 5 from next scaline above) - Load the BCD tens and units from the current line
  bne .CheckDirection                   ; 2+1   - 38/39 - If the number of notches isn't 0 then there's nothing left to do, just end processing
  jmp .EndLineProcessing                ; 3     - 41

.CheckDirection:
  ; Left or right - cycles only counting worst case from CALCULATE_NUMBER_OF_TENS_AND_UNITS
  ldx Direction                         ; 3   - 42
  cpx #$4c                              ; 2   - 44    - L in ascii
  beq .LeftTurn                         ; 2+1 - 46/47
  jmp .RightTurn                        ; 3   - 49    - If it wasn't left, it must be right so just jump

; Arrive here at 2 Scanlines & 47 cycles
; The accumulator contains the number of tens and units in BCD
.LeftTurn:
  sta Temp                              ; 3     - 49
  lda CurrentPosition                   ; 3     - 52
  beq .JustSubtractLeftTurn             ; 2+1   - 54/55  - If the current position was ALREADY 0 it's already been accounted for
                                        ;                - so just do the subtraction, but don't increment the counter for having passed 0

  SUBTRACT_CURRENT_POSITION_LEFT_TURN   ; 12    - 66
  bcc .LandedOnOrPassedZeroTurningLeft  ; 2+1   - 68/69 - If the carry flag was unset by the subtraction then we rolled over and passed zero
  beq .LandedOnOrPassedZeroTurningLeft  ; 2+1   - 70/71 - If we didn't land on zero then skip
  NEXT_SCANLINE                         ; 2 previous, 5 next - 3 Scanlines
  jmp .EndLineProcessing                ; 3     - 7

; Arrive here at 2 Scanlines & 69 OR 71 Cycles
.LandedOnOrPassedZeroTurningLeft:
  NEXT_SCANLINE                       ; 2 previous, 5 next - 3 SCANLINES
  lda #1                              ; 2   -  7
  sta IncrementBy                     ; 3   - 10
  LANDED_ON_ZERO                      ; 16 to 56 - 26-66
  jmp .EndLineProcessing              ; 3        - 29-69

; Arrive here at 2 Scalines & 55 cycles
.JustSubtractLeftTurn:
  SUBTRACT_CURRENT_POSITION_LEFT_TURN ; 12  - 67
  jmp .EndLineProcessing              ; 3   - 70

; Arrive here at 2 Scanlines & 49 cycles
; The accumulator contains the number of tens and units in BCD
.RightTurn:
  sta Temp              ; 3   - 52
  lda CurrentPosition   ; 3   - 55
  sed                   ; 2   - 57
  clc                   ; 2   - 59
  adc Temp              ; 3   - 62
  sta CurrentPosition   ; 3   - 65
  cld                   ; 2   - 67
  bcc .EndLineProcessing ; 2+1 - 69/70 ; No carry meaning we didn't go from 99 to 0, so no landing on 0

  NEXT_SCANLINE         ; 2 previous, 5 next, 3 SCANLINES
  lda #1                ; 2   - 7  (including 5 from NEXT_SCANLINE)
  sta IncrementBy       ; 3   - 10
  LANDED_ON_ZERO        ; 16 to 54 - 26 to 64

; Arrive here at:
;   0 Scanlines &     8 cycles if processing is already complete
;   2 Scanlines &    41 cycles if there were only whole rotations (e.g. if the number of turns is evenly divisible by 100)
;   2 Scanlines &    70 cycles if the current position was already 0 when the dial was turned left
;   3 Scanlines &     7 cycles if there were tens and units of turns which DIDN'T land on or cross zero
;   3 Scanlines & 29-69 cycles if if a left turn landed on, or crossed zero
;   3 Scanlines & 26-64 cycles if it was a right turn
.EndLineProcessing
  NEXT_SCANLINE
  rts

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Number graphics
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  align $100  ; Timing is so crucial for referencing these graphics we cannot afford to cross a page boundary
              ; so assure they are aligned into a single page of memory
; All of the numbers REQUIRE a blank column at the start to allow for correct spacing in a 6 digit horizontal number kernel
; Also all the numbers are upside down, their final row is the first one loaded, and their first row is the last one loaded
Number0:
  byte #0 ; All of the digits need to be a power of 2 after the previous, so add an empty byte
  byte #%00111110 ;   #####
  byte #%01000001 ;  #     #
  byte #%01000001 ;  #     #
  byte #%01000001 ;  #     #
  byte #%01000001 ;  #     #
  byte #%01000001 ;  #     #
  byte #%00111110 ;   #####

Number1:
  byte #0 ; All of the digits need to be a power of 2 after the previous, so add an empty byte
  byte #%00001000 ;     #
  byte #%00001000 ;     #
  byte #%00001000 ;     #
  byte #%00001000 ;     #
  byte #%00001000 ;     #
  byte #%00001000 ;     #
  byte #%00001000 ;     #

Number2:
  byte #0 ; All of the digits need to be a power of 2 after the previous, so add an empty byte
  byte #%01111111 ;  #######
  byte #%01000000 ;  #
  byte #%01000000 ;  #
  byte #%01111111 ;  #######
  byte #%00000001 ;        #
  byte #%00000001 ;        #
  byte #%01111111 ;  #######

Number3:
  byte #0 ; All of the digits need to be a power of 2 after the previous, so add an empty byte
  byte #%01111111 ;  #######
  byte #%00000001 ;        #
  byte #%00000001 ;        #
  byte #%01111111 ;  #######
  byte #%00000001 ;        #
  byte #%00000001 ;        #
  byte #%01111111 ;  #######

Number4:
  byte #0 ; All of the digits need to be a power of 2 after the previous, so add an empty byte
  byte #%00000001 ;        #
  byte #%00000001 ;        #
  byte #%00000001 ;        #
  byte #%01111111 ;  #######
  byte #%01000001 ;  #     #
  byte #%01000001 ;  #     #
  byte #%01000001 ;  #     #

Number5:
  byte #0 ; All of the digits need to be a power of 2 after the previous, so add an empty byte
  byte #%01111111 ;  #######
  byte #%00000001 ;        #
  byte #%00000001 ;        #
  byte #%01111111 ;  #######
  byte #%01000000 ;  #
  byte #%01000000 ;  #
  byte #%01111111 ;  #######

Number6:
  byte #0 ; All of the digits need to be a power of 2 after the previous, so add an empty byte
  byte #%01111111 ;  #######
  byte #%01000001 ;  #     #
  byte #%01000001 ;  #     #
  byte #%01111111 ;  #######
  byte #%01000000 ;  #
  byte #%01000000 ;  #
  byte #%01111111 ;  #######

Number7:
  byte #0 ; All of the digits need to be a power of 2 after the previous, so add an empty byte
  byte #%00000001 ;        #
  byte #%00000001 ;        #
  byte #%00000001 ;        #
  byte #%00000001 ;        #
  byte #%00000001 ;        #
  byte #%00000001 ;        #
  byte #%01111111 ;  #######

Number8:
  byte #0 ; All of the digits need to be a power of 2 after the previous, so add an empty byte
  byte #%01111111 ;  #######
  byte #%01000001 ;  #     #
  byte #%01000001 ;  #     #
  byte #%01111111 ;  #######
  byte #%01000001 ;  #     #
  byte #%01000001 ;  #     #
  byte #%01111111 ;  #######

Number9:
  byte #0 ; All of the digits need to be a power of 2 after the previous, so add an empty byte
  byte #%01111111 ;  #######
  byte #%00000001 ;        #
  byte #%00000001 ;        #
  byte #%01111111 ;  #######
  byte #%01000001 ;  #     #
  byte #%01000001 ;  #     #
  byte #%01111111 ;  #######

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

  MAC PROCESS_LINE
.ProcessLine
    lda Complete                 ; 3   - 3
    beq .ContinueToCountNotches  ; 2+1 - 5
    jmp .EndLineProcessing       ; 3   - 8

; Addive here at 6 cycles
.ContinueToCountNotches:
    NEXT_SCANLINE         ; 2 previous, 5 next - 1 SCANLINES - Such a waste, but it's the only sane way to cope with ADD_WHOLE_ROTATIONS wide variance

    ADD_WHOLE_ROTATIONS   ; 10 to 66 - Direction doesn't matter, add whole rotations

    NEXT_SCANLINE         ; 2 previous, 5 next - 2 SCANLINES

    CALCULATE_NUMBER_OF_TENS_AND_UNITS    ; 23/31 - 28/36 (incl 5 from next scaline above) - Load the BCD tens and units from the current line
    bne .CheckDirection                   ; 2+1   - 38/39 - If the number of notches isn't 0 then there's nothing left to do, just end processing
    jmp .EndLineProcessing                ; 3     - 41

.CheckDirection:
    ; Left or right - cycles only counting worst case from CALCULATE_NUMBER_OF_TENS_AND_UNITS
    ldx Direction                         ; 3   - 42
    cpx #$4c                              ; 2   - 44    - L in ascii
    beq .LeftTurn                         ; 2+1 - 46/47
    jmp .RightTurn                        ; 3   - 49    - If it wasn't left, it must be right so just jump

; Arrive here at 2 Scanlines & 47 cycles
; The accumulator contains the number of tens and units in BCD
.LeftTurn:
    sta Temp                              ; 3     - 49
    lda CurrentPosition                   ; 3     - 52
    beq .JustSubtractLeftTurn             ; 2+1   - 54/55  - If the current position was ALREADY 0 it's already been accounted for
                                          ;                - so just do the subtraction, but don't increment the counter for having passed 0

    SUBTRACT_CURRENT_POSITION_LEFT_TURN   ; 12    - 66
    bcc .LandedOnOrPassedZeroTurningLeft  ; 2+1   - 68/69 - If the carry flag was unset by the subtraction then we rolled over and passed zero
    beq .LandedOnOrPassedZeroTurningLeft  ; 2+1   - 70/71 - If we didn't land on zero then skip
    NEXT_SCANLINE                         ; 2 previous, 5 next - 3 Scanlines
    jmp .EndLineProcessing                ; 3     - 7

; Arrive here at 2 Scanlines & 69 OR 71 Cycles
.LandedOnOrPassedZeroTurningLeft:
    NEXT_SCANLINE                       ; 2 previous, 5 next - 3 SCANLINES
    lda #1                              ; 2   -  7
    sta IncrementBy                     ; 3   - 10
    LANDED_ON_ZERO                      ; 16 to 56 - 26-66
    jmp .EndLineProcessing              ; 3        - 29-69

; Arrive here at 2 Scalines & 55 cycles
.JustSubtractLeftTurn:
    SUBTRACT_CURRENT_POSITION_LEFT_TURN ; 12  - 67
    jmp .EndLineProcessing              ; 3   - 70

; Arrive here at 2 Scanlines & 49 cycles
; The accumulator contains the number of tens and units in BCD
.RightTurn:
    sta Temp              ; 3   - 52
    lda CurrentPosition   ; 3   - 55
    sed                   ; 2   - 57
    clc                   ; 2   - 59
    adc Temp              ; 3   - 62
    sta CurrentPosition   ; 3   - 65
    cld                   ; 2   - 67
    bcc .EndLineProcessing ; 2+1 - 69/70 ; No carry meaning we didn't go from 99 to 0, so no landing on 0

    NEXT_SCANLINE         ; 2 previous, 5 next, 3 SCANLINES
    lda #1                ; 2   - 7  (including 5 from NEXT_SCANLINE)
    sta IncrementBy       ; 3   - 10
    LANDED_ON_ZERO        ; 16 to 54 - 26 to 64

; Arrive here at:
;   0 Scanlines &     8 cycles if processing is already complete
;   2 Scanlines &    41 cycles if there were only whole rotations (e.g. if the number of turns is evenly divisible by 100)
;   2 Scanlines &    70 cycles if the current position was already 0 when the dial was turned left
;   3 Scanlines &     7 cycles if there were tens and units of turns which DIDN'T land on or cross zero
;   3 Scanlines & 29-69 cycles if if a left turn landed on, or crossed zero
;   3 Scanlines & 26-64 cycles if it was a right turn
.EndLineProcessing
  ENDM ; PROCESS_LINE

  ; Takes 7 cycles
  MAC NEXT_SCANLINE
.NextScanline
                            ; Cycles - Total - Notes
    sta WSYNC               ; 2      - 2
    dec ScanlineNumber      ; 5      - 7
  ENDM ; NEXT_SCANLINE

  ; Takes 5 cycles
  MAC SKIP_SCANLINE
.NextScanline
                            ; Cycles - Total - Notes
    dec ScanlineNumber      ; 5      - 5
  ENDM ; SKIP_SCANLINE

  ; Takes 7 cycles
  MAC BANK_SWITCH
.BankSwitch
    ldx BankNumber ; 3
    ldy $FFF4,X    ; 4
  ENDM ; BANK_SWITCH

  ; Takes 4 cycles
  MAC BANK_SWITCH_TO_0
.BankSwitchTo0
    ldy $FFF4      ; 4
  ENDM ; BANK_SWITCH_TO_0

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
  iny                               ; 2   -  2 :: 16 :: 30 :: 43 -
  lda (CurrentInputPosPointer),Y    ; 5/6 -  7 :: 21 :: 35 :: 48 - (If the earlier LDA was across a boundary this one cannot be) - Load the character at the new read position
  cmp #58                           ; 2   -  9 :: 23 :: 37 :: 50 - If the char is higher in the ascii table than the numbers (one of L R or N in our case)
  bpl .EndOfNumberFound             ; 2+1 - 11 :: 25 :: 38 :: 52 - then number end found - First time through this CANNOT be the end
  jmp .FindEndOfNumber              ; 3   - 14 :: 28 :: 41 :: __ -

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
  clc                             ; 2      - 13
  lda CurrentInputPosPointer      ; 3      - 16
  adc IncrementBy                 ; 3      - 19
  sta CurrentInputPosPointer      ; 3      - 22
  bcc .MacroOver                  ; 2+1    - 24/25

  clc                             ; 2      - 26
  lda CurrentInputPosPointer+1    ; 3      - 29
  adc #1                          ; 2      - 31
  sta CurrentInputPosPointer+1    ; 3      - 34
  jmp .MacroOver                  ; 3      - 37


; Reached here at 0 SCANLINES and 30 cycles:
.InputReadTotallyComplete ; If the input is exhausted we reach here With either 30 or 31 scanlines used
  BANK_SWITCH_TO_0                ; 4      - 34
  jmp LoopVBlank                  ; 3      - 37 - Skip all further processing and jump skipping the remaining veritcal blank

; Reached here in 4 Scanlines AND
;   25 cycles if input has not been totally exhausted, and incrementing the pointer does not require a carry
;   37 cycles if input has not been totally exhausted, and incrementing the pointer does require a carry
;    5 cycles if input has not been totally exhausted
.MacroOver
  BANK_SWITCH_TO_0 ; 4
  ENDM ; READ_LINE_INTO_RAM

; Takes from 10 to 66 cycles
  MAC ADD_WHOLE_ROTATIONS

    lda NotchesToMove           ; 3        - 3
    sec                         ; 2        - 5
    sbc #48                     ; 2        - 7        - Subtract 48 from the ascii value to get the corrent binary number
    bmi .WholeRotationsFinished ; 2 + 1    - 9/10     - If it's negative then it was binary 0 meaning no digit
    sta IncrementBy             ; 3        - 12       - Set up LANDED_ON_ZERO to add the number of hundreds

    LANDED_ON_ZERO              ; 16 to 54 - 28 to 66
.WholeRotationsFinished:
  ENDM ; ADD_WHOLE_ROTATIONS

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
  ENDM ; CALCULATE_NUMBER_OF_TENS_AND_UNITS

  ; Takes 12 cycles
  MAC SUBTRACT_CURRENT_POSITION_LEFT_TURN
    sed                                 ; 2   -  2 - Enable binary coded deciman
    sec                                 ; 2   -  4 -
    sbc Temp                            ; 3   -  7 - Subtract the tens from the current position
    sta CurrentPosition                 ; 3   - 10
    cld                                 ; 2   - 12 - Disable binary coded decimal
  ENDM ; SUBTRACT_CURRENT_POSITION_LEFT_TURN

  ; Takes 18, 28, or 35 cycles depending how many times the addition needs to carry
  ; This could be a constant time of 31 cycles by omitting the bcc's, but we want to use
  ; as few cycles as possible, and I will move to using INTIM/TIMINT for timing instead of
  ; aligning with individual scanlines, which means every cycle saved is worth it.
  ; Given only 1 in every 10000 increments will overflow to the third digit, we save a lot
  ; of cycles overall
  MAC LANDED_ON_ZERO
.LandedOnZero
                                ; C   - Running Total
    sed                         ; 2   -  2    - Set binary coded decimal addition
    clc                         ; 2   -  4    - Clear the carry flag
    lda TotalTimesOnZero+2      ; 3   -  7    - Load the least significant byte into the accumulator
    adc IncrementBy             ; 3   - 10    - Add the desired Increment
    sta TotalTimesOnZero+2      ; 3   - 13    - Store the result
    bcc .IncrementComplete      ; 2/3 - 15/16 - If there was no overflow just finish
    lda TotalTimesOnZero+1      ; 3   - 18    - In case there was overflow load the next most significant byte
    adc #0                      ; 2   - 20    - Add only the carry flag, should it have been set
    sta TotalTimesOnZero+1      ; 3   - 23    - Store the result
    bcc .IncrementComplete      ; 2/3 - 25/26
    lda TotalTimesOnZero        ; 3   - 28    - In case there was overflow load the most significant byte
    adc #0                      ; 2   - 30    - Add only the carry flag, should it have been set
    sta TotalTimesOnZero        ; 3   - 33    - Store the result
                                ; If there was an overflow.....oops, we exceeded our max of 6 digits
.IncrementComplete
    cld                         ; 2  - 18/28/35 - Disable binary coded decimal addition
  ENDM ; LANDED_ON_ZERO


