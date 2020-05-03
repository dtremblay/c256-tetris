.include "OPL3_def.asm"

OPL2_INIT
                .as
                setal
                ; Just Making sure all the necessary variables are cleared before doing anything
                LDA #$0000
                STA OPL2_REG_REGION
                STA OPL2_REG_OFFSET
                STA OPL2_NOTE
                STA OPL2_PARAMETER0
                STA OPL2_PARAMETER2
                
                setas
                ;LDA $2F
                ;STA OPL3_R_CONN_SEL
                LDA #0
                STA OPL3_R_OPL3_MODE  ; we're working in OPL2 mode
                RTL

;
;OPL2_PLAYNOTE
; Inputs
; OPL2_CHANNEL @ $000027 ;
; OPL2_NOTE    @ $000030 ; Notes start at 1 to 12
; OPL2_OCTAVE  @ $000031 ;
; OPL2_PARAMETER0 Will Change
OPL2_PLAYNOTE   ;Return void, Param: (byte channel, byte octave, byte note);
                setas
                PHX
                LDA #$00
                STA OPL2_PARAMETER0 ; Set Keyon False
                JSR OPL2_SET_KEYON
                ; Set Octave
                JSR OPL2_SET_BLOCK  ; OPL2_SET_BLOCK Already to OPL2_OCTAVE
                ; Now lets go pick the FNumber for the note we want
                
                setxs
                LDA OPL2_NOTE
                DEC A
                ASL A
                TAX
                LDA @lnoteFNumbers,X
                STA OPL2_PARAMETER0 ; Store the 8it in Param OPL2_PARAMETER0
                INX
                LDA @lnoteFNumbers,X
                STA OPL2_PARAMETER1 ; Store the 8bit in Param OPL2_PARAMETER1
                JSL OPL2_SET_FNUMBER
                LDA #$01
                STA OPL2_PARAMETER0 ; Set Keyon False
                JSR OPL2_SET_KEYON
                setxl
                PLX
                RTL
                
;
;OPL2_SET_KEYON
; Inputs
; OPL2_OPERATOR    @ $000026 ;
; OPL2_CHANNEL     @ $000027 ;
; OPL2_REG_OFFSET  @ $00002A ;
; OPL2_PARAMETER0 = Key On
OPL2_SET_KEYON              ;Return Byte, Param: (byte channel, bool keyOn);
                setas
                CLC
                LDA OPL2_CHANNEL
                AND #$0F  ; This is just precaution, it should be between 0 to 8
                ADC #$B0
                STA OPL2_REG_OFFSET
                LDA #$00
                STA OPL2_REG_OFFSET+1;
                setaxl
                ;Address Creation in $AFE700 Memory Section
                CLC
                LDA #<>OPL3_R_BASE
                ADC OPL2_REG_OFFSET
                STA OPL2_IND_ADDY_LL
                LDA #`OPL3_R_BASE
                STA OPL2_IND_ADDY_HL
                setas
                LDA OPL2_PARAMETER0
                AND #$01
                BEQ SET_KEYON_OFF
                LDA #$20
    SET_KEYON_OFF
                STA OPL2_PARAMETER0
                LDA [OPL2_IND_ADDY_LL]
                AND #$DF
                ORA OPL2_PARAMETER0
                STA [OPL2_IND_ADDY_LL]
                RTS
                
;
;OPL2_SET_BLOCK
; Inputs
; OPL2_OPERATOR    @ $000026 ;
; OPL2_CHANNEL     @ $000027 ;
; OPL2_REG_OFFSET  @ $00002A ;
; OPL2_OCTAVE      = $000031 ; Destructive
; OPL2_PARAMETER0 = Block
OPL2_SET_BLOCK           ;Return Byte, Param: (byte channel, byte block);
                setas
                CLC
                LDA OPL2_CHANNEL
                AND #$0F  ; This is just precaution, it should be between 0 to 8
                ADC #$B0
                STA OPL2_REG_OFFSET
                LDA #$00
                STA OPL2_REG_OFFSET+1;
                setaxl
                ;Address Creation in $AFE700 Memory Section
                CLC
                LDA #<>OPL3_R_BASE
                ADC OPL2_REG_OFFSET
                STA OPL2_IND_ADDY_LL
                LDA #`OPL3_R_BASE
                STA OPL2_IND_ADDY_HL
                setas
                LDA OPL2_OCTAVE
                AND #$07
                ASL
                ASL
                STA OPL2_OCTAVE
                LDA [OPL2_IND_ADDY_LL]
                AND #$E3
                ORA OPL2_OCTAVE
                STA [OPL2_IND_ADDY_LL]
                RTS
                
                
OPL2_GET_REG_OFFSET
                setaxs
                ; Get the Right List
                LDA OPL2_CHANNEL
                AND #$0F
                TAX
                LDA OPL2_OPERATOR   ; 0 = operator 1, other = operator 2
                BNE OPL2_Get_Register_Offset_l0
                LDA @lregisterOffsets_operator0, X
                BRA OPL2_Get_Register_Offset_exit
OPL2_Get_Register_Offset_l0
                LDA @lregisterOffsets_operator1, X
OPL2_Get_Register_Offset_exit
                STA OPL2_REG_OFFSET
                LDA #$00
                STA OPL2_REG_OFFSET+1;
                setaxl
                ;Address Creation in $AFE700 Memory Section
                CLC
                LDA #<>OPL3_R_BASE
                ADC OPL2_REG_OFFSET
                ADC OPL2_REG_REGION ; Ex: $20, or $40, $60, $80 (in 16bits)
                STA OPL2_IND_ADDY_LL
                LDA #`OPL3_R_BASE
                STA OPL2_IND_ADDY_HL
                RTS
                
;OPL2_SET_FNUMBER
; Inputs
; OPL2_OPERATOR    @ $000026 ;
; OPL2_CHANNEL     @ $000027 ;
; OPL2_REG_OFFSET  @ $00002A ;
; OPL2_PARAMETER0 = LSB fNumber
; OPL2_PARAMETER1 = MSB fNumber
OPL2_SET_FNUMBER            ;Return Byte, Param: (byte channel, short fNumber);
                setas
                CLC
                LDA OPL2_CHANNEL
                AND #$0F  ; This is just precaution, it should be between 0 to 8
                ADC #$A0
                STA OPL2_REG_OFFSET
                LDA #$00
                STA OPL2_REG_OFFSET+1;
                setaxl
                ;Address Creation in $AFE700 Memory Section
                CLC
                LDA #<>OPL3_R_BASE
                ADC OPL2_REG_OFFSET
                STA OPL2_IND_ADDY_LL
                LDA #`OPL3_R_BASE
                STA OPL2_IND_ADDY_HL
                setas
                LDA OPL2_PARAMETER0     ; Load the first 8 Bits Value of FNumber
                STA [OPL2_IND_ADDY_LL]  ; Load
                ; Let's go in Region $B0 Now
                CLC
                LDA OPL2_IND_ADDY_LL
                ADC #$10
                STA OPL2_IND_ADDY_LL
                LDA OPL2_PARAMETER1
                AND #$03
                STA OPL2_PARAMETER1
                LDA [OPL2_IND_ADDY_LL]
                AND #$FC
                ORA OPL2_PARAMETER1
                STA [OPL2_IND_ADDY_LL]
                RTL