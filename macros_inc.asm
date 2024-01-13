; ******************************************
; * display a string of text on screen
; * Param1: X position of first character
; * Param2: Y position of first character
; * Param3: color (fg/bg)
; * Param4: message pointer, #0 terminated
; ******************************************
display_text    .macro
                LDA #<(TEXT_START + COLUMNS_PER_LINE*\2 + \1)
                STA CURSORPOS
                LDA #>(TEXT_START + COLUMNS_PER_LINE*\2 + \1)
                STA CURSORPOS + 1
                LDA #\3
                STA CURCOLOR
                LDA #<\4
                STA MSG_ADDR
                LDA #>\4
                STA MSG_ADDR + 1
                JSR DISPLAY_MSG
                .endm
                
; **************************************
; * COPY DATA FROM RAM into LUT
; * Param1: source address
; * Param2: IO Page
; * Param3: destination address
; * Param4: length
; **************************************
copy_io_data    .macro
                lda #\2 ; Set the I/O page 
                sta MMU_IO_CTRL
                
                ; COPY the LUT to the IO Page 1 LUT0
                LDA #<\1
                STA SRC_PTR
                LDA #>\1
                STA SRC_PTR+1
                
                LDA #<\3
                STA DEST_PTR
                LDA #>\3
                STA DEST_PTR+1
                
                STZ MSG_ADDR
                STZ MSG_ADDR + 1
            
     cp_io_lp   LDA (SRC_PTR)
                STA (DEST_PTR)
                
                INC SRC_PTR
                BNE +
                INC SRC_PTR + 1
           +    INC DEST_PTR
                BNE +
                INC DEST_PTR + 1
                
           +    INC MSG_ADDR
                BNE +
                INC MSG_ADDR + 1
                
           +    LDY MSG_ADDR + 1
                CPY #>\4
                BNE +
                LDX MSG_ADDR
                CPX #<\4
                BEQ cp_io_end
           
           +    BRA cp_io_lp
    cp_io_end  
                .endm