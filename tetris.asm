; *************************************************************************
; * Attempt at a copy-cat game like Tetris
; * Author Daniel Tremblay
; * Code written for the C256 Foenix retro computer
; * Permission is granted to reuse this code to create your own games
; * for the C256 Foenix.
; * Copyright Daniel Tremblay 2020-2024
; * This code is provided without warranty.
; * Please attribute credits to Daniel Tremblay if you reuse.
; *************************************************************************
;.cpu "w65c02"
.include "macros_inc.asm"
.include "dma-macro.asm"
.include "dma_inc.asm"
.include "rtc_def.asm"
.include "interrupt_def.asm"
.include "timer_def.asm"
.include "math_def.asm"
.include "page0_inc.asm"
.include "tiny-vicky.asm"

.include "io_def.asm"

;* = $000500
;TODO:.include "keyboard_def.asm"

.include "base.asm"

* = $2000
.include "interrupt_handler.asm"

; ****************************************************
; *                CONSTANTS
; ****************************************************
TARGET_FMX         = 1
TARGET_U           = 2
TARGET_F256        = 3

COLUMNS_PER_LINE   = 80
ROW_PER_PAGE       = 60
INITIAL_GAME_SPEED = 40
BOARD_WIDTH        = 10
BOARD_HEIGHT       = 20

; ****************************************************
; *                RESERVED REGISTER AREA
; ****************************************************
TICK_COUNT      .byte 0
BOARDX          .byte 0
BOARDY          .byte 0
CURRENT_PIECE   .byte 0
NEXT_PIECE      .byte 0
PIECE_X         .word 5
PIECE_Y         .word 0
PIECE_ROT       .byte 0
PIECE_FIT       .byte 0
GAME_SPEED      .byte 0  ; how many ticks beteen bars falling
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

START_TILEMAP     = (TILEMAP + (40*5 + (40-(BOARD_WIDTH+4))/2 + 1)*2)
NEXT_PIECE_LOC    = (TILEMAP + (40*11 + 32)*2)
PIECE_VALUE       = $25  ; we're doing BCD additions

EFFECT_T_POSITION = $60 ; 4 bytes
EFFECT_T_WAIT_CNTR= $64 ; 2 bytes
EFFECT_L_POSITION = $66 ; 4 bytes
EFFECT_L_WAIT_CNTR= $6a ; 2 bytes
EFFECT_R_POSITION = $6c ; 4 bytes

MSG_ADDR          = $70
DEL_LINE_PTR      = $70
ROT_VAL           = $72
ROT_VAL2          = $73
LINE_CNTR         = $74
COPY_LINE_PTR     = $76
TOTAL_LINES       = $78 ; reserving 2 bytes
SRC_PTR           = $72
DEST_PTR          = $74

EFFECT_PLAY       = $7A ; 1 byte - 0 nothing, 1 tile down, 2 line, 4 rotate.
  TILE_EFFECT     = $1
  LINE_EFFECT     = $2
  ROTATE_EFFECT   = $4
EFFECT_R_WAIT_CNTR= $7B ; 2 bytes
BUTTON_PRESS      = $7D ; 1 byte
HISCORE_LINE      = $7E ; 1 byte
; $7F is used by the VGM player - leave it alone

GAME_OVER_TIMER   = $80 ; 1 byte
GAME_OVER_TICK    = $81 ; 1 byte
INTRO_SLIDE_CNT   = $82 ; 1 byte
JOYSTICK_POLL     = $83 ; 1 byte

; VGM Registers
SONG_START        = $84 ; 4 bytes
CURRENT_POSITION  = $88 ; 4 bytes
VGM_TEMP          = $8C ; 2 bytes
LOOP_OFFSET_REG   = $8E ; 2 bytes

PSG_BASE_ADDRESS  = $D608 ; address to the combined Left/Right address
OPL3_BASE_ADRESS  = $D580



; TEMPORARY MEMORY LOCATION
TEMP_LOCATION     = $90 ; 2 bytes
HISCORE_OFFSET    = $92 ; 1 byte

