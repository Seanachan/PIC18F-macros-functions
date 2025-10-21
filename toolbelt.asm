; ===================== toolbelt.inc (MPASM) =====================

; --- tiny helpers ---
MOVLF    MACRO val, dest       ; dest = literal
        MOVLW   val
        MOVWF   dest, ACCESS
        ENDM
SETBIT   MACRO f,b             ; f.b = 1
        BSF     f,b
        ENDM
CLRBIT   MACRO f,b             ; f.b = 0
        BCF     f,b
        ENDM
XCHG     MACRO a,b             ; swap a<->b (uses WREG)
        MOVF    a,W
        XORWF   b,F
        XORWF   a,F
        XORWF   b,F
        ENDM

; --- 16-bit add/sub/cmp (dest += src, etc.) ---
ADD16    MACRO dL,dH,sL,sH
        MOVF    sL,W
        ADDWF   dL,F
        MOVF    sH,W
        ADDWFC  dH,F
        ENDM
SUB16    MACRO dL,dH,sL,sH
        MOVF    sL,W
        SUBWF   dL,F
        MOVF    sH,W
        SUBWFB  dH,F
        ENDM
CMP16    MACRO aL,aH,bL,bH     ; sets C/Z from (a-b) without changing a
        LOCAL   _c1,_c2
        MOVF    bL,W
        SUBWF   aL,W           ; W=(aL-bL)
        MOVWF   0x7F           ; temp in access if allowed; else change
_c1     MOVF    bH,W
        SUBWFB  aH,W
        ENDM
INC16    MACRO xL,xH
        INCF    xL,F
        BTFSC   STATUS,0
        INCF    xH,F
        ENDM
DEC16    MACRO xL,xH
        MOVLW   1
        SUBWF   xL,F
        BTFSS   STATUS,0
        DECF    xH,F
        ENDM

; --- logical & arithmetic shifts (16-bit) ---
LSL16    MACRO xL,xH
        BCF     STATUS,0
        RLCF    xL,F
        RLCF    xH,F
        ENDM
LSR16    MACRO xL,xH
        BCF     STATUS,0
        RRCF    xH,F
        RRCF    xL,F
        ENDM
ASR16    MACRO xL,xH            ; arithmetic >>1
        BTFSC   xH,7
        BSF     STATUS,0
        BTFSS   xH,7
        BCF     STATUS,0
        RRCF    xH,F
        RRCF    xL,F
        ENDM

; --- 16/8 unsigned division: (dH:dL)/div -> quoH:quoL, rem ---
DIV16U8  MACRO dH,dL, div, quoH,quoL, rem, cnt
        LOCAL   _h,_hge,_hnx,_l,_lge,_lnx
        CLRF    quoH
        CLRF    rem
        MOVLW   8
        MOVWF   cnt
_h      RLCF    dH,F
        RLCF    rem,F
        MOVF    div,W
        SUBWF   rem,W
        BTFSC   STATUS,0
        GOTO    _hge
        BCF     STATUS,0
        RLCF    quoH,F
        GOTO    _hnx
_hge    MOVF    div,W
        SUBWF   rem,F
        BSF     STATUS,0
        RLCF    quoH,F
_hnx    DECFSZ  cnt,F
        GOTO    _h
        CLRF    quoL
        MOVLW   8
        MOVWF   cnt
_l      RLCF    dL,F
        RLCF    rem,F
        MOVF    div,W
        SUBWF   rem,W
        BTFSC   STATUS,0
        GOTO    _lge
        BCF     STATUS,0
        RLCF    quoL,F
        GOTO    _lnx
_lge    MOVF    div,W
        SUBWF   rem,F
        BSF     STATUS,0
        RLCF    quoL,F
_lnx    DECFSZ  cnt,F
        GOTO    _l
        ENDM

; --- 8x8 -> 16 multiply accumulate: acc += a*b (acc = aH:aL) ---
MAC16_8x8 MACRO a,b, accL,accH
        MOVF    a,W
        MULWF   b              ; PRODH:PRODL = a*b
        MOVF    PRODL,W
        ADDWF   accL,F
        MOVF    PRODH,W
        ADDWFC  accH,F
        ENDM

; FOR8_REG i, limReg, bodyLbl
; for (i=0; i<[*limReg]; i++) bodyLbl();
FOR8_REG MACRO i, limReg , bodyLbl
    LOCAL _loop, _end
    CLRF    i
_loop
    MOVF    i, W, ACCESS
    SUBWF   limReg, w, ACCESS
    BTFSC   STATUS, Z  ; if equal ? stop
    GOTO    _end
    BTFSS   STATUS, C  ; if i > limit ? stop
    GOTO    _end

    ; <<< Your code here >>>
    ; you can either write instructions directly here,
    ; or define a subroutine and replace the CALL below.

    CALL    bodyLbl    ; body() executes each loop

    INCF    i, F, ACCESS       ; i++
    GOTO    _loop
