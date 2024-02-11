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
                ;check_irq_bit INT_PENDING_REG1, INT1_VIA0, JOYSTICK_INTERRUPT
                ;DONTWORK check_irq_bit INT_PENDING_REG1, INT1_VIA1, KEYBOARD_INTERRUPT_MATRIX

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
; * The only keys accepted are Left Arrow, Right Arrow, Down Arrow and Space (to rotate)
; * Alias ASD keys to arrows?
; ****************************************************************
KEYBOARD_INTERRUPT_PS2
                ; LOAD_KBD_INPT_BUF        ; Get Scan Code from KeyBoard
                LDA PS2_KBD_IN
                STA KEYPRESSED
                BEQ DONT_REACT        ; if 0 then don't do anything
                
                ; for debugging - display the key
                LDA #<(TEXT_START + 60)
                STA CURSORPOS
                LDA #>(TEXT_START + 60)
                STA CURSORPOS + 1
                LDA #$50
                STA CURCOLOR
                LDA KEYPRESSED
                
                JSR DISPLAY_HEX
                
                
                CMP #$7F              ; ignore any keys above $7F
                BGE DONT_REACT
                
                LDA GAME_STATE
                CMP #GS_LINE_BONUS
                BEQ DONT_REACT
                
                CMP #GS_INTRO
                BNE NOT_INTRO
                
                LDA KEYPRESSED
                CMP #$29
                BNE DONT_REACT
                
                ; the user has pressed the SPACE key: change the game state to play
                LDA #GS_RESTARTING
                STA GAME_STATE
                ; this routine calls the DMA - must be done here?
                JSR CLR_SCREEN
                
                BRA DONT_REACT
               
    NOT_INTRO
                LDA GAME_STATE
                CMP #GS_NAME_ENTRY
                BEQ NAME_ENTRY
                
                LDA KEYPRESSED
                CMP #$1C  ; LEFT KEY
                BNE +
                
                JSR MOVE_PIECE_LEFT
                BRA DONT_REACT
                
         +      CMP #$29  ; SPACE
                BNE +
                
                JSR ROTATE_PIECE
                BRA DONT_REACT
                
         +      CMP #$23  ; RIGHT KEY
                BNE +
                
                JSR MOVE_PIECE_RIGHT
                BRA DONT_REACT
                
         +      CMP #$1B  ; DOWN KEY
                BNE DONT_REACT
                
                JSR MOVE_PIECE_DOWN      
                
     DONT_REACT   
                ; read until buffer is empty
         -      LDA PS2_STAT
                BIT #1
                BNE +
                
                LDA PS2_KBD_IN
                BRA -
         +      RTS
                
    NAME_ENTRY
                ; backspace and enter key have special actions
                ; other keys will lookup in array - if zero then nothing happens
                LDA KEYPRESSED
                CMP #BACKSPACE_KEY
                BEQ NE_BACKSPACE_KEY
                
                CMP #ENTER_KEY
                BEQ NE_ENTER_KEY
                
                TAX
                LDA KEYBOARD_TO_CHAR,X
                BEQ DONT_REACT
                
                JSR ADD_CHAR
                BRA DONT_REACT
                
    NE_BACKSPACE_KEY
                ; check that we're not going backwards
                JSR DEL_CHAR
                BRA DONT_REACT
                
    NE_ENTER_KEY
                JSR COMPLETE_ENTRY

                ; TODO - JSR SAVE_HI_SCORES
                
                LDA #GS_GAME_OVER
                STA GAME_STATE
                
                ; ERASE the ENTRY text
                LDA MMU_IO_CTRL
                PHA

                LDA #IO_PAGE2
                STA MMU_IO_CTRL
                
                LDA #<(TEXT_START + COLUMNS_PER_LINE*16 + 28)
                STA CURSORPOS
                LDA #>(TEXT_START + COLUMNS_PER_LINE*16 + 28)
                STA CURSORPOS + 1
                
                LDY #9 ; delete the bottom 9 lines
        ER_NEXT_LINE
                LDX #30 ; the number of characters to delete
                LDA #0
                
        ERASE_ENTRY_LOOP
                STA (CURSORPOS)
                INC CURSORPOS
                BNE +
                INC CURSORPOS + 1 
           +    DEX
                BNE ERASE_ENTRY_LOOP
                
                ; clear the next line
                CLC
                LDA CURSORPOS
                ADC #COLUMNS_PER_LINE - 30
                STA CURSORPOS
                BCC +
                INC CURSORPOS + 1
                
         +      DEY
                BNE ER_NEXT_LINE
                
                PLA
                STA MMU_IO_CTRL
                
    DONE_ENTRY
                RTS
                


