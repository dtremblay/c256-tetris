; *************************************************************************
; * Attempt at a copy-cat game like Tetris
; * Author Daniel Tremblay
; * Code written for the C256 Foenix retro computer
; * Permission is granted to reuse this code to create your own games
; * for the C256 Foenix.
; * Copyright Daniel Tremblay 2020
; * This code is provided without warranty.
; * Please attribute credits to Daniel Tremblay if you reuse.
; *************************************************************************
.cpu "65816"
.include "macros_inc.asm"
.include "bank_00_inc.asm"
.include "timer_def.asm"
.include "vicky_ii_def.asm"
.include "interrupt_def.asm"
.include "io_def.asm"
.include "kernel_inc.asm"
.include "math_def.asm"
.include "GABE_Control_Registers_def.asm"
.include "base.asm"
.include "EXP_C200_EVID_def.asm"

* = $000500
.include "keyboard_def.asm"
* = $160000
.include "interrupt_handler.asm"

TARGET_FMX       = 1
TARGET_U         = 2
COLUMNS_PER_LINE = 80
TICK_COUNT      .byte 0
BOARDX          .byte 0
BOARDY          .byte 0
CURRENT_PIECE   .byte 0
NEXT_PIECE      .byte 0
PIECE_X         .word 5
PIECE_Y         .word 0
PIECE_ROT       .byte 0
PIECE_FIT       .byte 0
GAME_SPEED      .byte 0 ; how many ticks beteen bars falling
PIECE_CNTR      .byte 0  ; we increase the speed of the game for every 10 pieces
SCORE           .fill 4, 0  ; decimal formatted score
GAME_STATE      .byte 4
GS_RUNNING      = 0   ;  0 - running,  
GS_GAME_OVER    = 1   ;  1 - game over, 
GS_RESTARTING   = 2   ;  2 - restarting, 
GS_LINE_BONUS   = 3   ;  3 - display line bonus, 
GS_INTRO        = 4   ;  4 - intro display
GS_NAME_ENTRY   = 5   ;  5 - name entry

LEVEL           .byte 1

INITIAL_GAME_SPEED = 40
BOARD_WIDTH     = 14
BOARD_HEIGHT    = 21
START_BOARD     = (1 + $40 * 5 + (40-BOARD_WIDTH)/2) * 2 + <>TL_MAP_0_ADDR
NEXT_PIECE_LOC  = (1 + $40 *11 + 31) * 2 + <>TL_MAP_0_ADDR
PIECE_VALUE     = $25  ; we're doing BCD additions

EFFECT_T_POSITION = $60 ; 4 bytes
EFFECT_T_WAIT_CNTR= $64 ; 2 bytes
EFFECT_L_POSITION = $66 ; 4 bytes
EFFECT_L_WAIT_CNTR= $6a ; 2 bytes
EFFECT_R_POSITION = $6c ; 4 bytes

MSG_ADDR        = $70
DEL_LINE_PTR    = $70
ROT_VAL         = $72
ROT_VAL2        = $73
LINE_CNTR       = $74
COPY_LINE_PTR   = $76
TOTAL_LINES     = $78 ; reserving 2 bytes

EFFECT_PLAY       = $7A ; 1 byte - 0 nothing, 1 tile down, 2 line, 4 rotate.
  TILE_EFFECT     = $1
  LINE_EFFECT     = $2
  ROTATE_EFFECT   = $4
EFFECT_R_WAIT_CNTR= $7B ; 2 bytes
BUTTON_PRESS      = $7D ; 1 byte
HISCORE_LINE      = $7E ; 1 byte
; $7F is used by the VGM player - leave it alone

GAME_OVER_TIMER = $80 ; 1 byte
GAME_OVER_TICK  = $81 ; 1 byte
INTRO_SLIDE_CNT = $82 ; 1 byte
JOYSTICK_POLL   = $83 ; 1 byte

OPM_BASE_ADDRESS  = $AFF000
PSG_BASE_ADDRESS  = $AFF100
OPN2_BASE_ADDRESS = $AFF200
OPL3_BASE_ADRESS  = $AFE600

; VGM Registers
SONG_START        = $84 ; 4 bytes
CURRENT_POSITION  = $88 ; 4 bytes
WAIT_CNTR         = $8C ; 2 bytes
LOOP_OFFSET_REG   = $8E ; 2 bytes

; TEMPORARY MEMORY LOCATION
TEMP_LOCATION     = $90 ; 2 bytes
HISCORE_OFFSET    = $92 ; 1 byte

TILESET_ADDR    = $B00000
TL_MAP_0_ADDR   = $B01000
TL_MAP_1_ADDR   = $B01800
BACKGROUND_ADDR = $B10000


GAME_START      
                setas
                setxl
                LDA #0
                STA KEYBOARD_SC_FLG
                STA MOUSE_PTR_CTRL_REG_L ; disable the mouse pointer
                STA VKY_TXT_CURSOR_CTRL_REG ; disable the cursor
                STA EFFECT_PLAY
                STA HISCORE_OFFSET
                
                ; set border color to 0
                STA BORDER_COLOR_B
                STA BORDER_COLOR_G
                STA BORDER_COLOR_R
                
                LDA #1
                STA LEVEL
                STA BORDER_CTRL_REG ; enable the border
                LDA #$20
                STA BORDER_X_SIZE
                STA BORDER_Y_SIZE
                
.for sc := 0, sc < 64, sc += 1
                LDA #' '
                STA EVID_TEXT_MEM + 100 * sc
                LDA #$10
                STA EVID_COLOR_MEM + 100 * sc
