LIST P=18F4520
#include <p18f4520.inc>
;#include "toolbelt.asm"
  CONFIG OSC = INTIO67
  CONFIG WDT = OFF
  org 0x00
MOVLF    MACRO val, dest       ; dest = literal
MOVLW   val
MOVWF   dest, ACCESS
ENDM

  GOTO main
;=============================  
;=============================
count_zeros:
  BCF     STATUS, C
  BTFSS  nH, 7 
  goto _shift
  RETURN

  _shift:
    RLCF  nL
    RLCF    nH 
    INCF    zeros, f
    GOTO    count_zeros
  RETURN
;  #include "bubble_sort"
;=============================
; MAIN PROGRAM
;=============================
main:
  mask EQU b'10000000'
  nH  EQU 0x00
  nL  EQU 0x01
  zeros EQU 0x0C
  sign EQU 0x0D
  ; ====== Prepare three source lists ======
  MOVLF 0x00, 0x00
  MOVLF 0x24, 0x01 

  MOVLF d'36', 0x02
  
  MOVF    mask, w
  ANDWF   nH, w
  MOVWF   sign
  RLNCF   sign,f

  RCALL   count_zeros

  BCF     STATUS,C
  RLCF   zeros 
  RLCF   zeros 
  BTFSC   sign, 0
  BSF     zeros, 7




  NOP
  END
