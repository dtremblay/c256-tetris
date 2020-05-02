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
; Start of Frame
                check_irq_bit INT_PENDING_REG0, FNX0_INT00_SOF, SOF_INTERRUPT


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
                
                LDX #$A000
                STX CURSORPOS
                LDX #$20
                STX CURCOLOR
                
                JSR DISPLAY_HEX
                LDA #0
                XBA
                LDA LAST_KEY
                TAX
                BEQ DONT_REACT
                LDA GAME_STATE
                CMP #3
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

;
; ///////////////////////////////////////////////////////////////////
; ///
; /// Start of Frame Interrupt
; /// 60Hz, 16ms Cyclical Interrupt
; ///
; ///////////////////////////////////////////////////////////////////
SOF_INTERRUPT

                .as
                
                LDA GAME_STATE  ; The SOF is still getting called, even when masked
                BNE SKIP_SOF 
                JSR DISPLAY_BOARD_LOOP
                BRA SOF_DONE
    SKIP_SOF
                CMP #3
                BNE SOF_DONE
                JSR REMOVE_LINES_LOOP
    SOF_DONE
                RTS

                
