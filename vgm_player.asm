; ****************************************************************************
; * Video Game Music Player
; * Author Daniel Tremblay
; * Code written for the C256 Foenix retro computer
; * Permission is granted to reuse this code to create your own games
; * for the F256 Foenix.
; * Copyright Daniel Tremblay 2020-2024
; * This code is provided without warranty.
; * Please attribute credits to Daniel Tremblay if you reuse.
; ****************************************************************************
; *   To play VGM files in your games, include this file first.
; *   Next, in your interrupt handler, enable timer0.
; *   In the TIMER0 interrupt handler, call the VGM_WRITE_REGISTER subroutine.
; *   In your game code, set the SONG_START to the beginning of your VGM file.
; *   Call VGM_SET_SONG_POINTERS, this will initialize the other register.
; *   Finally, call VGM_INIT_TIMERS to initialize TIMER0 and TIMER1.
; *   Chips supported at this time are:
; *     - SN76489 (PSG)
; *     - YM2612 (OPN2)
; *     - YM2151 (OPM)
; *     - YM262 (OPL3)
; *     - YM3812 (OPL2)
; ****************************************************************************

; Important offsets
VGM_VERSION       = $8  ; 32-bits
SN_CLOCK          = $C  ; 32-bits
LOOP_OFFSET       = $1C ; 32-bits
YM_OFFSET         = $2C ; 32-bits
OPM_CLOCK         = $30 ; 32-bits
VGM_OFFSET        = $34 ; 32-bits

; VGM Registers
COMMAND           = $7F ; 1 byte

;PCM_OFFSET        = $8A ; 4 bytes

AY_3_8910_A       = $90 ; 2 bytes
AY_3_8910_B       = $92 ; 2 bytes
AY_3_8910_C       = $94 ; 2 bytes
AY_3_8910_N       = $96 ; 2 bytes

;DATA_STREAM_CNT   = $7D ; 2 byte
;DATA_STREAM_TBL   = $8000 ; each entry is 4 bytes

; *******************************************************************
; * MACROS
; *******************************************************************
; Increment the song address.  We need to ensure we stay 
; within the slot bounds.
;
; first parameter is the address to incremented
; second parameter is the number of bytes to skip
; third parameter is the max hi byte
; fourth paramter is the min hi byte
increment_long_addr   .macro
            ; instead of PHA/PLA, use TAY and TYA
            TAY
            CLC
            LDA \1
            ADC #\2
            STA \1
            BCC skip_n_done
            
            LDA \1 + 1
            ADC #0
            STA \1 + 1
            CMP #\3 ; if we get to the upper bound, switch the slot
            BLT skip_n_done
            
            
            LDA #\4
            STA \1 + 1
            ; switch the slot to the next area in memory
            LDA #ACT_EDIT + ACT_ED_L0
            STA MMU_MEM_CTRL
            
            INC 8+2  ; slot 2
            LDA #0
            STA MMU_MEM_CTRL

    skip_n_done
            TYA
            .endm

; *******************************************************************
; * Interrupt driven sub-routine.
; *******************************************************************
VGM_WRITE_REGISTER
            LDA (CURRENT_POSITION)
            STA COMMAND
            
            increment_long_addr CURRENT_POSITION,1,>SLOT3,>SLOT2
            
            AND #$F0
            LSR A
            LSR A
            LSR A
            TAX
            JMP (VGM_COMMAND_TABLE,X)
            
    VGM_LOOP_DONE
            RTS
            
; *******************************************************************
; * Command Table
; *******************************************************************
VGM_COMMAND_TABLE
            .word <>INVALID_COMMAND ;0
            .word <>INVALID_COMMAND ;1
            .word <>INVALID_COMMAND ;2
            .word <>SKIP_BYTE_CMD   ;3 - reserved - not implemented
            .word <>SKIP_BYTE_CMD   ;4 - not implemented
            .word <>WRITE_YM_CMD    ;5 - YM*
            .word <>WAIT_COMMANDS   ;6
            .word <>WAIT_N_1        ;7
            .word <>YM2612_SAMPLE   ;8
            .word <>DAC_STREAM      ;9
            .word <>AY8910          ;A - AY8910
            .word <>SKIP_TWO_BYTES  ;B - not implemented
            .word <>SKIP_THREE_BYTES;C - not implemented
            .word <>SKIP_THREE_BYTES;D - not implemented
            .word <>SKIP_FOUR_BYTES ;E - not implemented
            .word <>SKIP_FOUR_BYTES ;F - not implemented
            
