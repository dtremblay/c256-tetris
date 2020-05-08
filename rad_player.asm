EFFECT_NONE              = $00
EFFECT_NOTE_SLIDE_UP     = $01
EFFECT_NOTE_SLIDE_DOWN   = $02
EFFECT_NOTE_SLIDE_TO     = $03
EFFECT_NOTE_SLIDE_VOLUME = $05
EFFECT_VOLUME_SLIDE      = $0A
EFFECT_SET_VOLUME        = $0C
EFFECT_PATTERN_BREAK     = $0D
EFFECT_SET_SPEED         = $0F

FNUMBER_MIN = $0156
FNUMBER_MAX = $02AE

FIFTY_HZ_COUNT   = 286360
SLOW_TIMER       = 786703
INSTR_REC_LEN    = 12

SongData .struct
version             .byte $00 ; bit 1 is RAD 1, bit 2 is RAD 2
songLength          .byte $00
InitialSpeed        .byte $06
hasSlowTimer        .byte $00 ;BOOL $00 = False, $01 = True
.ends

; special characters for notes
                    ;     C    C#   D    D#   E    F    F#   G    G#   A    A#   B    
note_array          .byte $43, $90, $44, $91, $45, $46, $92, $47, $93, $41, $94, $42, $43
TuneInfo .dstruct SongData

; ************************************************************************************************
; * We are assuming that the RAD File is already Loaded Somewhere
; * RAD_FILE_TEMP points to the RAD v1 file in memory
; ************************************************************************************************
RAD_INIT_PLAYER
            .as
            LDA #0
            STA RAD_ORDER_NUM
            STA RAD_ORDER_NUM + 1
            STA LINE_NUM_HEX
            
            STA @lMUSIC_TICK
            
            STA PATTERN_NUM
            
            LDA #`INSTRUMENT_LIBRARY
            STA INSTR_ADDR+2
                
            JSL OPL2_INIT   ; Init OPL2
            JSR RAD_ALL_NOTES_OFF
            
            ; get the version of the file
            LDY #$0010
            LDA [OPL2_ADDY_PTR_LO],Y
            CMP #$10 ; BCD version 1.0 or 2.1
            BNE RI_LOAD_VERSION_21
            JSL READ_VERSION_10
            BRA RI_DONE

    RI_LOAD_VERSION_21
            CMP #$21
            BNE RI_INVALID
            JSL READ_VERSION_21
            
    RI_DONE
            LDX RAD_ORDER_NUM
            LDA @lORDERS,X  ; load the first pattern in the order list
            INC A
    RI_INVALID
            RTL  ; End of RAD_INIT_PLAYER

; ************************************************************************************************
; Read a RAD file version 2.1
; ************************************************************************************************
READ_VERSION_21
            .as
            ;not implemented
            LDA #2
            STA @lTuneInfo.version
            JSR READ_TIMER
            JSR PARSER_RAD_FILE_INSTRUMENT_21; Parse the Instrument
            
            RTL  ; End of READ_VERSION_21

; ************************************************************************************************
; The timer setting is at offset $11 for both 1.0 and 2.1 RAD Formats
; ************************************************************************************************
READ_TIMER
            .as
            LDY #$11
            LDA [OPL2_ADDY_PTR_LO],Y
            BIT #$40
            BEQ RT_NOT_SLOW
            
            LDA #1
            STA @lTuneInfo.hasSlowTimer
            
            LDA #<SLOW_TIMER
            STA TIMER0_CMP_L
            
            LDA #>SLOW_TIMER
            STA TIMER0_CMP_M
            
            LDA #<`SLOW_TIMER
            STA TIMER0_CMP_H
            BRA SET_TIMER

    RT_NOT_SLOW
            BIT #$20
            BEQ RT_NOT_BPM
            
            INY
            setal
            LDA [OPL2_ADDY_PTR_LO],Y
            setas
            INY
            BRA SET_TIMER
            
    RT_NOT_BPM
            LDA #0
            STA @lTuneInfo.hasSlowTimer
    
            LDA #<FIFTY_HZ_COUNT
            STA TIMER0_CMP_L
            
            LDA #>FIFTY_HZ_COUNT
            STA TIMER0_CMP_M
            
            LDA #<`FIFTY_HZ_COUNT
            STA TIMER0_CMP_H
    SET_TIMER
            JSR INIT_TIMER0
            RTS

