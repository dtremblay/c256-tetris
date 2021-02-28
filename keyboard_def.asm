;
.if TARGET_SYS == TARGET_FMX
    STATUS_PORT        = $AF1064
    KBD_CMD_BUF        = $AF1064
    KBD_OUT_BUF        = $AF1060
    KBD_INPT_BUF       = $AF1060
    KBD_DATA_BUF       = $AF1060
    PORT_A             = $AF1060
    PORT_B             = $AF1061
.else
    STATUS_PORT        = $AF1807
    KBD_CMD_BUF        = $AF1807
    KBD_OUT_BUF        = $AF1803
    KBD_INPT_BUF       = $AF1803
    KBD_DATA_BUF       = $AF1803
    PORT_A             = $AF180A   ;This is a Timing Register, the value is hard coded, so there is no need to use those
    PORT_B             = $AF180B   ;This is a Timing Register, the value is hard coded, so there is no need to use those
.fi

; Status
OUT_BUF_FULL          = $01
INPT_BUF_FULL         = $02
SYS_FLAG              = $04
CMD_DATA              = $08
KEYBD_INH             = $10
TRANS_TMOUT           = $20
RCV_TMOUT             = $40
PARITY_EVEN           = $80
INH_KEYBOARD          = $10
KBD_ENA               = $AE
KBD_DIS               = $AD

; Keyboard Commands
KB_MENU               = $F1
KB_ENABLE             = $F4
KB_MAKEBREAK          = $F7
KB_ECHO               = $FE
KB_RESET              = $FF
KB_LED_CMD            = $ED

; Keyboard responses
KB_OK                 = $AA
KB_ACK                = $FA
KB_OVERRUN            = $FF
KB_RESEND             = $FE
KB_BREAK              = $F0
KB_FA                 = $10
KB_FE                 = $20
KB_PR_LED             = $40

.align 256
;                           $00, $01, $02, $03, $04, $05, $06, $07, $08, $09, $0A, $0B, $0C, $0D, $0E, $0F
ScanCode_Press_Set1   .text $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00    ; $00
                      .text $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00    ; $10
                      .text $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00    ; $20
                      .text $00, $00, $00, $00, $00, $00, $00, $00, $00, $08, $00, $00, $00, $00, $00, $00    ; $30
                      .text $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $02, $00, $04, $00, $00    ; $40
                      .text $06, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00    ; $50
                      .text $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00    ; $60
                      .text $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00    ; $70
                      
ScanCode_Press_Set2   .text $00, $00, $31, $32, $33, $34, $35, $36, $37, $38, $39, $30, $2D, $3D, $08, $09    ; $00
                      .text $51, $57, $45, $52, $54, $59, $55, $49, $4F, $50, $5B, $5D, $0D, $00, $41, $53    ; $10
                      .text $44, $46, $47, $48, $4A, $4B, $4C, $3B, $27, $60, $00, $5C, $5A, $58, $43, $56    ; $20
                      .text $42, $4E, $4D, $2C, $2E, $2F, $00, $2A, $00, $20, $00, $00, $00, $00, $00, $00    ; $30
                      .text $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00    ; $40
                      .text $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00    ; $50
                      .text $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00    ; $60
                      .text $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00    ; $70