; ****************************************************************
; ****************************************************************
; * Start of Frame Interrupt
; * 60Hz, 16ms Cyclical Interrupt
; ****************************************************************
; ****************************************************************
SOF_INTERRUPT
            
                LDA GAME_STATE  ; The SOF is still getting called, even when masked
                BNE CHK_GAME_RESTARTING
                
                CMP #GS_LINE_BONUS
                BEQ SOF_DONE
                
                JSR KEYBOARD_INTERRUPT_MATRIX
                JSR HANDLE_JOYSTICK
                JSR DISPLAY_BOARD_LOOP
                BRA SOF_DONE
                
    CHK_GAME_RESTARTING
                CMP #GS_RESTARTING
                BNE CHK_GAME_OVER

                
                
                BRA SOF_DONE
                
                
    CHK_GAME_OVER
                CMP #GS_GAME_OVER
                BNE CHK_REMOVE_LINES
                
                ; count 60 ticks for 1 second
                LDA GAME_OVER_TICK
                INC A
                STA GAME_OVER_TICK
                CMP #60
                BNE SOF_DONE
                
                STZ GAME_OVER_TICK
                SED
                LDA GAME_OVER_TIMER
                SEC
                SBC #1
                STA GAME_OVER_TIMER
                CLD
                JSR DISPLAY_COUNTDOWN
                
                LDA GAME_OVER_TIMER
                CMP #0
                BNE SOF_DONE
                
                LDA #GS_INTRO
                STA GAME_STATE
                JSR CLR_SCREEN
                JSR DISPLAY_INTRO
                
                BRA SOF_DONE
                
    CHK_REMOVE_LINES
                
                CMP #GS_LINE_BONUS
                BNE CHK_INTRO_SCREEN
                JSR REMOVE_LINES_LOOP
                
                BRA SOF_DONE
                
    CHK_INTRO_SCREEN
                CMP #GS_INTRO
                BNE CHK_ENTRY_SCREEN
                
                JSR KEYBOARD_INTERRUPT_MATRIX
                JSR HANDLE_JOYSTICK
                JSR INTRO_LOOP

                BRA SOF_DONE
                
    CHK_ENTRY_SCREEN
                CMP #GS_NAME_ENTRY
                BNE SOF_DONE
                
                JSR KEYBOARD_INTERRUPT_MATRIX
                ; write the user entry
                LDA #<(TEXT_START + COLUMNS_PER_LINE*16 + 45)
                STA CURSORPOS
                LDA #>(TEXT_START + COLUMNS_PER_LINE*16 + 45)
                STA CURSORPOS + 1
                LDA #$70
                STA CURCOLOR
                LDA #>HI_SCORES
                STA MSG_ADDR + 1
                CLC
                LDA #<HI_SCORES
                ADC TEMP_LOCATION
                STA MSG_ADDR

                JSR DISPLAY_MSG
                
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
                INC VKY_CURSOR_X
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
                DEC VKY_CURSOR_X
                
        D_C_DONE
                RTS
                
                
COMPLETE_ENTRY
                ; hide the cursor
                STZ VKY_CURSOR_CTRL
                
                ; replace all _ with space
        -       LDA HISCORE_OFFSET
                CMP #6
                BEQ CE_DONE
                
                CLC
                ADC TEMP_LOCATION
                
                TAX
                LDA #$20
                STA HI_SCORES,X
                INC HISCORE_OFFSET
                BRA - 
    CE_DONE
                RTS 
                
                
