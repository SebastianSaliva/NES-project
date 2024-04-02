PPUCTRL   = $2000
PPUMASK   = $2001
PPUSTATUS = $2002
PPUADDR   = $2006
PPUDATA   = $2007
OAMADDR   = $2003
OAMDMA    = $4014 

.segment "HEADER"
.byte $4e, $45, $53, $1a ; Magic string that always begins an iNES header
.byte $02        ; Number of 16KB PRG-ROM banks
.byte $01        ; Number of 8KB CHR-ROM banks
.byte %00000000  ; Horizontal mirroring, no save RAM, no mapper
.byte %00000000  ; No special-case flags set, no mapper
.byte $00        ; No PRG-RAM present
.byte $00        ; NTSC format


.segment "ZEROPAGE"
player_x: .res 1
player_y: .res 1
player_index01: .res 1
player_index02: .res 1
player_index03: .res 1
player_index04: .res 1

player_dir: .res 1
.exportzp player_x, player_y, player_index01, player_index02, player_index03, player_index04

.segment "CODE"
.proc irq_handler
  RTI
.endproc

.proc nmi_handler
  LDA #$00
  STA OAMADDR
  LDA #$02
  STA OAMDMA

  ; update tiles *after* DMA transfer
  JSR update_player

  ; draw character 1
  LDA #$00
  STA player_x
  LDA #$10
  STA player_y
  LDA #$01
  STA player_index01
  LDA #$02
  STA player_index02
  LDA #$11
  STA player_index03
  LDA #$12
  STA player_index04
  LDY #$00
  JSR draw_texture

  ; draw character 2
  LDA #$20
  STA player_x
  LDA #$10
  STA player_y
  LDA #$03
  STA player_index01
  LDA #$04
  STA player_index02
  LDA #$13
  STA player_index03
  LDA #$14
  STA player_index04
  LDY #$10
  JSR draw_texture

  ; draw character 3
  LDA #$40
  STA player_x
  LDA #$10
  STA player_y
  LDA #$05
  STA player_index01
  LDA #$06
  STA player_index02
  LDA #$15
  STA player_index03
  LDA #$16
  STA player_index04
  LDY #$20
  JSR draw_texture

  ; draw character 4
  LDA #$60
  STA player_x
  LDA #$10
  STA player_y
  LDA #$07
  STA player_index01
  LDA #$08
  STA player_index02
  LDA #$17
  STA player_index03
  LDA #$18
  STA player_index04
  LDY #$30
  JSR draw_texture

  ; draw character 5
  LDA #$80
  STA player_x
  LDA #$20
  STA player_y
  LDA #$09
  STA player_index01
  LDA #$0a
  STA player_index02
  LDA #$19
  STA player_index03
  LDA #$1a
  STA player_index04
  LDY #$40
  JSR draw_texture

  ; draw character 6
  LDA #$a0
  STA player_x
  LDA #$20
  STA player_y
  LDA #$0b
  STA player_index01
  LDA #$0c
  STA player_index02
  LDA #$1b
  STA player_index03
  LDA #$1c
  STA player_index04
  LDY #$50
  JSR draw_texture

  ; draw character 7
  LDA #$00
  STA player_x
  LDA #$40
  STA player_y
  LDA #$21
  STA player_index01
  LDA #$22
  STA player_index02
  LDA #$31
  STA player_index03
  LDA #$32
  STA player_index04
  LDY #$60
  JSR draw_texture

  ; draw character 8
  LDA #$20
  STA player_x
  LDA #$40
  STA player_y
  LDA #$23
  STA player_index01
  LDA #$24
  STA player_index02
  LDA #$33
  STA player_index03
  LDA #$34
  STA player_index04
  LDY #$70
  JSR draw_texture

  ; draw character 9
  LDA #$40
  STA player_x
  LDA #$40
  STA player_y
  LDA #$25
  STA player_index01
  LDA #$26
  STA player_index02
  LDA #$35
  STA player_index03
  LDA #$36
  STA player_index04
  LDY #$80
  JSR draw_texture

  ; draw character 10
  LDA #$60
  STA player_x
  LDA #$40
  STA player_y
  LDA #$27
  STA player_index01
  LDA #$28
  STA player_index02
  LDA #$37
  STA player_index03
  LDA #$38
  STA player_index04
  LDY #$90
  JSR draw_texture

  ; draw character 11
  LDA #$80
  STA player_x
  LDA #$50
  STA player_y
  LDA #$29
  STA player_index01
  LDA #$2a
  STA player_index02
  LDA #$39
  STA player_index03
  LDA #$3a
  STA player_index04
  LDY #$a0
  JSR draw_texture

  ; draw character 12
  LDA #$a0
  STA player_x
  LDA #$50
  STA player_y
  LDA #$2b
  STA player_index01
  LDA #$2c
  STA player_index02
  LDA #$3b
  STA player_index03
  LDA #$3c
  STA player_index04
  LDY #$b0
  JSR draw_texture

  ; draw steel wall 1
  LDA #$00
  STA player_x
  LDA #$80
  STA player_y
  LDA #$41
  STA player_index01
  LDA #$42
  STA player_index02
  LDA #$51
  STA player_index03
  LDA #$52
  STA player_index04
  LDY #$c0
  JSR draw_texture

  ; draw steel wall 2
  LDA #$20
  STA player_x
  LDA #$80
  STA player_y
  LDA #$43
  STA player_index01
  LDA #$44
  STA player_index02
  LDA #$53
  STA player_index03
  LDA #$54
  STA player_index04
  LDY #$d0
  JSR draw_texture

  ; draw brick wall 1
  LDA #$40
  STA player_x
  LDA #$80
  STA player_y
  LDA #$61
  STA player_index01
  LDA #$62
  STA player_index02
  LDA #$71
  STA player_index03
  LDA #$72
  STA player_index04
  LDY #$e0
  JSR draw_texture

  ; draw brick wall 2
  LDA #$60
  STA player_x
  LDA #$80
  STA player_y
  LDA #$63
  STA player_index01
  LDA #$64
  STA player_index02
  LDA #$73
  STA player_index03
  LDA #$74
  STA player_index04
  LDY #$f0
  JSR draw_texture

  ; draw bushes 1
  LDA #$80
  STA player_x
  LDA #$90
  STA player_y
  LDA #$45
  STA player_index01
  LDA #$46
  STA player_index02
  LDA #$55
  STA player_index03
  LDA #$56
  STA player_index04
  LDY #$00
  JSR draw_texture

  ; draw bushes 2
  LDA #$a0
  STA player_x
  LDA #$90
  STA player_y
  LDA #$47
  STA player_index01
  LDA #$48
  STA player_index02
  LDA #$57
  STA player_index03
  LDA #$58
  STA player_index04
  LDY #$10
  JSR draw_texture

  LDA #$00
  STA $2005
  STA $2005
  RTI