; ****************************************************
; *                GAME START
; ****************************************************
GAME_START      
                SEI
                LDA #0
                STA KEYBOARD_SC_FLG
                STA MOUSE_REG               ; disable the mouse pointer
                STA VKY_CURSOR_CTRL         ; disable the cursor
                STA EFFECT_PLAY
                STA HISCORE_OFFSET
                
                LDA #1
                STA LEVEL
                
                STZ MMU_IO_CTRL       ; enable vicky io
                STZ VKY_BRDR_CTRL     ; disable the border
                STZ VKY_TILEMAP0_CTRL ; disable tilemap 0
                STZ VKY_TILEMAP1_CTRL ; disable tilemap 1
                STZ VKY_TILEMAP2_CTRL ; disable tilemap 2
                STZ VKY_BM0_CTRL      ; disable bitmap 0
                STZ VKY_BM1_CTRL      ; disable bitmap 1
                STZ VKY_BM2_CTRL      ; disable bitmap 2
                
                ; write the RNG seed
                LDA RTC_SECS
                STA RND_SEEDL 
                LDA #5
                STA PIECE_X
                STZ RND_SEEDH
                LDA #RND_ENABLE + RND_SEED_LOAD
                STA RND_CTRL
                
                JSR LOAD_GAME_ASSETS
                ; read the hi-score list from disk
                ; JSR ISDOS_INIT
                ; JSR LOAD_HI_SCORES
                LDA #GS_INTRO
                STA GAME_STATE
                
                JSR VGM_INIT_TIMERS
                
                ; set the display mode to tiles
                LDA #VKY_Tile_Mode_En + VKY_Bitmap_Mode_En + VKY_Text_Mode_En + VKY_Graph_Mode_En + VKY_Text_Overlay
                STA VKY_MSTR_CTRL_0
                
                ; enable Random Number Generation
                LDA #RND_ENABLE
                STA RND_CTRL
                
    NEXT_GAME
                JSR CLR_SCREEN ; clears the text
                
                ; Enable SOF and TIMER0 and PS2 Keyboard
                LDA #~( INT0_VKY_SOF | INT0_TIMER_0 | INT0_TIMER_1 | INT0_PS2_KBD)
                STA INT_MASK_REG0
                ; Enable Joystick and F256K Keyboard
                LDA #~( INT1_VIA0 | INT1_VIA1 )
                STA INT_MASK_REG1
                
                LDA GAME_STATE
                CMP #GS_INTRO
                BNE SKIP_INTRO
                
                JSR DISPLAY_INTRO
                CLI
                BRA INFINITE_LOOP
                
        SKIP_INTRO
                SEI
            RANDOM_TRY_AGAIN
                LDA RND_L
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
          
; *******************************************************************          
; *  Clear the text display 
; *  Because this is in IO page, we can't use DMA.       
; *******************************************************************
CLR_SCREEN
                ; save the IO PAGE in the stack
                LDA MMU_IO_CTRL
                PHA
                
                ; Initialize the Text Pointer/Text Color Pointer
                STZ MSG_ADDR
                LDA #>COLOR_START
                STA MSG_ADDR + 1
                
                LDY #0
        -       LDX #0
        -       
                LDA #IO_PAGE3
                STA MMU_IO_CTRL
                
                LDA #0
                STA (MSG_ADDR)
                
                LDA #IO_PAGE2
                STA MMU_IO_CTRL
                
                LDA #$20
                STA (MSG_ADDR)
                INC MSG_ADDR
                BNE +  ; test if MSG_ADDR has rolled over
                INC MSG_ADDR + 1
       +        INX
                CPX #COLUMNS_PER_LINE
                BNE -
                INY
                CPY #ROW_PER_PAGE
                BNE --
                
                ; restore the IO Page
                PLA
                STA MMU_IO_CTRL
                RTS

; ****************************************************************215          
; *  Display Board Loop
; *  This code is called 60 times per second.
; *******************************************************************
DISPLAY_BOARD_LOOP
                ; TIMING
                LDA TICK_COUNT
                INC A
                STA TICK_COUNT
                CMP GAME_SPEED
                BNE TIMING_DONE
                
                LDA #0
                STA TICK_COUNT
                ; the piece is moving down one row
                LDA PIECE_Y
                INC A
                STA PIECE_Y
                
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
                ;JSR PLAY_EFFECT_TILE_DOWN
                JSR COPY_PIECE ; copy the piece into the board
                
                SED
                CLC
                LDA SCORE
                ADC #PIECE_VALUE
                STA SCORE
                BCC NG_CONTINUE
                
                LDA SCORE + 1
                ADC #0
                STA SCORE + 1
                BCC NG_CONTINUE
                
                LDA SCORE + 2
                ADC #0
                STA SCORE + 2
                BCC NG_CONTINUE
                
                LDA SCORE + 3
                ADC #0
                STA SCORE + 3

        NG_CONTINUE
                CLD
                
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
                JSR DRAW_BOARD ; we need to blank the board to redraw the piece
                JSR DRAW_PIECE
                JSR DRAW_HI_SCORES
                JSR DRAW_SCORE
                JSR DRAW_LEVEL
                JSR DRAW_LINES
                
				RTS
   