; *************************************************************************
; * Initialize the timer for 50Hz
; *************************************************************************
INIT_TIMER0
            .as
            PHB
            
            LDA #0
            PHA
            PLB ; set databank to 0
            
            setas
            LDA #0    ; set timer0 charge to 0
            STA TIMER0_CHARGE_L
            STA TIMER0_CHARGE_M
            STA TIMER0_CHARGE_H
            
            LDA #TMR0_CMP_RECLR  ; count up from "CHARGE" value to TIMER_CMP
            STA TIMER0_CMP_REG
            
            LDA #(TMR0_EN | TMR0_UPDWN | TMR0_SCLR)
            STA TIMER0_CTRL_REG
            
            PLB
            RTS

; ************************************************************************************************
; Read a RAD file version 1.1
; ************************************************************************************************
READ_VERSION_10
            .as
            LDA #1
            STA @lTuneInfo.version
            
            JSR PARSER_RAD_FILE_INSTRUMENT_10; Parse the Instrument
            JSR PROCESS_ORDER_LIST_10 ; Parse the Order List
            JSR READ_PATTERNS_10
            
            JSR READ_TIMER
            RTL  ; End of READ_VERSION_10

ADLIB_OFFSETS .byte 7,1,8,2,9,3,10,4,5,11,6

; ************************************************************************************************
; Read the instrument table. 
; RAD V1.0 Format
; ************************************************************************************************
PARSER_RAD_FILE_INSTRUMENT_10
            .as
            INY ; $11 bit 7: description, bit6: slow timer, bits4..0: speed
            
            LDA [OPL2_ADDY_PTR_LO],Y
            ;Will Ignore the has slowSlowTimer for now
            AND #$1F
            STA @lTuneInfo.InitialSpeed
            LDA [OPL2_ADDY_PTR_LO],Y
            AND #$80
            BEQ READ_INSTR_DATA
    Not_Done_With_Description
            INY ; Move the Pointer Forward
            LDA [OPL2_ADDY_PTR_LO],Y
            CMP #$00  ; Check for the End of Text
            BNE Not_Done_With_Description

    READ_INSTR_DATA
            INY ; This points after either After Description or next to Offset 0x11
            
            ; Let's Init the Address Point for the instrument Tables
            LDA #<`INSTRUMENT_LIBRARY
            STA RAD_ADDR + 2
            
            ; Let's Read Some Instruments HERE
    ProcessNextInstruments_10
            setas
            LDA [OPL2_ADDY_PTR_LO],Y  ; Read Instrument Number
            BEQ DoneProcessingInstrument_10
            
            setal
            ; find the address of the instrument by multiplying by the record length
            DEC A
            STA @lUNSIGNED_MULT_A
            LDA #INSTR_REC_LEN
            STA @lUNSIGNED_MULT_B
            LDA @lUNSIGNED_MULT_RESULT  ; not sure why this one requires a long address - bank is still 0
            
            CLC
            ADC #<>INSTRUMENT_LIBRARY
            STA RAD_ADDR
            LDA #0
            setas
            
            INY
            STZ RAD_TEMP
            STA [RAD_ADDR]  ; Not a drum instrument
            
    Transfer_Instrument_Info
            LDX RAD_TEMP
            LDA ADLIB_OFFSETS,X  ; RAD uses a different order for registers
            TAX
            
            LDA [OPL2_ADDY_PTR_LO],Y  ; Read Register
            PHY
            TXY
            STA [RAD_ADDR],Y  ; Write to the instrument table 
            PLY
            INY
            INC RAD_TEMP
            LDA RAD_TEMP
            CMP #11
            BCC Transfer_Instrument_Info
            
            BRA ProcessNextInstruments_10
            
    DoneProcessingInstrument_10
            INY
            RTS

