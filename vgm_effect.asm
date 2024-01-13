; *****************************************************************************
; * Play a special effect using the SN76489
; *****************************************************************************
play_effect     .macro
                LDX \1
                CPX #0
                BEQ PE_READ_COMMAND
                
                DEX
                STX \1
                RTS
                
    PE_READ_COMMAND
                
                LDA [\2]
                increment_long_addr \2
                CMP #$50
                BNE PE_CHK_WAIT_50th
                
                LDA [\2]
                STA PSG_BASE_ADDRESS
                increment_long_addr \2
                BRA PE_DONE ; for some reason, this chip needs more time between writes
                
        PE_CHK_WAIT_50th
                CMP #$62
                BNE PE_CHK_WAIT_60th
                
                LDX #$2df
                STX \1
                BRA PE_DONE
        
        PE_CHK_WAIT_60th
                CMP #$63
                BNE PE_CHK_END_SONG
                
                LDX #$372
                STX \1
                BRA PE_DONE
                
        PE_CHK_END_SONG
                CMP #$66 ; end of song
                BNE PE_DONE
            
                LDA EFFECT_PLAY
                AND #~(\3)
                STA EFFECT_PLAY ; effect is done 
                
        PE_DONE
                RTS
                .endm

PLAY_T_EFFECT
            .play_effect EFFECT_T_WAIT_CNTR, EFFECT_T_POSITION, TILE_EFFECT
            
PLAY_L_EFFECT
            .play_effect EFFECT_L_WAIT_CNTR, EFFECT_L_POSITION, LINE_EFFECT
            
PLAY_R_EFFECT
            .play_effect EFFECT_R_WAIT_CNTR, EFFECT_R_POSITION, ROTATE_EFFECT
                
; *****************************************************************************
; * Setup the Tile Down Effect
; *****************************************************************************
PLAY_EFFECT_TILE_DOWN
                LDX #<>VGM_EFFECT_DROP + $40 ; we know the offset already
                STX EFFECT_T_POSITION
                LDA #`VGM_EFFECT_DROP + $40
                STA EFFECT_T_POSITION + 2
                
                LDX #0
                STX EFFECT_T_WAIT_CNTR
                
                LDA EFFECT_PLAY
                ORA #TILE_EFFECT
                STA EFFECT_PLAY
                
                ; enable the TIMER1 interrupt
                ;LDA #~( FNX0_INT00_SOF | FNX0_INT02_TMR0 | FNX0_INT03_TMR1 )
                ;STA @lINT_MASK_REG0
                
                RTS
                
; *****************************************************************************
; * Setup the Line Effect
; *****************************************************************************
PLAY_EFFECT_LINE
                LDX #<>VGM_EFFECT_LINE + $40 ; we know the offset already
                STX EFFECT_L_POSITION
                LDA #`VGM_EFFECT_LINE + $40
                STA EFFECT_L_POSITION + 2
                
                LDX #0
                STX EFFECT_L_WAIT_CNTR
                
                LDA EFFECT_PLAY
                ORA #LINE_EFFECT
                STA EFFECT_PLAY
                
                ; enable the TIMER1 interrupt
                ;LDA #~( FNX0_INT00_SOF | FNX0_INT02_TMR0 | FNX0_INT03_TMR1 )
                ;STA @lINT_MASK_REG0
                
                RTS
                
; *****************************************************************************
; * Setup the Rotate Effect
; *****************************************************************************
PLAY_EFFECT_ROTATE
                .as
                LDX #<>VGM_EFFECT_ROTATE + $40 ; we know the offset already
                STX EFFECT_R_POSITION
                LDA #`VGM_EFFECT_ROTATE + $40
                STA EFFECT_R_POSITION + 2
                
                LDX #0
                STX EFFECT_R_WAIT_CNTR
                
                LDA EFFECT_PLAY
                ORA #ROTATE_EFFECT
                STA EFFECT_PLAY
                
                ; enable the TIMER1 interrupt
                ;LDA #~( FNX0_INT00_SOF | FNX0_INT02_TMR0 | FNX0_INT03_TMR1 )
                ;STA @lINT_MASK_REG0
                
                RTS