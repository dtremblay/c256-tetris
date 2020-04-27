; *************************************************************************
; * Lame attempt at a copy-cat game like Tetris
; * Work under progress!
; *************************************************************************
.cpu "65816"
.include "macros_inc.asm"
.include "bank_00_inc.asm"
.include "vicky_def.asm"
.include "interrupt_def.asm"
.include "io_def.asm"
.include "kernel_inc.asm"
.include "math_def.asm"
.include "GABE_Control_Registers_def.asm"
.include "base.asm"

* = $000500
.include "keyboard_def.asm"
* = $160000
.include "interrupt_handler.asm"

TICK_COUNT      .byte 0
LAST_KEY        .word 0
BOARDX          .byte 0
BOARDY          .byte 0
CURRENT_PIECE   .byte 0
PIECE_X         .word 6
PIECE_Y         .word 0
PIECE_ROT       .byte 0
PIECE_FIT       .byte 0
GAME_SPEED      .byte 50 ; how many ticks beteen bars falling
PIECE_CNTR      .byte 0  ; we increase the speed of the game for every 10 pieces
SCORE           .long 0  ; decimal formatted score
GAME_STATE      .byte 0  ; 0 - running, 1 - game over
LEVEL           .byte 1

BOARD_WIDTH     = 14
BOARD_HEIGHT    = 21
START_BOARD     = $A900 + (72-BOARD_WIDTH)/2
PIECE_VALUE     = 25
LINE_VALUE      = 100
MSG_ADDR        = $60
ROT_VAL         = $62
ROT_VAL2        = $63

HEX_VALUES      .text '0','1','2','3','4','5','6','7','8','9','A','B','C','D','E','F'
GAME_OVER_MSG   .text 'GAME OVER',0
SCORE_MSG       .text 'SCORE:',0
                
GAME_START      
                setas
                setxl
                LDA #0
                STA KEYBOARD_SC_FLG 
                JSR INIT_GAME
                setal
                JSL INITSUPERIO
                LDA #6
                STA GABE_RNG_SEED_LO ; set the max value from 0 to 6
                STA PIECE_X
                JSL INITKEYBOARD
                setas
                
                LDA #0
                STA KEYBOARD_SC_FLG 
                JSL CLRSCREEN
                
                ; Enable SOF
                LDA #~( FNX0_INT00_SOF )
                STA @lINT_MASK_REG0
                ; Enable Keyboard
                LDA #~( FNX1_INT00_KBD )
                STA @lINT_MASK_REG1
                
                ; enable Random Number Generation
                LDA #1
                STA GABE_RNG_CTRL
                
                JSR PICK_NEXT_PIECE
                CLI
                
                ; wait for interrupts
    INFINITE_LOOP
                NOP
                NOP
                NOP
                LDA GAME_STATE
                CMP #2
                BEQ GAME_START
                BRA INFINITE_LOOP
                
DISPLAY_BOARD   
                .as
                ; TIMING
                LDA TICK_COUNT
                INC A
                STA TICK_COUNT
                CMP #50
                BNE TIMING_DONE
                
                LDA PIECE_Y
                INC A
                STA PIECE_Y
                LDA #0
                STA TICK_COUNT
                
    TIMING_DONE
                ; does the piece fit in this position?
                JSR DOES_PIECE_FIT
                LDA PIECE_FIT
                BEQ LOGIC_DONE
                
                ; if Y position is 0, then game over
                LDA PIECE_Y
                DEC A
                STA PIECE_Y
                BNE NOT_GAME_OVER
                
                JMP GAME_OVER
        NOT_GAME_OVER
                ; set the piece in place
                JSR COPY_PIECE
                setal
                CLC
                LDA SCORE
                ADC #PIECE_VALUE
                STA SCORE
                setas
                BCC NG_CONTINUE
                ; increment the hi-byte
                LDA SCORE+2
                INC A
                STA SCORE+2
        NG_CONTINUE
                JSR LOOK_FOR_LINES
                
                ; choose another piece and set it at the top
                LDA #6
                STA PIECE_X
                LDA #0
                STA PIECE_Y
                STA PIECE_FIT
                STA PIECE_ROT
                
                JSR PICK_NEXT_PIECE
                LDA PIECE_CNTR
                INC A
                STA PIECE_CNTR
                CMP #10
                BNE LOGIC_DONE
                
                LDA #0
                STA PIECE_CNTR
                LDA LEVEL
                INC A
                STA LEVEL
                
    LOGIC_DONE
                JSR DRAW_BOARD
                JSR DRAW_PIECE
                JSR DRAW_SCORE
                JSR DRAW_LEVEL
                
                RTS
                
