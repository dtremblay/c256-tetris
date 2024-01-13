;;;
;;; Register address definitions for the math coprocessor
;;;

; Unsigned Multiplier In A (16Bits), In B (16Bits), Answer (32Bits)
MULU_A           = $DE00   ; 2 Bytes Operand A (ie: A x B)
MULU_B           = $DE02   ; 2 Bytes Operand B (ie: A x B)
MULU_RES         = $DE10   ; 4 Bytes Result of A x B

; Unsigned Divide Denominator A (16Bits), Numerator B (16Bits),
; Quotient (16Bits), Remainder (16Bits)
DIVU_DEN         = $DE04 ; 2 Bytes Denominator
DIVU_NUM         = $DE06 ; 2 Bytes Numberator
D0_RESULT        = $DE14 ; 2 Bytes quotient result of Num/Den ex: 7/2 = 3 r 1
D0_REMAINDER     = $DE16 ; 2 Bytes remainder of Num/Den ex: 7/2 = 3 r 1

; 32Bit Adder
ADDER_A          = $DE08 ; 4 bytes (32 bit) Accumulator A
ADDER_B          = $DE0C ; 4 bytes (32 bit) Accumulator B
ADDER_R          = $DE18 ; 4 bytes (32 bit) Result