_end
ENDM


; --- simple 8-bit for(i=0;i<limit;i++) { body() } ---
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

; ============================================================
; FOR2D_REG i, j, limI, limJ, bodyLbl
; for (i=0; i<[*limI]; i++)
;   for (j=0; j<[*limJ]; j++)
;       bodyLbl();
; Notes:
;  - limI, limJ are register addresses holding the limits.
;  - Compares via (i - limit) so:
;      Z=1 ? i == limit  ? stop
;      C=1 ? i >  limit  ? stop (no-borrow means i >= limit)
; ============================================================
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

    CLRF    j                 ; j = 0
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


    
; --- memset: fill count bytes at FSRx with value in W ---
MEMSET   MACRO fsrL,fsrH, count
        LOCAL   _ms1,_ms2
_ms1    MOVF    count,W
        BZ      _ms2
        MOVWF   POSTINC0       ; assumes FSR0 targeted; change if needed
        DECF    count,F
        GOTO    _ms1
_ms2    ENDM

; --- memcpy: copy count bytes FSR0 -> FSR1 ---
MEMCPY   MACRO count
        LOCAL   _cp1,_cp2
_cp1    MOVF    count,W
        BZ      _cp2
        MOVF    POSTINC0,W
        MOVWF   POSTINC1
        DECF    count,F
        GOTO    _cp1
_cp2    ENDM

; --- nibble helpers ---
GET_HINIB MACRO src,dst
        MOVF    src,W
        MOVWF   dst
        SWAPF   dst,F
        ANDLW   0x0F
        MOVWF   dst
        ENDM
GET_LONIB MACRO src,dst
        MOVF    src,W
        ANDLW   0x0F
        MOVWF   dst
        ENDM
PACK_NIB  MACRO hi,lo,dst
        MOVF    hi,W
        ANDLW   0x0F
        MOVWF   dst
        SWAPF   dst,F
        MOVF    lo,W
        ANDLW   0x0F
        IORWF   dst,F
        ENDM

; div_8_8 divd, divsor, quo_dest, rem_dest
; (divd / divsor) → quotient in quo_dest, remainder in rem_dest
; Uses temps: 0x20 (quo), 0x22 (rem), 0x26 (cnt)

div_8_8 MACRO divd, divsor, quo_dest, rem_dest, cnt_dest
    LOCAL loop, no_sub, next

    CLRF    quo_dest            ; quo
    CLRF    rem_dest            ; rem
    MOVLW   8
    MOVWF   cnt_dest            ; cnt = 8

loop:
    ; shift dividend bit into remainder (MSB-first)
    BCF     STATUS, C       ; ensure 0 shifts into LSB
    RLCF    divd, F
    RLCF    rem_dest, F         ; rem <<= 1 | carry

    ; compare rem vs divsor (unsigned)
    MOVF    divsor, W
    SUBWF   rem_dest, W         ; C=1 if rem >= divsor
    BTFSS   STATUS, C
    GOTO    no_sub

    ; rem >= divsor → subtract, shift '1' into quotient
    MOVF    divsor, W
    SUBWF   rem_dest, F         ; rem -= divsor (leaves C=1)
    RLCF    quo_dest, F         ; shift in 1 to quo
    GOTO    next

no_sub:
    ; rem < divsor → shift '0' into quotient
    BCF     STATUS, C
    RLCF    quo_dest, F

next:
    DECFSZ  cnt_dest, F
    GOTO    loop

    CLRF    cnt_dest
ENDM



; 16-bit ÷ 8-bit Unsigned (long division)
; (divH:divL) / divsor  →  quoH:quoL, rem
DIV16U8_LONG MACRO divH, divL, divsor, quoH, quoL, rem, cnt
    LOCAL _loop, _no_sub, _next

    CLRF    quoH
    CLRF    quoL
    CLRF    rem
    MOVLW   9
    MOVWF   cnt

_loop
    ; --- shift dividend into remainder (MSB-first) ---
    BCF     STATUS, C      ; << ensure 0 shifts into divL LSB
    RLCF    divL, F
    RLCF    divH, F
    RLCF    rem, F         ; C now = old bit7 of rem (not used next)

    ; --- test rem >= divsor (unsigned) ---
    MOVF    divsor, W
    SUBWF   rem, W         ; C=1 if rem >= divsor
    BTFSS   STATUS, C
    GOTO    _no_sub

    ; rem >= divsor → subtract and shift '1' into quotient
    MOVF    divsor, W
    SUBWF   rem, F         ; leaves C=1 (no borrow)
    RLCF    quoL, F        ; shift in C=1
    RLCF    quoH, F
    GOTO    _next