PICK_NEXT_PIECE
                .as
                LDA GABE_RNG_DAT_LO
                AND #7
                STA CURRENT_PIECE
                CMP #7
                BEQ PICK_NEXT_PIECE
                RTS

DISPLAY_SYMBOL
                .as
                STA [CURSORPOS]
                setal
                LDA CURSORPOS
                CLC
                ADC #$2000
                STA COLORPOS
                setas
                LDA CURCOLOR
                STA [COLORPOS]
                RTS
                
INVALID_KEY
                RTS
                
; *******************************************************************
; * Look for lines
; *******************************************************************
LOOK_FOR_LINES
                .as
                STZ ROT_VAL2 ; line count max 4
    INIT_LINE_CHECK
                LDY #0
                STZ ROT_VAL  ; column count max 10
                setal
                LDA PIECE_Y
                STA UNSIGNED_MULT_A
                LDA #BOARD_WIDTH
                STA UNSIGNED_MULT_B
                LDA UNSIGNED_MULT_RESULT
                TAX
                setas
                
    CHK_NEXT_COL
                LDA BOARD,X
                BEQ CHK_NEXT_LINE
                INC ROT_VAL
                INX
                INY
                CPY #BOARD_WIDTH
                BNE CHK_NEXT_COL
                
                LDA ROT_VAL
                CMP #BOARD_WIDTH
                BEQ LINE_FOUND
                
    CHK_NEXT_LINE
                INC ROT_VAL2
                LDA PIECE_Y
                INC A
                STA PIECE_Y
                CMP #BOARD_HEIGHT-1
                BEQ LOOK_LINE_DONE
                LDA ROT_VAL2
                CMP #4
                BNE INIT_LINE_CHECK
    LOOK_LINE_DONE
                RTS
                
    LINE_FOUND
                setal
                LDA PIECE_Y
                STA UNSIGNED_MULT_A
                LDA #BOARD_WIDTH
                STA UNSIGNED_MULT_B
                LDA UNSIGNED_MULT_RESULT
                TAX
                setas
                INX
                INX ; skip the first two columns
                LDY #0
                LDA #'='
        LINE_CHAR
                STA BOARD,X
                INX
                INY
                CPY #BOARD_WIDTH-4
                BNE LINE_CHAR
                
                BRA CHK_NEXT_LINE

GET_PIECE_VALUE
                .as
                LDA #0
                XBA
                LDA PIECE_ROT
                BNE ROT_NEXT
                LDA PIECE0,X  ; ROTATION 0
                RTS
    ROT_NEXT
                CMP #1
                BNE ROT_2
                
                PHX
                TXA
                AND #$F0
                STA ROT_VAL2
                
                TXA
                AND #3
                TAX
                SEC
                LDA #12       ; ROTATION 1
        CMP_R1
                CPX #0
                BEQ R1_DONE
                SBC #4
                DEX
                BRA CMP_R1
        R1_DONE
                STA ROT_VAL
                LDA 1,S
                LSR A
                LSR A
                AND #3
                CLC
                ADC ROT_VAL
                ADC ROT_VAL2
                TAX
                LDA PIECE0,X  ; ROTATION 1
                PLX
                RTS
    ROT_2
                CMP #2
                BNE ROT_3
                PHX
                
                TXA
                AND #$F0
                STA ROT_VAL2
                TXA
                AND #$F
                STA ROT_VAL
                SEC
                LDA #$F
                SBC ROT_VAL
                CLC
                ADC ROT_VAL2
                TAX
                LDA PIECE0,X  ; ROTATION 2
                
                PLX
                RTS
                
    ROT_3       
                PHX
                TXA
                AND #$F0
                STA ROT_VAL2
                TXA
                AND #$C
                LSR A
                LSR A
                STA ROT_VAL
                
                LDA 1,S
                AND #3
                TAX
                LDA #3       ; ROTATION 3
        CMP_R3
                CPX #0
                BEQ R3_DONE
                CLC
                ADC #4
                DEX
                BRA CMP_R3
        R3_DONE
                SEC
                SBC ROT_VAL
                CLC
                ADC ROT_VAL2
                TAX
                LDA PIECE0,X  ; ROTATION 3
                PLX
                
                RTS
