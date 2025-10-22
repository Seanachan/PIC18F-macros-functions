LIST P=18F4520
#include <p18f4520.inc>
#include "toolbelt.asm"

  CONFIG OSC = INTIO67
  CONFIG WDT = OFF
  org 0x00
  _startH EQU 0x00
_startL EQU 0x01
_endH EQU 0x02
_endL EQU 0x03
;  LFSR 0, 0x000
;  LFSR 1, 0x010
  GOTO main
;=============================  
;=============================
  bodyLbl:
;    MOVFF i, POSTINC0
;    MOVFF j, POSTINC1
;    INCF sum, f
;    RETURN
  
  #include "mul_extended.asm"
;  #include "bubble_sort"
;=============================
; MAIN PROGRAM
;=============================
main:
  ; ====== Prepare three source lists ======
  MOVLF 0x90, 0x00
  MOVLF 0x00, 0x01
  MOVLF 0x0C, 0x02
  MOVLF 0x00, 0x03
  
  ; ====== Sort merged data ======
  
;  DIV16U8 0x10, 0x11, 0x12, 0x20, 0x21, 0x30, 0x31
;  MAC16_8x8 0x12, 0x12, 0x20, 0x21
;  FOR8 0x00, 0x0A, something
;  GCD16U_STEIN 0x01, 0x00, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09
  _finish:
    NOP
  MOVLF 0x00, _startH
MOVLF 0x03, _startL
MOVLF 0x00, _endH
MOVLF 0x03, _endL
  CMP16U   _startL, _startH, _endL, _endH
    BR_GT16U _startL, _startH, _endL, _endH, _finish
    


  NOP
  END