_no_sub
    ; rem < divsor → shift '0' into quotient
    BCF     STATUS, C      ; << be explicit: shift 0
    RLCF    quoL, F
    RLCF    quoH, F

_next
    DECFSZ  cnt, F
    GOTO    _loop
ENDM

;; --- Template for recursion ---
;RECUR_FUNC:
;    ; base case
;    <check condition>
;    BZ  BASE_DONE
;
;    ; save current state
;    MOVFF PARAM, TEMP
;    <modify PARAM for recursive call>
;
;    CALL RECUR_FUNC       ; recursion
;
;    ; restore
;    MOVFF TEMP, PARAM
;    <combine result>
;
;BASE_DONE:
;    RETURN

; =========================================================
; GCD8 a, b, dest, t0
; Computes gcd(a, b) for 8-bit unsigned values.
; Result placed in 'dest'. Uses temp byte 't0'.
; Does not require any other macros.
; =========================================================
GCD8 MACRO a, b, dest, t0
    LOCAL _start, _a_zero, _b_zero, _loop, _mod_try, _mod_done, _done

_start
    ; handle edge cases
    MOVF    a, W
    BZ      _a_zero
    MOVF    b, W
    BZ      _b_zero
    GOTO    _loop

_a_zero
    MOVFF   b, dest
    GOTO    _done

_b_zero
    MOVFF   a, dest
    GOTO    _done

; Euclid loop:
; while (b != 0) { t0 = a % b; a = b; b = t0; }
_loop
    ; t0 = a % b  (repeated subtraction modulo)
    MOVF    a, W
    MOVWF   t0

_mod_try
    ; try t0 -= b; if borrow (C=0), undo and finish modulo
    MOVF    b, W
    SUBWF   t0, F          ; t0 = t0 - b
    BTFSC   STATUS, C      ; if no borrow (t0 >= 0), keep subtracting
    GOTO    _mod_try

    ; borrow occurred → undo last subtract, t0 is remainder
    MOVF    b, W
    ADDWF   t0, F          ; t0 += b (restore to positive remainder)

_mod_done
    ; a = b; b = t0
    MOVFF   b, a
    MOVFF   t0, b

    ; if b == 0 → done (gcd in a)
    MOVF    b, W
    BZ      _b_zero        ; reuse path: dest = a

    GOTO    _loop

_done
ENDM

; =========================================================
; GCD16U_STEIN aL,aH, bL,bH, outL,outH,  tL,tH,  k, tmp
; Computes gcd( (aH:aL), (bH:bL) ) → (outH:outL), unsigned.
; Temps:
;   tL:tH = work copy of B
;   k     = common power-of-two count
;   tmp   = 1-byte scratch for swapping
; No other macro dependencies.
; =========================================================
GCD16U_STEIN MACRO aL,aH, bL,bH, outL,outH, tL,tH, k, tmp
    LOCAL _a_zero,_b_zero,_common,_make_a_odd,_gcd_loop,_t_even
    LOCAL _cmp_swap,_do_swap,_sub,_done,_shift_back

    ; out = A, t = B
    MOVFF   aL, outL
    MOVFF   aH, outH
    MOVFF   bL, tL
    MOVFF   bH, tH

    ; if A == 0 → gcd = B
    MOVF    outL, W
    IORWF   outH, W
    BZ      _a_zero

    ; if B == 0 → gcd = A
    MOVF    tL, W
    IORWF   tH, W
    BZ      _b_zero

    ; k = 0 (common factors of 2)
    CLRF    k

_common
    ; while A even AND B even: A>>=1; B>>=1; k++
    BTFSC   outL, 0
    GOTO    _make_a_odd
    BTFSC   tL, 0
    GOTO    _make_a_odd

    ; A >>= 1 (logical)
    BCF     STATUS, C
    RRCF    outH, F
    RRCF    outL, F
    ; B >>= 1 (logical)
    BCF     STATUS, C
    RRCF    tH, F
    RRCF    tL, F
    INCF    k, F
    GOTO    _common

_make_a_odd
    ; make A odd: while A even, A >>= 1
    BTFSC   outL, 0
    GOTO    _gcd_loop
    BCF     STATUS, C
    RRCF    outH, F
    RRCF    outL, F
    GOTO    _make_a_odd

_gcd_loop
    ; if B == 0 → done (A is gcd)
    MOVF    tL, W
    IORWF   tH, W
    BZ      _shift_back

_t_even
    ; while B even, B >>= 1
    BTFSC   tL, 0
    GOTO    _cmp_swap
    BCF     STATUS, C
    RRCF    tH, F
    RRCF    tL, F
    GOTO    _t_even

