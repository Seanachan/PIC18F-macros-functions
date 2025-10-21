; Example: for (i = 0; i < 5; i++)
; i is stored at 0x20

    CLRF    0x20        ; i = 0

for_loop:
    MOVF    0x20, W
    SUBLW   5           ; W = 5 - i
    BTFSC   STATUS, Z   ; if i == 5 ? Z = 1
    GOTO    for_end
    BTFSS   STATUS, C   ; if i >= 5 ? C = 0
    GOTO    for_end

    ; ===== loop body =====
    NOP                 ; do something here
    ; =====================

    INCF    0x20, F     ; i++
    GOTO    for_loop

for_end:
    NOP



