; Important offsets
VGM_VERSION       = $8  ; 32-bits
SN_CLOCK          = $C  ; 32-bits
LOOP_OFFSET       = $1C ; 32-bits
YM_OFFSET         = $2C ; 32-bits
OPM_CLOCK         = $30 ; 32-bits
VGM_OFFSET        = $34 ; 32-bits

; *******************************************************************
; * Interrupt driven sub-routine.
; *******************************************************************
VGM_WRITE_REGISTER
            .as
            LDX WAIT_CNTR
            CPX #0
            BEQ STORE_VALUES
            
            DEX
            STX WAIT_CNTR
            
            RTS
            
            
    STORE_VALUES
            ; PHB
            
            ; LDA CURRENT_POSITION + 2
            ; PHA
            ; PLB
            ; .databank ?
            
            LDY CURRENT_POSITION
            ; first byte is a  command - should be $54 for YM2151
    VGM_CHECK_NEXT
            LDA [SONG_START],Y
            INY
            
        CHK_PSG
            CMP #$50
            BNE CHK_YM2612_P0
            
            LDA [SONG_START],Y
            STA PSG_BASE_ADDRESS
            INY
            JMP WR_DONE
            
        CHK_YM2612_P0
            CMP #$52
            BNE CHK_YM2612_P1
            
            ; the second byte is the register
            LDA #0
            XBA
            LDA [SONG_START],Y
            TAX
            INY
            
            ; the third byte is the value to write in the register
            LDA [SONG_START],Y
            STA @lOPN2_BASE_ADDRESS,X
            INY
            BRA VGM_CHECK_NEXT
            
        CHK_YM2612_P1
            CMP #$53
            BNE CHK_YM2151
            
            ; the second byte is the register
            LDA #0
            XBA
            LDA [SONG_START],Y
            TAX
            INY
            
            ; the third byte is the value to write in the register
            LDA [SONG_START],Y
            STA @lOPN2_BASE_ADDRESS + $100,X
            INY
            BRA VGM_CHECK_NEXT
            
        CHK_YM2151
            CMP #$54
            BNE CHK_YM262_P0
            
            ; the second byte is the register
            LDA #0
            XBA
            LDA [SONG_START],Y
            TAX
            INY
            
            ; the third byte is the value to write in the register
            LDA [SONG_START],Y
            STA @lOPM_BASE_ADDRESS,X
            INY
            BRA VGM_CHECK_NEXT
        
        CHK_YM262_P0
            CMP #$5E
            BNE CHK_YM262_P1
            
            ; the second byte is the register
            LDA #0
            XBA
            LDA [SONG_START],Y
            TAX
            INY
            
            ; the third byte is the value to write in the register
            LDA [SONG_START],Y
            STA @lOPL3_BASE_ADRESS,X
            INY
            BRA WR_DONE
            
        CHK_YM262_P1
            CMP #$5F
            BNE CHK_WAIT_N_SAMPLES
            
            ; the second byte is the register
            LDA #0
            XBA
            LDA [SONG_START],Y
            TAX
            INY
            
            ; the third byte is the value to write in the register
            LDA [SONG_START],Y
            STA @lOPL3_BASE_ADRESS+ $100,X
            INY
            BRA WR_DONE
            
        CHK_WAIT_N_SAMPLES
            CMP #$61
            BNE CHK_WAIT_60
            setal
            LDA [SONG_START],Y
            TAX
            STX WAIT_CNTR
            setas
            INY
            INY
            
            BRA WR_DONE
            
        CHK_WAIT_60
            CMP #$62
            BNE CHK_WAIT_50
            
            LDX #$2df
            STX WAIT_CNTR

            BRA WR_DONE
            
        CHK_WAIT_50
            CMP #$63
            BNE CHK_END_SONG
            
            LDX #$372
            STX WAIT_CNTR

            BRA WR_DONE
            
        CHK_END_SONG
            CMP #$66 ; end of song
            BNE CHK_DATA_BLOCK
            
            JSR SET_LOOP_POINTERS
            ;PLB
            RTS
            
        CHK_DATA_BLOCK
            CMP #$67
            BNE CHK_WAIT_N
            
            JSR READ_DATA_BLOCK
            
            JMP VGM_CHECK_NEXT
            
        CHK_WAIT_N
            BIT #$70
            BEQ CHK_YM2612_DAC
            
            AND #$F
            TAX
            INX ; $7n where we wait n+1
            STX WAIT_CNTR
            BRA WR_DONE
            
        CHK_YM2612_DAC
            BIT #$80
            BEQ CHK_DATA_STREAM
            
            ; write directly to DAC then wait n
            
            ; this is the wait part
            AND #$F
            TAX
            STX WAIT_CNTR
            BRA WR_DONE
            
        CHK_DATA_STREAM
            CMP #$90
            BNE SKIP_CMD
            
    SKIP_CMD
            ;JSL PRINTAH

    WR_DONE
            setal
            TYA
            SBC CURRENT_POSITION
            setas
            BCS WR_DONE_DONE
            
            INC CURRENT_POSITION + 2
            
    WR_DONE_DONE
            STY CURRENT_POSITION
            ;PLB
            RTS
            