.next
                
                
                setal
                LDA #5
                STA GABE_RNG_SEED_LO ; set the max value from 0 to 6
                STA PIECE_X
                
                setas
                
                LDA #EVID_Ctrl_Text_Mode_En
                STA EVID_MSTR_CTRL_REG_L
                
                LDA #'A'
                STA EVID_TEXT_MEM + 100 * 2
                LDA #$10
                STA EVID_COLOR_MEM + 100 * 2
                
                JSR LOAD_GAME_ASSETS
                JSR ISDOS_INIT
                JSR LOAD_HI_SCORES
                LDA #GS_INTRO
                ;LDA #GS_NAME_ENTRY ; test hiscore
                STA GAME_STATE
                
                JSR CLEAR_TILESET
                
                JSR VGM_INIT_TIMERS
                
                ; set the display mode to tiles
                LDA #Mstr_Ctrl_TileMap_En + Mstr_Ctrl_Bitmap_En + Mstr_Ctrl_Text_Mode_En + Mstr_Ctrl_Graph_Mode_En + Mstr_Ctrl_Text_Overlay
                STA MASTER_CTRL_REG_L
                
                ; enable Random Number Generation
                LDA #1
                STA GABE_RNG_CTRL
                
    NEXT_GAME
                JSL CLRSCREEN ; clears the text
                
                ; Enable SOF and TIMER0
                LDA #~( FNX0_INT00_SOF | FNX0_INT02_TMR0 | FNX0_INT03_TMR1)
                STA @lINT_MASK_REG0
                ; Enable Keyboard
                LDA #~( FNX1_INT00_KBD )
                STA @lINT_MASK_REG1
                
                LDA GAME_STATE
                CMP #GS_INTRO
                BNE SKIP_INTRO
                
                JSR DISPLAY_INTRO
                CLI
                BRA INFINITE_LOOP
                
        SKIP_INTRO
                SEI
            RANDOM_TRY_AGAIN
                LDA GABE_RNG_DAT_LO
                AND #7
                STA NEXT_PIECE
                CMP #7
                BEQ RANDOM_TRY_AGAIN
                
                JSR PICK_NEXT_PIECE
                
                JSR DRAW_NEXT_PIECE
                CLI
                
                ; wait for interrupts
    INFINITE_LOOP
                NOP
                NOP
                NOP
                LDA GAME_STATE
                CMP #GS_RESTARTING
                BNE IL_DONE
                
                LDA #GS_RUNNING
                STA GAME_STATE
                JSR INIT_GAME
                
                BRA NEXT_GAME
        
        IL_DONE
                BRA INFINITE_LOOP
                
DISPLAY_BOARD_LOOP
                .as
                ; TIMING
                LDA TICK_COUNT
                INC A
                STA TICK_COUNT
                CMP GAME_SPEED
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
                BNE NOT_GAME_OVER
                JMP GAME_OVER
                
        NOT_GAME_OVER
                ; set the piece in place
                JSR PLAY_EFFECT_TILE_DOWN
                JSR COPY_PIECE
                
                setal
                SED
                CLC
                LDA SCORE
                ADC #PIECE_VALUE
                STA SCORE
                BCC NG_CONTINUE ; carry
                ; increment the hi-byte
                CLC
                LDA SCORE+2
                ADC #1
                STA SCORE+2
        NG_CONTINUE
                CLD
                setas
                JSR LOOK_FOR_LINES
                
                ; choose another piece and set it at the top
                LDA #5
                STA PIECE_X
                LDA #0
                STA PIECE_Y
                STA PIECE_FIT
                STA PIECE_ROT
                STA TICK_COUNT
                
                JSR PICK_NEXT_PIECE
                ; draw the next piece
                JSR DRAW_NEXT_PIECE
                
                LDA PIECE_CNTR
                INC A
                STA PIECE_CNTR
                CMP #10
                BNE LOGIC_DONE
                
                ; increase difficulty level and game speed
                LDA #0
                STA PIECE_CNTR
                SED
                CLC
                LDA LEVEL
                ADC #1
                STA LEVEL
                CLD
                LDA GAME_SPEED
                SEC
                SBC #2
                STA GAME_SPEED
                
    LOGIC_DONE
                JSR DRAW_BOARD
                JSR DRAW_PIECE
                JSR DRAW_HI_SCORES
                JSR DRAW_SCORE
                JSR DRAW_LEVEL
                JSR DRAW_LINES
                
                RTS
                
                
                
PICK_NEXT_PIECE
                .as
                LDA NEXT_PIECE
                STA CURRENT_PIECE
                
    PN_TRY_AGAIN
                LDA GABE_RNG_DAT_LO
                AND #7
                STA NEXT_PIECE
                CMP #7
                BEQ PN_TRY_AGAIN
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
                STZ LINE_CNTR
                STZ LINE_CNTR + 1
    INIT_LINE_CHECK
                LDY #0
                STZ ROT_VAL  ; column count max 10
                setal
                LDA PIECE_Y
                DEC A
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
                CMP #BOARD_HEIGHT
                BEQ LOOK_LINE_DONE
                LDA ROT_VAL2
                CMP #4
                BNE INIT_LINE_CHECK
    LOOK_LINE_DONE
                RTS
                
    LINE_FOUND
                INC LINE_CNTR
                LDA #3
                STA GAME_STATE
                setal
                LDA PIECE_Y
                DEC A
                STA UNSIGNED_MULT_A
                LDA #BOARD_WIDTH
                STA UNSIGNED_MULT_B
                LDA UNSIGNED_MULT_RESULT
                TAX
                setas
                INX
                INX ; skip the first two columns
                LDY #0
                LDA #9
                STA BOARD,X
                INX
                INY
                LDA #10
        LINE_CHAR
                STA BOARD,X
                INX
                INY
                CPY #BOARD_WIDTH-5
                BNE LINE_CHAR
                LDA #11
                STA BOARD,X
                
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
; * Handle Joystick Movements
; * Remember that the joystick at rest returns $9F.
; * Poll the joystick 10 times a second.
; *****************************************************************************
HANDLE_JOYSTICK
                .as
                LDA JOYSTICK_POLL
                INC A
                STA JOYSTICK_POLL
                CMP #6
                BNE JS_DONE
                
                STZ JOYSTICK_POLL
                LDA JOYSTICK0
                
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
                BEQ MOVE_DOWN_DONE
                
                LDA PIECE_Y
                INC A
                STA PIECE_Y
                
                JSR DOES_PIECE_FIT
                LDA PIECE_FIT
                BEQ MOVE_DOWN_DONE
                
                LDA PIECE_Y
                DEC A
                STA PIECE_Y
                LDA #0
                STA PIECE_FIT
                
    MOVE_DOWN_DONE
                RTS