INVALID_COMMAND
            JMP VGM_WRITE_REGISTER
            
restart_timer0      .macro
            LDA #TMR_CMP_RESET  ; reset to 0 when COMPARE value reached
            STA TIMER0_CMP_CTR
            
            lda #TMR_CLR          ; Clear timer 0
            sta TIMER0_CTRL_REG
            
            LDA #(TMR_EN | TMR_UPDWN | TMR_INT_EN )
            STA TIMER0_CTRL_REG
                    .endm
            
restart_timer1      .macro
            LDA #TMR_CMP_RESET  ; reset to 0 when COMPARE value reached
            STA TIMER1_CMP_CTR
            
            lda #TMR_CLR          ; Clear timer 0
            sta TIMER1_CTRL_REG
            
            LDA #(TMR_EN | TMR_UPDWN )
            STA TIMER1_CTRL_REG
                    .endm
            
SKIP_BYTE_CMD
            increment_long_addr CURRENT_POSITION,1,>SLOT3,>SLOT2
            JMP VGM_WRITE_REGISTER
            
SKIP_TWO_BYTES
            increment_long_addr CURRENT_POSITION,2,>SLOT3,>SLOT2
            JMP VGM_WRITE_REGISTER
            
SKIP_THREE_BYTES
            increment_long_addr CURRENT_POSITION,3,>SLOT3,>SLOT2
            JMP VGM_WRITE_REGISTER
            
SKIP_FOUR_BYTES
            increment_long_addr CURRENT_POSITION,4,>SLOT3,>SLOT2
            JMP VGM_WRITE_REGISTER
            