; ****************************************************************308          
; *  Randomly pick the next piece        
; *******************************************************************
PICK_NEXT_PIECE
                LDA NEXT_PIECE
                STA CURRENT_PIECE
                
    PN_TRY_AGAIN
                LDA RND_L
                AND #7
                STA NEXT_PIECE
                CMP #7
                BEQ PN_TRY_AGAIN
                RTS

; ****************************************************************337
; * Look for lines
; *******************************************************************
LOOK_FOR_LINES
                STZ ROT_VAL2 ; line count max 4
                STZ LINE_CNTR
                STZ LINE_CNTR + 1
    INIT_LINE_CHECK
                LDY #0
                STZ ROT_VAL  ; column count max 10
                
                ; calculate the position of the piece in the board
                LDA PIECE_Y
                DEC A
                STA MULU_A
                STZ MULU_A + 1
                LDA #BOARD_WIDTH
                STA MULU_B
                STZ MULU_B + 1
                ; store the result into CURSORPOS
                LDA MULU_RES
                STA ADDER_A
                LDA MULU_RES + 1
                STA ADDER_A + 1
                LDA #<BOARD
                STA ADDER_B
                LDA #>BOARD
                STA ADDER_B + 1
                LDA ADDER_RES
                STA CURSORPOS
                LDA ADDER_RES + 1
                STA CURSORPOS + 1
                
    CHK_NEXT_COL
                LDA (CURSORPOS),Y
                BEQ CHK_NEXT_LINE
                INC ROT_VAL
                INY
                CPY #BOARD_WIDTH
                BNE CHK_NEXT_COL
                
                LDA ROT_VAL
                CMP #BOARD_WIDTH
                BEQ LINE_FOUND  ; if the count is 14 then we have a full line
                
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
              
    ; when a line is found, we're going to replace the tiles with "checkered tiles"
	LINE_FOUND
				BRA CHK_NEXT_LINE

; ****************************************************************416
; * Get Piece Value - TODO: rename to GET_TILE_VALUE
; * X must contain the piece value multiplied by 16 plus an offset.
; *   For example, the 4th offset of piece 5 would have X=$54
; * This is really way too complicated.  Store the rotations in memory
; *  and retrieve them.
; *******************************************************************     
GET_PIECE_VALUE

                LDA PIECE_ROT
                BNE ROT_NEXT
                
                ; if rotation is 0, return one of the following
                ; 0,1,2,3, 4,5,6,7, 8,9,10,11, 12,13,14,15
                LDA PIECE0,X  ; ROTATION 0
                RTS
    ROT_NEXT
                CMP #1
                BNE ROT_2
                
                ; if rotation is 1, return on of the following
                ; 12,8,4,0, 13,9,5,1, 14,10,6,2, 15,11,7,3
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
                PLA
                ; LDA 1,S
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
                
                ; if rotation is 2, return on of the following
                ; 15,14,13,12, 11,10,9,8, 7,6,5,4, 3,2,1,0
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
                
                ;PLX
                RTS
                
    ROT_3       
                ; if rotation is 2, return on of the following
                ; 15,14,13,12, 11,10,9,8, 7,6,5,4, 3,2,1,0
                PHX
                TXA
                AND #$F0
                STA ROT_VAL2
                TXA
                AND #$C
                LSR A
                LSR A
                STA ROT_VAL
                
                PLA
                ;LDA 1,S
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
                ;PLX
                RTS
                
; **************************************************************************512
; * Handle Joystick Movements
; * Remember that the joystick at rest returns $9F.
; * Poll the joystick 10 times a second.
; *****************************************************************************
HANDLE_JOYSTICK
                RTS
                
; **************************************************************************569
; * User Pressed Left Arrow
; *****************************************************************************
MOVE_PIECE_LEFT
				RTS

; **************************************************************************595
; * User Pressed Right Arrow
; *****************************************************************************
MOVE_PIECE_RIGHT
				RTS

; **************************************************************************621
; * User Pressed Down Arrow
; *****************************************************************************
MOVE_PIECE_DOWN
				RTS

; **************************************************************************647
; * User Pressed Space Bar
; *****************************************************************************
ROTATE_PIECE
				RTS

