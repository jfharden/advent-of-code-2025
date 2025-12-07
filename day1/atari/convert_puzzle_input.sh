#!/bin/bash

# NOTE The F4 bank switching scheme uses F4 - FB as bank switching hotspots, so the
# highest usable address is 0xFFF3
# There is 0xFF3 - 0x400 (3059) bytes of space available for puzzle input storage in each 
# rom bank, so this script takes a simple text file of the real puzzle input and outputs
# an input file with the input split into upto 8 macros of puzzle input.
# It will create empty macros where needed to pad to 8.
#
# It expects a file includes/real_puzzle_input.txt to be the real puzzle input
#
# It creates a file includes/real_puzzle_input.h which you can include in your asm file
#
# Example output
#
# ```
# ; The puzzle input should be written into the macros below
# ; Each line needs to become the 2 lines:
# ;    dc.b "<LINE>"
# ;
# ; A bank needs to end with an ASCII N if the data is to continue in the next bank
# ;    byte "N"
# ;
# ; The end of the entire input, irrespective of bank, needs to be an ascii Z
# ;    byte "Z"
# ;
# ; The very end of the puzzle input should have two byte #0 lines
# ;
# ; The input specified below is from the problem text, not a full puzzle input
# 
#   MAC PUZZLE_INPUT_BANK_1
#     dc.b "L68"
#     dc.b "L30"
#     dc.b "R48"
#     dc.b "L5"
#     dc.b "N" 
#   ENDM
# 
#   MAC PUZZLE_INPUT_BANK_2
#     dc.b "R60"
#     dc.b "L55"
#     dc.b "L1"
#     dc.b "N"
#   ENDM
# 
#   MAC PUZZLE_INPUT_BANK_3
#     dc.b "L99"
#     dc.b "R14"
#     dc.b "L82"
#     dc.b "Z" 
#   ENDM
#
#  MAC PUZZLE_INPUT_BANK_4
#  ENDM
#
#  MAC PUZZLE_INPUT_BANK_5
#  ENDM
#
#  MAC PUZZLE_INPUT_BANK_6
#  ENDM
#
#  MAC PUZZLE_INPUT_BANK_7
#  ENDM
#
#  MAC PUZZLE_INPUT_BANK_8
#  ENDM
# ```

set -euo pipefail


INPUT_FILE="includes/real_puzzle_input.txt"
OUTPUT_FILE="includes/real_puzzle_input.h"

if [ ! -f "$INPUT_FILE" ]; then
  echo "ERROR: File includes/real_puzzle_input.txt not found"
  exit 1
fi

if [ -f "$OUTPUT_FILE" ]; then
  echo "ERROR: includes/real_puzzle_input.h already exists, cowardly refusing to overwrite"
  exit 1
fi

cat <<EOF >"$OUTPUT_FILE"
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
EOF

CURRENT_BANK_NUMBER=1
BYTE_COUNT=0

function MACRO_HEADER {
  echo "  MAC PUZZLE_INPUT_BANK_${CURRENT_BANK_NUMBER}"
}

function BANK_TERMINATOR {
  echo '    dc.b "N"'
}

function MACRO_FOOTER {
  echo -e "  ENDM\n"
}

function INPUT_TERMINATOR {
  echo '    dc.b "Z"'
}

echo "BANK 1"
MACRO_HEADER >> "$OUTPUT_FILE"
while read -r LINE_WITH_NEWLINE; do
  LINE="$(tr -d "\n" <<<"$LINE_WITH_NEWLINE")"
  LINE_BYTE_COUNT="$(echo -n "$LINE" | wc -c)"
  BYTE_COUNT="$((BYTE_COUNT + LINE_BYTE_COUNT))"

  # Setting max to 3055 to have a touch of wiggle room
  if [ "$BYTE_COUNT" -ge 3055 ]; then
    BYTE_COUNT=0
    CURRENT_BANK_NUMBER=$((CURRENT_BANK_NUMBER + 1))

    echo "BANK $CURRENT_BANK_NUMBER"
    if [ "$CURRENT_BANK_NUMBER" -gt 8 ]; then
      echo "ERROR: Cannot fit input into 8 banks with 3064 bytes free"
      exit 1
    fi
    BANK_TERMINATOR >> "$OUTPUT_FILE"
    MACRO_FOOTER >> "$OUTPUT_FILE"
    MACRO_HEADER >> "$OUTPUT_FILE"
  fi

  echo "    dc.b \"$LINE\"" >> "$OUTPUT_FILE"

done < "includes/real_puzzle_input.txt"
INPUT_TERMINATOR >> "$OUTPUT_FILE"
MACRO_FOOTER >> "$OUTPUT_FILE"

CURRENT_BANK_NUMBER=$((CURRENT_BANK_NUMBER + 1))
if [ "$CURRENT_BANK_NUMBER" -le 8 ]; then
  for EMPTY_BANK_NUMBER in $(seq $CURRENT_BANK_NUMBER 8); do
    echo "BANK $CURRENT_BANK_NUMBER - EMPTY"
    MACRO_HEADER >> "$OUTPUT_FILE"
    MACRO_FOOTER >> "$OUTPUT_FILE"

    CURRENT_BANK_NUMBER=$((CURRENT_BANK_NUMBER + 1))
  done
fi