; we need to combine R1 and R0 together before we send
; the data to the SN76489
AY8910
            LDA COMMAND
            CMP #$A0
            BEQ AY_COMMAND
            
            JMP SKIP_TWO_BYTES
            
    AY_COMMAND
            ; the second byte is the register
            LDA (CURRENT_POSITION)
            increment_long_addr CURRENT_POSITION,1,>SLOT3,>SLOT2
            CMP #0 ; Register 0 fine
            BNE AY_R1
            
            LDA AY_3_8910_A
            CMP #8
            BLT R0_FINE
            
            LDA #$87
            STA PSG_BASE_ADDRESS
            LDA #$3F
            STA PSG_BASE_ADDRESS
            increment_long_addr CURRENT_POSITION,1,>SLOT3,>SLOT2
            JMP VGM_WRITE_REGISTER
            
        R0_FINE
            ; this is a two-byte operation - TODO: review this code.
            STA VGM_TEMP
            
            LDA (CURRENT_POSITION)
            increment_long_addr CURRENT_POSITION,1,>SLOT3,>SLOT2
            LSR A ; drop the LSB
            ;BBR 0,VGM_TEMP,+
            .byte $0f, $8c, $02
            
            ORA #$80
            
      +     PHA
            AND #$F
            ORA #$80
            STA PSG_BASE_ADDRESS
            
            PLA
            LSR A
            LSR A
            LSR A
            LSR A
            ; TODO: add the low-nibble from VGM_TEMP into hi-nibble
            AND #$3F ; 6 bits

            STA PSG_BASE_ADDRESS
            JMP VGM_WRITE_REGISTER
            
            
    AY_R1   CMP #1
            BNE AY_R2
            
            LDA (CURRENT_POSITION)
            increment_long_addr CURRENT_POSITION,1,>SLOT3,>SLOT2
            AND #$F
            STA AY_3_8910_A
            
            JMP VGM_WRITE_REGISTER
            
    AY_R2   CMP #2
            BNE AY_R3
            
            LDA AY_3_8910_B
            CMP #8
            BLT R1_FINE
            
            LDA #$A7
            STA PSG_BASE_ADDRESS
            LDA #$3F
            STA PSG_BASE_ADDRESS
            increment_long_addr CURRENT_POSITION,1,>SLOT3,>SLOT2
            JMP VGM_WRITE_REGISTER
            
        R1_FINE
            ; this is a two-byte operation
            ;XBA
            STA VGM_TEMP
            LDA (CURRENT_POSITION)
            increment_long_addr CURRENT_POSITION,1,>SLOT3,>SLOT2
            LSR A ; drop the LSB
            ;BBR 0,VGM_TEMP,+
            .byte $0f, $8c, $02
            ORA #$80
            
     +      PHA
            AND #$F
            ORA #$A0
            STA PSG_BASE_ADDRESS
            
            PLA
            LSR A
            LSR A
            LSR A
            LSR A
            ; TODO: add the low-nibble from VGM_TEMP into hi-nibble
            AND #$3F ; 6 bits

            STA PSG_BASE_ADDRESS
            JMP VGM_WRITE_REGISTER
            
    AY_R3   CMP #3
            BNE AY_R4
            
            LDA (CURRENT_POSITION)
            increment_long_addr CURRENT_POSITION,1,>SLOT3,>SLOT2
            AND #$F
            STA AY_3_8910_B
            
            JMP VGM_WRITE_REGISTER
            
    AY_R4   CMP #4
            BNE AY_R5
            
            LDA AY_3_8910_C
            CMP #8
            BLT R2_FINE
            
            LDA #$C7
            STA PSG_BASE_ADDRESS
            LDA #$3F
            STA PSG_BASE_ADDRESS
            increment_long_addr CURRENT_POSITION,1,>SLOT3,>SLOT2
            JMP VGM_WRITE_REGISTER
            
        R2_FINE
            ; this is a two-byte operation - TODO: review this code
            ;XBA
            STA VGM_TEMP
            LDA (CURRENT_POSITION)
            increment_long_addr CURRENT_POSITION,1,>SLOT3,>SLOT2
            
            LSR A ; drop the LSB
            ;BBR 0,VGM_TEMP,+
            .byte $0f, $8c, $02
            ORA #$80
            
     +      PHA
            AND #$F
            ORA #$C0
            STA PSG_BASE_ADDRESS
            
            PLA
            LSR A
            LSR A
            LSR A
            LSR A
            ; TODO: add the low-nibble from VGM_TEMP into hi-nibble
            AND #$3F ; 6 bits

            STA PSG_BASE_ADDRESS
            JMP VGM_WRITE_REGISTER
            
    AY_R5   CMP #5
            BNE AY_R10
            
            LDA (CURRENT_POSITION)
            increment_long_addr CURRENT_POSITION,1,>SLOT3,>SLOT2
            AND #$F
            STA AY_3_8910_C
            
            JMP VGM_WRITE_REGISTER
    
    AY_R10
            CMP #8
            BNE AY_R11
            
            LDA #$F
            SEC
            SBC (CURRENT_POSITION)
            increment_long_addr CURRENT_POSITION,1,>SLOT3,>SLOT2
            AND #$F
            ORA #$90
            STA PSG_BASE_ADDRESS
            JMP VGM_WRITE_REGISTER
            
    AY_R11
            CMP #9
            BNE AY_R12
            
            LDA #$F
            SEC
            SBC (CURRENT_POSITION)
            increment_long_addr CURRENT_POSITION,1,>SLOT3,>SLOT2
            
            AND #$F
            ORA #$B0
            STA PSG_BASE_ADDRESS
            JMP VGM_WRITE_REGISTER
            
    AY_R12
            CMP #10
            BNE AY_R15
            
            LDA #$F
            SEC
            SBC (CURRENT_POSITION)
            increment_long_addr CURRENT_POSITION,1,>SLOT3,>SLOT2
            AND #$F
            ORA #$D0
            STA PSG_BASE_ADDRESS
            JMP VGM_WRITE_REGISTER
            
    AY_R15
            increment_long_addr CURRENT_POSITION,1,>SLOT3,>SLOT2
            JMP VGM_WRITE_REGISTER

