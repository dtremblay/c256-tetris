.include "SDCard_Controller_def.asm"

;******************************************************************************
; ISDOS_INIT
; Init the SDCARD
; Inputs:
;  None
; Affects:
;   SDCARD_PRSNT_MNT = 0 if SD card is not present or 1 is present.
;******************************************************************************
ISDOS_INIT
                .as
                TURN_ON_SD_LED
                
                LDA #0
                
                ; SD Card is not present
                STA SDCARD_PRSNT_MNT 
                
                ; initialize the SD Card reader
                LDA #SDC_TRANS_INIT_SD
                STA SDC_TRANS_TYPE_REG
                
                LDA #SDC_TRANS_START
                STA SDC_TRANS_CONTROL_REG
              
    SD_WAIT     LDA SDC_TRANS_STATUS_REG
                AND #SDC_TRANS_BUSY
                CMP #SDC_TRANS_BUSY
                BEQ SD_WAIT
                
                ; check for errors
                LDA SDC_TRANS_ERROR_REG
                BEQ SD_INIT_SUCCESS
                
                LDA #'F'
                STA EVID_TEXT_MEM + 100 *3
                LDA #$10
                STA EVID_COLOR_MEM + 100 *3
                
                BRA SD_INIT_DONE
                
    SD_INIT_SUCCESS
                ; SD Card is present
                LDA #1
                STA SDCARD_PRSNT_MNT
                LDA #'B'
                STA EVID_TEXT_MEM + 100 *3
                LDA #$10
                STA EVID_COLOR_MEM + 100 *3

    SD_INIT_DONE
                TURN_OFF_SD_LED
                RTS