; **************************************************************************695
; * Lock a piece into place in the board
; *****************************************************************************
COPY_PIECE      
                LDA CURRENT_PIECE
                ASL A
                ASL A
                ASL A
                ASL A
                TAX
                
                LDA PIECE_Y
                DEC A
                STA MULU_A
                STZ MULU_A+1
                LDA #BOARD_WIDTH
                STA MULU_B
                STZ MULU_B+1
                ; ignore the second byte of the multiplication
                CLC
                LDA MULU_RES
                ADC PIECE_X
                TAY
                
    NEXT_COPY
                JSR GET_PIECE_VALUE
                CMP #0
                BEQ SKIP_COPY
                
                ; is the board occupied for this byte
                PHX
                PHY ; TYX
                PLX
                STA BOARD,X
                PLX
                
        SKIP_COPY
                INX
                INY
                TXA
                AND #3
                BNE NEXT_COPY
                
                TYA
                CLC
                ADC #BOARD_WIDTH
                TAY
                
                TXA
                AND #$F
                BNE NEXT_COPY
                
                RTS

; **************************************************************************753
; * This is the tougher function.  Used to detect collisions.
; *****************************************************************************
DOES_PIECE_FIT
                LDA CURRENT_PIECE
                ASL A
                ASL A
                ASL A
                ASL A
                TAX
                
                ; multiply the Py*BoardWidth+Px Max value is 200
                LDA PIECE_Y
                STA MULU_A
                STZ MULU_A+1
                LDA #BOARD_WIDTH
                STA MULU_B
                STZ MULU_B+1
                
                CLC
                LDA MULU_RES
                ADC PIECE_X
                TAY
                
    NEXT_COLLISION
                JSR GET_PIECE_VALUE
                CMP #0   ; skip the empty tiles
                BEQ SKIP_BYTE
                
                ; is the board occupied for this byte
                PHX
                PHY ; TYX
                PLX
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
                
                TYA
                CLC
                ADC #BOARD_WIDTH
                TAY
                
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

; **************************************************************************819
; draw the board to the tilemap
; *****************************************************************************
DRAW_BOARD
                LDA #<START_TILEMAP
                STA CURSORPOS
                LDA #>START_TILEMAP
                STA CURSORPOS + 1
                
                STZ CURCOLOR  ; use this pointer to count the number of rows
     DB_INNER   LDX #0
                LDY #0
                
                LDA #1
                STA (CURSORPOS),Y ; the tile
                INY
                INY
                LDA #1
                STA (CURSORPOS),Y ; the tile
                INY
                INY
                
          -     LDA BOARD,X
                STA (CURSORPOS),Y ; the tile
                INX
                INY
                INY
                CPX #BOARD_WIDTH
                BNE - 
                
                LDA #1
                STA (CURSORPOS),Y ; the tile
                INY
                INY
                LDA #1
                STA (CURSORPOS),Y ; the tile
                INY
                INY
                INC CURCOLOR ; increment the row count
                
                ; calculate the offset to the next row of tiles
                CLC
                LDA CURSORPOS
                ADC #40*2
                STA CURSORPOS
                BCC +
                INC CURSORPOS + 1
                
         +      LDX CURCOLOR
                CPX #BOARD_HEIGHT
                BNE DB_INNER
                
                ; now draw the two bottom row(s)
                LDY #0
         -      LDA #1
                STA (CURSORPOS),Y
                INY
                INY
                CPY #(BOARD_WIDTH + 4) * 2
                BNE -
                
                RTS

; **************************************************************************871
; * Draw the piece in the tilemap
; *****************************************************************************
DRAW_PIECE
                LDA CURRENT_PIECE
                ASL A
                ASL A
                ASL A
                ASL A
                TAX
                
                ; Put the StartTilemap + Py*40*2 into cursorpos
                LDA PIECE_Y
                STA MULU_A
                STZ MULU_A + 1
                LDA #40*2
                STA MULU_B
                STZ MULU_B + 1
                
                LDA MULU_RES
                STA ADDER_A
                LDA MULU_RES+1
                STA ADDER_A + 1
                LDA #<START_TILEMAP
                STA ADDER_B
                LDA #>START_TILEMAP
                STA ADDER_B+1
                
                LDA ADDER_RES
                STA CURSORPOS
                LDA ADDER_RES+1
                STA CURSORPOS+1
                
    CP_NEXT_ROW ; Put the Px * 2 into Y
                LDA PIECE_X
                ASL A
                TAY 
                
    DP_NEXT_PIECE_SYMBOL
                JSR GET_PIECE_VALUE
                CMP #0
                BEQ SKIP_DRAW
                
                STA (CURSORPOS),Y
                
        SKIP_DRAW
                INX
                INY
                LDA #0
                STA (CURSORPOS),Y
                INY
                ; we have to copy 4 tiles per row
                TXA
                AND #3
                BNE DP_NEXT_PIECE_SYMBOL
                
                ; draw into the next row
                CLC
                LDA CURSORPOS
                ADC #40*2
                STA CURSORPOS
                BCC +
                INC CURSORPOS+1
                
                
         +      TXA
                AND #$F
                BNE CP_NEXT_ROW
                
                RTS
                