VGM_SET_SONG_POINTERS
            .as
            
            ; add the start offset
            setal
            CLC
            LDY #VGM_OFFSET
            LDA [SONG_START],Y
            ADC #VGM_OFFSET
            STA CURRENT_POSITION
            LDA #0
            STA WAIT_CNTR
            setas
            
            RTS
            
SET_LOOP_POINTERS
            .as
            
            ; add the start offset
            setal
            CLC
            LDY #LOOP_OFFSET
            LDA [SONG_START],Y
            BEQ NO_LOOP_INFO
            
            ADC #LOOP_OFFSET
            BRA STORE_PTR
            
    NO_LOOP_INFO
            LDY #VGM_OFFSET
            LDA [SONG_START],Y
            ADC #VGM_OFFSET
    STORE_PTR
            STA CURRENT_POSITION
            LDA #0
            STA WAIT_CNTR
            setas
            
            RTS
            
VGM_INIT_TIMER0
            .as
            
            LDA #64
            STA TIMER0_CMP_L
            LDA #1
            STA TIMER0_CMP_M
            LDA #0
            STA TIMER0_CMP_H
            
            LDA #0    ; set timer0 charge to 0
            STA TIMER0_CHARGE_L
            STA TIMER0_CHARGE_M
            STA TIMER0_CHARGE_H
            
            LDA #TMR0_CMP_RECLR  ; count up from "CHARGE" value to TIMER_CMP
            STA TIMER0_CMP_REG
            
            LDA #(TMR0_EN | TMR0_UPDWN | TMR0_SCLR)
            STA TIMER0_CTRL_REG

            RTS
            
; *******************************************************************************
; * Read a data block   - 67 66 tt ss ss ss ss
; *******************************************************************************
READ_DATA_BLOCK
            .as
            
            LDA [SONG_START],Y ; should be 66
            ;CMP #$66 ; what happens if it's not 66?
            INY
            LDA  [SONG_START],Y ; should be the type - I expect $C0
            PHA
            INY
            
            ; read the size of the data stream - and compute the end of stream position
            setal
            LDA [SONG_START],Y
            STA ADDER_A
            INY
            INY
            
            LDA [SONG_START],Y
            STA ADDER_A + 2
            INY
            INY
            
            TYA
            STA ADDER_B
            setas
            LDA CURRENT_POSITION + 2
            STA ADDER_B + 2
            LDA #0
            STA ADDER_B + 3
            
            ; continue reading the file here
            setal
            LDA ADDER_R
            STA CURRENT_POSITION
            TAY
            setas
            LDA ADDER_R + 2
            STA CURRENT_POSITION + 2
            
    UNKNOWN_DATA_BLOCK
            RTS