; *******************************************************************
; * YM Commands
; *******************************************************************
WRITE_YM_CMD
            .as
            LDA COMMAND

            ; should use a Jump Table to speed this up
            CMP #$50
            BNE CHK_YM2413
            
            LDA (CURRENT_POSITION)
            STA PSG_BASE_ADDRESS
            increment_long_addr CURRENT_POSITION,1,>SLOT3,>SLOT2
            JMP VGM_LOOP_DONE ; for some reason, this chip needs more time between writes
            
        CHK_YM2413
            CMP #$51
            BNE CHK_YM2612_P0
            
            ; the second byte is the register
            LDA (CURRENT_POSITION)
            STA OPL3_BASE_ADRESS
            increment_long_addr CURRENT_POSITION,1,>SLOT3,>SLOT2
            
            ; the third byte is the value to write in the register
            LDA (CURRENT_POSITION)
            STA OPL3_BASE_ADRESS+1
            increment_long_addr CURRENT_POSITION,1,>SLOT3,>SLOT2
            JMP VGM_WRITE_REGISTER
            
        CHK_YM2612_P0
            CMP #$52
            BNE CHK_YM2612_P1
            
            ; the second byte is the register
            ;LDA (CURRENT_POSITION)
            ;TAX
            increment_long_addr CURRENT_POSITION,2,>SLOT3,>SLOT2
            
            ; the third byte is the value to write in the register
            ;LDA (CURRENT_POSITION)
            ;STA OPN2_BASE_ADDRESS,X
            ;increment_long_addr CURRENT_POSITION,1,>SLOT3,>SLOT2
            JMP VGM_LOOP_DONE ; for some reason, this chip needs more time between writes
            
        CHK_YM2612_P1
            CMP #$53
            BNE CHK_YM2151
            
            ; the second byte is the register
            ;LDA (CURRENT_POSITION)
            ;TAX
            increment_long_addr CURRENT_POSITION,2,>SLOT3,>SLOT2
            
            ; the third byte is the value to write in the register
            ;LDA (CURRENT_POSITION)
            ;STA OPN2_BASE_ADDRESS + $100,X
            ;increment_long_addr CURRENT_POSITION,1,>SLOT3,>SLOT2
            JMP VGM_LOOP_DONE ; for some reason, this chip needs more time between writes
            
        CHK_YM2151
            CMP #$54
            BNE CHK_YM2203
            
            ; the second byte is the register
            ;LDA (CURRENT_POSITION)
            ;TAX
            increment_long_addr CURRENT_POSITION,2,>SLOT3,>SLOT2
            
            ; the third byte is the value to write in the register
            ;LDA (CURRENT_POSITION)
            ;STA OPM_BASE_ADDRESS,X
            ;increment_long_addr CURRENT_POSITION,1,>SLOT3,>SLOT2
            JMP VGM_WRITE_REGISTER
            
        CHK_YM2203
            CMP #$55
            BNE CHK_YM2608_P0
            
            ; the second byte is the register
            ;LDA (CURRENT_POSITION)
            ;TAX
            increment_long_addr CURRENT_POSITION,2,>SLOT3,>SLOT2
            
            ; the third byte is the value to write in the register
            ;LDA (CURRENT_POSITION)
            ;STA @lOPM_BASE_ADDRESS,X
            
            ;increment_long_addr CURRENT_POSITION,1,>SLOT3,>SLOT2
            JMP VGM_WRITE_REGISTER
            
        CHK_YM2608_P0
            CMP #$56
            BNE CHK_YM2608_P1
            
            ; the second byte is the register
            LDA (CURRENT_POSITION)
            CMP #$10  ; if the register is 0 to $1F, process as SSG
            BGE YM2608_FM
            JMP AY8910

        YM2608_FM
            TAX
            increment_long_addr CURRENT_POSITION,1,>SLOT3,>SLOT2
            
            ; the third byte is the value to write in the register
            ;LDA (CURRENT_POSITION)
            ;STA OPN2_BASE_ADDRESS,X
            increment_long_addr CURRENT_POSITION,1,>SLOT3,>SLOT2
            JMP VGM_WRITE_REGISTER
            
        CHK_YM2608_P1
            CMP #$57
            BNE CHK_YM2610_P0
            
            ; the second byte is the register
            ;LDA (CURRENT_POSITION)
            ;TAX
            increment_long_addr CURRENT_POSITION,2,>SLOT3,>SLOT2
            
            ; the third byte is the value to write in the register
            ;LDA (CURRENT_POSITION)
            ;STA OPN2_BASE_ADDRESS,X
            ;increment_long_addr CURRENT_POSITION,1,>SLOT3,>SLOT2
            JMP VGM_WRITE_REGISTER
            
        CHK_YM2610_P0
            CMP #$58
            BNE CHK_YM2610_P1
            
            ; the second byte is the register
            LDA (CURRENT_POSITION)
            CMP #$10  ; if the register is 0 to $1F, process as SSG
            BGE YM2610_FM
            JMP AY8910
            
        YM2610_FM
            ;TAX
            increment_long_addr CURRENT_POSITION,2,>SLOT3,>SLOT2
            
            ; the third byte is the value to write in the register
            ;LDA (CURRENT_POSITION)
            ;STA OPN2_BASE_ADDRESS,X
            ;increment_long_addr CURRENT_POSITION,1,>SLOT3,>SLOT2
            JMP VGM_WRITE_REGISTER
            
        CHK_YM2610_P1
            CMP #$59
            BNE CHK_YM3812
            
            ; the second byte is the register
            ;LDA (CURRENT_POSITION)
            ;TAX
            increment_long_addr CURRENT_POSITION,2,>SLOT3,>SLOT2
            
            ; the third byte is the value to write in the register
            ;LDA (CURRENT_POSITION)
            ;STA OPN2_BASE_ADDRESS + $100,X
            ;increment_long_addr CURRENT_POSITION,1,>SLOT3,>SLOT2
            JMP VGM_WRITE_REGISTER
            
        CHK_YM3812
            CMP #$5A
            BNE CHK_YM262_P0
            
            ; the second byte is the register
            LDA (CURRENT_POSITION)
            STA OPL3_BASE_ADRESS
            increment_long_addr CURRENT_POSITION,1,>SLOT3,>SLOT2
            
            ; the third byte is the value to write in the register
            LDA (CURRENT_POSITION)
            STA OPL3_BASE_ADRESS+1
            increment_long_addr CURRENT_POSITION,1,>SLOT3,>SLOT2
            JMP VGM_WRITE_REGISTER
        
        CHK_YM262_P0
            CMP #$5E
            BNE CHK_YM262_P1
            
            ; the second byte is the register
            LDA (CURRENT_POSITION)
            STA OPL3_BASE_ADRESS
            increment_long_addr CURRENT_POSITION,1,>SLOT3,>SLOT2
            
            ; the third byte is the value to write in the register
            LDA (CURRENT_POSITION)
            STA OPL3_BASE_ADRESS + 1
            increment_long_addr CURRENT_POSITION,1,>SLOT3,>SLOT2
            JMP VGM_WRITE_REGISTER
            
        CHK_YM262_P1
            CMP #$5F
            BNE YM_DONE
            
            ; the second byte is the register
            LDA (CURRENT_POSITION)
            STA OPL3_BASE_ADRESS + 2
            increment_long_addr CURRENT_POSITION,1,>SLOT3,>SLOT2
            
            ; the third byte is the value to write in the register
            LDA (CURRENT_POSITION)
            STA OPL3_BASE_ADRESS + 1
            increment_long_addr CURRENT_POSITION,1,>SLOT3,>SLOT2
    YM_DONE
            JMP VGM_WRITE_REGISTER

