; ***************************************************************************
; Pending Interrupt (Read and Write Back to Clear)
TIMER0_CTRL_REG   = $D650 ; TIMER0 (Write - Control, Read Status)
TIMER1_CTRL_REG   = $D658 ; TIMER1 Write - Control, Read Status)

; Control Register Definitions
    TMR_EN     = $01
    TMR_CLR    = $02
    TMR_LOAD   = $04
    TMR_UPDWN  = $08
    TMR_INT_EN = $80

TIMER0_VALUE      = $D651 ; Use if you want to Precharge and countdown
TIMER1_VALUE      = $D659 ; Use if you want to Precharge and countdown

; Compare Block
TIMER0_CMP_CTR   = $D654 ; TIMER0 Compare Register   
TIMER1_CMP_CTR   = $D65C ; TIMER0 Compare Register

    TMR_CMP_RESET     = $01 ; set to one for it to cycle when Counting up
    TMR_CMP_RELOAD    = $02 ; Set to one for it to reload when Counting Down

TIMER0_CMP      = $D655 ; Load this Value for Countup
TIMER1_CMP      = $D65D ;