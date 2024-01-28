;////////////////////////////////////////////////////////////////////////////
;////////////////////////////////////////////////////////////////////////////
;////////////////////////////////////////////////////////////////////////////
; Interrupt Handler
;////////////////////////////////////////////////////////////////////////////
;////////////////////////////////////////////////////////////////////////////
;////////////////////////////////////////////////////////////////////////////

check_irq_bit  .macro
                LDA \1
                AND #\2
                CMP #\2
                BNE END_CHECK
                STA \1
                JSR \3
                
END_CHECK
                .endm
                
IRQ_HANDLER
                PHA
                PHX
                PHY
; First Block of 8 Interrupts
                LDA INT_PENDING_REG0
                BEQ CHECK_PENDING_REG1

; Start of Frame (display), timer 0 (music), mouse (ignored)
                check_irq_bit INT_PENDING_REG0, INT0_VKY_SOF, SOF_INTERRUPT
                check_irq_bit INT_PENDING_REG0, INT0_TIMER_0, TIMER0_INTERRUPT
                ;check_irq_bit INT_PENDING_REG0, INT0_TIMER_1, TIMER1_INTERRUPT
                check_irq_bit INT_PENDING_REG0, INT0_PS2_KBD, KEYBOARD_INTERRUPT_PS2  ; for PS/2 keyboard

; Second Block of 8 Interrupts
CHECK_PENDING_REG1
                LDA INT_PENDING_REG1
                BEQ CHECK_PENDING_REG2   ; BEQ EXIT_IRQ_HANDLE
; Keyboard Interrupt
                check_irq_bit INT_PENDING_REG1, INT1_VIA0, JOYSTICK_INTERRUPT
                check_irq_bit INT_PENDING_REG1, INT1_VIA1, KEYBOARD_INTERRUPT_MATRIX

; Third Block of 8 Interrupts
CHECK_PENDING_REG2
                LDA INT_PENDING_REG2
                STA INT_PENDING_REG2
                BEQ EXIT_IRQ_HANDLE
                
EXIT_IRQ_HANDLE
                PLY
                PLX
                PLA
                RTI
                
; ****************************************************************
;
;  Joystick
;
; ****************************************************************
JOYSTICK_INTERRUPT
                ;RTS
; ****************************************************************
;
;  MATRIX Keyboard
;
; ****************************************************************
KEYBOARD_INTERRUPT_MATRIX
                ;RTS

; ****************************************************************
; * The only keys accepted are Left Arrow, Right Arrow, Down Arrow and Space (to rotate)
; * Alias ASD keys to arrows?
; ****************************************************************
KEYBOARD_INTERRUPT_PS2

    ; MORE_KEYS
                ; LOAD_KBD_INPT_BUF        ; Get Scan Code from KeyBoard
                LDA KBD_IN
                STA KEYPRESSED
                
                ; for debugging - display the key
                LDA #<(TEXT_START + 60)
                STA CURSORPOS
                LDA #>(TEXT_START + 60)
                STA CURSORPOS + 1
                LDA #$50
                STA CURCOLOR
                LDA KEYPRESSED
                JSR DISPLAY_HEX
                
                CMP #$7F
                BGE DONT_REACT
                ; TAX
                LDA GAME_STATE
                CMP #GS_INTRO
                BNE NOT_INTRO
                
                ; the user has pressed a key change the game state to play
                LDA #GS_RESTARTING
                STA GAME_STATE
                ; this routine calls the DMA - must be done here?
                JSR CLR_SCREEN
                
                BRA DONT_REACT
               
    NOT_INTRO
                LDA GAME_STATE
                CMP #GS_NAME_ENTRY
                BEQ NAME_ENTRY
                
                ; LDA ScanCode_Press_Set1,X
                ; TAX
                ; CPX #0
                ; BEQ DONT_REACT
                ; LDA GAME_STATE
                ; CMP #GS_LINE_BONUS
                ; BEQ DONT_REACT
                ; JSR (KEY_JUMP_TABLE,X)
                ; RTS
                
    NAME_ENTRY
                ; .xs
                ; CPX #$E
                ; BEQ BACKSPACE_KEY
                
                ; CPX #$1C
                ; BEQ ENTER_KEY
                
                ; LDA ScanCode_Press_Set2,X
                ; CMP #0
                ; BEQ DONT_REACT
                
                ; JSR ADD_CHAR
                ; BRA DONT_REACT
                
    ; BACKSPACE_KEY
                ; JSR DEL_CHAR
                ; BRA DONT_REACT
                
    ; ENTER_KEY
                ; ; replace all _ with space
                ; LDA HISCORE_OFFSET
                ; CMP #6
                ; BEQ E_K_DONE
                ; CLC
                ; ADC TEMP_LOCATION
                
                ; TAX
                ; LDA #$20
                
                ; STA HI_SCORES,X
                ; INC HISCORE_OFFSET
                ; BRA ENTER_KEY
                
        ; E_K_DONE
                ; setxl
                ; JSR SAVE_HI_SCORES
                
                ; LDA #GS_GAME_OVER
                ; STA GAME_STATE
                
                ; ; ERASE the ENTRY text
                ; LDY #$A000 + COLUMNS_PER_LINE*32 + 24
                ; STY CURSORPOS
                
                ; LDY #7 ; delete 7 lines
        ; ER_NEXT_LINE
                ; LDX #30 ; the number of characters to delete
                ; LDA #0
                
        ; ERASE_ENTRY_LOOP
                ; STA [CURSORPOS]
                ; INC CURSORPOS
                ; DEX
                ; BNE ERASE_ENTRY_LOOP
                
                ; setal
                ; LDA CURSORPOS
                ; CLC
                ; ADC #COLUMNS_PER_LINE - 30
                ; STA CURSORPOS
                ; setas
                
                ; DEY
                ; BNE ER_NEXT_LINE
                
    DONT_REACT
                RTS
                