; *****************************************************************************
; * User Pressed Space Bar
; *****************************************************************************
ROTATE_PIECE
                .as
                LDA GAME_STATE
                CMP #GS_GAME_OVER ; user pressed the space bar to restart the game
                BEQ CHANGE_STATE

                CMP #GS_INTRO
                BNE ROT_START
    CHANGE_STATE
                LDA #GS_RESTARTING
                STA GAME_STATE
                
                RTS
                
    ROT_START
                LDA PIECE_ROT
                INC A
                CMP #4
                BNE ROTATE_CHECK_COLLISION
                LDA #0
    ROTATE_CHECK_COLLISION
                STA PIECE_ROT
                JSR DOES_PIECE_FIT
                LDA PIECE_FIT
                BEQ ROTATE_DONE
                
                LDA #0
                STA PIECE_FIT
                
                ; collision detected
                LDA PIECE_ROT
                BEQ ROTATE_3
                DEC A
                BRA UNDO_ROT_COLISION
                
    ROTATE_3
                LDA #3
    UNDO_ROT_COLISION
                STA PIECE_ROT
                RTS
                
    ROTATE_DONE
                JSR PLAY_EFFECT_ROTATE
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
                DEC A
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
                ADC #2
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
                
; draw the board as tiles
DRAW_BOARD
                .as
                .xl
                LDX #START_BOARD
                STX CURSORPOS
                LDA #`TL_MAP_0_ADDR
                STA CURSORPOS + 2
                
                LDX #0
                LDA #0
                STA BOARDY
    NEXT_ROW
                LDA #0
                STA BOARDX
        NEXT_SYMBOL
                LDA BOARD,X
                CMP #'#'
                BNE SKIP_DR_BRD
                LDA #1
                BRA DISPLAY_BLOCK
                
            SKIP_DR_BRD
                ;LDA #0
            DISPLAY_BLOCK
                STA [CURSORPOS]
                INX 
                INC CURSORPOS
                ; each tile is 16 bits - the second byte is tileset0 and lut0
                LDA #0
                STA [CURSORPOS]
                INC CURSORPOS
                
                LDA BOARDX
                INC A
                STA BOARDX
                CMP #BOARD_WIDTH
                BNE NEXT_SYMBOL
                
                setal
                LDA CURSORPOS
                CLC
                ADC #($40-BOARD_WIDTH) * 2
                STA CURSORPOS
                setas
                LDA BOARDY
                INC A
                STA BOARDY
                CMP #BOARD_HEIGHT
                BNE NEXT_ROW
                RTS

DRAW_PIECE
                .as
                LDA #`TL_MAP_0_ADDR
                STA CURSORPOS + 2
                setal
                LDA #START_BOARD
                CLC
                ADC PIECE_X
                ADC PIECE_X ; multiply by 2
                STA CURSORPOS
                LDA #128 ; each tile is 16-bits
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
                
                LDA CURRENT_PIECE ; each piece is 16 bytes
                ASL A
                ASL A
                ASL A
                ASL A
                TAX
        DP_NEXT_PIECE_SYMBOL
                JSR GET_PIECE_VALUE
                CMP #0
                BEQ SKIP_DRAW
                
                LDA CURRENT_PIECE ; skip first two tiles
                CLC
                ADC #2
                STA [CURSORPOS]
                
        SKIP_DRAW
                INX
                INC CURSORPOS
                LDA #0
                STA [CURSORPOS]
                INC CURSORPOS
                TXA
                AND #3
                BNE DP_NEXT_PIECE_SYMBOL
                
                setal
                LDA CURSORPOS
                CLC
                ADC #($40-4) * 2
                STA CURSORPOS
                TXA
                AND #$F
                setas
                BNE DP_NEXT_PIECE_SYMBOL
                
                RTS
                
DRAW_NEXT_PIECE
                .as
                LDY #$A000 + COLUMNS_PER_LINE * 16 + 56
                STY CURSORPOS
                LDA #$AF
                STA CURSORPOS + 2
                LDA #$20
                STA CURCOLOR
                
                LDY #<>NEXT_TILE_MSG
                STY MSG_ADDR
                JSR DISPLAY_MSG
                
                LDX #NEXT_PIECE_LOC
                STX CURSORPOS
                LDA #`TL_MAP_0_ADDR
                STA CURSORPOS + 2
                
                LDA #0
                XBA
                
                LDA NEXT_PIECE ; each piece is 16 bytes
                ASL A
                ASL A
                ASL A
                ASL A
                TAX
        DNP_NEXT_PIECE_SYMBOL
                LDA PIECE0,X
                CMP #0
                BEQ DRAW_BLANK
                
                LDA NEXT_PIECE ; skip fist two tiles
                CLC
                ADC #2
                
        DRAW_BLANK
                STA [CURSORPOS]
                
                INX
                INC CURSORPOS
                LDA #0
                STA [CURSORPOS]
                INC CURSORPOS
                TXA
                AND #3
                BNE DNP_NEXT_PIECE_SYMBOL
                
                setal
                LDA CURSORPOS
                CLC
                ADC #($40-4) * 2
                STA CURSORPOS
                TXA
                AND #$F
                setas
                BNE DNP_NEXT_PIECE_SYMBOL
                
                RTS
                
DRAW_SCORE
                .as
                LDY #$A000 + COLUMNS_PER_LINE * 5 + 56
                STY CURSORPOS
                LDA #$AF
                STA CURSORPOS + 2
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
                
