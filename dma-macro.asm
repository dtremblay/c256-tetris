; DMA Fill Macro
; first parameter is the fill byte
; second parameter is the destination address
; third parameter is the length

dma_fill    .macro   
            lda #DMA_CTRL_FILL | DMA_CTRL_ENABLE
            sta DMA_CTRL

            lda #\1
            sta DMA_FILL_VAL

            lda #<\2
            sta DMA_DST_ADDR
            lda #>\2
            sta DMA_DST_ADDR+1
            lda #`\2
            and #$03
            sta DMA_DST_ADDR+2

            lda #<\3
            sta DMA_COUNT
            lda #>\3
            sta DMA_COUNT+1
            lda #`\3
            and #$03
            sta DMA_COUNT+2

            lda DMA_CTRL
            ora #DMA_CTRL_START
            sta DMA_CTRL

wait_dma:   ; Wait until DMA is not busy
            lda DMA_STATUS      
            and #DMA_STAT_BUSY
            cmp #DMA_STAT_BUSY
            beq wait_dma

            ; Turn off the DMA engine
            stz DMA_CTRL        
            
            .endm
            
; DMA Fill 2D Macro
; first parameter is the fill byte
; second parameter is the destination address
; third parameter is the width
; fourth parameter is the height    
; fifth parameter is the stride   
dma_fill_2d .macro   
            lda #DMA_CTRL_FILL | DMA_CTRL_2D | DMA_CTRL_ENABLE
            sta DMA_CTRL

            lda #\1
            sta DMA_FILL_VAL

            lda #<\2
            sta DMA_DST_ADDR
            lda #>\2
            sta DMA_DST_ADDR+1
            lda #`\2
            and #$03
            sta DMA_DST_ADDR+2

            lda #<\3
            sta DMA_WIDTH
            lda #>\3
            sta DMA_WIDTH+1
            
            lda #<\4
            sta DMA_HEIGHT
            lda #>\4
            sta DMA_HEIGHT+1
            
            lda #<\5
            sta DMA_STRIDE_DST
            lda #>\5
            sta DMA_STRIDE_DST+1

            lda DMA_CTRL
            ora #DMA_CTRL_START
            sta DMA_CTRL

wait_dma:   ; Wait until DMA is not busy
            lda DMA_STATUS      
            and #DMA_STAT_BUSY
            cmp #DMA_STAT_BUSY
            beq wait_dma

            ; Turn off the DMA engine
            stz DMA_CTRL        
            
            .endm
            
            
; DMA Copy Macro
; first parameter is the source address
; second parameter is the destination address
; third parameter is the length
dma_copy    .macro 
            lda #DMA_CTRL_ENABLE
            sta DMA_CTRL

            lda #<\1
            sta DMA_SRC_ADDR
            lda #>\1
            sta DMA_SRC_ADDR+1
            lda #`\1
            and #$03
            sta DMA_SRC_ADDR+2
            
            lda #<\2
            sta DMA_DST_ADDR
            lda #>\2
            sta DMA_DST_ADDR+1
            lda #`\2
            and #$03
            sta DMA_DST_ADDR+2

            lda #<\3
            sta DMA_COUNT
            lda #>\3
            sta DMA_COUNT+1
            lda #`\3
            and #$03
            sta DMA_COUNT+2

            lda DMA_CTRL
            ora #DMA_CTRL_START
            sta DMA_CTRL

wait_dma:   ; Wait until DMA is not busy
            lda DMA_STATUS      
            and #DMA_STAT_BUSY
            cmp #DMA_STAT_BUSY
            beq wait_dma

            ; Turn off the DMA engine
            stz DMA_CTRL
            .endm


; DMA Copy 2D Macro
; first parameter is the source address
; second parameter is the destination address
; third parameter is the width
; fourth parameter is the height    
; fifth parameter is the source stride 
; sixth parameter is the destination stride 
dma_copy_2D  .macro 
            lda #DMA_CTRL_2D | DMA_CTRL_ENABLE
            sta DMA_CTRL

            lda #<\1
            sta DMA_SRC_ADDR
            lda #>\1
            sta DMA_SRC_ADDR+1
            lda #`\1
            and #$03
            sta DMA_SRC_ADDR+2

            lda #<\2
            sta DMA_DST_ADDR
            lda #>\2
            sta DMA_DST_ADDR+1
            lda #`\2
            and #$03
            sta DMA_DST_ADDR+2

            lda #<\3
            sta DMA_WIDTH
            lda #>\3
            sta DMA_WIDTH+1
            
            lda #<\4
            sta DMA_HEIGHT
            lda #>\4
            sta DMA_HEIGHT+1
            
            lda #<\5
            sta DMA_STRIDE_SRC
            lda #>\5
            sta DMA_STRIDE_SRC+1
            
            lda #<\6
            sta DMA_STRIDE_DST
            lda #>\6
            sta DMA_STRIDE_DST+1

            lda DMA_CTRL
            ora #DMA_CTRL_START
            sta DMA_CTRL

wait_dma:   ; Wait until DMA is not busy
            lda DMA_STATUS      
            and #DMA_STAT_BUSY
            cmp #DMA_STAT_BUSY
            beq wait_dma

            ; Turn off the DMA engine
            stz DMA_CTRL   
             .endm