; *******************************************************************
; * Wait Commands
; *******************************************************************
WAIT_COMMANDS
            .as
            LDA COMMAND
            CMP #$61
            BEQ +
            JMP CHK_WAIT_60th
            
       +    LDA (CURRENT_POSITION)
            STA MULU_A
            increment_long_addr CURRENT_POSITION,1,>SLOT3,>SLOT2
            LDA (CURRENT_POSITION)
            STA MULU_A + 1
            increment_long_addr CURRENT_POSITION,1,>SLOT3,>SLOT2
            LDA #<(6290000/11000)
            STA MULU_B
            LDA #>(6290000/11000)
            STA MULU_B + 1
            
            LDA MULU_RES
            STA TIMER0_CMP
            LDA MULU_RES + 1
            STA TIMER0_CMP + 1
            LDA MULU_RES + 2
            STA TIMER0_CMP + 2
            restart_timer0
            
            JMP VGM_LOOP_DONE
            
        CHK_WAIT_60th
            CMP #$62
            BNE CHK_WAIT_50th
            
            ; 1/60th of a second = $3_A51B timer charge
            LDA #<$A51B
            STA TIMER0_CMP
            LDA #>$A51B
            STA TIMER0_CMP + 1
            LDA #3
            STA TIMER0_CMP + 2
            restart_timer0
            JMP VGM_LOOP_DONE
            
        CHK_WAIT_50th
            CMP #$63
            BNE CHK_END_SONG
            
            ; 1/50th of a second = $4_5FBA timer charge
            LDA #<$5FBA
            STA TIMER0_CMP
            LDA #>$5FBA
            STA TIMER0_CMP + 1
            LDA #4
            STA TIMER0_CMP + 2
            restart_timer0
            JMP VGM_LOOP_DONE

        CHK_END_SONG
            CMP #$66 ; end of song
            BNE CHK_DATA_BLOCK
            
            LDA LOOP_OFFSET_REG
            STA CURRENT_POSITION
            LDA LOOP_OFFSET_REG + 1
            STA CURRENT_POSITION + 1
            
            ; change the slot 2 reference
            LDA #ACT_EDIT + ACT_ED_L0
            STA MMU_MEM_CTRL
            LDA LOOP_OFFSET_REG + 2
            STA 8+2
            LDA #0
            STA MMU_MEM_CTRL
          
            JMP VGM_LOOP_DONE
            
        CHK_DATA_BLOCK
            CMP #$67
            BNE DONE_WAIT
            
            JSR READ_DATA_BLOCK
    DONE_WAIT
            JMP VGM_LOOP_DONE