DRAW_HI_SCORES
                .as
                ; display "HI SCORES:"
                LDY #$A000 + COLUMNS_PER_LINE * 5 + 3
                STY CURSORPOS
                LDA #$AF
                STA CURSORPOS + 2
                LDA #$20
                STA CURCOLOR
                
                LDY #<>HI_SCORE_MSG
                STY MSG_ADDR
                JSR DISPLAY_MSG
                
                ; display the highest scores
                LDY #$A000 + COLUMNS_PER_LINE * 6 + 3
                STY CURSORPOS
                
                LDY #<>HI_SCORES
                STY MSG_ADDR
                
                LDX #0
                
    DHS_NEXT_SCORE
                
                JSR DISPLAY_MSG
                
                INC CURSORPOS
                ; display the score
                setas
                LDA HI_SCORES + 9,X
                JSR DISPLAY_HEX
                LDA HI_SCORES + 8,X
                JSR DISPLAY_HEX
                LDA HI_SCORES + 7,X
                JSR DISPLAY_HEX
                
                setal
                ; increment the score reader to the next line
                TXA
                CLC
                ADC #10
                TAX
                
                ; place the start of the message to the next player's name
                CLC
                ADC #<>HI_SCORES
                STA MSG_ADDR
                
                ; calculate the position to write to
                LDA CURSORPOS
                CLC
                ADC #COLUMNS_PER_LINE - 13 ; name is 6+1 and score is 3 * 2 chars = 13
                STA CURSORPOS
                
                ; if the score is not zero, then display the name and score
                LDA HI_SCORES + 7,X
                setas
                BNE DHS_NEXT_SCORE

                RTS
DRAW_LEVEL
                .as
                LDY #$A000 + COLUMNS_PER_LINE * 7 + 56
                STY CURSORPOS
                LDA #$AF
                STA CURSORPOS + 2
                LDA #$20
                STA CURCOLOR
                
                LDY #<>LEVEL_MSG
                STY MSG_ADDR
                JSR DISPLAY_MSG
                
                CLC
                LDA CURSORPOS
                ADC #5
                STA CURSORPOS
                LDA LEVEL
                JSR DISPLAY_HEX
                
                RTS
                
DRAW_LINES
                .as
                LDY #$A000 + COLUMNS_PER_LINE * 13 + 56
                STY CURSORPOS
                LDA #$AF
                STA CURSORPOS + 2
                LDA #$20
                STA CURCOLOR
                
                LDY #<>LINES_MSG
                STY MSG_ADDR
                JSR DISPLAY_MSG
                
                INC CURSORPOS
                LDA TOTAL_LINES+1
                JSR DISPLAY_HEX
                LDA TOTAL_LINES
                JSR DISPLAY_HEX
                
                RTS
                
; *******************************************************************
; * This routine will display the "BONUS" for 50 ticks and 
; * then delete the lines.
; *******************************************************************
REMOVE_LINES_LOOP
                .as
                LDA TICK_COUNT
                INC A
                STA TICK_COUNT
                CMP #1
                BNE WAIT_FOR_50
                
                ; display bonus message
                LDY #$A000 + COLUMNS_PER_LINE * 11 + 56
                STY CURSORPOS
                LDA #$AF
                STA CURSORPOS + 2
                LDA #$20
                STA CURCOLOR
                
                LDY #<>BONUS_MSG
                STY MSG_ADDR
                JSR DISPLAY_MSG
                
                INC CURSORPOS
                
                LDX LINE_CNTR
                LDA BONUS,X
                JSR DISPLAY_HEX
                LDA #0
                JSR DISPLAY_HEX
                ; play sound effect
                JSR PLAY_EFFECT_LINE
                
                BRA SKIP_DELETE_LINES
    WAIT_FOR_50
                CMP #50
                BNE SKIP_DELETE_LINES
                
                ; delete the bonus line
                LDY #$A000 + COLUMNS_PER_LINE * 11 + 56
                STY CURSORPOS
                LDA #0
                LDY #0
        CLEAR_BONUS_LP
                STA [CURSORPOS],Y
                INY
                CPY #16
                BNE CLEAR_BONUS_LP
                
                ; add the bonus to the score
                LDX LINE_CNTR
                LDA BONUS,X
                XBA ; multiply by 256
                LDA #0
                setal
                SED
                CLC 
                ADC SCORE
                STA SCORE
                BCC CB_CONTINUE ; carry
                
                ; increment the hi-byte
                CLC
                LDA SCORE+2
                ADC #1
                STA SCORE+2
        CB_CONTINUE
                ; calculate the number of total lines
                LDA LINE_CNTR
                CLC
                ADC TOTAL_LINES
                STA TOTAL_LINES
                setas
                
                BCC BONUS_CONTINUE
                ; increment the hi-byte
                LDA SCORE+2
                CLC
                ADC #1
                
                STA SCORE+2
        BONUS_CONTINUE
                CLD
                ; delete the lines
                JSR DELETE_LINES
                
                ; reset the game state
                LDA #0
                STA TICK_COUNT
                STA GAME_STATE
                
    SKIP_DELETE_LINES
                RTS
                
DISPLAY_MSG
                .as
                PHX
                PHB
                LDA #`SCORE_MSG
                PHA
                PLB
    MSG_LOOP
                LDA (MSG_ADDR)
                BEQ MSG_DONE
                JSR DISPLAY_SYMBOL
                LDX CURSORPOS
                INX
                STX CURSORPOS
                LDX MSG_ADDR
                INX
                STX MSG_ADDR
                BRA MSG_LOOP
                
    MSG_DONE    PLB
                PLX
                RTS
                
