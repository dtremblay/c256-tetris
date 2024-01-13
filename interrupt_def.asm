; Pending Interrupt (Read and Write Back to Clear)
INT_PENDING_REG0 = $D660 ;
INT_PENDING_REG1 = $D661 ;
INT_PENDING_REG2 = $D662 ;

; Polarity Set
INT_POL_REG0     = $D664 ;
INT_POL_REG1     = $D665 ;
INT_POL_REG2     = $D666 ;

; Edge Detection Enable
INT_EDGE_REG0    = $D668 ;
INT_EDGE_REG1    = $D669 ;
INT_EDGE_REG2    = $D66A ;

; Mask
INT_MASK_REG0    = $D66C ;
INT_MASK_REG1    = $D66D ;
INT_MASK_REG2    = $D66E ;

; Interrupt Bit Definition
; Register Block 0
    INT0_VKY_SOF   = $01  ; TinyVicky Start Of Frame interrupt
    INT0_VKY_SOL   = $02  ; TinyVicky Start Of Line interrupt
    INT0_PS2_KBD   = $04  ; PS/2 keyboard event
    INT0_PS2_MOUSE = $08  ; PS/2 mouse event
    INT0_TIMER_0   = $10  ; Timer0 Interrupt
    INT0_TIMER_1   = $20  ; Timer1 Interrupt
    INT0_RSVD      = $40  ; 
    INT0_CARTRIDGE = $80  ; Interrupt asserted by the cartridge

; Register Block 1
    INT1_UART      = $01  ; UART
    INT1_RSVD1     = $02  ; 
    INT1_RSVD2     = $04  ;
    INT1_RSVD3     = $08  ;
    INT1_RTC       = $10  ; Real Time Clock
    INT1_VIA0      = $20  ; Events from the 65C22 VIA chip
    INT1_VIA1      = $40  ; F256k Only: local keyboard
    INT1_SDC_INS   = $80  ; User has inserted an SD card

; Register Block 2
    INT2_IEC_DATA_i = $01  ; IEC Data In
    INT2_IEC_CLK_i  = $02  ; IEC Clock In
    INT2_IEC_ATN_i  = $04  ; IEC Attenuation In
    INT2_IEC_SREQ_i = $08  ; IEC SREC In
    INT2_RSVD1      = $10  ;
    INT2_RSVD2      = $20  ;
    INT2_RSVD3      = $40  ;
    INT2_RSVD4      = $80  ;