; *******************************************************************
; * Wait N+1 Commands
; *******************************************************************
WAIT_N_1
            LDA COMMAND
            AND #$F
            INC A
            
            STA MULU_A
            STZ MULU_A + 1
            
            ; this assumes a sampling rate of 44kHz - TODO read the sampling rate in the VGM file
            LDA #$<145
            STA MULU_B
            LDA #$>145
            STA MULU_B + 1
            
            LDA MULU_RES
            STA TIMER0_CMP
            LDA MULU_RES + 1
            STA TIMER0_CMP + 1
            LDA MULU_RES + 2
            STA TIMER0_CMP + 2
            
            restart_timer0
            JMP VGM_LOOP_DONE
            
; *******************************************************************
; * Play Samples and wait N
; *******************************************************************
YM2612_SAMPLE
            ; .as
            
            ; ; write directly to YM2612 DAC then wait n
            ; ; load a value from database
            ; LDA [PCM_OFFSET]
            ; STA OPN2_BASE_ADDRESS + $2A
            
            ; ; increment PCM_OFFSET
            ; setal
            ; LDA PCM_OFFSET
            ; INC A
            ; STA PCM_OFFSET
            ; BCC YMS_WAIT
            ; LDA PCM_OFFSET + 2
            ; INC A
            ; STA PCM_OFFSET + 2
            
    ; YMS_WAIT
            ; setas
            ; LDA #0
            ; XBA
            ; LDA COMMAND
            ; ; this is the wait part
            ; AND #$F
            ; TAX
            ; STX WAIT_CNTR
            
    ; YMS_NOT_ZERO
            JMP VGM_WRITE_REGISTER
            
; *******************************************************************
; * Don't know yet
; *******************************************************************
DAC_STREAM
            ;JMP VGM_LOOP_DONE
            JMP VGM_WRITE_REGISTER