; ************************************************************932
; * Draw Next Piece to the right of the tilemap.
; * Since the tiles are 8x8, we could probably replace
; * with sprites, but this would use more memory.
; ***************************************************************
DRAW_NEXT_PIECE
                display_text 56, 19, $20, NEXT_TILE_MSG
                
                LDA #<NEXT_PIECE_LOC
                STA CURSORPOS
                LDA #>NEXT_PIECE_LOC
                STA CURSORPOS + 1
                
                LDA NEXT_PIECE ; each piece is 16 bytes
                ASL A
                ASL A
                ASL A
                ASL A
                TAX
    DNP_SYMBOL_NEXT_LINE
                LDY #0
        DNP_SYMBOL
                LDA PIECE0,X
                CMP #0
                BEQ DNP_DRAW_BLANK
                
        DNP_DRAW_BLANK
                STA (CURSORPOS),Y
                
                INX
                INY
                LDA #0
                STA (CURSORPOS),Y
                INY
                TXA
                AND #3
                BNE DNP_SYMBOL
                
                LDA CURSORPOS
                CLC
                ADC #40 * 2
                STA CURSORPOS
                BCC +
                INC CURSORPOS + 1
                
        +       TXA
                AND #$F

                BNE DNP_SYMBOL_NEXT_LINE
                
                RTS
      
; *************************************************************************992
; * Draw Score      
; ****************************************************************************
DRAW_SCORE
                display_text 56,5,$20,SCORE_MSG
                CLC
                LDA CURSORPOS
                ADC #8
                STA CURSORPOS
                LDA SCORE + 2
                JSR DISPLAY_HEX
                LDA SCORE + 1
                JSR DISPLAY_HEX
                LDA SCORE
                JSR DISPLAY_HEX
                RTS
                
; ************************************************************************1015
; * Draw High Scores     
; ****************************************************************************
DRAW_HI_SCORES
                display_text 3,5,$20,HI_SCORE_MSG
                
                ; prepare to write the high scores
                LDA #<(TEXT_START + COLUMNS_PER_LINE*6 + 3)
                STA CURSORPOS
                LDA #>(TEXT_START + COLUMNS_PER_LINE*6 + 3)
                STA CURSORPOS + 1
                
                LDA #<HI_SCORES
                STA MSG_ADDR
                LDA #>HI_SCORES
                STA MSG_ADDR+1
                
                LDX #0
                LDA #$40
                STA CURCOLOR
                
    DHS_NEXT_SCORE
                JSR DISPLAY_MSG
                
                ; display the score
                CLC
                LDA CURSORPOS
                ADC #7
                STA CURSORPOS
                LDA HI_SCORES + 9,X
                JSR DISPLAY_HEX
                LDA HI_SCORES + 8,X
                JSR DISPLAY_HEX
                LDA HI_SCORES + 7,X
                JSR DISPLAY_HEX
                
                ; increment the score reader to the next line
                TXA
                CLC
                ADC #10
                TAX
                
                ; place the start of the message to the next player's name
                CLC
                LDA MSG_ADDR
                ADC #10
                STA MSG_ADDR
                
                ; calculate the position to write to
                LDA CURSORPOS
                CLC
                ADC #COLUMNS_PER_LINE - 13 ; name is 6+1 and score is 3 * 2 chars = 13
                STA CURSORPOS
                BCC +
                INC CURSORPOS + 1
                
         +      ; if the score is not zero, then display the name and score
                LDA HI_SCORES + 7,X
                BNE DHS_NEXT_SCORE
                LDA HI_SCORES + 8,X
                BNE DHS_NEXT_SCORE
                LDA HI_SCORES + 9,X
                BNE DHS_NEXT_SCORE

                RTS
                
; ************************************************************************1076
; * Draw Level  
; ****************************************************************************
DRAW_LEVEL
                display_text 56,7,$20,LEVEL_MSG
                
                ; right align the level with the score above
                CLC
                LDA CURSORPOS
                ADC #12
                STA CURSORPOS
                LDA LEVEL
                JSR DISPLAY_HEX
                RTS
                
                