; *****************************************************************************
; * User Pressed Left Arrow
; *****************************************************************************
MOVE_PIECE_LEFT
                .as
                LDA GAME_STATE
                CMP #1 ; user pressed the space bar to restart the game
                BEQ MOVE_LEFT_DONE
                
                LDA PIECE_X
                DEC A
                STA PIECE_X
                JSR DOES_PIECE_FIT
                LDA PIECE_FIT
                BEQ MOVE_LEFT_DONE
                
                ; collision detected
                LDA PIECE_X
                INC A
                STA PIECE_X
                LDA #0
                STA PIECE_FIT
                
    MOVE_LEFT_DONE
                RTS

; *****************************************************************************
; * User Pressed Right Arrow
; *****************************************************************************
MOVE_PIECE_RIGHT
                .as
                LDA GAME_STATE
                CMP #1 ; user pressed the space bar to restart the game
                BEQ MOVE_RIGHT_DONE
                
                LDA PIECE_X
                INC A
                STA PIECE_X
                JSR DOES_PIECE_FIT
                LDA PIECE_FIT
                BEQ MOVE_RIGHT_DONE
                
                ; collision detected
                LDA PIECE_X
                DEC A
                STA PIECE_X
                LDA #0
                STA PIECE_FIT
                
    MOVE_RIGHT_DONE
                RTS

; *****************************************************************************
; * User Pressed Down Arrow
; *****************************************************************************
MOVE_PIECE_DOWN
                .as
                LDA GAME_STATE
                CMP #1 ; user pressed the space bar to restart the game
                BEQ DOWN_DONE
                
                LDA PIECE_Y
                INC A
                STA PIECE_Y
                
    DOWN_DONE
                RTS

; *****************************************************************************
; * User Pressed Space Bar
; *****************************************************************************
ROTATE_PIECE
                .as
                LDA GAME_STATE
                CMP #1 ; user pressed the space bar to restart the game
                BNE ROT_START
                LDA #2
                STA GAME_STATE
                RTS
                
    ROT_START
                LDA PIECE_ROT
                INC A
                CMP #4
                BNE ROTATE_DONE
                LDA #0
    ROTATE_DONE
                STA PIECE_ROT
                RTS
                
; *****************************************************************************
; * Lock a piece into place
; *****************************************************************************
COPY_PIECE
                .as
                LDA CURRENT_PIECE
                ASL A
                ASL A
                ASL A
                ASL A
                TAX
                
                setal
                LDA PIECE_Y
                STA UNSIGNED_MULT_A
                LDA #BOARD_WIDTH
                STA UNSIGNED_MULT_B
                LDA UNSIGNED_MULT_RESULT
                CLC
                ADC PIECE_X
                TAY
                LDA #0
                setas
                
    NEXT_COPY
                JSR GET_PIECE_VALUE
                CMP #0
                BEQ SKIP_COPY
                
                ; is the board occupied for this byte
                PHX
                TYX
                CLC
                LDA CURRENT_PIECE
                ADC #65
                STA BOARD,X
                PLX
                
        SKIP_COPY
                INX
                INY
                TXA
                AND #3
                BNE NEXT_COPY
                
                setal
                TYA
                CLC
                ADC #BOARD_WIDTH-4
                TAY
                setas
                
                TXA
                AND #$F
                BNE NEXT_COPY
                
                RTS
