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
                LDA #0  ; clear B
                XBA
                
                LDA KBD_INPT_BUF        ; Get Scan Code from KeyBoard
                STA KEYBOARD_SC_TMP     ; Save Code Immediately
                
                TAX
                LDA ScanCode_Press_Set1,X
                STA LAST_KEY
                
                LDA #0
                XBA
                LDA LAST_KEY
                TAX
                BEQ DONT_REACT
                LDA GAME_STATE
                CMP #GS_LINE_BONUS
                BEQ DONT_REACT
                
                JSR (KEY_JUMP_TABLE,X)
    DONT_REACT
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
                BNE CHK_REMOVE_LINES 
                JSR DISPLAY_BOARD_LOOP
                BRA SOF_DONE
                
    CHK_REMOVE_LINES
                CMP #3
                BNE CHK_INTRO_SCREEN
                JSR REMOVE_LINES_LOOP
                BRA SOF_DONE
                
    CHK_INTRO_SCREEN
                CMP #4
                BNE SOF_DONE
                JSR DISPLAY_INTRO
    SOF_DONE
                RTS


; ****************************************************************
; ****************************************************************
; * Play notes
; ****************************************************************
; ****************************************************************
TIMER0_INTERRUPT
                .as
                
                LDA @lMUSIC_TICK
                BNE INCR_MUSIC_TICK
                
                JSR RAD_PLAYNOTES
                
    INCR_MUSIC_TICK
                LDA @lMUSIC_TICK
                INC A
                STA @lMUSIC_TICK
                CMP @lTuneInfo.InitialSpeed
                BNE TIMER0_DONE
                
                ; increment the line
                LDA LINE_NUM_HEX
                INC A
                STA LINE_NUM_HEX
                CMP #64 ; patterns have 64 lines
                BNE INCR_DONE
                
                STZ LINE_NUM_HEX
                JSR INCREMENT_ORDER
    INCR_DONE
                LDA #0
                STA @lMUSIC_TICK
    TIMER0_DONE
                
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