; ************************************************************************************************
; Read the instrument table. 
; RAD V2.1 Format
; ************************************************************************************************
PARSER_RAD_FILE_INSTRUMENT_21
    PR_LOOP
            ; skip the description
            LDA [OPL2_ADDY_PTR_LO],Y
            INY
            CMP #0
            BNE PR_LOOP
            
            ; Let's Init the Address Point for the instrument Tables
            LDA #<`INSTRUMENT_LIBRARY
            STA RAD_ADDR + 2
            
            ; Let's Read Some Instruments HERE
    ProcessNextInstruments_21
            setas
            LDA [OPL2_ADDY_PTR_LO],Y  ; Read Instrument Number
            BEQ DoneProcessingInstrument_21
            
            ; TODO _ CONTINUE HERE
            
    DoneProcessingInstrument_21
            INY
            RTS

; ************************************************************************************************
; * Read the orders list
; ************************************************************************************************
PROCESS_ORDER_LIST_10
            .as
            LDA [OPL2_ADDY_PTR_LO],Y  ; Read Song Length
            STA @lTuneInfo.songLength
            TAX
            INY
            
            setal
            LDA #<>ORDERS
            STA RAD_ADDR
            LDA #<`ORDERS
            STA RAD_ADDR + 2
            setas
    READ_ORDER
            LDA [OPL2_ADDY_PTR_LO],Y
            INY
            STA [RAD_ADDR]
            INC RAD_ADDR
            BCS ORDER_CONTINUE
            INC RAD_ADDR + 1
    ORDER_CONTINUE
            DEX
            BNE READ_ORDER
            RTS

; ************************************************************************************************
; * Read the pattern table
; * Y contains the position in the file
; ************************************************************************************************
READ_PATTERNS_10
            .as
            ; RAD_PATTRN holds the pattern number
            STZ RAD_PATTRN
            ; high byte of the pattern address
            LDA #<`PATTERNS
            STA RAD_PTN_DEST + 2
    NEXT_PATTERN
            
            ; read the file offset
            setal
            
            ; compute the start address of the pattern
            LDA RAD_PATTRN
            AND #$00FF
            STA @lUNSIGNED_MULT_A
            LDA #PATTERN_BYTES
            STA @lUNSIGNED_MULT_B
            LDA @lUNSIGNED_MULT_RESULT
            INC A ; skip the pattern byte
            STA RAD_PTN_DEST
            
        PHY  ; save our spot in the RAD file
            TYX
            setas
            LDY #0
            LDA #0
    CLEAR_PATTERN
            STA [RAD_PTN_DEST],Y
            INY
            CPY #PATTERN_BYTES
            BNE CLEAR_PATTERN
            setal
            TXY
            LDA [OPL2_ADDY_PTR_LO],Y ;  read the offset in the file to the pattern
            BEQ SKIP_PATTERN
            
            TAY
            setas
            JSR READ_PATTERN_10
            
    SKIP_PATTERN
        PLY  ; restore our read position in the RAD file
            INY
            INY
            setas
            INC RAD_PATTRN
            LDA RAD_PATTRN
            CMP #32
            BNE NEXT_PATTERN
            RTS

; ************************************************************************************************
; * Read the pattern table
; * Y contains the position in the RAD 1.0 file
; * RAD_PTN_DEST is the address to write to
; ************************************************************************************************
READ_PATTERN_10
            .as
            LDA [OPL2_ADDY_PTR_LO],Y ; read the line number - bit 7 indicates the last line 
            STA @lRAD_LINE
            INY
            setal
            AND #$7F
            STA @lUNSIGNED_MULT_A
            LDA #LINE_BYTES
            STA @lUNSIGNED_MULT_B
            LDA @lUNSIGNED_MULT_RESULT
            INC A ; skip the line number
            STA @lRAD_LINE_PTR
            setas
            
    READ_NOTE
            LDX RAD_LINE_PTR ; X contains the offset in the destination memory
 
            LDA [OPL2_ADDY_PTR_LO],Y ; channel - bit 7 indicates the last note
            INY
            STA @lRAD_LAST_NOTE
            AND #$F
            STA @lRAD_CHANNEL
            
            setal
            TXA
            CLC
            ADC RAD_CHANNEL ; multiply channel by 3
            ADC RAD_CHANNEL 
            ADC RAD_CHANNEL
            TAX
            setas
            
            LDA [OPL2_ADDY_PTR_LO],Y ; note / octave
            PHY
            TXY
            STA [RAD_PTN_DEST],Y
            PLY
            INY
            INX 
            
            LDA [OPL2_ADDY_PTR_LO],Y ; instrument/effect
            PHY
            TXY
            STA [RAD_PTN_DEST],Y
            PLY
            INY
            INX
            
            AND #$F
            BEQ CHECK_LASTNOTE
            
            LDA [OPL2_ADDY_PTR_LO],Y ; effect parameter
            PHY
            TXY
            STA [RAD_PTN_DEST],Y
            PLY
            INY
            INX
     CHECK_LASTNOTE
            LDA @lRAD_LAST_NOTE
            BPL READ_NOTE
            
            LDA @lRAD_LINE
            BPL READ_PATTERN_10
            RTS