; *****************************************************************************
; * This is the tougher function.  Used to detect collisions.
; *****************************************************************************
DOES_PIECE_FIT
                .as
                LDA #0
                XBA
                LDA CURRENT_PIECE
                ASL A
                ASL A
                ASL A
                ASL A
                TAX
                
                setal
                LDA PIECE_Y
                STA UNSIGNED_MULT_A
                LDA #BOARD_WIDTH
                STA UNSIGNED_MULT_B
                LDA UNSIGNED_MULT_RESULT
                CLC
                ADC PIECE_X
                TAY
                LDA #0
                setas
                
    NEXT_COLLISION
                JSR GET_PIECE_VALUE
                CMP #0
                BEQ SKIP_BYTE
                
                ; is the board occupied for this byte
                PHX
                TYX
                LDA BOARD,X
                PLX
                CMP #0
                BNE OCCUPIED
                
                
    SKIP_BYTE
                INX
                INY
                TXA
                AND #3
                BNE NEXT_COLLISION
                
                setal
                TYA
                CLC
                ADC #BOARD_WIDTH-4
                TAY
                setas
                
                TXA
                AND #$F
                BNE NEXT_COLLISION
                BRA PF_DONE
                
                ; passed the end of the board
    OCCUPIED
                LDA #1
                STA PIECE_FIT
    PF_DONE
                RTS
DRAW_PIECE
                .as
                LDA #$63
                STA CURCOLOR
                setal
                LDA #START_BOARD
                CLC
                ADC PIECE_X
                STA CURSORPOS
                LDA #128
                STA UNSIGNED_MULT_A
                LDA PIECE_Y
                STA UNSIGNED_MULT_B
                LDA UNSIGNED_MULT_RESULT
                CLC
                ADC CURSORPOS
                STA CURSORPOS
                setas
                
                LDA #0
                XBA
                
                LDA CURRENT_PIECE
                ASL A
                ASL A
                ASL A
                ASL A
                TAX
        NEXT_PIECE_SYMBOL
                JSR GET_PIECE_VALUE
                CMP #0
                BEQ SKIP_DRAW
                
                LDA CURRENT_PIECE
                CLC
                ADC #65
                JSR DISPLAY_SYMBOL
        SKIP_DRAW
                INX
                INC CURSORPOS
                TXA
                AND #3
                BNE NEXT_PIECE_SYMBOL
                
                setal
                LDA CURSORPOS
                CLC
                ADC #124
                STA CURSORPOS
                TXA
                AND #$F
                setas
                BNE NEXT_PIECE_SYMBOL
                
                RTS
; draw the board
DRAW_BOARD
                .as
                .xl
                LDA #$40
                STA CURCOLOR
                LDX #START_BOARD
                STX CURSORPOS
                
                LDX #0
                LDA #0
                STA BOARDY
    NEXT_ROW
                LDA #0
                STA BOARDX
        NEXT_SYMBOL
                LDA BOARD,X
                JSR DISPLAY_SYMBOL
                INX 
                INC CURSORPOS
                LDA BOARDX
                INC A
                STA BOARDX
                CMP #BOARD_WIDTH
                BNE NEXT_SYMBOL
                
                setal
                LDA CURSORPOS
                CLC
                ADC #128-BOARD_WIDTH
                STA CURSORPOS
                setas
                LDA BOARDY
                INC A
                STA BOARDY
                CMP #BOARD_HEIGHT
                BNE NEXT_ROW
                RTS
                
DRAW_SCORE
                .as
                LDY #$A000 + 128*5 + 56
                STY CURSORPOS
                LDA #$20
                STA CURCOLOR
                
                LDY #<>SCORE_MSG
                STY MSG_ADDR
                JSR DISPLAY_MSG
                
                INC CURSORPOS
                LDA SCORE + 2
                JSR DISPLAY_HEX
                LDA SCORE + 1
                JSR DISPLAY_HEX
                LDA SCORE
                JSR DISPLAY_HEX
                
                RTS
                
DRAW_LEVEL
                .as
                RTS
                
DISPLAY_MSG
                .as
                PHB
                LDA #`SCORE_MSG
                PHA
                PLB
    MSG_LOOP
                LDA (MSG_ADDR)
                BEQ MSG_DONE
                JSR DISPLAY_SYMBOL
                INC CURSORPOS
                INC MSG_ADDR
                BRA MSG_LOOP
                
    MSG_DONE    PLB
                RTS
                