GAME_OVER
                .as
                ; check if the score is one of the 10 highest
                JSR CHECK_SCORE
                
                LDA HISCORE_LINE
                CMP #10
                BEQ NOT_A_HISCORE
                
                ; show the user name entry screen
                LDA #GS_NAME_ENTRY
                BRA G_O_RESUME
                
        NOT_A_HISCORE
                LDA #GS_GAME_OVER
        G_O_RESUME
                STA GAME_STATE
                LDA #0
                STA GAME_OVER_TICK
                LDA #$30
                STA GAME_OVER_TIMER
                
                LDA #$0 ; disable the tiles
                STA TL0_CONTROL_REG
                STA TL1_CONTROL_REG
                
                ; load the game over music
                LDA #`VGM_GAME_OVER_MUSIC
                STA CURRENT_POSITION + 2
                STA SONG_START + 2
                setal
                LDA #<>VGM_GAME_OVER_MUSIC
                STA SONG_START
                setas
                JSR VGM_SET_SONG_POINTERS
                
                JSL CLRSCREEN
                LDY #$A000 + COLUMNS_PER_LINE*26 + 31
                STY CURSORPOS
                LDA #$AF
                STA CURSORPOS + 2
                LDA #$23
                STA CURCOLOR
                ; display GAME OVER
                LDY #<>GAME_OVER_MSG
                STY MSG_ADDR
                JSR DISPLAY_MSG
                
                ; display SCORE
                LDY #$A000 + COLUMNS_PER_LINE*27 + 29
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
                
                LDA GAME_STATE
                CMP #GS_NAME_ENTRY
                BNE G_O_SKIP_ENTRY_MSG
                
                ; display Press Return when done message
                LDY #$A000 + COLUMNS_PER_LINE*36 + 24
                STY CURSORPOS
                LDY #<>RETURN_DONE_MSG
                STY MSG_ADDR
                JSR DISPLAY_MSG
                
                ; display Backspace message
                LDY #$A000 + COLUMNS_PER_LINE*37 + 24
                STY CURSORPOS
                LDY #<>BKSP_MSG
                STY MSG_ADDR
                JSR DISPLAY_MSG
                
                LDY #$A000 + COLUMNS_PER_LINE*32 + 24
                STY CURSORPOS
                LDA #$23
                STA CURCOLOR
                ; display USER_NAME_ENTRY PROMPT
                LDY #<>ENTER_USERNAME_MSG
                STY MSG_ADDR
                JSR DISPLAY_MSG
                
        G_O_SKIP_ENTRY_MSG
                JSR DISPLAY_COUNTDOWN
                
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
                
DISPLAY_COUNTDOWN
                .as
                ; display RESTART
                LDY #$A000 + COLUMNS_PER_LINE*29 + 29
                STY CURSORPOS
                LDA #$AF
                STA CURSORPOS + 2
                LDA #$20
                STA CURCOLOR
                
                LDY #<>RESTART_MSG
                STY MSG_ADDR
                JSR DISPLAY_MSG
                
                ; the countdown timer is in BCD
                LDA GAME_OVER_TIMER
                JSR DISPLAY_HEX
                
                RTS
DISPLAY_HEX
                .as
                PHX
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
                PLX
                RTS

; *****************************************************************************
; * Delete the full lines - start from the bottom of the board.
; *****************************************************************************
DELETE_LINES
                .as
                PHB
                setal
                LDA LINE_CNTR
                AND #$F
                ; if 0 then there are no lines to delete and we shouldn't have gotten here
                BEQ DELETE_LINES_DONE
                
                ; find the deleted lines
                LDA #BOARD_WIDTH * (BOARD_HEIGHT-2)
        LOOK_UP
                STA BYTE_CNTR
                
                TAX
                INX
                INX
        DL_CHECK_NEXT
                
                LDA @lBOARD,X
                CMP #$A09  ; these are the start and middle tiles
                BNE DONT_DELETE
                
                ; LDA #<>BOARD
                ; CLC
                ; ADC BYTE_CNTR
                ; TAX
                ; ADC #BOARD_WIDTH
                ; TAY
                ; LDA BYTE_CNTR
                ; DEC A
                ; MVP `BOARD,`BOARD

                ; LDA BYTE_CNTR
                ; TAX
                ; LDA LINE_CNTR
                ; DEC A
                ; STA LINE_CNTR
                
                ; *************** Replace MVP with loop starting from the bottom ************
                PHX
                
                LDA BYTE_CNTR
                TAX
        -       LDA BOARD,X
                STA BOARD+BOARD_WIDTH,X
                DEX
                BNE -
                
                PLX
                
                ; check the next line
                LDA LINE_CNTR
                AND #$F
                DEC A
                STA LINE_CNTR
                
                BNE DL_CHECK_NEXT
                
                BRA DELETE_LINES_DONE
                
        DONT_DELETE
                LDA BYTE_CNTR
                SEC
                SBC #BOARD_WIDTH
                BRA LOOK_UP
                
    DELETE_LINES_DONE
                setas
                PLB
                RTS

