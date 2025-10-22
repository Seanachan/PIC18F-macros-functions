LIST P=18F4520
#include <p18f4520.inc>
;#include "toolbelt.asm"
  CONFIG OSC = INTIO67
  CONFIG WDT = OFF
  org 0x00
;  i EQU 0x30
;  j EQU 0x31
;  limI EQU 0x32
;  limJ EQU 0x33
;  sum EQU 0x34
;  LFSR 0, 0x000
;  LFSR 1, 0x010
  MOVLF    MACRO val, dest       ; dest = literal
        MOVLW   val
        MOVWF   dest
        ENDM
  GOTO main
nL EQU 0x00
nH EQU 0x01
 


;=============================  
;=============================

;  #include "mul_extended.asm"
;  #include "bubble_sort"
;=============================
; MAIN PROGRAM
;=============================
main:
  ; ====== Prepare three source lists ======

  
 NOP
  END