; ************************************************************************1098
; * Draw Lines  
; ****************************************************************************
DRAW_LINES
                display_text 56,13, $20, LINES_MSG
                
                ; right align the level with the score above
                CLC
                LDA CURSORPOS
                ADC #10
                STA CURSORPOS

                LDA TOTAL_LINES+1
                JSR DISPLAY_HEX
                LDA TOTAL_LINES
                JSR DISPLAY_HEX
                RTS
                
; *************************************************************************1219
; * Display a text message
; * The message pointer is in MSG_ADDR and must be zero terminated.
; * The position on screen is stored in CURSORPOS.
; * The color of the text is stored in CURCOLOR.
; *****************************************************************************
DISPLAY_MSG
                ; save the IO PAGE in the stack
                LDA MMU_IO_CTRL
                PHA
                LDY #0
          -
                ; copy the character
                LDA #IO_PAGE2
                STA MMU_IO_CTRL
                LDA (MSG_ADDR),Y
                BEQ MSG_DONE
                
                STA (CURSORPOS),Y
                ; change the color
                LDA #IO_PAGE3
                STA MMU_IO_CTRL
                LDA CURCOLOR
                STA (CURSORPOS),Y
                
                INY
                CPY #64
                BNE -
                
    MSG_DONE    
                ; restore the IO Page
                PLA
                STA MMU_IO_CTRL
                RTS
            
; *************************************************************************1245
; * Game Over screen
; *****************************************************************************
GAME_OVER
				RTS
                
; *************************************************************************1386
; * Display Hex value at CURSORPOS, with color CURCOLOR
; * Value to display is in A
; *****************************************************************************  
DISPLAY_HEX
                PHX
                ;push IO Page
                LDX MMU_IO_CTRL
                PHX
                
                PHA
                
                
                AND #$F0
                LSR A
                LSR A
                LSR A
                LSR A
                CLC
                ADC #'0'
                
                LDX #IO_PAGE2
                STX MMU_IO_CTRL
                STA (CURSORPOS)
                
                ; write the two color bytes now
                LDX #IO_PAGE3
                STX MMU_IO_CTRL
                LDA CURCOLOR
                STA (CURSORPOS)
                INC CURSORPOS
                STA (CURSORPOS)
                
                PLA
                AND #$F
                CLC
                ADC #'0'
                
                LDX #IO_PAGE2
                STX MMU_IO_CTRL
                STA (CURSORPOS)
                INC CURSORPOS
                
                ; restore MMU IO PAGE
                PLA
                STA MMU_IO_CTRL
                
                PLX
                RTS
    
; *************************************************************************1498
; * Load Game Assets in memory
; * We're using two tilemaps: 0 is the game board, 1 is the intro "C256 Foenix"
; * the tileset is the same for both tilemaps.
; * Set the tilemaps, tilesets and bitmap addresses.
; * The tiles use LUT0.
; * The bitmap uses LUT1.
; *****************************************************************************
LOAD_GAME_ASSETS
                ; save the IO Page
                LDA MMU_IO_CTRL
                PHA
                
                ; set IO Page 0
                STZ MMU_IO_CTRL
                ; disable all graphics
                LDA #0
                STA VKY_MSTR_CTRL_0
                
                copy_io_data PALETTE, 1, $D000, $400
                copy_io_data BACKGROUND_PAL, 1, $D400, $400
                copy_io_data FONTSET, 1, $C000, $800
                
                STZ MMU_IO_CTRL
                
                LDA #<TILESET
                STA VKY_TILESET0_ADDR
                LDA #>TILESET
                STA VKY_TILESET0_ADDR + 1
                LDA #`TILESET
                STA VKY_TILESET0_ADDR + 2
                ; enable tileset with 128 stride
                LDA #VKY_TILESET_SQ
                STA VKY_TILESET0_CTRL
                
                LDA #<BACKGROUND
                STA VKY_BM1_ADDR_L
                LDA #>BACKGROUND
                STA VKY_BM1_ADDR_L + 1
                LDA #`BACKGROUND
                STA VKY_BM1_ADDR_L + 2
                ; enable bitmap 1 with LUT1
                LDA #VKY_BITMAP_EN + VKY_BITMAP_LUT1
                STA VKY_BM1_CTRL
                
                ; disable bitmap 0
                STZ VKY_BM0_CTRL
                
                ; disable all tilemaps
                STZ VKY_TILEMAP0_CTRL
                STZ VKY_TILEMAP1_CTRL
                STZ VKY_TILEMAP2_CTRL
                ; set the tilemap sizes
                LDA #40
                STA VKY_TILEMAP0_WIDTH
                LDA #30
                STA VKY_TILEMAP0_HEIGHT
                
                LDA #64
                STA VKY_TILEMAP1_WIDTH
                LDA #30
                STA VKY_TILEMAP1_HEIGHT
                STZ VKY_TILEMAP0_SCR_X
                STZ VKY_TILEMAP0_SCR_Y
                STZ VKY_TILEMAP1_SCR_X
                STZ VKY_TILEMAP1_SCR_Y
                
                ; set the tilemap 0 address
                LDA #<TILEMAP
                STA VKY_TILEMAP0_AD
                LDA #>TILEMAP
                STA VKY_TILEMAP0_AD + 1
                LDA #`TILEMAP
                STA VKY_TILEMAP0_AD + 2
                
                ; set the tilemap 1 address
                LDA #<INTRO_TILEMAP
                STA VKY_TILEMAP1_AD
                LDA #>INTRO_TILEMAP
                STA VKY_TILEMAP1_AD + 1
                LDA #`INTRO_TILEMAP
                STA VKY_TILEMAP1_AD + 2
                
                ; assign bitmap1 to LAYER2
                LDA #VK_LYR_BMP1
                STA VKY_LAYER_CTRL1
                ; assign tilemap0 to layer0
                ; assign tilemap1 to layer1
                LDA #VK_LYR_TLM0 + (VK_LYR_TLM1<<4)
                STA VKY_LAYER_CTRL0
                
                ; restore the IO page
                PLA
                STA MMU_IO_CTRL
                
                RTS