; we're using two tilemaps: 0 is the game board, 1 is the intro "C256 Foenix"
; the tileset is the same for both tilemaps.  Stored at B0:0000
; the 
LOAD_GAME_ASSETS
                .as
                PHB
                ; disable graphics to start with
                LDA #Mstr_Ctrl_Disable_Vid
                STA MASTER_CTRL_REG_L
                
                ; set the tilemap addresses
                LDA #0
                STA TL0_START_ADDY_H ; addresses are offset by $B0:0000
                STA TL1_START_ADDY_H
                STA TILESET0_ADDY_H  ; tileset offset
                STA BM0_CONTROL_REG  ; disable bitmap 0
                LDA #(`BACKGROUND_ADDR - $B00000)
                STA BM1_START_ADDY_H ; start at $b1:0000
                LDA #8
                STA TILESET0_ADDY_CFG ; set stride to 256
                STA TILESET1_ADDY_CFG ; set stride to 256
                
                setal
                LDA #0
                STA BM1_START_ADDY_L ; B1:0000
                STA TL0_WINDOW_X_POS_L
                STA TL0_WINDOW_Y_POS_L
                STA TL1_WINDOW_X_POS_L
                STA TL1_WINDOW_Y_POS_L
                STA TILESET0_ADDY_L ; offset of the tileset 0 is B0:0000
                
                ; base addresses for tilemaps
                LDA #<>TL_MAP_0_ADDR
                STA TL0_START_ADDY_L
                LDA #<>TL_MAP_1_ADDR
                STA TL1_START_ADDY_L
                
                ; both tilemaps are 64 x 32
                LDA #64
                STA TL0_TOTAL_X_SIZE_L
                STA TL1_TOTAL_X_SIZE_L
                LDA #32
                STA TL0_TOTAL_Y_SIZE_L
                STA TL1_TOTAL_Y_SIZE_L
                
                ; load tiles
                LDA #$1000-1
                LDX #<>TILESET
                LDY #<>TILESET_ADDR
                MVN `TILESET,`TILESET_ADDR ; B0:0000
                
                ; load tile palette
                LDA #$400-1
                LDX #<>PALETTE
                LDY #<>GRPH_LUT0_PTR
                MVN #`PALETTE,#`GRPH_LUT0_PTR ; PALETTE LUT 0 AF:2000
                
                ; load background palette
                LDA #$400-1
                LDX #<>BACKGROUND_PAL
                LDY #<>GRPH_LUT1_PTR
                MVN #`BACKGROUND_PAL,#`GRPH_LUT1_PTR; PALETTE LUT 1 AF:2400
                
                ; load background image - need 4 x 64k moves
                LDA #$FFFF
                LDX #<>BACKGROUND
                LDY #$0
                MVN `BACKGROUND,$B1
                
                LDA #$FFFF
                LDX #<>BACKGROUND
                LDY #0
                MVN `BACKGROUND+$10000,$B2
                
                LDA #$FFFF
                LDX #<>BACKGROUND
                LDY #0
                MVN `BACKGROUND+$20000,$B3
                
                LDA #$FFFF
                LDX #<>BACKGROUND
                LDY #0
                MVN `BACKGROUND+$30000,$B4
                
                LDA #$AFFF
                LDX #<>BACKGROUND
                LDY #0
                MVN `BACKGROUND+$40000,$B5
                
                LDA #$800-1
                LDX #<>FONTSET
                LDY #<>FONT_MEMORY_BANK0
                MVN `FONTSET,`FONT_MEMORY_BANK0
                
                setas
                PLB ; MVN operations set the bank - so we need to reset
                ; disable tile layer 1
                LDA #0
                STA TL1_CONTROL_REG
                ; enable tile layer 0
                LDA #$1
                STA TL0_CONTROL_REG

                ; enable bitmap 1, with LUT 1
                LDA #$3
                STA BM1_CONTROL_REG
                
                
                RTS
; *****************************************************************************
; * INIT GAME
; *****************************************************************************
INIT_GAME
                .as
                LDA #INITIAL_GAME_SPEED
                STA GAME_SPEED
                LDA #0       ;Set Cursor Disabled
                STA VKY_TXT_CURSOR_CTRL_REG
                STA PIECE_Y
                STA PIECE_FIT
                STA TICK_COUNT
                STA SCORE
                STA SCORE + 1
                STA SCORE + 2
                STA TOTAL_LINES
                STA TOTAL_LINES + 1
                ; set border color to 0
                STA BORDER_COLOR_B
                STA BORDER_COLOR_G
                STA BORDER_COLOR_R
                
                LDA #1
                STA LEVEL
                
                LDA #COLUMNS_PER_LINE
                STA COLS_PER_LINE
                
                ; Setup the Interrupt Controller
                ; For Now all Interrupt are Falling Edge Detection (IRQ)
                LDA #$FF
                STA @lINT_EDGE_REG0
                STA @lINT_EDGE_REG1
                STA @lINT_EDGE_REG2
                STA @lINT_EDGE_REG3
                
                ; ; Mask all Interrupt @ This Point
                LDA #$FF
                STA @lINT_MASK_REG0
                STA @lINT_MASK_REG1
                STA @lINT_MASK_REG2
                STA @lINT_MASK_REG3
                
                JSR CLEAR_TILESET
                
                LDA #$1
                STA TL0_CONTROL_REG ; enable the board tiles
                LDA #$0
                STA TL1_CONTROL_REG ; disable the intro tiles
                
                ; load the play music
                LDA #`VGM_PLAY_MUSIC
                STA CURRENT_POSITION + 2
                STA SONG_START + 2
                
                setal
                LDA #<>VGM_PLAY_MUSIC
                STA SONG_START
                setas
                JSR VGM_SET_SONG_POINTERS
                
                ; set the display mode to tiles
                LDA #Mstr_Ctrl_TileMap_En + Mstr_Ctrl_Bitmap_En + Mstr_Ctrl_Text_Mode_En + Mstr_Ctrl_Graph_Mode_En + Mstr_Ctrl_Text_Overlay
                STA MASTER_CTRL_REG_L
                
                RTS

INTRO_LOOP
                .as
                LDA TICK_COUNT
                INC A
                STA TICK_COUNT
                CMP #20
                BNE INTRO_LOOP_DONE 
                LDA #0
                STA TICK_COUNT
                
                LDX #0
                LDA INTRO_SLIDE_CNT
                INC A
                STA INTRO_SLIDE_CNT
                
                LDX #0
                
                ; prepare to copy bytes from mem to video ram
                LDA #`TL_MAP_1_ADDR
                STA CURSORPOS + 2
                LDY #<>TL_MAP_1_ADDR
                STY CURSORPOS
                LDX #0
                LDY #0
        IL_NEXT_TILE
                LDA INTRO_TILESET,X
                BEQ IT_SKIP
                INC A
                CMP #9
                BNE IT_GOOD
                
                LDA #2
            IT_GOOD
                STA INTRO_TILESET,X
                STA [CURSORPOS],Y
                
            IT_SKIP
                INX
                INY
                LDA #0
                STA [CURSORPOS],Y
                INY
                CPX #$5C0
                BNE IL_NEXT_TILE
                
    INTRO_LOOP_DONE
                RTS