; KEY_JUMP_TABLE
                ; .word <>INVALID_KEY
                ; .word <>MOVE_PIECE_LEFT
                ; .word <>MOVE_PIECE_RIGHT
                ; .word <>MOVE_PIECE_DOWN
                ; .word <>ROTATE_PIECE
                


; ****************************************************************
; ****************************************************************
; * Start of Frame Interrupt
; * 60Hz, 16ms Cyclical Interrupt
; ****************************************************************
; ****************************************************************
SOF_INTERRUPT
                ; empty the keyboard buffer, just in case
        ; EMPTY_KBD_BUFFER
                ; LOAD_KBD_STATUS_PORT
                
                ; BIT #1
                ; BEQ GS_KBD_NOT_FULL
                ; LOAD_KBD_INPT_BUF
                ; BRA EMPTY_KBD_BUFFER
        ; GS_KBD_NOT_FULL
                
                ; JSR HANDLE_JOYSTICK
                
                LDA GAME_STATE  ; The SOF is still getting called, even when masked
                BNE CHK_GAME_RESTARTING
                
                JSR DISPLAY_BOARD_LOOP
                BRA SOF_DONE
                
    CHK_GAME_RESTARTING
                CMP #GS_RESTARTING
                BNE CHK_GAME_OVER

                
                
                BRA SOF_DONE
                
                
    CHK_GAME_OVER
                CMP #GS_GAME_OVER
                BNE CHK_REMOVE_LINES
                
                ; ; count 60 ticks for 1 second
                ; LDA GAME_OVER_TICK
                ; INC A
                ; STA GAME_OVER_TICK
                ; CMP #60
                ; BNE SOF_DONE
                
                ; LDA #0
                ; STA GAME_OVER_TICK
                ; SED
                ; LDA GAME_OVER_TIMER
                ; SEC
                ; SBC #1
                ; STA GAME_OVER_TIMER
                ; CLD
                ; JSR DISPLAY_COUNTDOWN
                
                ; LDA GAME_OVER_TIMER
                ; CMP #0
                ; BNE SOF_DONE
                
                ; LDA #GS_INTRO
                ; STA GAME_STATE
                ; JSR CLR_SCREEN
                ; JSR DISPLAY_INTRO
                
                BRA SOF_DONE
                
    CHK_REMOVE_LINES
                
                CMP #GS_LINE_BONUS
                BNE CHK_INTRO_SCREEN
                ; JSR REMOVE_LINES_LOOP
                BRA SOF_DONE
                
    CHK_INTRO_SCREEN
                CMP #GS_INTRO
                BNE CHK_ENTRY_SCREEN
                
                JSR INTRO_LOOP
                BRA SOF_DONE
                
    CHK_ENTRY_SCREEN
                CMP #GS_NAME_ENTRY
                BNE SOF_DONE
                
                ; ; write the user entry
                ; LDY #$A000 + COLUMNS_PER_LINE * 32 + 40
                ; STY CURSORPOS
                ; LDA #$AF
                ; STA CURSORPOS + 2
                ; LDA #$23
                ; STA CURCOLOR
                
                ; ; display USER_NAME_ENTRY PROMPT
                ; setal
                ; LDA #<>HI_SCORES
                ; CLC
                ; ADC TEMP_LOCATION
                ; STA MSG_ADDR
                ; setas

                ; JSR DISPLAY_MSG
                
    SOF_DONE
                RTS


; ****************************************************************
; ****************************************************************
; * Play VGM files
; ****************************************************************
; ****************************************************************
TIMER0_INTERRUPT
                JSR VGM_WRITE_REGISTER
                RTS
                
TIMER1_INTERRUPT
                ; LDA EFFECT_PLAY
                ; BEQ NO_EFFECT
                
                ; BIT #TILE_EFFECT
                ; BEQ CHK_LINE_EFFECT
                ; JSR PLAY_T_EFFECT
                
        ; CHK_LINE_EFFECT
                ; LDA EFFECT_PLAY
                ; BIT #LINE_EFFECT
                ; BEQ CHK_ROTATE_EFFECT
                ; JSR PLAY_L_EFFECT
                
        ; CHK_ROTATE_EFFECT
                ; LDA EFFECT_PLAY
                ; BIT #ROTATE_EFFECT
                ; BEQ NO_EFFECT
                ; JSR PLAY_R_EFFECT
                
    ; NO_EFFECT
                RTS
                
                
; *******************************************************************
; * The pointer to the hi-score entry line must be provided
; *******************************************************************
ADD_CHAR        
                PHA
                LDA HISCORE_OFFSET
                CMP #6
                BEQ A_C_DONE
                
                INC HISCORE_OFFSET
                CLC
                ADC TEMP_LOCATION
                TAX
                PLA
                STA HI_SCORES,X
                RTS
                
        A_C_DONE
                PLA
                RTS
                
DEL_CHAR        
                LDA HISCORE_OFFSET
                BEQ D_C_DONE
                
                DEC HISCORE_OFFSET
                DEC A
                CLC
                ADC TEMP_LOCATION
                TAX
                LDA #'_'
                STA HI_SCORES,X
                
        D_C_DONE
                RTS