; *******************************************************************
; * Copy the song offset pointer to CURRENT_POSITION
; *******************************************************************
VGM_SET_SONG_POINTERS           
            ; compute song_start + vgm_offset + song_offset
            LDY #VGM_OFFSET
            LDA (SONG_START),Y
            CLC
            ADC #VGM_OFFSET
            STA ADDER_A
            
            ; second byte
            INC Y
            LDA (SONG_START),Y
            STA ADDER_A + 1
            BCC +
            INC ADDER_A + 1
            
       +    LDA SONG_START
            STA ADDER_B
            LDA SONG_START + 1
            STA ADDER_B + 1
            
            LDA ADDER_RES
            STA CURRENT_POSITION
            LDA ADDER_RES + 1
            STA CURRENT_POSITION +1
            
            ; check if loop offset is zero
            LDY #LOOP_OFFSET
            LDA (SONG_START),Y
            BNE +
            
            INY
            LDA (SONG_START),Y
            BNE +
            
            ; if offset is zero, set the LOOP_OFFSET_REG to CURRENT_POSITION
            LDA CURRENT_POSITION
            STA LOOP_OFFSET_REG
            LDA CURRENT_POSITION + 1
            STA LOOP_OFFSET_REG + 1
            LDA SONG_START + 2
            STA LOOP_OFFSET_REG + 2
            
       +    ; add the loop offset
            LDY #LOOP_OFFSET
            CLC
            LDA (SONG_START),Y
            ADC #LOOP_OFFSET ; add the current position
            STA ADDER_A
            
            ; second byte
            INY
            LDA (SONG_START),Y
            STA ADDER_A + 1
            BCC +
            INC ADDER_A + 1
            
      +     LDA SONG_START
            STA ADDER_B
            LDA SONG_START + 1
            STA ADDER_B + 1
            LDA ADDER_RES
            STA LOOP_OFFSET_REG
            LDA ADDER_RES + 1
            STA LOOP_OFFSET_REG + 1
            ;TODO: this is not certain -check
            LDA SONG_START + 2
            STA LOOP_OFFSET_REG + 2
            
            RTS

; the game uses two timers:
; * timer0 is for the music
; * timer1 is for the effects
VGM_INIT_TIMERS
            LDA #5
            STA TIMER0_CMP
            STA TIMER1_CMP
            LDA #5
            STA TIMER0_CMP+1
            STA TIMER1_CMP+1
            LDA #5
            STA TIMER0_CMP+2
            STA TIMER1_CMP+2
            
            restart_timer0
            restart_timer1

            RTS
            
; *******************************************************************************
; * Read a data block   - 67 66 tt ss ss ss ss
; * Probably should not be using sampling on the F256
; *******************************************************************************
READ_DATA_BLOCK
            ; .as
            ; LDA [CURRENT_POSITION] ; should be 66
            ; ;CMP #$66 ; what happens if it's not 66?
            ; increment_long_addr CURRENT_POSITION
            ; LDA  [CURRENT_POSITION] ; should be the type - I expect $C0
            ; PHA
            ; increment_long_addr CURRENT_POSITION
            
            ; ; read the size of the data stream - and compute the end of stream position
            ; setal
            ; LDA [CURRENT_POSITION]
            ; STA ADDER_A
            ; increment_long_addr CURRENT_POSITION
            ; increment_long_addr CURRENT_POSITION
            ; setal
            ; LDA [CURRENT_POSITION]
            ; STA ADDER_A + 2
            ; increment_long_addr CURRENT_POSITION
            ; increment_long_addr CURRENT_POSITION
            ; setal
            ; LDA CURRENT_POSITION
            ; STA ADDER_B
            ; LDA CURRENT_POSITION + 2
            ; STA ADDER_B + 2
            
            ; ; continue reading the file here
            ; LDA ADDER_R
            ; STA CURRENT_POSITION
            ; LDA ADDER_R + 2
            ; STA CURRENT_POSITION + 2
            
            ; setas
            ; PLA
            ; BEQ UNCOMPRESSED
            ; CMP #$C0
            ; BNE UNKNOWN_DATA_BLOCK
            
    ; UNCOMPRESSED
            ; setal
            ; LDA DATA_STREAM_CNT ; multiply by 4
            ; ASL A
            ; ASL A
            ; TAX
            
            ; LDA ADDER_B
            ; STA DATA_STREAM_TBL,X
            ; LDA ADDER_B + 2
            ; STA DATA_STREAM_TBL,X + 2

            ; INC DATA_STREAM_CNT
            ; setas
            
    ; UNKNOWN_DATA_BLOCK
            RTS
