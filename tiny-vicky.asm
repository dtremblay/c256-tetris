; Tiny Vicky
VKY_MSTR_CTRL_0 = $D000 ; Vicky Master Control Register 0
    VKY_Text_Mode_En   = 1
    VKY_Text_Overlay   = 2
    VKY_Graph_Mode_En  = 4
    VKY_Bitmap_Mode_En = 8
    VKY_Tile_Mode_En   = $10
    VKY_Sprite_Mode_En = $20
    VKY_Gamma_En       = $40

VKY_MSTR_CTRL_1 = $D001 ; Vicky Master Control Register 1
    VKY_Clock_70     = 1
    VKY_Dbl_X_Text   = 2
    VKY_Dbl_Y_Text   = 4
    VKY_Monitor_Sleep= 8
    VKY_Font_Overlay = $20
    VKY_Font_Set     = $40
    
VKY_LAYER_CTRL0 = $D002
VKY_LAYER_CTRL1 = $D003
    VK_LYR_BMP0 = 0
    VK_LYR_BMP1 = 1
    VK_LYR_BMP2 = 2
    VK_LYR_TLM0 = 4
    VK_LYR_TLM1 = 5
    VK_LYR_TLM2 = 6



VKY_BRDR_CTRL   = $D004 ; Vicky Border Control Register
VKY_BKG_COL_B   = $D00D ; Vicky Graphics Background Color Blue
VKY_BKG_COL_G   = $D00E ; Vicky Graphics Background Color Green
VKY_BKG_COL_R   = $D00F ; Vicky Graphics Background Color Red
VKY_BRDR_WIDTH  = $D008 ; 5-bit int
VKY_BRDR_HEIGHT = $D009 ; 5-bit int
VKY_BGND_BLUE   = $D00D ; Blue component of background color
VKY_BGND_GREEN  = $D00E ; Green component of background color
VKY_BGND_RED    = $D00F ; Red component of background color

VKY_CURSOR_CTRL = $D010 ; Cursor control register
    VKY_CURSOR_EN  = 1
    VKY_CURSOR_RATE_100  = 0
    VKY_CURSOR_RATE_50   = 2
    VKY_CURSOR_RATE_25   = 4
    VKY_CURSOR_RATE_20   = 6
    VKY_CUR_FLSH_DISABLE = 8
VKY_CURSOR_CHAR = $D012
VKY_CURSOR_X    = $D014
VKY_CURSOR_Y    = $D016

VKY_BM0_CTRL    = $D100 ; Bitmap #0 Control Register
VKY_BM0_ADDR_L  = $D101 ; Bitmap #0 Address bits 7..0
VKY_BM0_ADDR_M  = $D102 ; Bitmap #0 Address bits 15..8
VKY_BM0_ADDR_H  = $D103 ; Bitmap #0 Address bits 17..16

VKY_BM1_CTRL    = $D108 ; Bitmap #1 Control Register
VKY_BM1_ADDR_L  = $D109 ; Bitmap #1 Address bits 7..0
VKY_BM1_ADDR_M  = $D10A ; Bitmap #1 Address bits 15..8
VKY_BM1_ADDR_H  = $D10B ; Bitmap #1 Address bits 17..16

VKY_BM2_CTRL    = $D110 ; Bitmap #2 Control Register
VKY_BM2_ADDR_L  = $D111 ; Bitmap #2 Address bits 7..0
VKY_BM2_ADDR_M  = $D112 ; Bitmap #2 Address bits 15..8
VKY_BM2_ADDR_H  = $D113 ; Bitmap #2 Address bits 17..16
    VKY_BITMAP_EN   = 1
    VKY_BITMAP_LUT0 = 0
    VKY_BITMAP_LUT1 = 2
    VKY_BITMAP_LUT2 = 4
    VKY_BITMAP_LUT3 = 6
    
VKY_TILEMAP0_CTRL   = $D200
VKY_TILEMAP0_AD     = $D201
VKY_TILEMAP0_WIDTH  = $D204
VKY_TILEMAP0_HEIGHT = $D206
VKY_TILEMAP0_SCR_X  = $D208
VKY_TILEMAP0_SCR_Y  = $D20A

VKY_TILEMAP1_CTRL   = $D20C
VKY_TILEMAP1_AD     = $D20D
VKY_TILEMAP1_WIDTH  = $D210
VKY_TILEMAP1_HEIGHT = $D212
VKY_TILEMAP1_SCR_X  = $D214
VKY_TILEMAP1_SCR_Y  = $D216

VKY_TILEMAP2_CTRL   = $D218
VKY_TILEMAP2_AD     = $D219
VKY_TILEMAP2_WIDTH  = $D21C
VKY_TILEMAP2_HEIGHT = $D21E
VKY_TILEMAP2_SCR_X  = $D220
VKY_TILEMAP2_SCR_Y  = $D222
    VKY_TILEMAP_EN  = 1
    VKY_TILEMAP_16  = 0
    VKY_TILEMAP_8   = $10
    
VKY_TILESET0_ADDR   = $D280
VKY_TILESET0_CTRL   = $D283
VKY_TILESET1_ADDR   = $D284
VKY_TILESET1_CTRL   = $D287
VKY_TILESET2_ADDR   = $D288
VKY_TILESET2_CTRL   = $D28B
VKY_TILESET3_ADDR   = $D28C
VKY_TILESET3_CTRL   = $D28F
    VKY_TILESET_LIN = 0
    VKY_TILESET_SQ  = 8
    

VKY_SP0_CTRL    = $D900 ; Sprite #0’s control register
VKY_SP0_AD_L    = $D901 ; Sprite #0’s pixel data address register
VKY_SP0_AD_M    = $D902
VKY_SP0_AD_H    = $D903
VKY_SP0_POS_X_L = $D904 ; Sprite #0’s X position register
VKY_SP0_POS_X_H = $D905
VKY_SP0_POS_Y_L = $D906 ; Sprite #0’s Y position register
VKY_SP0_POS_Y_H = $D907
    VKY_SPRITE_EN  = 1
    VKY_SPRITE_LUT0= 0
    VKY_SPRITE_LUT1= 2
    VKY_SPRITE_LUT2= 4
    VKY_SPRITE_LUT3= 6
    VKY_SPR_LYR0   = 0
    VKY_SPR_LYR1   = 8
    VKY_SPR_LYR2   = $10
    VKY_SPR_LYR3   = $18
    VKY_SPR_32X32  = 0
    VKY_SPR_24X24  = $20
    VKY_SPR_16X16  = $40
    VKY_SPR_8X8    = $60


RND_SEEDL       = $D6A4 ; write
RND_SEEDH       = $D6A5 ; write
RND_L           = $D6A4 ; read
RND_H           = $D6A5 ; read
RND_CTRL        = $D6A6 ; write
RND_STAT        = $D6A6 ; read
; Random Number Generator Ctrl bits
    RND_ENABLE    = 1
    RND_SEED_LOAD = 2
    RND_DONE      = 4 ; read