; *************************************************************************1609
; * INIT GAME
; *****************************************************************************
INIT_GAME
                LDA #INITIAL_GAME_SPEED
                STA GAME_SPEED
                LDA #0
                STA PIECE_Y
                STA PIECE_FIT
                STA TICK_COUNT
                STA SCORE
                STA SCORE + 1
                STA SCORE + 2
                STA TOTAL_LINES
                STA TOTAL_LINES + 1
                
                LDA #1
                STA LEVEL
                
                ; clear board and tilemap
                dma_fill 0, BOARD, BOARD_WIDTH*BOARD_HEIGHT + 40*30*2
                
                ; enable the board tiles
                LDA #VKY_TILEMAP_EN | VKY_TILEMAP_8
                STA VKY_TILEMAP0_CTRL
                ; disable the intro tiles
                STZ VKY_TILEMAP1_CTRL
                
                ; load the play music - switch slot 2 to point the the song start
                LDA #ACT_EDIT + ACT_ED_L0
                STA MMU_MEM_CTRL
                
                LDA #(VGM_PLAY_MUSIC / $2000)
                STA SONG_START + 2
                STA 8+2
                LDA #0
                STA MMU_MEM_CTRL
                
                LDA #<VGM_PLAY_MUSIC
                STA SONG_START
                LDA #>VGM_PLAY_MUSIC
                STA SONG_START + 1

                JSR VGM_SET_SONG_POINTERS
                
                ; set the display mode to tiles
                LDA #VKY_Tile_Mode_En + VKY_Bitmap_Mode_En + VKY_Text_Mode_En + VKY_Graph_Mode_En + VKY_Text_Overlay
                STA VKY_MSTR_CTRL_0
                
                RTS

; *************************************************************************1667
; * INTRO LOOP
; * This routine makes the colors rotate in the intro screen, 
; * just by cycling the tiles.
; *****************************************************************************
INTRO_LOOP
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
                
                ; switch slot 2 ($4000) to point to the VMG area
                ; switch slot 5 ($A000) to point to the tiles area $1_0000 (slot 8)
                LDA #ACT_EDIT + ACT_ED_L0
                STA MMU_MEM_CTRL
                LDA #(VGM_INTRO_MUSIC / $2000)
                STA 8+2
                LDA #($1_0000 / $2000)
                STA 8+5
                LDA #0
                STA MMU_MEM_CTRL
                
                ; prepare to copy bytes from mem to video ram
                LDA #<SLOT5 + (INTRO_TILEMAP - TILESET)
                STA CURSORPOS
                LDA #>SLOT5 + (INTRO_TILEMAP - TILESET)
                STA CURSORPOS + 1
                
                LDY #0
        IL_NEXT_ROW
                LDX #0
        IL_NEXT_TILE
                LDA (CURSORPOS)
                BEQ IT_SKIP
                INC A
                CMP #9
                BNE IT_GOOD
                
                LDA #2
            IT_GOOD
                STA (CURSORPOS)
                
            IT_SKIP
                CLC
                LDA CURSORPOS
                ADC #2
                STA CURSORPOS
                BCC +
                INC CURSORPOS + 1
            +   INX
                CPX #64
                BNE IL_NEXT_TILE
                INY
                CPY #23 ; we don't want to clear the bottom panel
                BNE IL_NEXT_ROW
                
    INTRO_LOOP_DONE
                RTS
                