DISPLAY_INTRO
                .as
                ; disable layer 0
                LDA #0
                STA TL0_CONTROL_REG 
                
                ; load the intro music
                LDA #`VGM_INTRO_MUSIC
                STA CURRENT_POSITION + 2
                STA SONG_START + 2
                setal
                LDA #<>VGM_INTRO_MUSIC
                STA SONG_START
                setas
                JSR VGM_SET_SONG_POINTERS
                
                LDY #$A000 + COLUMNS_PER_LINE*43 + 26
                STY CURSORPOS
                LDA #$AF
                STA CURSORPOS + 2
                LDA #$70
                STA CURCOLOR
                
                LDY #<>INTRO_MSG
                STY MSG_ADDR
                JSR DISPLAY_MSG
                
                ; display the hardware designer message
                LDY #$A000 + COLUMNS_PER_LINE*45 + 20
                STY CURSORPOS
                LDA #$70
                STA CURCOLOR
                LDY #<>MACHINE_DESIGNER_MSG
                STY MSG_ADDR
                JSR DISPLAY_MSG
                
                ; display the software developer message
                LDY #$A000 + COLUMNS_PER_LINE*47 + 20
                STY CURSORPOS
                LDA #$70
                STA CURCOLOR
                LDY #<>SOFTWARE_DEV_MSG
                STY MSG_ADDR
                JSR DISPLAY_MSG
                
                LDA #0
                STA INTRO_SLIDE_CNT
                
                ; prepare to copy bytes from mem to video ram
                LDA #`TL_MAP_1_ADDR
                STA CURSORPOS + 2
                LDY #<>TL_MAP_1_ADDR
                STY CURSORPOS
                LDX #0
                LDY #0
        IT_LOOP
                LDA INTRO_TILESET,X
                STA [CURSORPOS],Y
                INX
                INY
                LDA #0
                STA [CURSORPOS],Y
                INY
                CPX #$800
                BNE IT_LOOP
                
                ; enable tile layer 1
                LDA #$1
                STA TL1_CONTROL_REG
                RTS
                
CLEAR_TILESET   
                .as
                ; clear the tileset - address is B5:0000 in Video RAM
                LDX #<>TL_MAP_0_ADDR
                STX CURSORPOS
                LDA #`TL_MAP_0_ADDR
                STA CURSORPOS + 2
                LDA #0
                LDY #0
        CLEAR_TS_LOOP
                STA [CURSORPOS],Y
                INY
                CPY #$1000  ; each tile is now 16-bits
                BNE CLEAR_TS_LOOP
                RTS

; *****************************************************************************
; *  Load the high scores from SD Card
; *  The file named "tetris.scr" must be present in the root sector.
; *****************************************************************************
LOAD_HI_SCORES
                .as
                
                LDA SDCARD_PRSNT_MNT
                BNE LHS_CARD_PRSNT
                JMP LHS_DONE
                
   LHS_CARD_PRSNT
                setal
                LDA #<>tetris_scr
                STA DOS_FD_PTR
                LDA #`tetris_scr
                STA DOS_FD_PTR + 2
                
                LDA #<>SCORE_PATH
                STA tetris_scr.PATH
                LDA #`SCORE_PATH
                STA tetris_scr.PATH + 2
                
                LDA #<>HI_SCORES
                STA DOS_DST_PTR
                LDA #`HI_SCORES
                STA DOS_DST_PTR + 2
                
                LDA #0
                STA tetris_scr.BUFFER
                LDA #$1F
                STA tetris_scr.BUFFER + 2
                setas
                
                LDA #2
                STA tetris_scr.DEV
                
                JSL F_LOAD
                BCS LHS_FILE_EXISTS  ; F_OPEN was a success
                
                BRA LHS_DONE
                
                
    LHS_FILE_EXISTS
                .as
                LDA DOS_STATUS
                BNE LHS_DONE
                
                ; print O to evid to signify the file was open
                LDA #'O'
                STA EVID_TEXT_MEM + 100 * 5
                LDA #$10
                STA EVID_COLOR_MEM + 100 * 5
                JSL F_CLOSE
                
                RTS
                
    LHS_FILE_CREATED
                .as
                LDA DOS_STATUS
                BEQ LHS_DONE
                
                ;now copy the cluster to current
                setal
                LDA tetris_scr.FIRST_CLUSTER
                STA tetris_scr.CLUSTER
                LDA tetris_scr.FIRST_CLUSTER + 2
                STA tetris_scr.CLUSTER + 2
                setas
                
                ; created the file
                LDA #'Y'
                STA EVID_TEXT_MEM + 100 * 6
                LDA #$10
                STA EVID_COLOR_MEM + 100 * 6
                RTS
                
    LHS_DONE
                .as
                LDA DOS_STATUS
                CLC
                ADC #$30
                STA EVID_TEXT_MEM + 100 * 14
                LDA #$10
                STA EVID_COLOR_MEM + 100 * 14
                RTS
                
                
; *****************************************************************************
; *  Save the high scores to SD Card
; *  The file "tetris.scr" will be saved in the root sector.
; *****************************************************************************
SAVE_HI_SCORES
                .as
                LDA SDCARD_PRSNT_MNT
                BEQ SHS_DONE
                
                setal
                LDA #<>tetris_scr
                STA DOS_FD_PTR
                
                LDA #<>SCORE_PATH
                STA tetris_scr.PATH
                
                LDA #100
                STA tetris_scr.SIZE
                LDA #0
                STA tetris_scr.SIZE + 2
                
                LDA #<>HI_SCORES
                STA tetris_scr.BUFFER
                LDA #`HI_SCORES
                STA tetris_scr.BUFFER + 2
                setas
                LDA #2
                STA tetris_scr.DEV
                
                LDA #`tetris_scr
                STA DOS_FD_PTR + 2
                LDA #`SCORE_PATH
                STA tetris_scr.PATH + 2
                
                JSL F_WRITE
    SHS_DONE
                RTS
                
