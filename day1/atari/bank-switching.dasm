;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
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
  include "includes/input.h"

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Define variables for use in RAM
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

  seg.u Variables
  org $80

BankNumber              byte ; Allocate a byte which tells us which bank of memory the input is being read from currently
ScanlineNumber          byte ; Allocate 1 byte to store the current scanline number
CurrentInputPosPointer  ds 2 ; Allocate enough space to store a pointer to the current position in the puzzle input
Direction               byte ; Allocate 1 byte to store the direction (L or R)
NotchesToMove           ds 3 ; Allocate enough bytes to store 3 digits for rotation
Complete                byte ; Allocate space for a flag saying that processing the input is complete
IncrementBy             byte ; Allocate space used to tell macros how much to increment $something by
NextBank                byte ; An indicator to say whether the bank needs to be advanced for more puzzle input 1 means NO, 0 means YES

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

  lda #0
  sta BankNumber

  lda #<PuzzleInputBank1
  sta CurrentInputPosPointer
  lda #>PuzzleInputBank1
  sta CurrentInputPosPointer+1

  lda #0
  sta Complete

  lda #1
  sta NextBank

NextFrame:
  ;; Set register a to value 2
  lda #2      ; 2
  ;; Store value of register a (#2) to the TIA VBLANK to enable the VBLANK
  sta VBLANK  ; 3
  ;; Store value of register a (#2) to the TIA VSYNC memory address to enable VSYNC
  sta VSYNC   ; 3

  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;; Generate the 3 lines of empty VSYNC
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  sta WSYNC   ; Set WSYNC to force the cpu to wait for the end of the 1st scanline
  sta WSYNC   ; Set WSYNC to force the cpu to wait for the end of the 2nd scanline
  sta WSYNC   ; Set WSYNC to force the cpu to wait for the end of the 3rd scanline

  lda #0
  sta VSYNC

  ldx #37
  sta ScanlineNumber 
  ENDM
  PREAMBLE

  READ_LINE_INTO_RAM  ; 4 scanlines - 9/39 - 9/39
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; END BANK PREAMBLE, this MUST be identical in every bank
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
LoopVBlank:
  sta WSYNC   ; Set WSYNC to force the cpu to wait for the end of the current VBLANK line
  dec ScanlineNumber
  bne LoopVBlank

  lda #0
  sta VBLANK  ; Q: Couldn't we just stx VBLANK instead, we know x is at 0 right now since we just looped with bne

  lda #242
  sta ScanlineNumber

LoopVisible:

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
LoopOverscan:
  sta WSYNC
  dec ScanlineNumber
  bne LoopOverscan

  jmp NextFrame

  org $1400
  rorg $F400

PuzzleInputBank1;
  PUZZLE_INPUT_BANK_1

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Fill ROM to 4KB and set NMI, reset and interrupt vectors
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  org $1FFA
  rorg $FFFA
  .word Start ; NMI
  .word Start ; RESET
  .word Start ; BREAK

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
;; Fill ROM to 4KB and set NMI, reset and interrupt vectors
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  org $2FFA
  rorg $FFFA
  .word Start ; NMI
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
;; Fill ROM to 4KB and set NMI, reset and interrupt vectors
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  org $3FFA
  rorg $FFFA
  .word Start ; NMI
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
;; Fill ROM to 4KB and set NMI, reset and interrupt vectors
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  org $4FFA
  rorg $FFFA
  .word Start ; NMI
  .word Start ; RESET
  .word Start ; BREAK

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; BANK 5
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  seg code
  org $4000
  rorg $F000

  PREAMBLE
  READ_LINE_INTO_RAM ; This will switch back to bank 1

  org $5400
  rorg $F400

PuzzleInputBank5;
  PUZZLE_INPUT_BANK_5

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Fill ROM to 4KB and set NMI, reset and interrupt vectors
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  org $5FFA
  rorg $FFFA
  .word Start ; NMI
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
;; Fill ROM to 4KB and set NMI, reset and interrupt vectors
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  org $6FFA
  rorg $FFFA
  .word Start ; NMI
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
;; Fill ROM to 4KB and set NMI, reset and interrupt vectors
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  org $7FFA
  rorg $FFFA
  .word Start ; NMI
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
;; Fill ROM to 4KB and set NMI, reset and interrupt vectors
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  org $8FFA
  rorg $FFFA
  .word Start ; NMI
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
 
  ; Macro uses 4 scanlines AND:
  ;   39 scanlines if input is not totally exhausted
  ;    9 cycles if input is totally exhausted
  ; Macro requires AT LEAST 32 cycles remaining on the current scanline
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