; 1710*****************************************************************************
; * DISPLAY INTRO SCREEN
; *****************************************************************************          
DISPLAY_INTRO
                ; disable layer 0
                LDA #0
                STA VKY_TILEMAP0_CTRL 
                
                ; set slot 2 to the start of the INTRO MUSIC
                LDA #ACT_EDIT + ACT_ED_L0
                STA MMU_MEM_CTRL
                
                LDA #(VGM_INTRO_MUSIC / $2000)
                STA SONG_START + 2
                STA 8+2
                
                LDA #0
                STA MMU_MEM_CTRL
                
                ; load the intro music - slot 2 should be set to the hi-byte
                LDA #<VGM_INTRO_MUSIC
                STA SONG_START
                LDA #>VGM_INTRO_MUSIC
                STA SONG_START + 1
                JSR VGM_SET_SONG_POINTERS
                
                display_text 29, 47, $70, INTRO_MSG
                display_text 23, 49, $70, MACHINE_DESIGNER_MSG
                display_text 23, 51, $70, SOFTWARE_DEV_MSG
                
                LDA #0
                STA INTRO_SLIDE_CNT
                
                ; enable tile layer 1
                LDA #VKY_TILEMAP_EN | VKY_TILEMAP_8
                STA VKY_TILEMAP1_CTRL
                RTS
                
.include "vgm_player.asm"
                
; *****************************************************************************
; * variables
; *****************************************************************************
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
    .byte 0,0,3,0
    .byte 0,0,3,0
    .byte 0,0,3,0
    .byte 0,0,3,0

PIECE1
    .byte 0,4,4,0
    .byte 0,4,4,0
    .byte 0,0,0,0
    .byte 0,0,0,0

PIECE2
    .byte 0,5,0,0
    .byte 0,5,0,0
    .byte 0,5,5,0
    .byte 0,0,0,0

PIECE3
    .byte 0,0,6,0
    .byte 0,0,6,0
    .byte 0,6,6,0
    .byte 0,0,0,0

PIECE4
    .byte 0,0,7,0
    .byte 0,7,7,0
    .byte 0,0,7,0
    .byte 0,0,0,0

PIECE5
    .byte 0,0,8,0
    .byte 0,8,8,0
    .byte 0,8,0,0
    .byte 0,0,0,0

PIECE6
    .byte 0,2,0,0
    .byte 0,2,2,0
    .byte 0,0,2,0
    .byte 0,0,0,0

BOARD
    .fill BOARD_HEIGHT*BOARD_WIDTH, 0

TILEMAP
    .fill 40*30*2, 0  ; the board is 40 x 30 - each tile is 2 bytes
      
HI_SCORES
    .text 'DAN   ',0
    .byte $86,$24,$00 ; little-endian
    .text 'TINTIN',0
    .byte $35,$22,$00 ; little-endian
    .text 'MILOU ',0
    .byte $75,$21,$00 ; little-endian
.rept 7
    .fill 6, $20   ; only 6 characters for the name, null terminated
    .fill 4, 0     ; BCD encoded score
.next
; reserve the next 412 byte for the SD card buffer
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

; these assets need to be copied by the CPU into IO Pages
* = $4000
BACKGROUND_PAL
.binary "assets/background-320x240.pal"
PALETTE
.binary "assets/tetris-tiles-small.pal"
FONTSET
.binary "assets/tetris-font.bin"

; these assets can be reach by Tiny Vicky without paging.
* = $1_0000
TILESET
.binary "assets/tetris-tiles-small.bin"
INTRO_TILEMAP
.binary "assets/title-tiles.tlm"
BACKGROUND
.binary "assets/background-320x240.bin"

; these are the music assets
VGM_INTRO_MUSIC
    .binary "music/06 Stage 2, 3 Boss, Stage 5 YMF262.vgm"
VGM_PLAY_MUSIC
    .binary "music/07 Stage 3 YM262.vgm"
VGM_GAME_OVER_MUSIC
;    .binary "music/07 Player's Turn YM262.vgm"
VGM_EFFECT_DROP
VGM_EFFECT_ROTATE
;.binary "tile-down.vgm"
VGM_EFFECT_LINE
;.binary "bar.vgm"