; Keyboard stuff
BACKSPACE_KEY = $66
ENTER_KEY     = $5A

; the array below is a list of scan codes to character
KEYBOARD_TO_CHAR
.byte $00   ; $00 nothing
.byte $00	; $01  F9 pressed
.byte $00   ; $02 nothing
.byte $00	; $03  F5 pressed
.byte $00	; $04  F3 pressed
.byte $00	; $05  F1 pressed
.byte $00	; $06  F2 pressed
.byte $00	; $07  F12 pressed
.byte $00   ; $08 nothing
.byte $00	; $09  F10 pressed
.byte $00	; $0A  F8 pressed
.byte $00	; $0B  F6 pressed
.byte $00	; $0C  F4 pressed
.byte $00	; $0D  tab pressed
.byte $00	; $0E  ` (back tick) pressed	
.byte $00   ; $0F nothing	
.byte $00   ; $10 nothing	
.byte $00	; $11  left alt pressed
.byte $00	; $12  left shift pressed	
.byte $00   ; $13 nothing	
.byte $00	; $14  left control pressed
.byte 'Q'	; $15  Q pressed
.byte '1'	; $16  1 pressed		
.byte $00   ; $17 nothing
.byte $00   ; $18 nothing
.byte $00   ; $19 nothing
.byte 'Z'	; $1A  Z pressed
.byte 'S'	; $1B  S pressed
.byte 'A'	; $1C  A pressed
.byte 'W'	; $1D  W pressed
.byte '2'	; $1E  2 pressed		
.byte $00   ; $1F nothing
.byte $00   ; $20 nothing
.byte 'C'	; $21  C pressed
.byte 'X'	; $22  X pressed
.byte 'D'	; $23  D pressed
.byte 'E'	; $24  E pressed
.byte '4'	; $25  4 pressed
.byte '3'	; $26  3 pressed		
.byte $00   ; $27 nothing
.byte $00   ; $28 nothing
.byte $00	; $29  space pressed
.byte 'V'	; $2A  V pressed
.byte 'F'	; $2B  F pressed
.byte 'T'	; $2C  T pressed
.byte 'R'	; $2D  R pressed
.byte '5'	; $2E  5 pressed		
.byte $00   ; $2F nothing
.byte $00   ; $30 nothing
.byte 'N'	; $31  N pressed
.byte 'B'	; $32  B pressed
.byte 'H'	; $33  H pressed
.byte 'G'	; $34  G pressed
.byte 'Y'	; $35  Y pressed
.byte '6'	; $36  6 pressed		
.byte $00   ; $37 nothing
.byte $00   ; $38 nothing
.byte $00   ; $39 nothing	
.byte 'M'	; $3A  M pressed
.byte 'J'	; $3B  J pressed
.byte 'U'	; $3C  U pressed
.byte '7'	; $3D  7 pressed
.byte '8'	; $3E  8 pressed		
.byte $00   ; $3F nothing
.byte $00   ; $40 nothing
.byte $00	; $41  , pressed
.byte 'K'	; $42  K pressed
.byte 'I'	; $43  I pressed
.byte 'O'	; $44  O pressed
.byte '0'	; $45  0 (zero) pressed
.byte '9'	; $46  9 pressed		
.byte $00   ; $47 nothing
.byte $00   ; $48 nothing
.byte '.'	; $49  . pressed
.byte $00	; $4A  / pressed
.byte 'L'	; $4B  L pressed
.byte $00	; $4C   ; pressed
.byte 'P'	; $4D  P pressed
.byte '-'	; $4E  - pressed		
.byte $00   ; $4F nothing
.byte $00   ; $50 nothing
.byte $00   ; $51 nothing
.byte $00	; $52  ' pressed		
.byte $00   ; $53 nothing
.byte $00	; $54  [ pressed
.byte $00	; $55  = pressed				
.byte $00   ; $56 nothing
.byte $00   ; $57 nothing
.byte $00	; $58  CapsLock pressed
.byte $00	; $59  right shift pressed
.byte $00	; $5A  enter pressed
.byte $00	; $5B  ] pressed
.byte $00   ; $5C nothing	
.byte $00	; $5D  \ pressed				   
.byte $00   ; $5E nothing	
.byte $00   ; $5F nothing	
.byte $00   ; $60 nothing	
.byte $00   ; $61 nothing	
.byte $00   ; $62 nothing	
.byte $00   ; $63 nothing	
.byte $00   ; $64 nothing	
.byte $00   ; $65 nothing	
.byte $00	; $66  backspace pressed	
.byte $00   ; $67 nothing	
.byte $00   ; $68 nothing		
.byte '1'	; $69  (keypad) 1 pressed
.byte $00   ; $6A nothing	
.byte '4'	; $6B  (keypad) 4 pressed
.byte '7'	; $6C  (keypad) 7 pressed						
.byte $00   ; $6D nothing	
.byte $00   ; $6E nothing	
.byte $00   ; $6F nothing	
.byte '0'	; $70  (keypad) 0 pressed
.byte '.'	; $71  (keypad) . pressed
.byte '2'	; $72  (keypad) 2 pressed
.byte '5'	; $73  (keypad) 5 pressed
.byte '6'	; $74  (keypad) 6 pressed
.byte '8'	; $75  (keypad) 8 pressed
.byte $00	; $76  escape pressed
.byte $00	; $77  NumberLock pressed
.byte $00	; $78  F11 pressed
.byte '+'	; $79  (keypad) + pressed
.byte '3'	; $7A  (keypad) 3 pressed
.byte '-'	; $7B  (keypad) - pressed
.byte '*'	; $7C  (keypad) * pressed
.byte '9'	; $7D  (keypad) 9 pressed
.byte $00	; $7E  ScrollLock pressed		
.byte $00   ; $7F nothing	
.byte $00   ; $80 nothing	
.byte $00   ; $81 nothing	
.byte $00   ; $82 nothing	
.byte $00	; $83  F7 pressed

; the matrix has 60 keys
KEYMATRIX_TO_CHAR
.byte $00   ; $00 delete key
.byte '3'   ; $01 3 pressed
.byte '5'   ; $02 5 pressed
.byte '7'   ; $03 7 pressed
.byte '9'   ; $04 9 pressed
.byte '-'   ; $05 - pressed
.byte '+'   ; $06 + pressed
.byte '1'   ; $07 1 pressed
.byte $00   ; $08 RETURN pressed
.byte 'W'   ; $09 W pressed
.byte 'R'   ; $0A R pressed
.byte 'Y'   ; $0B Y pressed
.byte 'I'   ; $0C I pressed
.byte 'P'   ; $0D P pressed
.byte $00   ; $0E ] pressed
.byte $00   ; $0F BKSPC pressed

.byte $00   ; $10 LEFT key
.byte 'A'   ; $11 A pressed
.byte 'D'   ; $12 D pressed
.byte 'G'   ; $13 G pressed
.byte 'J'   ; $14 J pressed
.byte 'L'   ; $15 L pressed
.byte $00   ; $16 ; pressed
.byte $00   ; $17 CTRL pressed

.byte $00   ; $18 ?? pressed
.byte 'W'   ; $19 W pressed
.byte 'R'   ; $1A R pressed
.byte 'Y'   ; $1B Y pressed
.byte 'I'   ; $1C I pressed
.byte 'P'   ; $1D P pressed
.byte $00   ; $1E \ pressed
.byte $00   ; $1F BKSPC pressed

.byte $00   ; $20 F1 key
.byte 'Z'   ; $21 Z pressed
.byte 'C'   ; $22 C pressed
.byte 'B'   ; $23 B pressed
.byte 'M'   ; $24 M pressed
.byte '.'   ; $25 . pressed
.byte $00   ; $26 RSHIFT pressed
.byte $00   ; $27 SPACE pressed
.byte $00   ; $28 F3 pressed
.byte 'S'   ; $29 S pressed
.byte 'F'   ; $2A F pressed
.byte 'H'   ; $2B H pressed
.byte 'K'   ; $2C K pressed
.byte $00   ; $2D ' pressed
.byte $00   ; $2E ALT pressed
.byte $00   ; $2F FOENIX pressed

.byte $00   ; $30 F5 key
.byte 'E'   ; $31 E pressed
.byte 'T'   ; $32 T pressed
.byte 'U'   ; $33 U pressed
.byte 'O'   ; $34 O pressed
.byte $00   ; $35 [ pressed
.byte $00   ; $36 TAB pressed
.byte 'Q'   ; $37 Q pressed
.byte $00   ; $38 UP pressed
.byte $00   ; $39 SHIFT pressed
.byte 'X'   ; $3A X pressed
.byte 'V'   ; $3B V pressed
.byte 'N'   ; $3C N pressed
.byte $00   ; $3D , pressed
.byte $00   ; $3E / pressed
.byte $00   ; $3F BKSPC pressed