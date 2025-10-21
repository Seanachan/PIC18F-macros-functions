#include <p18f4520.inc>
#include "toolbelt.asm"
  LIST P=18F4520
  CONFIG OSC = HS
  CONFIG WDT = OFF
  cblock 0x20
    j  
    i 
    len
    pivot
  endc
REST_VECT: CODE 0x0000
 GOTO	main
bodyLbl:
  MOVF pivot, w
  CPFSGT  INDF2, ACCESS
  GOTO cont

  GOTO _return
cont:
  MOVF INDF0, w, ACCESS
  MOVFF INDF2, INDF0
  MOVWF INDF2, ACCESS
  INCF i, F
  INCF FSR0L, F

_return:
  INCF FSR2L, F
  
  RETURN

main:
  MOVLF 0x07, len
  MOVLB 0x000
  LFSR 0, 0x000
  
  MOVLF 0x01, POSTINC0
  MOVLF 0x03, POSTINC0
  MOVLF 0x07, POSTINC0
  MOVLF 0x02, POSTINC0
  MOVLF 0x09, POSTINC0
  MOVLF 0x08, POSTINC0
  MOVLF 0x04, POSTINC0
  MOVLF 0x06, INDF0
  MOVLF 0x01, i
  
  MOVFF INDF0, pivot;pivot
  CLRF j
  LFSR 0, 0x000 ;i
  LFSR 2, 0x000 ;j
  
  FOR8 j, 0x07, bodyLbl
;  FOR8_REG j, len, bodyLbl 
  LFSR 2, 0x000
  DECF i, f
  MOVF i, w
  ADDWF FSR2L, f
  LFSR 0, 0x007
  
  MOVF INDF0, w, ACCESS
  MOVFF INDF2, INDF0
  MOVWF INDF2, ACCESS

NOP
  END
