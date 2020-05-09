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
                AND #\2
                STA \1
                JSR \3
                
END_CHECK
                .endm
                
IRQ_HANDLER
; First Block of 8 Interrupts
                .as
                setdp 0
                
                .as
                LDA #0  ; set the data bank register to 0
                PHA
                PLB
                setas
                LDA INT_PENDING_REG0
                BEQ CHECK_PENDING_REG1

; Start of Frame (display), timer 0 (music), mouse (ignored)
                check_irq_bit INT_PENDING_REG0, FNX0_INT00_SOF, SOF_INTERRUPT
                check_irq_bit INT_PENDING_REG0, FNX0_INT02_TMR0, TIMER0_INTERRUPT
                ;check_irq_bit INT_PENDING_REG0, FNX0_INT03_TMR1, TIMER1_INTERRUPT
                check_irq_bit INT_PENDING_REG0, FNX0_INT07_MOUSE, MOUSE_INTERRUPT

; Second Block of 8 Interrupts
CHECK_PENDING_REG1
                setas
                
                LDA INT_PENDING_REG1
                BEQ CHECK_PENDING_REG2   ; BEQ EXIT_IRQ_HANDLE
; Keyboard Interrupt
                check_irq_bit INT_PENDING_REG1, FNX1_INT00_KBD, KEYBOARD_INTERRUPT

; Third Block of 8 Interrupts
CHECK_PENDING_REG2
                setas
                LDA INT_PENDING_REG2
                BEQ EXIT_IRQ_HANDLE
                
EXIT_IRQ_HANDLE
                ; Exit Interrupt Handler

                RTL

; ****************************************************************
; ****************************************************************
;
;  KEYBOARD_INTERRUPT
;
; ****************************************************************
; ****************************************************************
; * The only keys accepted are Left Arrow, Right Arrow, Down Arrow and Space (to rotate)
; * Alias ASD keys to arrows?
KEYBOARD_INTERRUPT
                .as
                
                setxs
                LDA KBD_INPT_BUF        ; Get Scan Code from KeyBoard
                CMP KEYBOARD_SC_TMP     ; don't accept auto-repeat
                BEQ DONT_REACT
                
                STA KEYBOARD_SC_TMP     ; Save Code Immediately
                TAX
                LDA ScanCode_Press_Set1,X
                TAX
                CPX #0
                BEQ DONT_REACT
                LDA GAME_STATE
                CMP #GS_LINE_BONUS
                BEQ DONT_REACT
                
                setxl
                JSR (KEY_JUMP_TABLE,X)
    DONT_REACT
                setxl
                LDA KBD_INPT_BUF
                RTS
                
KEY_JUMP_TABLE
                .word <>INVALID_KEY
                .word <>MOVE_PIECE_LEFT
                .word <>MOVE_PIECE_RIGHT
                .word <>MOVE_PIECE_DOWN
                .word <>ROTATE_PIECE

; ****************************************************************
; ****************************************************************
; * Start of Frame Interrupt
; * 60Hz, 16ms Cyclical Interrupt
; ****************************************************************
; ****************************************************************
SOF_INTERRUPT

                .as
                LDA GAME_STATE  ; The SOF is still getting called, even when masked
                BNE CHK_GAME_OVER 
                JSR DISPLAY_BOARD_LOOP
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
                
                LDA #0
                STA GAME_OVER_TICK
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
                JSL CLRSCREEN
                JSR DISPLAY_INTRO
                
                BRA SOF_DONE
                
    CHK_REMOVE_LINES
                
                CMP #3
                BNE CHK_INTRO_SCREEN
                JSR REMOVE_LINES_LOOP
                BRA SOF_DONE
                
    CHK_INTRO_SCREEN
                CMP #4
                BNE SOF_DONE
                JSR INTRO_LOOP
    SOF_DONE
                RTS


; ****************************************************************
; ****************************************************************
; * Play VGM files
; ****************************************************************
; ****************************************************************
TIMER0_INTERRUPT
                .as
                JSR VGM_WRITE_REGISTER
                RTS
                
; ****************************************************************
; ****************************************************************
; * Mouse Interrupt
; * We still need to service the mouse interrupts, even 
; * though we don't use it.
; ****************************************************************
; ****************************************************************
MOUSE_INTERRUPT .as
                setas
                LDA @lINT_PENDING_REG0
                AND #FNX0_INT07_MOUSE
                STA @lINT_PENDING_REG0
                LDA KBD_INPT_BUF
                LDX #$0000
                setxs
                LDX MOUSE_PTR
                STA @lMOUSE_PTR_BYTE0, X
                INX
                CPX #$03
                BNE EXIT_FOR_NEXT_VALUE
                ; Create Absolute Count from Relative Input
                LDA @lMOUSE_PTR_X_POS_L
                STA MOUSE_POS_X_LO
                LDA @lMOUSE_PTR_X_POS_H
                STA MOUSE_POS_X_HI

                LDA @lMOUSE_PTR_Y_POS_L
                STA MOUSE_POS_Y_LO
                LDA @lMOUSE_PTR_Y_POS_H
                STA MOUSE_POS_Y_HI

                setas
                LDX #$00
EXIT_FOR_NEXT_VALUE
                STX MOUSE_PTR

                setxl
                RTS