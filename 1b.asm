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

;  LFSR 0, 0x000
;  LFSR 1, 0x010
  GOTO main
;=============================  
;=============================
shift_4_l: 

;1 
BCF     STATUS, C
RLCF    l4, f
RLCF    l3, f
RLCF    l2, f
RLCF    l1, f
; 2
BCF     STATUS, C
RLCF    l4, f
RLCF    l3, f
RLCF    l2, f
RLCF    l1, f
; 3
BCF     STATUS, C
RLCF    l4, f
RLCF    l3, f
RLCF    l2, f
RLCF    l1, f
; 4
BCF     STATUS, C
RLCF    l4, f
RLCF    l3, f
RLCF    l2, f
RLCF    l1, f

RETURN  
  
shift_4_r: 
; 1
BCF     STATUS, C
RRCF    r1, f
RRCF    r2, f
RRCF    r3, f
RRCF    r4, f

; 1
BCF     STATUS, C
RRCF    r1, f
RRCF    r2, f
RRCF    r3, f
RRCF    r4, f
    
; 1
BCF     STATUS, C
RRCF    r1, f
RRCF    r2, f
RRCF    r3, f
RRCF    r4, f
    
; 1
BCF     STATUS, C
RRCF    r1, f
RRCF    r2, f
RRCF    r3, f
RRCF    r4, f
RETURN  

func:
CLRF    l_bit
CLRF    r_bit
MOVF    l_mask, w
ANDWF   l1, w
MOVWF   l_bit

MOVF    r_mask, w
ANDWF   r4, w
MOVWF   r_bit

MOVF r_bit, w
SWAPF   WREG, w
CPFSEQ  l_bit
GOTO    not_palindrome
RETURN
;  #include "bubble_sort"
;=============================
; MAIN PROGRAM
;=============================
main:
  i  EQU 0x0A
  l1 EQU 0x20
  l2 EQU 0x21
  l3 EQU 0x22
  l4 EQU 0x23

  r1 EQU 0x24
  r2 EQU 0x25
  r3 EQU 0x26
  r4 EQU 0x27

  l_bit EQU 0x28
  r_bit EQU 0x29
  l_mask EQU 0x2A
  r_mask EQU 0x2B
  ; ====== Prepare three source lists ======
  MOVLF 0xF0, l_mask
  MOVLF 0x0F, r_mask

  MOVLF 0x0C, 0x00
  MOVLF 0x22, 0x01
  MOVLF 0x22, 0x02
  MOVLF 0xC0, 0x03

  MOVFF   0x00, l1
  MOVFF   0x01, l2
  MOVFF   0x02, l3
  MOVFF   0x03, l4

  MOVFF   0x00, r1
  MOVFF   0x01, r2
  MOVFF   0x02, r3
  MOVFF   0x03, r4

RCALL shift_4_l


CALL    func
CALL    func
CALL    func



is_palindrome:
  MOVLF 0xFF, 0x10
  GOTO    _fin
not_palindrome:    
  MOVLF 0x00, 0x10
_fin:
  NOP
  END