; ****************************************************************
;
;  MATRIX Keyboard Polling Routine
;
; ****************************************************************
KEYBOARD_INTERRUPT_MATRIX
                LDA KBD_POLL
                INC A
                STA KBD_POLL
                CMP #6
                BNE KIM_END
                
                STZ KBD_POLL
                
                LDA #$FF
                STA VIA1_DDRB    ; allows output on Port B
                
                LDA GAME_STATE
                CMP #GS_NAME_ENTRY
                BEQ KIM_ENTRY
                
                CMP #GS_INTRO
                BEQ KIM_SPACE
                
                LDA #~%0000_0100 ; select line 2, which contain A and D keys
                STA VIA1_IORB
                
                LDA VIA1_IORA
                BIT #2  ; check if the A key is pressed
                BNE +
                
                JSR MOVE_PIECE_LEFT
                BRA KIM_END
                
         +      BIT #4   ; check if the D key is pressed
                BNE +
                
                JSR MOVE_PIECE_RIGHT
                BRA KIM_END
                
         +      LDA #~%0010_0000 ; select line 5, which contains S
                STA VIA1_IORB
                
                LDA VIA1_IORA
                BIT #2    ; check if the S key is pressed
                BNE KIM_SPACE
                
                JSR MOVE_PIECE_DOWN
                BRA KIM_END
                
     KIM_SPACE  LDA #~%0001_0000    ; select line 4, which contains SPACE
                STA VIA1_IORB ; check if the SPACE key is pressed
                LDA VIA1_IORA
                BIT #$80
                BNE KIM_END
                
                LDA #SPACE_KEY
                STA KEYPRESSED
                
                LDA GAME_STATE
                BNE +
                
                JSR ROTATE_PIECE
                BRA KIM_END
                
        +       CMP #GS_INTRO
                BNE KIM_END
                
                ; the user has pressed a key change the game state to play
                LDA #GS_RESTARTING
                STA GAME_STATE
                ; this routine calls the DMA - must be done here?
                JSR CLR_SCREEN
                
    KIM_END     LDA #0             ; disable writing to Port B
                STA VIA1_DDRB
                RTS
                
    KIM_ENTRY
                LDA #$FF
                STA VIA1_DDRB    ; allows output on Port B
                
                LDX #0
                LDA #1
     SCAN_LOOP  STA TEMP_LOCATION
                EOR #$FF  ; flip all the bits
                STA VIA1_IORB  ; output the scan line
                LDA VIA1_IORA
                EOR #$FF
                ; if not #0
                BEQ SCL_X
      
                JSR MATRIX_KEY
                
                ; for debugging - display the key
                LDA #<(TEXT_START + 40)
                STA CURSORPOS
                LDA #>(TEXT_START + 40)
                STA CURSORPOS + 1
                LDA #$50
                STA CURCOLOR
                LDA KEYPRESSED
                PHA
                JSR DISPLAY_HEX
                PLA
                CMP #$F  ; backspace
                BNE KIM_CHK_RETURN
                
                JSR DEL_CHAR
                BRA KIME_END
                
       KIM_CHK_RETURN
                CMP #$8
                BNE KIM_OTHER_KEYS
                
                JSR COMPLETE_ENTRY
                
                BRA KIME_END
                
       KIM_OTHER_KEYS
                ; ignore key codes above $40
                CMP #$40
                BGE KIME_END
                
                TAX
                LDA KEYMATRIX_TO_CHAR,X
                BEQ KIME_END
                
                JSR ADD_CHAR
                BRA KIME_END
                
                
        SCL_X   LDA TEMP_LOCATION
                ASL A
                INX
                CPX #8
                BNE SCAN_LOOP
                
                
     KIME_END   LDA #0             ; disable writing to Port B
                STA VIA1_DDRB
                RTS
                
MATRIX_KEY  
                ; a key is pressed  X *8 + A
                BIT #1
                BEQ +
                LDA #0
                BRA PBS
                
             +  BIT #2
                BEQ + 
                LDA #1
                BRA PBS
                
             +  BIT #4
                BEQ + 
                LDA #2
                BRA PBS
                
             +  BIT #8
                BEQ + 
                LDA #3
                BRA PBS
                
             +  BIT #$10
                BEQ + 
                LDA #4
                BRA PBS
                
             +  BIT #$20
                BEQ + 
                LDA #5
                BRA PBS
                
             +  BIT #$40
                BEQ + 
                LDA #6
                BRA PBS
                
             +  BIT #$80
                BEQ PBS
                LDA #7
        PBS     STA KEYPRESSED
                TXA
                ASL A
                ASL A
                ASL A
                CLC
                ADC KEYPRESSED
                STA KEYPRESSED
                RTS
; **************************************************************************512
; * Handle Joystick Movements
; * Remember that the joystick at rest returns $FF.
; * Poll the joystick 10 times a second.
; *****************************************************************************
HANDLE_JOYSTICK
                LDA JOYSTICK_POLL
                INC A
                STA JOYSTICK_POLL
                CMP #6
                BNE JS_DONE
                
                
                STZ JOYSTICK_POLL
                
                LDA #<(TEXT_START + 5)
                STA CURSORPOS
                LDA #>(TEXT_START + 5)
                STA CURSORPOS + 1
                LDA #$20
                STA CURCOLOR
                
                ; DEBUG DISPLAY VIA PORT 0
                LDX MMU_IO_CTRL
                LDA #0
                STA MMU_IO_CTRL
                LDA VIA0_IORB
                STX MMU_IO_CTRL
                PHA
                JSR DISPLAY_HEX
                PLA
                ; we don't care about up #1
                BIT #2 ; down
                BNE JS_LEFT
                
                STZ BUTTON_PRESS
                JSR MOVE_PIECE_DOWN
                BRA JS_DONE
                
        JS_LEFT
                BIT #4 ; left
                BNE JS_RIGHT
                
                STZ BUTTON_PRESS
                JSR MOVE_PIECE_LEFT
                BRA JS_DONE
                
        JS_RIGHT
                BIT #8 ; right
                BNE JS_BUTTON
                
                STZ BUTTON_PRESS
                JSR MOVE_PIECE_RIGHT
                BRA JS_DONE
                
        JS_BUTTON
                BIT #$10 ; button
                BNE JS_NONE
                
                LDA BUTTON_PRESS
                BNE JS_DONE
                
                LDA #1
                STA BUTTON_PRESS
                JSR ROTATE_PIECE
                RTS
                
        JS_NONE
                STZ BUTTON_PRESS
        JS_DONE
                RTS
                