INCREMENT_ORDER
            .as
            PHA
            LDA #0
            XBA
            LDA @lRAD_ORDER_NUM
            INC A
            CMP @lTuneInfo.songLength
            BNE LOAD_ORDER
            LDA #0
    LOAD_ORDER
            STA @lRAD_ORDER_NUM
            TAX
            LDA @lORDERS,X  ; load the pattern from the order list
            INC A
            STA PATTERN_NUM
            PLA
            RTS

; ************************************************************************************************
; * Turn off all notes to all 9 channels
; ************************************************************************************************
RAD_ALL_NOTES_OFF
            .as
            PHY
            setal
            LDA #<>OPL3_R_BASE
            STA OPL2_IND_ADDY_LL
            LDA #`OPL3_R_BASE
            STA OPL2_IND_ADDY_LL + 2
            setas
            LDY #$A0
            LDA #0
        NEXT_NOTE_OFF
            STA [OPL2_IND_ADDY_LL],Y
            INY
            CPY #$B9
            BNE NEXT_NOTE_OFF
            PLY
            RTS

; ************************************************************************************************
; * Play the notes given a pattern and line number.
; ************************************************************************************************
RAD_PLAYNOTES
            .as
            PHY
            
            LDX #$A080
            STX CURSORPOS
            
            LDA RAD_ORDER_NUM
            JSR DISPLAY_HEX
            LDA PATTERN_NUM
            JSR DISPLAY_HEX
            LDA LINE_NUM_HEX
            JSR DISPLAY_HEX
            
            setal
            LDA PATTERN_NUM
            AND #$FF
            DEC A ; start at 0
            STA @lUNSIGNED_MULT_A
            LDA #PATTERN_BYTES
            STA @lUNSIGNED_MULT_B
            LDA @lUNSIGNED_MULT_RESULT
            INC A ; skip the pattern number byte
            STA RAD_PTN_DEST
            
            LDA LINE_NUM_HEX
            AND #$7F
            STA @lUNSIGNED_MULT_A
            LDA #LINE_BYTES
            STA @lUNSIGNED_MULT_B
            LDA @lUNSIGNED_MULT_RESULT
            INC A  ; skip the line number byte

            TAY ; Y contains the line offset
            LDA #0
            setas
            STZ OPL2_REG_REGION
    PN_NEXT_NOTE
            STA @lOPL2_CHANNEL
    
    PN_PLAY_NOTE
            ; read the octave
            LDA [RAD_PTN_DEST],Y  ; octave/note
            PHA
            PHA
            AND #$70
            LSR
            LSR
            LSR
            LSR
            STA @lOPL2_OCTAVE
            ; read the node
            PLA  ; octave/note
            AND #$0F ; note
            STA @lOPL2_NOTE
            ; read the instrument #
            PLA  ; bit 7 is bit 4 of the instrument number
            AND #$80
            LSR A
            LSR A
            LSR A
            STA RAD_TEMP
            
            INY
            LDA [RAD_PTN_DEST],Y  ; instrument/effect
            AND #$F0
            LSR A
            LSR A
            LSR A
            LSR A
            ADC RAD_TEMP
            BEQ SKIP_INSTRUMENT
            DEC A  ; instruments are starting at 0
            STA @lINSTR_NUMBER
     
            PHY
            LDX OPL2_CHANNEL
            LDA #0
            XBA
            LDA @lregisterOffsets_operator0,X
            TAX
            JSR LOAD_INSTRUMENT
            PLY
            
        SKIP_INSTRUMENT
            LDA @lOPL2_NOTE
            BEQ SKIP_NOTE  ; if the note is 0, don't play anything.
            CMP #$0F ; NOTE OFF
            BEQ RAD_NOTE_OFF
            
            setal
            PHY
            JSR OPL2_GET_REG_OFFSET
            JSL OPL2_PLAYNOTE
            PLY
            setas
            
        SKIP_NOTE
            LDA #0
            XBA
            LDA [RAD_PTN_DEST],Y  ; instrument/effect
            INY
            AND #$F
            BEQ SKIP_EFFECT
            ASL A ; double bytes
            TAX
            JSR (RAD_EFFECT_TABLE,X)
        SKIP_EFFECT
            INY
            
            
    PN_CONTINUE
            ; increment the channel
            LDA #0  ; clear B
            XBA
            LDA @lOPL2_CHANNEL
            INC A
            CMP #9
            BNE PN_NEXT_NOTE
            PLY
            RTS