GAME_OVER
                .as
                ; stop the SOF interrupts
                LDA #$FF
                STA @lINT_MASK_REG0
                
                LDA #1
                STA GAME_STATE
                
                JSL CLRSCREEN
                LDY #$A000 + 128*26 + 31
                STY CURSORPOS
                LDA #$20
                STA CURCOLOR
                ; display GAME OVER
                LDY #<>GAME_OVER_MSG
                STY MSG_ADDR
                
                JSR DISPLAY_MSG
                
                ; display SCORE
                
                ; clear the board
                LDA #0
                STA PIECE_Y
                
                LDX #2
        CLEAR_BOARD_ROW
                LDY #0
                LDA #0
        CLEAR_BOARD_COL
                STA BOARD,X
                INX
                INY
                CPY #10
                BNE CLEAR_BOARD_COL
                
                INX
                INX
                INX
                INX
                LDA PIECE_Y
                INC A
                STA PIECE_Y
                CMP #BOARD_HEIGHT-1
                BNE CLEAR_BOARD_ROW
                
                LDA #0
                STA PIECE_Y
                
                RTS
                
DISPLAY_HEX
                .as
                PHA
                XBA
                LDA #0
                XBA
                
                AND #$F0
                LSR A
                LSR A
                LSR A
                LSR A
                TAX
                LDA HEX_VALUES,X
                JSR DISPLAY_SYMBOL
                ; increment the writing position
                INC CURSORPOS
                LDA #0  ; clear B
                XBA
                PLA
                AND #$F
                TAX
                LDA HEX_VALUES,X
                JSR DISPLAY_SYMBOL
                INC CURSORPOS
                RTS

; *****************************************************************************
; * INIT GAME
; *****************************************************************************
INIT_GAME
                .as
                LDA #50
                STA GAME_SPEED
                LDA #0       ;Set Cursor Disabled
                STA VKY_TXT_CURSOR_CTRL_REG
                STA PIECE_Y
                STA PIECE_FIT
                STA TICK_COUNT
                STA GAME_STATE
                STA SCORE
                STA SCORE + 1
                STA SCORE + 2
                LDA #1
                STA LEVEL
                
                ; Setup the Interrupt Controller
                ; For Now all Interrupt are Falling Edge Detection (IRQ)
                LDA #$FF
                STA @lINT_EDGE_REG0
                STA @lINT_EDGE_REG1
                STA @lINT_EDGE_REG2
                STA @lINT_EDGE_REG3
                
                ; Mask all Interrupt @ This Point
                LDA #$FF
                STA @lINT_MASK_REG0
                STA @lINT_MASK_REG1
                STA @lINT_MASK_REG2
                STA @lINT_MASK_REG3
                
                RTS
                
; *****************************************************************************
; * variables
; *****************************************************************************
BOARD
.rept BOARD_HEIGHT - 1
    .byte '#'
    .byte '#'
    .rept BOARD_WIDTH -4
        .byte 0
    .next
    .byte '#'
    .byte '#'
.next
.rept BOARD_WIDTH
    .byte '#'
.next

PIECE0
    .byte 0,0,1,0
    .byte 0,0,1,0
    .byte 0,0,1,0
    .byte 0,0,1,0

PIECE1
    .byte 0,1,1,0
    .byte 0,1,1,0
    .byte 0,0,0,0
    .byte 0,0,0,0

PIECE2
    .byte 0,1,0,0
    .byte 0,1,0,0
    .byte 0,1,1,0
    .byte 0,0,0,0

PIECE3
    .byte 0,0,1,0
    .byte 0,0,1,0
    .byte 0,1,1,0
    .byte 0,0,0,0

PIECE4
    .byte 0,0,1,0
    .byte 0,1,1,0
    .byte 0,0,1,0
    .byte 0,0,0,0

PIECE5
    .byte 0,0,1,0
    .byte 0,1,1,0
    .byte 0,1,0,0
    .byte 0,0,0,0

PIECE6
    .byte 0,1,0,0
    .byte 0,1,1,0
    .byte 0,0,1,0
    .byte 0,0,0,0