; *****************************************************************************
; * Compare the player score with the 10 highest
; * If one is found to be lower, then insert a new line (drop the last line) 
; * and write the score there
; *****************************************************************************
CHECK_SCORE     
                .as
                LDA #0
                XBA
                LDA #0
                STA HISCORE_LINE
                STA HISCORE_OFFSET
                STA TEMP_LOCATION
                LDX #0

        C_S_LOOP
                LDA HI_SCORES+9,X
                CMP SCORE+2
                BLT C_S_INSERT_LINE
                BNE C_S_NEXT
                
                LDA HI_SCORES+8,X
                CMP SCORE+1
                BLT C_S_INSERT_LINE
                BNE C_S_NEXT
                
                LDA HI_SCORES+7,X
                CMP SCORE
                BLT C_S_INSERT_LINE
                
        C_S_NEXT
                INC HISCORE_LINE
                TXA
                CLC
                ADC #10
                STA TEMP_LOCATION
                TAX
                
                LDA HISCORE_LINE
                CMP #10
                BNE C_S_LOOP
                BRA C_S_DONE
                
    C_S_INSERT_LINE
                
                ; start moving byte starting from the end
                LDX #100-10
        C_S_INSERT_LINE_LOOP
                LDA HI_SCORES,X-1
                STA HI_SCORES+10,X-1
                DEX
                CPX TEMP_LOCATION
                BNE C_S_INSERT_LINE_LOOP
                
                ; copy _ in the first 6 characters,then 0, and then the player score
                LDA #0
                LDY #6
                XBA
                LDA TEMP_LOCATION
                TAX
                LDA #'_'
        CS_EMPTY_CHAR_LOOP
                STA HI_SCORES,X
                INX
                DEY
                BNE CS_EMPTY_CHAR_LOOP
                LDA #0
                STA HI_SCORES,X
                INX
                
                LDA SCORE
                STA HI_SCORES,X
                INX
                
                LDA SCORE+1
                STA HI_SCORES,X
                INX
                
                LDA SCORE+2
                STA HI_SCORES,X
    
        C_S_DONE
                RTS
                
                

.include "vgm_player.asm"
.include "vgm_effect.asm"
.include "SDOS.asm"

; *****************************************************************************
; * variables
; *****************************************************************************
HEX_VALUES      .text '0','1','2','3','4','5','6','7','8','9','A','B','C','D','E','F'
BONUS           .text 0,1,3,6,$10 ; these are BCD values
GAME_OVER_MSG   .text 'GAME OVER',0
SCORE_MSG       .text 'SCORE:',0
LEVEL_MSG       .text 'LEVEL:',0
BONUS_MSG       .text 'BONUS:  ',0
LINES_MSG       .text 'LINES:  ',0
NEXT_TILE_MSG   .text 'NEXT PIECE:',0
RESTART_MSG     .text 'Restart in ',0
INTRO_MSG       .text 'Welcome to C256 Tetris',0
MACHINE_DESIGNER_MSG .text 'Hardware Designer: Stefany Allaire',0
SOFTWARE_DEV_MSG     .text 'Software Developer: Daniel Tremblay',0
HI_SCORE_MSG    .text 'HI SCORES:',0
ENTER_USERNAME_MSG .text 'ENTER USER NAME:',0
RETURN_DONE_MSG .text 'Press <Enter> when done', 0
BKSP_MSG        .text 'Press <Bksp> to delete', 0
BYTE_CNTR       .word 0
SCORE_PATH      .text 'tetris.scr',0

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

HI_SCORES
    .text 'DAN   ',0
    .byte $86,$24,$00 ; little-endian
.rept 9
    .fill 6, $20   ; only 6 characters for the name, null terminated
    .fill 4, 0     ; BCD encoded score
.next
; reserve the next 412 byte for the buffer
     .fill 412, 0

; File Descriptor -- Used as parameter for higher level DOS functions
FILEDESC            .struct
STATUS              .byte ?             ; The status flags of the file descriptor (open, closed, error, EOF, etc.)
DEV                 .byte ?             ; The ID of the device holding the file
PATH                .dword ?            ; Pointer to a NULL terminated path string
CLUSTER             .dword ?            ; The current cluster of the file.
FIRST_CLUSTER       .dword ?            ; The ID of the first cluster in the file
BUFFER              .dword ?            ; Pointer to a cluster-sized buffer
SIZE                .dword ?            ; The size of the file
CREATE_DATE         .word ?             ; The creation date of the file
CREATE_TIME         .word ?             ; The creation time of the file
MODIFIED_DATE       .word ?             ; The modification date of the file
MODIFIED_TIME       .word ?             ; The modification time of the file
                    .ends

tetris_scr .dstruct FILEDESC

TILESET
.binary "tetris-tiles.data"
BACKGROUND_PAL
.binary "background.data.pal"
PALETTE
.binary "tetris-tiles.data.pal"
INTRO_TILESET
.binary "title-tiles.data"
FONTSET
.binary "tetris-font.bin"

VGM_EFFECT_DROP
VGM_EFFECT_ROTATE
.binary "tile-down.vgm"
VGM_EFFECT_LINE
.binary "bar.vgm"


.if TARGET_SYS == TARGET_FMX
    VGM_INTRO_MUSIC
        ;.binary "music/02 Strolling Player YM2151.vgm"
        .binary "music/01 Peddler YM2151.vgm"
    VGM_PLAY_MUSIC
        .binary "music/05 Troika YM2151.vgm"
    VGM_GAME_OVER_MUSIC
        .binary "music/04 Kalinka YM2151.vgm"
.elsif TARGET_SYS = TARGET_U
    VGM_INTRO_MUSIC
        .binary "music/06 Stage 2, 3 Boss, Stage 5 YMF262.vgm"
    ;* = $17bf26
    VGM_PLAY_MUSIC
        .binary "music/07 Stage 3 YM262.vgm"
    ;* = $18b8b8
    VGM_GAME_OVER_MUSIC
        .binary "music/07 Player's Turn YM262.vgm"
.fi


* = $1A0000
BACKGROUND
.binary "background.data"