_cmp_swap
    ; if A > B, swap(A,B) so that B >= A
    MOVF    tL, W
    SUBWF   outL, W        ; W = outL - tL
    MOVF    tH, W
    SUBWFB  outH, W        ; C=1 → A >= B
    BTFSC   STATUS, C
    GOTO    _do_swap       ; swap if A >= B (safe also for equality)

    ; B = B - A
_sub
    MOVF    outL, W
    SUBWF   tL, F
    MOVF    outH, W
    SUBWFB  tH, F
    GOTO    _gcd_loop

_do_swap
    ; swap outL <-> tL  (use tmp)
    MOVFF   outL, tmp
    MOVFF   tL,  outL
    MOVFF   tmp, tL
    ; swap outH <-> tH
    MOVFF   outH, tmp
    MOVFF   tH,  outH
    MOVFF   tmp, tH
    GOTO    _sub

_shift_back
    ; restore common factor: A <<= k
    MOVF    k, W
    BZ      _done
    ; loop: while k-- > 0: A <<= 1
    ; (logical left shift)
    BCF     STATUS, C
    RLCF    outL, F
    RLCF    outH, F
    DECF    k, F
    GOTO    _shift_back

_a_zero
    ; gcd = B
    MOVFF   tL, outL
    MOVFF   tH, outH
    GOTO    _done

_b_zero
    ; gcd = A already in out
_done
ENDM

; =========================================================
; Comparators
; =========================================================

; CMP16U  aL,aH, bL,bH
; Effect: computes (a - b) into W (throwaway) to set flags.
; Flags:  Z=1 → a==b
;         C=1 → a>=b   (no borrow)
;         C=0 → a<b
CMP16U MACRO aL,aH, bL,bH
    LOCAL _c1
    MOVF    bL, W
    SUBWF   aL, W         ; W = aL - bL   (sets C/Z)
_c1 MOVF    bH, W
    SUBWFB  aH, W         ; W = aH - bH - !C
ENDM

; Use immediately after CMP16U
BR_EQ16   MACRO label     ; a == b
    BTFSC   STATUS, Z
    GOTO    label
ENDM

BR_NE16   MACRO label     ; a != b
    BTFSS   STATUS, Z
    GOTO    label
ENDM

BR_LT16U  MACRO label     ; a < b  (unsigned)
    BTFSS   STATUS, C     ; C=0 => borrow => a<b
    GOTO    label
ENDM

BR_GE16U  MACRO label     ; a >= b (unsigned)
    BTFSC   STATUS, C
    GOTO    label
ENDM

BR_GT16U  MACRO label     ; a > b (unsigned)
    ; (a>=b) && (a!=b)
    BTFSC   STATUS, C
    BTFSS   STATUS, Z
    GOTO    label
ENDM

BR_LE16U  MACRO label     ; a <= b (unsigned)
    ; !(a>b)  →  (C==0) || (Z==1)
    BTFSS   STATUS, C
    GOTO    label
    BTFSC   STATUS, Z
    GOTO    label
ENDM

; BR_LT16S aL,aH,bL,bH,label   → branch if (a < b) signed
BR_LT16S MACRO aL,aH,bL,bH,label
    LOCAL _after
    CMP16U  aL,aH, bL,bH
    BTFSC   STATUS, Z         ; equal → not less
    GOTO    _after
    ; test N XOR OV
    BTFSC   STATUS, 4         ; N
    BTFSS   STATUS, 3         ; OV
    GOTO    label             ; N=1,OV=0 → less
    BTFSS   STATUS, 4
    BTFSC   STATUS, 3
    GOTO    label             ; N=0,OV=1 → less
_after
ENDM

; BR_GE16S  → branch if (a >= b) signed
BR_GE16S MACRO aL,aH,bL,bH,label
    LOCAL _after
    CMP16U  aL,aH, bL,bH
    BTFSC   STATUS, Z
    GOTO    label             ; equal → ge
    ; !(N XOR OV) → ge
    BTFSS   STATUS, 4
    BTFSS   STATUS, 3
    GOTO    label             ; N=0,OV=0
    BTFSC   STATUS, 4
    BTFSC   STATUS, 3
    GOTO    label             ; N=1,OV=1
_after
ENDM

; =================== sample usage ===================
; ; Compare A(0x31:0x30) with B(0x33:0x32)
; CMP16U  0x30,0x31, 0x32,0x33
; BR_EQ16  equal_u
; BR_LT16U less_u
; ; else greater_u
; GOTO    greater_u

; equal_u:
;     ; a==b
;     GOTO done

; less_u:
;     ; a<b (unsigned)
;     GOTO done

; greater_u:
;     ; a>b (unsigned)
; done:

; =================== end of toolbelt.inc ===================