RAD_NOTE_OFF
            .as
            LDA @lOPL2_CHANNEL
            CLC
            ADC #$B0
            STA OPL2_IND_ADDY_LL
            LDA #0
            STA [OPL2_IND_ADDY_LL]
            INY
            ;INY
            INY
            BRA PN_CONTINUE
            
RAD_EFFECT_TABLE
            .word <>RAD_EFFECT_NONE              ; 00
            .word <>RAD_EFFECT_NOTE_SLIDE_UP     ; 01
            .word <>RAD_EFFECT_NOTE_SLIDE_DOWN   ; 02
            .word <>RAD_EFFECT_NOTE_SLIDE_TO     ; 03
            .word <>RAD_NOOP            
            .word <>RAD_EFFECT_NOTE_SLIDE_VOLUME ; 05
            .word <>RAD_NOOP            
            .word <>RAD_NOOP            
            .word <>RAD_NOOP            
            .word <>RAD_NOOP            
            .word <>RAD_EFFECT_VOLUME_SLIDE      ; 0A
            .word <>RAD_NOOP            
            .word <>RAD_EFFECT_SET_VOLUME        ; 0C
            .word <>RAD_EFFECT_PATTERN_BREAK     ; 0D
            .word <>RAD_NOOP            
            .word <>RAD_EFFECT_SET_SPEED         ; 0F

; ******************************************************
; * Y contains the pointer to the effect parameter
; ******************************************************
RAD_NOOP
RAD_EFFECT_NONE
RAD_EFFECT_NOTE_SLIDE_TO
RAD_EFFECT_NOTE_SLIDE_VOLUME
            .as
            RTS
            
RAD_EFFECT_VOLUME_SLIDE
            .as
            PHY
            
            LDA [RAD_PTN_DEST],Y ; store value of the effect in RAD_CHANNE_EFFCT
            STA RAD_CHANNE_EFFCT
            
            setal
            LDA #<>OPL3_R_BASE
            STA OPL2_IND_ADDY_LL
            LDA #`OPL3_R_BASE
            STA OPL2_IND_ADDY_LL + 2
            setaxs
            
            ; READ the current volume, offset $40, 00 is loud, 63 is
            LDA OPL2_CHANNEL
            TAX
            LDA @lregisterOffsets_operator0,X
            CLC
            ADC #$40
            TAY
            
            ; first operator
            LDA [OPL2_IND_ADDY_LL],Y ; volume
            PHA
            AND #$3F
            CLC
            ADC RAD_CHANNE_EFFCT ; check for values greater than 50
            CMP #$40 ; if there's an overflow, use #$3F (low volume)
            BCC NO_OVERFLOW_0
            LDA #$3F
    NO_OVERFLOW_0
            AND #$3F
            STA RAD_TEMP
            PLA 
            AND #$C0
            ORA RAD_TEMP
            STA [OPL2_IND_ADDY_LL],Y
            INY
            INY
            INY
            
            ; second operator
            LDA [OPL2_IND_ADDY_LL],Y ; volume
            PHA
            AND #$3F
            CLC
            ADC RAD_CHANNE_EFFCT
            CMP #$40 ; if there's an overflow, use #$3F (low volume)
            BCC NO_OVERFLOW_1
            LDA #$3F
    NO_OVERFLOW_1
            AND #$3F
            STA RAD_TEMP
            PLA 
            AND #$C0
            ORA RAD_TEMP
            STA [OPL2_IND_ADDY_LL],Y
            
            setxl
            PLY
            RTS
            
