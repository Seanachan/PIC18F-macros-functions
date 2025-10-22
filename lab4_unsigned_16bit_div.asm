LIST P=18F4520
#include <p18f4520.inc>
#include "toolbelt.asm"
  CONFIG OSC = INTIO67
  CONFIG WDT = OFF
  org 0x00
  ; i EQU 0x30
  ; j EQU 0x31
  ; limI EQU 0x32
  ; limJ EQU 0x33
  ; sum EQU 0x34
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
  MOVLF 0x00, 0x00 ;divdH
  MOVLF 0x14, 0x01 ;divdL
  MOVLF 0x00, 0x02 ;disrH
  MOVLF 0x0A, 0x03 ;disrL

   DIV16U16_UNSIGNED 0x00, 0x01, 0x02, 0x03, 0x10, 0x11, 0x12, 0x13, 0x20 
;  DIV16U8_LONG 0x00, 0x01, 0x02, 0x10, 0x11, 0x12, 0x20
  NOP
  END