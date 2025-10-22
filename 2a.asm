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
        MOVWF   dest, ACCESS
        ENDM
  GOTO main
;=============================  
;=============================

;  #include "mul_extended.asm"
;  #include "bubble_sort"
;=============================
; MAIN PROGRAM
;=============================
main:
  ; ====== Prepare three source lists ======
  LFSR 0, 0x00
  LFSR 1, 0x01
  LFSR 2, 0x02
  MOVLF 0x04, 0x00
  MOVLF 0x0F, 0x01

  ; RCALL build_list

  MOVFF POSTINC0, INDF2
  MOVF POSTINC1, w 
  ADDWF POSTINC2


  MOVFF POSTINC0, INDF2
  MOVF POSTINC1, w 
  ADDWF POSTINC2


  MOVFF POSTINC0, INDF2
  MOVF POSTINC1, w 
  ADDWF POSTINC2
  
  MOVFF POSTINC0, INDF2
  MOVF POSTINC1, w 
  ADDWF POSTINC2
  
  MOVFF POSTINC0, INDF2
  MOVF POSTINC1, w 
  ADDWF POSTINC2
  
  MOVFF POSTINC0, INDF2
  MOVF POSTINC1, w 
  ADDWF POSTINC2
  NOP
  END


