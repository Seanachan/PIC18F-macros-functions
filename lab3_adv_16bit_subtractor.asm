LIST P=18F4520
#include <p18f4520.inc>
#include "toolbelt.asm"
  CONFIG OSC = INTIO67
  CONFIG WDT = OFF
  org 0x00
  i EQU 0x30
  j EQU 0x31
  limI EQU 0x32
  limJ EQU 0x33
  sum EQU 0x34
;  LFSR 0, 0x000
;  LFSR 1, 0x010
  GOTO main
;=============================  
;=============================
;  bodyLbl:
;    MOVFF i, POSTINC0
;    MOVFF j, POSTINC1
;    INCF sum, f
;    RETURN
  
;  #include "mul_extended.asm"
;  #include "bubble_sort"
;=============================
; MAIN PROGRAM
;=============================
main:
  ; ====== Prepare three source lists ======
  MOVLF 0x74, 0x00
  dH EQU 0x00
  MOVLF 0x58, 0x01
  dL EQU 0x01

  MOVLF 0x40, 0x10
  sH EQU 0x10
  MOVLF 0x46, 0x11
  sL EQU 0x11
  ; MOVLF 0x34, 0x20
  ; MOVLF 0x12, 0x21 

  SUB16_TO dL, dH, sL, sH, 0x21, 0x20

  NOP
  END