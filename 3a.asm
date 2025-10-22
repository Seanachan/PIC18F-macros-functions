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
FOR2D_REG MACRO i, j, limI, limJ, bodyLbl
    LOCAL _outer, _inner, _end_inner, _end_outer

    CLRF    i                 ; i = 0
_outer
    MOVF    limI, W
    SUBWF   i, W              ; W = i - limI
    BTFSC   STATUS, Z         ; i == limI ?
    GOTO    _end_outer
    BTFSC   STATUS, C         ; i > limI ?
    GOTO    _end_outer

    MOVFF    i, j                 ; j = 0
    INCF j, f
_inner
    MOVF    limJ, W
    SUBWF   j, W              ; W = j - limJ
    BTFSC   STATUS, Z         ; j == limJ ?
    GOTO    _end_inner
    BTFSC   STATUS, C         ; j > limJ ?
    GOTO    _end_inner

    ; ---------- your operation here ----------
    CALL    bodyLbl
    ; -----------------------------------------

    INCF    j, F              ; j++
    GOTO    _inner

_end_inner
    INCF    i, F              ; i++
    GOTO    _outer

_end_outer
ENDM

  GOTO main
;=============================  
;=============================
  bodyLbl:
  LFSR    1, 0x000 ;i
  LFSR    2, 0x000 ;j

  MOVF    i, w, ACCESS
  SUBWF   j, w, ACCESS

;  MOVWF 0x0D
  BZ      _return

  cont:
    MOVF i, w
    ADDWF   FSR1L, f
    MOVF j, w
    ADDWF   FSR2L, f

    MOVF INDF1, w
    ADDWF   INDF2, w
    CPFSEQ  target
    GOTO _return
    INCF    ans, f

  _return:
  RETURN    
;  #include "bubble_sort"
;=============================
; MAIN PROGRAM
;=============================
main:
  i  EQU 0x0A
  j  EQU 0x0B
  limI EQU 0x0C
  limJ EQU 0x0D
  target EQU 0x05
  ans EQU 0x10
  ; ====== Prepare three source lists ======
  LFSR    0, 0x000
  MOVLF 0x05, POSTINC0
  MOVLF 0x05, POSTINC0
  MOVLF 0x05, POSTINC0
  MOVLF 0x05, POSTINC0
  MOVLF 0x05, POSTINC0
  MOVLF 0x0A, target

  MOVLF 0x04, limI
  MOVLF 0x05, limJ

 FOR2D_REG i, j, limI, limJ, bodyLbl
  NOP
  END
