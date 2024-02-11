MMU_MEM_CTRL   = $0000
    ACT_LUT0  = 0
    ACT_LUT1  = 1
    ACT_LUT2  = 2
    ACT_LUT3  = 3
    
    ACT_ED_L0 = $00
    ACT_ED_L1 = $10
    ACT_ED_L2 = $20
    ACT_ED_L3 = $30
    ACT_EDIT  = $80

MMU_IO_CTRL    = $0001
    IO_PAGE0  = 0
    IO_PAGE1  = 1
    IO_PAGE2  = 2
    IO_PAGE3  = 3
    IO_DISABLE= 4
    
SLOT0 = 0
SLOT1 = $2000
SLOT2 = $4000
SLOT3 = $6000
SLOT4 = $8000
SLOT5 = $A000
SLOT6 = $C000
SLOT7 = $E000

; Text Display - in IO Page 2
TEXT_START    = $C000
; Color Display - in IO Page 3
COLOR_START   = $C000

PS2_CTRL      = $D640
    K_WR      = 2
    M_WR      = 4
    KCLR      = $10
    MCLR      = $20
    
PS2_OUT       = $D641
PS2_KBD_IN    = $D642
MOUSE_IN      = $D643
PS2_STAT      = $D644
    K_EMPTY   = 1
    M_EMPTY   = 2
; MOUSE Registers
MOUSE_REG     = $D6E0
    MOUSE_PTR_ENABLE = 1
    MOUSE_PTR_MODE   = 2

MOUSE_PTR_X   = $D6E2 ; only valid in MODE=0
MOUSE_PTR_Y   = $D6E4 ; only valid in MODE=0

MOUSE_PS2_0   = $D6E6 ; only valid in MODE=1
MOUSE_PS2_1   = $D6E7 ; only valid in MODE=1
MOUSE_PS2_2   = $D6E8 ; only valid in MODE=1

; VIA 0 and 1 are in reverse addresses
; Junior's VIA - For Joystick
VIA0_IORB     = $DC00
VIA0_IORA     = $DC01
VIA0_DDRB     = $DC02
VIA0_DDRA     = $DC03
VIA0_INTR_FLG = $DC0D
VIA0_INTR_REG = $DC0E
    VIA_IRQ_SET     = $80
    VIA_IRQ_TMR1_EN = $40
    VIA_IRQ_TMR2_EN = $20
    VIA_IRQ_CB1_EN  = $10
    VIA_IRQ_CB2_EN  = $08
    VIA_IRQ_SHR_EN  = $04
    VIA_IRQ_CA1_EN  = $02
    VIA_IRQ_CA2_EN  = $01
   

; F256K's VIA - For Matrix Keyboard
VIA1_IORB     = $DB00
VIA1_IORA     = $DB01
VIA1_DDRB     = $DB02
VIA1_DDRA     = $DB03
VIA1_INTR_FLG = $DB0D
VIA1_INTR_REG = $DB0E

; Dip switch Ports
DIPSWITCH     = $AFE804  ;(R) $AFE804...$AFE807

; SD Card CH376S Port
SDCARD_DATA   = $AFE808  ;(R/W) SDCARD (CH376S) Data PORT_A (A0 = 0)
SDCARD_CMD    = $AFE809  ;(R/W) SDCARD (CH376S) CMD/STATUS Port (A0 = 1)
; SD Card Card Presence / Write Protect Status Reg
SDCARD_STAT   = $AFE810  ;(R) SDCARD (Bit[0] = CD, Bit[1] = WP)

; Audio WM8776 CODEC Control Interface (Write Only)
CODEC_DATA_LO = $AFE820  ;(W) LSB of Add/Data Reg to Control CODEC See WM8776 Spec
CODEC_DATA_HI = $AFE821  ;(W) MSB od Add/Data Reg to Control CODEC See WM8776 Spec
CODEC_WR_CTRL = $AFE822  ;(W) Bit[0] = 1 -> Start Writing the CODEC Control Register