.endproc

.proc reset_handler
  SEI
  CLD
  LDX #$40
  STX $4017
  LDX #$FF
  TXS
  INX
  STX $2000
  STX $2001
  STX $4010
  BIT $2002
vblankwait:
  BIT $2002
  BPL vblankwait

	LDX #$00
	LDA #$FF
clear_oam:
	STA $0200,X ; set sprite y-positions off the screen
	INX
	INX
	INX
	INX
	BNE clear_oam

	; initialize zero-page values
	LDA #$80
	STA player_x
	LDA #$a0
	STA player_y

  LDA #$01 
  STA  player_index01
  LDA #$02
  STA player_index02
  LDA #$11
  STA player_index03
  LDA #$12
  STA player_index04

vblankwait2:
  BIT $2002
  BPL vblankwait2
  JMP main
.endproc



.proc main
  ; write a palette
  LDX PPUSTATUS
  LDX #$3f
  STX PPUADDR
  LDX #$00
  STX PPUADDR


load_palettes:
  LDA palettes,X
  STA PPUDATA
  INX
  CPX #$20
  BNE load_palettes

	; write nametables


vblankwait:       ; wait for another vblank before continuing
  BIT PPUSTATUS
  BPL vblankwait

  LDA #%10010000  ; turn on NMIs, sprites use first pattern table
  STA PPUCTRL
  LDA #%00011110  ; turn on screen
  STA PPUMASK

forever:
  JMP forever
.endproc

.proc update_player
  PHP
  PHA
  TXA
  PHA
  TYA
  PHA

  PLA
  TAY
  PLA
  TAX
  PLA
  PLP
  RTS
.endproc

.proc draw_texture
  ; save registers
  PHP
  PHA
  TXA
  PHA
  TYA
  PHA

  ; write player ship tile numbers
  LDA player_index01
  STA $0201,Y
  LDA player_index02
  STA $0205,Y
  LDA player_index03
  STA $0209,Y
  LDA player_index04
  STA $020d,Y

  ; write player ship tile attributes
  ; use palette 0
  LDA #$00
  STA $0202,Y
  STA $0206,Y
  STA $020a,Y
  STA $020e,Y

  ; store tile locations
  ; top left tile:
  LDA player_y
  STA $0200,Y
  LDA player_x
  STA $0203,Y

  ; top right tile (x + 8):
  LDA player_y
  STA $0204,Y
  LDA player_x
  CLC
  ADC #$08
  STA $0207,Y

  ; bottom left tile (y + 8):
  LDA player_y
  CLC
  ADC #$08
  STA $0208,Y
  LDA player_x
  STA $020b,Y

  ; bottom right tile (x + 8, y + 8)
  LDA player_y
  CLC
  ADC #$08
  STA $020c,Y
  LDA player_x
  CLC
  ADC #$08
  STA $020f,Y

  ; restore registers and return
  PLA
  TAY
  PLA
  TAX
  PLA
  PLP
  RTS
.endproc

.segment "VECTORS"
.addr nmi_handler, reset_handler, irq_handler

.segment "RODATA"
palettes:
.byte $30, $36, $21, $0f
.byte $0f, $2b, $3c, $39
.byte $0f, $0c, $07, $13
.byte $0f, $19, $09, $29

.byte $0f, $21, $36, $30
.byte $0f, $19, $09, $29
.byte $0f, $19, $09, $29
.byte $0f, $19, $09, $29

.segment "CHR"
.incbin "labgraphics.chr"