RAD_EFFECT_PATTERN_BREAK
            .as
            LDA [RAD_PTN_DEST],Y  ; effect parameter
            STA LINE_NUM_HEX
            JSR INCREMENT_ORDER
            PLY ; don't return to the calling method, return to the parent
            PLY
            RTS

RAD_EFFECT_SET_SPEED
            .as
            LDA [RAD_PTN_DEST],Y  ; effect parameter
            STA @lTuneInfo.InitialSpeed

            RTS

; ******************************************************
; * Y contains the pointer to the effect parameter
; ******************************************************
RAD_EFFECT_NOTE_SLIDE_UP
RAD_EFFECT_NOTE_SLIDE_DOWN
            .as
            PHY
            LSR
            STA RAD_EFFECT ; 1 slide down, 2 slide up
            
            LDA [RAD_PTN_DEST],Y ; store value of the effect in RAD_CHANNE_EFFCT
            STA RAD_CHANNE_EFFCT
            
            setal
            LDA #<>OPL3_R_BASE
            STA OPL2_IND_ADDY_LL
            LDA #`OPL3_R_BASE
            STA OPL2_IND_ADDY_LL + 2
            setaxs
            ; read the current fnumber into accumulator
            LDA OPL2_CHANNEL
            CLC
            ADC #$A0
            TAY
            
            LDA [OPL2_IND_ADDY_LL],Y ; read low fnumber byte
        PHA ; store A on the stack
            TYA
            CLC
            ADC #$10
            TAY
            
            LDA [OPL2_IND_ADDY_LL],Y ; read bits 0,1 of high fnumber
            STA RAD_TEMP  ; store the entire value of $B0
            setxl
            
            XBA
        PLA ; A is now the FNUMBER
            TAX ; X is now the FNUMBER
            
            ; if effect is 1, then decrease fnumber, otherwise, increase
            LDA RAD_EFFECT
            BIT #2
            BEQ SLIDE_UP
            
            setal
            TXA
            SEC
            SBC RAD_CHANNE_EFFCT  ; substract the effect parameter
            setas
            BRA FINISH_SLIDE
    
    SLIDE_UP
            setal
            TXA
            CLC
            ADC RAD_CHANNE_EFFCT  ; substract the effect parameter
            setas
            
    FINISH_SLIDE
            ; now store the value back into fnumber
            setxs
            XBA
            AND #3
            ORA RAD_TEMP
            STA [OPL2_IND_ADDY_LL],Y
            TYA
            SEC
            SBC #$10
            TAY
            XBA
            STA [OPL2_IND_ADDY_LL],Y
            
            setxl
            PLY
            RTS

; ******************************************************
; * Y contains the pointer to the effect parameter
; ******************************************************
RAD_EFFECT_SET_VOLUME
            .as
            PHY
            setal
            LDA #<>OPL3_R_BASE
            STA OPL2_IND_ADDY_LL
            LDA #`OPL3_R_BASE
            STA OPL2_IND_ADDY_LL + 2
            setas

            LDA [RAD_PTN_DEST],Y  ; effect parameter
            AND #$7F
            BEQ HANDLE_ZERO
            DEC A
        HANDLE_ZERO
            EOR #$3F ; complement
            STA RAD_TEMP
            setxs
            LDX OPL2_CHANNEL
            LDA @lregisterOffsets_operator0,X
            CLC
            ADC #$40
            TAY
            LDA [OPL2_IND_ADDY_LL],Y
            AND #$C0 ; 
            CLC
            ADC RAD_TEMP
            STA [OPL2_IND_ADDY_LL],Y
            INY
            INY
            INY
            LDA [OPL2_IND_ADDY_LL],Y
            AND #$C0 ;
            CLC
            ADC RAD_TEMP
            STA [OPL2_IND_ADDY_LL],Y
            setxl
            PLY
            RTS

