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
FOR8 MACRO i, limit, bodyLbl
    LOCAL _loop, _end
    CLRF    i          ; i = 0
_loop
    MOVF    i, W
    SUBLW   limit      ; compare i with limit
    BTFSC   STATUS, Z  ; if equal ? stop
    GOTO    _end
    BTFSS   STATUS, C  ; if i > limit ? stop
    GOTO    _end

    ; <<< Your code here >>>
    ; you can either write instructions directly here,
    ; or define a subroutine and replace the CALL below.

    CALL    bodyLbl    ; body() executes each loop

    INCF    i, F       ; i++
    GOTO    _loop
_end
ENDM
;  LFSR 0, 0x000
;  LFSR 1, 0x010
  GOTO main
;=============================  
;=============================
  bodyLbl:
    CLRF    l_bit
    CLRF    r_bit

   BCF     STATUS, C
    RLCF    lr, f
    RLCF    ll, f 

    BTFSC   STATUS, C
    MOVLF 0x01, l_bit



   BCF     STATUS, C
    RRCF    rl, f 
    RRCF    rr, f

    BTFSC   STATUS, C
    MOVLF 0x01, r_bit

    MOVF l_bit, w
    CPFSEQ  r_bit
    GOTO not_palindrome;not equal
    
   RETURN
  
;  #include "bubble_sort"
;=============================
; MAIN PROGRAM
;=============================
main:
  i  EQU 0x0A
  ll EQU 0x20
  lr EQU 0x21

  rl EQU 0x22
  rr EQU 0x23

  l_bit EQU 0x24
  r_bit EQU 0x25
  ; ====== Prepare three source lists ======
  MOVLF 0x63, 0x00
  MOVLF 0xC6, 0x01

  MOVFF   0x00, ll
  MOVFF   0x01, lr
  MOVFF   0x00, rl
  MOVFF   0x01, rr

BCF     STATUS, C
RLCF    lr, f
RLCF    ll, f

FOR8 i, 0x07, bodyLbl



is_palindrome:
  MOVLF 0xFF, 0x10
  GOTO    _fin
not_palindrome:    
  MOVLF 0x00, 0x10
_fin:
  NOP
  END
