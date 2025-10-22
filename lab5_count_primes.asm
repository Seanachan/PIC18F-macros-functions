LIST P=18F4520
#include <p18f4520.inc>
#include "toolbelt.asm"
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
  GOTO main
;=============================  
;=============================
  #include "prime_test"
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
_startH EQU 0x00
_startL EQU 0x01
_endH EQU 0x02
_endL EQU 0x03

countH EQU 0x40
countL EQU 0x41
MOVLF 0x00, _startH
MOVLF 0x72, _startL
MOVLF 0x02, _endH
MOVLF 0x02, _endL
; MOVLF 0x00, _startH
;MOVLF 0x02, _startL
;MOVLF 0x00, _endH
;MOVLF 0x0A, _endL

; --- access-bank fixed addresses (example) ---
 CLRF countL, ACCESS
 CLRF countH, ACCESS

begin:
    ; if start > end ? done  (inclusive range)
CMP16U   _startL, _startH, _endL, _endH
    BR_GT16U _startL, _startH, _endL, _endH, _finish

    ; n := start
    MOVFF   _startL, nL
    MOVFF   _startH, nH
    CLRF isPrime
    CALL    prime_test          ; sets isPrime = 1 if prime, else 0

    ; if isPrime == 0 ? skip add
    BTFSS   isPrime, 0          ; skip next if bit is SET (prime)
    GOTO    skip_add            ; if not prime, jump over the add

    ; count++
    MOVLW   0x01
    ADDWF   countL, F, ACCESS
    MOVLW   0x00
    ADDWFC  countH, F, ACCESS

skip_add:
    ; start++
    MOVLW   0x01
    ADDWF   _startL, F, ACCESS
    MOVLW   0x00
    ADDWFC  _startH, F, ACCESS
    GOTO    begin

_finish:
;    DIV16U16_UNSIGNED _endH, _endL, _startH, _startL, 0x40, 0x41, 0x42,0x43,  0x0A

    NOP
 

  END