;
RAD_SETINSTRUMENT
              PHY
              ; Carrier
              setas
              LDA #$01
              STA OPL2_OPERATOR
              setal

              LDA #<`INSTRUMENT_LIBRARY
              STA OPL2_ADDY_PTR_HI
              LDA OPL2_PARAMETER0
              AND #$00FF
              DEC A
              ASL A
              ASL A
              ASL A
              ASL A
              CLC
              ADC #<>INSTRUMENT_LIBRARY
              STA OPL2_ADDY_PTR_LO
              setal
              LDA #$0020
              JSL OPL2_GET_REG_OFFSET
              setas
              LDY #$0000
              LDA [OPL2_ADDY_PTR_LO],Y
              STA [OPL2_IND_ADDY_LL]
              setal
              LDA #$0040
              JSL OPL2_GET_REG_OFFSET
              setas
              LDY #$0002
              LDA [OPL2_ADDY_PTR_LO],Y
              STA [OPL2_IND_ADDY_LL]
              setal
              LDA #$0060
              JSL OPL2_GET_REG_OFFSET
              setas
              LDY #$0004
              LDA [OPL2_ADDY_PTR_LO],Y
              STA [OPL2_IND_ADDY_LL]
              setal
              LDA #$0080
              JSL OPL2_GET_REG_OFFSET
              setas
              LDY #$0006
              LDA [OPL2_ADDY_PTR_LO],Y
              STA [OPL2_IND_ADDY_LL]
              setal
              LDA #$00E0
              JSL OPL2_GET_REG_OFFSET
              setas
              LDY #$0009
              LDA [OPL2_ADDY_PTR_LO],Y
              AND #$0F
              STA [OPL2_IND_ADDY_LL]
              ; MODULATOR
              LDA #$00
              STA OPL2_OPERATOR
              ;  opl2.setRegister(0x20 + registerOffset, instruments[instrumentIndex][1]);
              setal
              LDA #$0020
              JSL OPL2_GET_REG_OFFSET
              setas
              LDY #$0001
              LDA [OPL2_ADDY_PTR_LO],Y
              STA [OPL2_IND_ADDY_LL]
              ;  opl2.setRegister(0x40 + registerOffset, instruments[instrumentIndex][3]);
              setal
              LDA #$0040
              JSL OPL2_GET_REG_OFFSET
              setas
              LDY #$0003
              LDA [OPL2_ADDY_PTR_LO],Y
              STA [OPL2_IND_ADDY_LL]
              ; opl2.setRegister(0x60 + registerOffset, instruments[instrumentIndex][5]);
              setal
              LDA #$0060
              JSL OPL2_GET_REG_OFFSET
              setas
              LDY #$0005
              LDA [OPL2_ADDY_PTR_LO],Y
              STA [OPL2_IND_ADDY_LL]
              ;  opl2.setRegister(0x80 + registerOffset, instruments[instrumentIndex][7]);
              setal
              LDA #$0080
              JSL OPL2_GET_REG_OFFSET
              setas
              LDY #$00071
              LDA [OPL2_ADDY_PTR_LO],Y
              STA [OPL2_IND_ADDY_LL]
              ;  opl2.setRegister(0xE0 + registerOffset, (instruments[instrumentIndex][9] & 0xF0) >> 4);
              setal
              LDA #$00E0
              JSL OPL2_GET_REG_OFFSET
              setas
              LDY #$0009
              LDA [OPL2_ADDY_PTR_LO],Y
              AND #$F0
              LSR A
              LSR A
              LSR A
              LSR A
              STA [OPL2_IND_ADDY_LL]
              ;  opl2.setRegister(0xC0 + channel, instruments[instrumentIndex][8]);
              LDA OPL2_CHANNEL
              CLC
              AND #$0F  ; This is just precaution, it should be between 0 to 8
              ADC #$C0
              STA OPL2_REG_OFFSET
              LDA #$00
              STA OPL2_REG_OFFSET+1;
              setaxl
              CLC
              LDA #<>OPL3_R_BASE
              ADC OPL2_REG_OFFSET
              STA OPL2_IND_ADDY_LL
              LDA #`OPL3_R_BASE
              STA OPL2_IND_ADDY_HL
              setas
              LDY #$0008
              LDA [OPL2_ADDY_PTR_LO],Y
              STA [OPL2_IND_ADDY_LL]
              PLY
              RTS

; X contains the channel offset
LOAD_INSTRUMENT
                .as
                LDA @lINSTR_NUMBER

                ; calculate the memory offset to the instrument bank
                STA @lUNSIGNED_MULT_A
                LDA #0
                STA @lUNSIGNED_MULT_A + 1
                STA @lUNSIGNED_MULT_B + 1
                LDA #INSTR_REC_LEN
                STA @lUNSIGNED_MULT_B
                setal
                LDA @lUNSIGNED_MULT_RESULT
                
                CLC
                ADC #<>INSTRUMENT_LIBRARY
                STA INSTR_ADDR
                
                setas

                LDA [INSTR_ADDR]
                BNE DRUM_SET
                
                ; $20 Amp Mod, Vibrator, EG Type, Key Scaling, F Mult
                INC INSTR_ADDR
                BNE LD_INST_1
                INC INSTR_ADDR+1
    LD_INST_1         
                JSR LOAD_AM_VIB_MULT
                
                ; $40 Key Scaling Lvl, Operator Lvl
                INC INSTR_ADDR
                BNE LD_INST_2
                INC INSTR_ADDR+1
    LD_INST_2 
                JSR LOAD_KEY_OP_LVL
                
                ; $60 Attack Rate, Decay Rate
                INC INSTR_ADDR
                BNE LD_INST_3
                INC INSTR_ADDR+1
    LD_INST_3 
                JSR LOAD_ATT_DEC_RATE
                
                ; $80 Sustain Level, Release Rate
                INC INSTR_ADDR
                BNE LD_INST_4
                INC INSTR_ADDR+1
    LD_INST_4
                JSR LOAD_SUSTAIN_RELEASE_RATE
                
                ; $C0 Feedback, Connection Type
                INC INSTR_ADDR
                BNE LD_INST_5
                INC INSTR_ADDR+1
    LD_INST_5
                PHX
                LDX OPL2_CHANNEL
                JSR LOAD_FEEDBACK_ALGO
                PLX
                
                ; $E0 Waveform Selection
                INC INSTR_ADDR
                BNE LD_INST_6
                INC INSTR_ADDR+1
    LD_INST_6
                JSR LOAD_WAVE
                
                setal
                LDA INSTR_ADDR
                ADC #6
                STA INSTR_ADDR
                setas
                
DRUM_SET
                RTS
                
; X contains the OPL2 register offset
LOAD_AM_VIB_MULT
                LDA [INSTR_ADDR]
                STA @lOPL3_R_AM_VID_EG_KSR_MULT,X
                LDY #6
                LDA [INSTR_ADDR], Y
                STA @lOPL3_R_AM_VID_EG_KSR_MULT + 3,X
                
                RTS
                
; X contains the OPL2 register
LOAD_KEY_OP_LVL
                ; Operator 1
                LDA [INSTR_ADDR]
                STA @lOPL3_R_KSL_TL,X
                
                ; Operator 2
                LDY #6
                LDA [INSTR_ADDR],Y
                STA @lOPL3_R_KSL_TL + 3,X
                
                RTS

LOAD_ATT_DEC_RATE
                LDA [INSTR_ADDR]
                STA @lOPL3_R_AR_DR,X
                
                LDY #6
                LDA [INSTR_ADDR],Y
                STA @lOPL3_R_AR_DR + 3,X
                RTS
                
LOAD_SUSTAIN_RELEASE_RATE
                LDA [INSTR_ADDR]
                STA @lOPL3_R_SL_RR,X
                
                LDY #6
                LDA [INSTR_ADDR],Y
                STA @lOPL3_R_SL_RR + 3,X
                RTS
                
LOAD_FEEDBACK_ALGO
                LDA [INSTR_ADDR]
                ORA #$F0 ; Channel B
                STA @lOPL3_R_FEEDBACK,X
                RTS

LOAD_WAVE
                LDA [INSTR_ADDR]
                STA @lOPL3_R_WAVE_SELECT,X
                
                LDY #5
                LDA [INSTR_ADDR],Y
                STA @lOPL3_R_WAVE_SELECT+3,X
                RTS