; PPU Registers
PPUCTRL    = $2000 ; PPU Control Register
PPUMASK    = $2001 ; PPU Mask Register
PPUSTATUS  = $2002 ; PPU Status Register
PPUADDR    = $2006 ; PPU Address Register
PPUDATA    = $2007 ; PPU Data Register
OAMADDR    = $2003 ; OAM Address Register
OAMDMA     = $4014 ; OAM DMA Register for sprite data transfer

; Controller Registers
CONTROLLER1 = $4016 ; Gamepad 1 Input Register
CONTROLLER2 = $4017 ; Gamepad 2 Input Register

; Controller Button Bitmasks
BTN_RIGHT   = %00000001 ; Right button bitmask
BTN_LEFT    = %00000010 ; Left button bitmask
BTN_DOWN    = %00000100 ; Down button bitmask
BTN_UP      = %00001000 ; Up button bitmask
BTN_START   = %00010000 ; Start button bitmask
BTN_SELECT  = %00100000 ; Select button bitmask
BTN_B       = %01000000 ; B button bitmask
BTN_A       = %10000000 ; A button bitmask

PPUSCROLL = $2005

.segment "HEADER"
.byte $4e, $45, $53, $1a  ; NES file header magic string
.byte $02                  ; Number of 16KB PRG-ROM banks
.byte $01                  ; Number of 8KB CHR-ROM banks
.byte %00000001            ; ROM control byte 1: horizontal mirroring, no battery-backed RAM
.byte %00000000            ; ROM control byte 2: no mapper, no four-screen, no trainer
.byte $00                  ; PRG-RAM size (none)
.byte $00                  ; TV system (NTSC)

.segment "ZEROPAGE"
player_x: .res 1           ; Reserve 1 byte for player x-position
player_y: .res 1           ; Reserve 1 byte for player y-position
player_index01: .res 1     ; Reserve 1 byte for player sprite index
player_index02: .res 1
player_index03: .res 1
player_index04: .res 1
player_direction: .res 1   ; Reserve 1 byte for player direction
player_walk_state: .res 1  ; Reserve 1 byte for player walk state
pad1: .res 1               ; Reserve 1 byte for gamepad 1 state
myb: .res 1
mxb: .res 1
hb: .res 1
lb: .res 1
temp: .res 1
stage: .res 1
stageSide: .res 1
nametablehb: .res 1
mi: .res 1

scroll: .res 1
ppuctrl_settings: .res 1

moving: .res 1

endflag: .res 1


collmetatile_x: .res 1
collmetatile_y: .res 1
collmetatile: .res 1
collbyte_index: .res 1
collbyte_offset: .res 1
collbyte: .res 1
collmask: .res 1
collindex: .res 1

checkx: .res 1
checky: .res 1

screen: .res 1
screen_metatile_x: .res 1 

behind: .res 1


.segment "CODE"

.proc irq_handler
  RTI                        ; Return from interrupt
.endproc


.proc check_collision

    PHP                   
    PHA                      
    TXA                       
    PHA              
    TYA                       
    PHA   

    LDA checkx
    CLC
    ADC scroll

    ROR A 
    LSR A
    LSR A
    LSR A

    STA collmetatile_x

    LDA collmetatile_x
    AND #%00001111

    STA screen_metatile_x


    LDA collmetatile_x
    LSR A 
    LSR A
    LSR A
    LSR A

    STA screen

    LDA checky
    LSR A 
    LSR A
    LSR A
    LSR A
    STA collmetatile_y

    LDA collmetatile_y
    ASL A
    ASL A
    ASL A
    ASL A
    CLC
    ADC screen_metatile_x

    STA collbyte_index

    LDA screen_metatile_x
    AND #%11

    STA temp

    LDA #$03
    SEC 
    SBC temp

    ASL A

    STA collbyte_offset


    LDA screen
    CMP #$00
    BNE rightside


    LDA stage
    CMP #%00
    BNE onstage2left

    LDA collbyte_index
    LSR A
    LSR A

    TAX
    LDA stage1left, x

    STA collbyte
    JMP next
onstage2left:
    LDA collbyte_index
    LSR A
    LSR A

    TAX
    LDA stage2left, x

    STA collbyte
    JMP next

  rightside:

      LDA stage
      CMP #%00
      BNE onstage2right

      LDA collbyte_index
      LSR A
      LSR A

      TAX
      LDA stage1right, x

      STA collbyte
      JMP next

onstage2right:

      LDA collbyte_index
      LSR A
      LSR A

      TAX
      LDA stage2right, x

      STA collbyte

  next:

      LDA collbyte_offset
      CMP #$00
      BEQ dontshift

      LDA collbyte_offset
      CMP #$02
      BEQ shift2

      LDA collbyte_offset
      CMP #$04
      BEQ shift4
    
      LDA collbyte_offset
      CMP #$06
      BEQ shift6


  dontshift:

    LDA #%00000011
    STA collmask
    
    LDA collbyte 
    AND collmask

    STA collindex

    JMP end

  shift2:
    LDA #%00001100
    STA collmask
    
    LDA collbyte 
    AND collmask
    LSR A
    LSR A
    STA collindex

    JMP end
  shift4:
    LDA #%00110000
    STA collmask
    
    LDA collbyte 
    AND collmask

    LSR A
    LSR A
    LSR A
    LSR A
    STA collindex

    JMP end
  shift6:
    LDA #%11000000
    STA collmask
    
    LDA collbyte 
    AND collmask
    LSR A
    LSR A
    LSR A
    LSR A
    LSR A
    LSR A

    STA collindex

    JMP end

  end:

      PLA
      TAY
      PLA
      TAX
      PLA
      PLP
      RTS 
.endproc

.proc load_background
    PHP                   
    PHA                      
    TXA                       
    PHA              
    TYA                       
    PHA              

  LDX #$00    ; Initialize row counter

  loopBG:

      LDA stage
      CMP #%00
      BEQ bgstage1left

      LDA stage
      CMP #%10
      BEQ bgstage1right

      LDA stage
      CMP #%01
      BEQ bgstage2left

      LDA stage
      CMP #%11
      BEQ bgstage2right

  bgstage1left:

      LDA stage1left ,X ; Load byte index
      STA mi
      jmp continue

  bgstage1right:

      LDA stage1right ,X ; Load byte index
      STA mi
      jmp continue

  bgstage2left:

      LDA stage2left ,X ; Load byte index
      STA mi
      jmp continue

  bgstage2right:

      LDA stage2right ,X ; Load byte index
      STA mi

  continue:

      TXA
      LSR A
      LSR A
      
      STA myb

      TXA
      AND #$03

      STA mxb

      LDA myb 
      LSR A
      LSR A
      AND #$03

      CLC

      ADC nametablehb

      STA hb

      LDA mxb
      ASL A
      ASL A
      ASL A

      STA temp

      LDA myb
      ASL A
      ASL A
      ASL A
      ASL A
      ASL A
      ASL A
      CLC
      ADC temp

      STA lb

      LDA mi

      AND #%11000000
      LSR A
      LSR A
      LSR A
      LSR A
      LSR A
      LSR A
      STA temp

        
      LDA stage
      CMP #%10
      BEQ dontadd1
      LDA stage
      CMP #%00
      BEQ dontadd1

      INC temp
      INC temp
      INC temp
      INC temp

  dontadd1:
      LDA PPUSTATUS
      LDA hb
      STA PPUADDR
      LDA lb
      STA PPUADDR
      LDA temp
      STA PPUDATA

      INC lb

      LDA PPUSTATUS
      LDA hb
      STA PPUADDR
      LDA lb
      STA PPUADDR
      LDA temp
      STA PPUDATA

      LDA lb
      CLC
      ADC #$1F
      STA lb

      LDA PPUSTATUS
      LDA hb
      STA PPUADDR
      LDA lb
      STA PPUADDR
      LDA temp
      STA PPUDATA

      INC lb

      LDA PPUSTATUS
      LDA hb
      STA PPUADDR
      LDA lb
      STA PPUADDR
      LDA temp
      STA PPUDATA



      ; next 2 bits

      

      LDA mxb
      ASL A
      ASL A
      ASL A

      STA temp

      LDA myb
      ASL A
      ASL A
      ASL A
      ASL A
      ASL A
      ASL A
      CLC
      ADC temp

      STA lb

      INC lb
      INC lb

      LDA mi ; Load byte index
      AND #%00110000

      
      LSR A
      LSR A
      LSR A
      LSR A

      STA temp


      LDA stage
      CMP #%10
      BEQ dontadd2
      LDA stage
      CMP #%00
      BEQ dontadd2

      INC temp
      INC temp
      INC temp
      INC temp


  dontadd2:

      LDA PPUSTATUS
      LDA hb
      STA PPUADDR
      LDA lb
      STA PPUADDR
      LDA temp
      STA PPUDATA

      INC lb

      LDA PPUSTATUS
      LDA hb
      STA PPUADDR
      LDA lb
      STA PPUADDR
      LDA temp
      STA PPUDATA

      LDA lb
      CLC
      ADC #$1F
      STA lb

      LDA PPUSTATUS
      LDA hb
      STA PPUADDR
      LDA lb
      STA PPUADDR
      LDA temp
      STA PPUDATA

      INC lb

      LDA PPUSTATUS
      LDA hb
      STA PPUADDR
      LDA lb
      STA PPUADDR
      LDA temp
      STA PPUDATA


      ; next

      LDA mxb
      ASL A
      ASL A
      ASL A

      STA temp

      LDA myb
      ASL A
      ASL A
      ASL A
      ASL A
      ASL A
      ASL A
      CLC
      ADC temp

      STA lb
      
      INC lb
      INC lb
      INC lb
      INC lb
      LDA mi ; Load byte index

      AND #%00001100
      
      LSR A
      LSR A


      STA temp


      LDA stage
      CMP #%10
      BEQ dontadd3
      LDA stage
      CMP #%00
      BEQ dontadd3

      INC temp
      INC temp
      INC temp
      INC temp


  dontadd3:

      LDA PPUSTATUS
      LDA hb
      STA PPUADDR
      LDA lb
      STA PPUADDR
      LDA temp
      STA PPUDATA

      INC lb

      LDA PPUSTATUS
      LDA hb
      STA PPUADDR
      LDA lb
      STA PPUADDR
      LDA temp
      STA PPUDATA

      LDA lb
      CLC
      ADC #$1F
      STA lb

      LDA PPUSTATUS
      LDA hb
      STA PPUADDR
      LDA lb
      STA PPUADDR
      LDA temp
      STA PPUDATA

      INC lb

      LDA PPUSTATUS
      LDA hb
      STA PPUADDR
      LDA lb
      STA PPUADDR
      LDA temp
      STA PPUDATA

      
      ; next


      LDA mxb
      ASL A
      ASL A
      ASL A

      STA temp

      LDA myb
      ASL A
      ASL A
      ASL A
      ASL A
      ASL A
      ASL A
      CLC
      ADC temp

      STA lb


      INC lb
      INC lb
      INC lb
      INC lb
      INC lb
      INC lb

      LDA mi ; Load byte index

      AND #%00000011

      
      STA temp

      LDA stage
      CMP #%10
      BEQ dontadd4
      LDA stage
      CMP #%00
      BEQ dontadd4

      INC temp
      INC temp
      INC temp
      INC temp

  dontadd4:

      LDA PPUSTATUS
      LDA hb
      STA PPUADDR
      LDA lb
      STA PPUADDR
      LDA temp
      STA PPUDATA

      INC lb

      LDA PPUSTATUS
      LDA hb
      STA PPUADDR
      LDA lb
      STA PPUADDR
      LDA temp
      STA PPUDATA

      LDA lb
      CLC
      ADC #$1F
      STA lb

      LDA PPUSTATUS
      LDA hb
      STA PPUADDR
      LDA lb
      STA PPUADDR
      LDA temp
      STA PPUDATA

      INC lb

      LDA PPUSTATUS
      LDA hb
      STA PPUADDR
      LDA lb
      STA PPUADDR
      LDA temp
      STA PPUDATA

      
      INX         ; Increment byte counter
      CPX #$3C    ; Compare with 60
      BEQ LoadAttribute   ; if at end, avoid jmp loopbg

      JMP loopBG


  LoadAttribute:

    INC lb

    LDA $2002             ; read PPU status to reset the high/low latch
    LDA hb
    STA $2006             ; write the high byte of $23C0 address
    LDA lb
    STA $2006             ; write the low byte of $23C0 address

    LDX #$00
  LoadAttributeLoop:


    LDA stage
    CMP #%00
    BEQ att1left

    LDA stage
    CMP #%01
    BEQ att2left

    LDA stage
    CMP #%10
    BEQ att1right

    LDA stage
    CMP #%11
    BEQ att2right


  att1left:
    LDA stage1leftAttribute, x 
    jmp continue2
  att1right:
    LDA stage1rightAttribute, x 
    jmp continue2
  att2left:
    LDA stage2leftAttribute, x 
    jmp continue2
  att2right:
    LDA stage2rightAttribute, x 

  continue2:

    STA $2007             ; write to PPU
    INX                   ; X = X + 1
    CPX #$40              ; Compare X to hex $08, decimal 8 - copying 8 bytes
    BNE LoadAttributeLoop


    PLA
    TAY
    PLA
    TAX
    PLA
    PLP
    RTS 
.endproc


.proc main
  ; Initial PPU setup

    LDX PPUSTATUS             ; Clear the PPU status register
    LDX #$3f
    STX PPUADDR               ; Set PPU address to $3F00 (palette memory)
    LDX #$00
    STX PPUADDR               ; Reset PPU address low byte

  load_palettes:
    LDA palettes,X            ; Load palette data
    STA PPUDATA               ; Write palette data to PPU
    INX                       ; Increment index
    CPX #$20                  ; Check if all palette data is written
    BNE load_palettes         ; Loop until all data is written



  render_background:
      
      LDA #$24
      STA nametablehb
      LDA #%10
      STA stage
      JSR load_background


      LDA #$20
      STA nametablehb
      LDA #%00
      STA stage
      JSR load_background


      


    ; Wait for vertical blank to start PPU modifications
  vblankwait:
    BIT PPUSTATUS             ; Check VBlank flag
    BPL vblankwait            ; Wait until VBlank starts
    

    LDA #%10010000            ; Enable NMI, use first pattern table for sprites 
    STA ppuctrl_settings
    STA PPUCTRL
    LDA #%00011110            ; Enable rendering
    STA PPUMASK

  forever:

    LDA endflag
    CMP #$00
    BEQ end

    LDA endflag
    CMP #$02
    BEQ end

    LDA endflag
    CMP #$01
    BEQ reachedEnd1

    LDA endflag
    CMP #$03
    BEQ reachedEnd2


  reachedEnd1:

    INC endflag

  SEI                       ; Disable interrupts
  CLD                       ; Clear decimal mode

  LDX #$40
  STX $4017                 ; Disable APU frame IRQ
  LDX #$FF
  TXS                       ; Set stack pointer
  INX
  STX $2000                 ; Write to PPUCTRL
  STX $2001                 ; Write to PPUMASK
  STX $4010                 ; Disable DMC IRQ

  ; Wait for vertical blank to ensure no screen tearing
  BIT $2002
vblankwait2:
  BIT $2002
  BPL vblankwait2


    LDA #$00
    STA scroll
    LDA #$24
    STA nametablehb
    LDA #%11
    STA stage
    JSR load_background




    LDA #$20
    STA nametablehb
    LDA #%01
    STA stage
    JSR load_background

    LDA #$00
    STA player_x
    STA scroll
    LDA #$D0
    STA player_y



vblankwait3:
  BIT $2002
  BPL vblankwait3



    LDA #%10010000            ; Enable NMI, use first pattern table for sprites 
    STA ppuctrl_settings
    STA PPUCTRL
    LDA #%00011110            ; Enable rendering
    STA PPUMASK

    JMP end

  reachedEnd2:
    INC endflag


  end:

    JMP forever               ; Infinite loop
.endproc



.proc nmi_handler
  ; Handle NMI (usually VBlank)


  LDA #$00
  STA OAMADDR               ; Reset OAM address to 0
  LDA #$02
  STA OAMDMA                ; Start OAM DMA transfer

  ; Controller handling and player movement
  JSR read_controller1      ; Read controller 1 state

  ; Update player position based on input
  LDA player_walk_state
  CLC
  ADC #$05                  ; Increment walk state
  STA player_walk_state

  JSR update_player         ; Update player sprite based on controller input

  ; Draw player sprite
  JSR draw_texture          ; Draw textures based on player state

  LDA player_x
  CMP #$EF
  BNE dontchangestage

  INC endflag

dontchangestage:


  LDA scroll
  CMP #$FF ; did we scroll to the end of a nametable?
  BNE set_scroll_positions
  ; if yes,
  ; update base nametable
  LDA ppuctrl_settings
  EOR #%00000001
   ; flip bit #1 to its opposite
  STA ppuctrl_settings
  STA PPUCTRL

  STA scroll

set_scroll_positions:

  LDA moving
  CMP #$00
  BEQ end


  LDA player_direction
  CMP #$00
  BEQ decscroll

  LDA player_direction
  CMP #$02
  BEQ incscroll

  JMP end

decscroll:
  DEC scroll
  JMP end

incscroll:
  INC scroll

end:

  LDA scroll ; x scroll
  STA PPUSCROLL
  LDA #$00 ; y scroll
  STA PPUSCROLL
  RTI                        ; Return from interrupt
.endproc



    
.proc update_player
  ; Update player position and direction based on controller input
    PHP                       ; Save processor status
    PHA                       ; Save accumulator
    TXA                       ; Transfer X to accumulator
    PHA                       ; Save accumulator
    TYA                       ; Transfer Y to accumulator
    PHA                       ; Save accumulator

    LDA #$00
    STA moving
    LDA pad1
    AND #BTN_A
    BEQ check_left

    LDA #$01
    STA endflag
    JMP done_checking


  check_left:

    LDA pad1                  ; Load gamepad state
    AND #BTN_LEFT             ; Check if left button is pressed
    BEQ check_right           ; If not, check right button


    LDA #$00                  ; Set direction to left
    STA player_direction

    LDA player_x 
    SEC
    SBC #$01
    STA checkx
    LDA player_y 
    STA checky


    JSR check_collision

    LDA collindex
    CMP #$01
    BEQ check_right

    LDA collindex
    CMP #$02
    BEQ check_right



    LDA player_x 
    SEC
    SBC #$01
    STA checkx
    LDA player_y 
    CLC
    ADC #$0F
    STA checky


    JSR check_collision

    LDA collindex
    CMP #$01
    BEQ check_up

    LDA collindex
    CMP #$02
    BEQ check_up



    DEC player_x              ; Decrement x-position (move left)

    LDA #$01
    STA moving

    JMP exit                  ; Exit updating

  check_right:
    LDA pad1
    AND #BTN_RIGHT            ; Check if right button is pressed
    BEQ check_up              ; If not, check up button



    LDA #$02                  ; Set direction to right
    STA player_direction

    LDA player_x 
    CLC
    ADC #$10
    STA checkx
    LDA player_y 
    STA checky



    JSR check_collision

    LDA collindex
    CMP #$01
    BEQ check_up

    LDA collindex
    CMP #$02
    BEQ check_up


    LDA player_x 
    CLC
    ADC #$10
    STA checkx
    LDA player_y 
    CLC
    ADC #$0F
    STA checky

    JSR check_collision

    LDA collindex
    CMP #$01
    BEQ check_up

    LDA collindex
    CMP #$02
    BEQ check_up



    INC player_x              ; Increment x-position (move right)

    LDA #$01
    STA moving

    JMP exit                  ; Exit updating

  check_up:
    LDA pad1
    AND #BTN_UP               ; Check if up button is pressed
    BEQ check_down            ; If not, check down button

    LDA #$03                  ; Set direction to up
    STA player_direction

    LDA player_x 
    STA checkx
    LDA player_y 
    SEC
    SBC #$01
    STA checky

    JSR check_collision
    
    LDA collindex
    CMP #$01
    BEQ exit

    LDA collindex
    CMP #$02
    BEQ exit


    LDA player_x 
    CLC
    ADC #$0F
    STA checkx
    LDA player_y 
    SEC
    SBC #$01
    STA checky

    JSR check_collision
    
    LDA collindex
    CMP #$01
    BEQ exit

    LDA collindex
    CMP #$02
    BEQ exit


    DEC player_y
    JMP exit                  ; Exit updating

  check_down:
    LDA pad1
    AND #BTN_DOWN             ; Check if down button is pressed
    BEQ done_checking         ; If not, done checking


    LDA #$01                  ; Set direction to down
    STA player_direction

    LDA player_x 
    STA checkx
    LDA player_y 
    CLC
    ADC #$0F
    STA checky

    JSR check_collision
    
    LDA collindex
    CMP #$01
    BEQ exit

    LDA collindex
    CMP #$02
    BEQ exit

    LDA player_x 
    CLC
    ADC #$0F
    STA checkx
    LDA player_y 
    CLC
    ADC #$10
    STA checky

    JSR check_collision
    
    LDA collindex
    CMP #$01
    BEQ exit

    LDA collindex
    CMP #$02
    BEQ exit


    INC player_y

    JMP exit                  ; Exit updating

  done_checking:
    LDA #$00                  ; Reset walk state
    STA player_walk_state

  exit:

    LDA player_x 
    STA checkx
    LDA player_y 
    STA checky
    LDA #$00
    STA behind
    JSR check_collision

    LDA collindex
    CMP #$03
    BEQ isbehind

    LDA player_x 
    CLC 
    ADC #$0F
    STA checkx
    LDA player_y 
    STA checky

    JSR check_collision

    LDA collindex
    CMP #$03
    BEQ isbehind

    LDA player_x 
    STA checkx
    LDA player_y 
    CLC 
    ADC #$0F
    STA checky

    JSR check_collision

    LDA collindex
    CMP #$03
    BEQ isbehind

    LDA player_x 
    CLC
    ADC #$0F
    STA checkx
    LDA player_y 
    CLC 
    ADC #$0F
    STA checky

    JSR check_collision

    LDA collindex
    CMP #$03
    BEQ isbehind

    JMP out

  isbehind:
    LDA #$01
    STA behind

  out: 


    PLA                       ; Restore accumulator from stack
    TAY                       ; Transfer accumulator to Y
    PLA                       ; Restore accumulator from stack
    TAX                       ; Transfer accumulator to X
    PLA                       ; Restore accumulator from stack
    PLP                       ; Restore processor status
    RTS                       ; Return from subroutine
.endproc

.proc draw_texture
    ; Draw player texture based on direction and animation state
    PHP                       ; Save processor status
    PHA                       ; Save accumulator
    TXA                       ; Transfer X to accumulator
    PHA                       ; Save accumulator
    TYA                       ; Transfer Y to accumulator
    PHA                       ; Save accumulator

    LDA player_walk_state     ; Load current walk state
    CMP #$40                  ; Compare to animation states
    BCC playerInState0        ; Branch to state 0 if less

    LDA player_walk_state
    CMP #$80
    BCC playerInState1        ; Branch to state 1 if less

    LDA player_walk_state
    CMP #$c0
    BCC playerInState2mid     ; Branch to state 2 if less

    JMP playerInState3        ; Jump to state 3

  playerInState0:
    LDA player_direction      ; Load current direction
    CMP #$00                  ; Compare to directions
    BNE skip1                 ; Skip to next if not equal

    ; Set sprite indices for animation state 0, direction 0
    LDA #$03
    STA player_index01
    LDA #$04
    STA player_index02
    LDA #$13
    STA player_index03
    LDA #$14
    STA player_index04

    JMP exit                  ; Exit drawing

  skip1:
    LDA player_direction
    CMP #$01
    BNE skip2

    ; Set sprite indices for animation state 0, direction 1
    LDA #$09
    STA player_index01
    LDA #$0a
    STA player_index02
    LDA #$19
    STA player_index03
    LDA #$1a
    STA player_index04

    JMP exit                  ; Exit drawing

  skip2:
    LDA player_direction
    CMP #$02
    BNE skip3

    ; Set sprite indices for animation state 0, direction 2
    LDA #$23
    STA player_index01
    LDA #$24
    STA player_index02
    LDA #$33
    STA player_index03
    LDA #$34
    STA player_index04

    JMP exit                  ; Exit drawing

  skip3:
    ; Set sprite indices for animation state 0, direction 3
    LDA #$29
    STA player_index01
    LDA #$2a
    STA player_index02
    LDA #$39
    STA player_index03
    LDA #$3a
    STA player_index04

    JMP exit                  ; Exit drawing

  playerInState2mid:
    JMP playerInState2        ; Continue to state 2

  playerInState1:
    LDA player_direction
    CMP #$00
    BNE skip4

    ; Set sprite indices for animation state 1, direction 0
    LDA #$01
    STA player_index01
    LDA #$02
    STA player_index02
    LDA #$11
    STA player_index03
    LDA #$12
    STA player_index04

    JMP exit                  ; Exit drawing

  skip4:
    LDA player_direction
    CMP #$01
    BNE skip5

    ; Set sprite indices for animation state 1, direction 1
    LDA #$07
    STA player_index01
    LDA #$08
    STA player_index02
    LDA #$17
    STA player_index03
    LDA #$18
    STA player_index04

    JMP exit                  ; Exit drawing

  skip5:
    LDA player_direction
    CMP #$02
    BNE skip6

    ; Set sprite indices for animation state 1, direction 2
    LDA #$21
    STA player_index01
    LDA #$22
    STA player_index02
    LDA #$31
    STA player_index03
    LDA #$32
    STA player_index04

    JMP exit                  ; Exit drawing

  skip6:
    ; Set sprite indices for animation state 1, direction 3
    LDA #$27
    STA player_index01
    LDA #$28
    STA player_index02
    LDA #$37
    STA player_index03
    LDA #$38
    STA player_index04

    JMP exit                  ; Exit drawing

  playerInState2:
    LDA player_direction
    CMP #$00
    BEQ playerWalkLeftState2

    LDA player_direction
    CMP #$01
    BEQ playerWalkDownState2

    LDA player_direction
    CMP #$02
    BEQ playerWalkRightState2

    JMP playerWalkUpState2    ; Continue to respective walking state

  playerInState3:
    LDA player_direction
    CMP #$00
    BEQ playerWalkLeftState3

    LDA player_direction
    CMP #$01
    BEQ playerWalkDownState3

    LDA player_direction
    CMP #$02
    BEQ playerWalkRightState3

    JMP playerWalkUpState3    ; Continue to respective walking state

  playerWalkLeftState2:
    ; Set sprite indices for walking state 2, left direction
    LDA #$03
    STA player_index01
    LDA #$04
    STA player_index02
    LDA #$13
    STA player_index03
    LDA #$14
    STA player_index04

    JMP exit                  ; Exit drawing

  playerWalkDownState2:
    ; Set sprite indices for walking state 2, down direction
    LDA #$09
    STA player_index01
    LDA #$0a
    STA player_index02
    LDA #$19
    STA player_index03
    LDA #$1a
    STA player_index04

    JMP exit                  ; Exit drawing

  playerWalkRightState2:
    ; Set sprite indices for walking state 2, right direction
    LDA #$23
    STA player_index01
    LDA #$24
    STA player_index02
    LDA #$33
    STA player_index03
    LDA #$34
    STA player_index04

    JMP exit                  ; Exit drawing

  playerWalkUpState2:
    ; Set sprite indices for walking state 2, up direction
    LDA #$29
    STA player_index01
    LDA #$2a
    STA player_index02
    LDA #$39
    STA player_index03
    LDA #$3a
    STA player_index04

    JMP exit                  ; Exit drawing

  playerWalkLeftState3:
    ; Set sprite indices for walking state 3, left direction
    LDA #$05
    STA player_index01
    LDA #$06
    STA player_index02
    LDA #$15
    STA player_index03
    LDA #$16
    STA player_index04

    JMP exit                  ; Exit drawing

  playerWalkDownState3:
    ; Set sprite indices for walking state 3, down direction
    LDA #$0b
    STA player_index01
    LDA #$0c
    STA player_index02
    LDA #$1b
    STA player_index03
    LDA #$1c
    STA player_index04

    JMP exit                  ; Exit drawing

  playerWalkRightState3:
    ; Set sprite indices for walking state 3, right direction
    LDA #$25
    STA player_index01
    LDA #$26
    STA player_index02
    LDA #$35
    STA player_index03
    LDA #$36
    STA player_index04

    JMP exit                  ; Exit drawing

  playerWalkUpState3:
    ; Set sprite indices for walking state 3, up direction
    LDA #$2b
    STA player_index01
    LDA #$2c
    STA player_index02
    LDA #$3b
    STA player_index03
    LDA #$3c
    STA player_index04

    JMP exit                  ; Exit drawing

  exit:
    ; Write sprite indices to the PPU
    LDA player_index01
    STA $0201                 ; Write sprite index to PPU
    LDA player_index02
    STA $0205
    LDA player_index03
    STA $0209
    LDA player_index04
    STA $020d

    ; Assign palette 0 to all sprites

    LDA behind
    ASL A
    ASL A
    ASL A
    ASL A
    ASL A


    STA $0202
    STA $0206
    STA $020a
    STA $020e

    ; Set sprite positions based on player x, y coordinates
    ; top left tile:
    LDA player_y
    STA $0200
    LDA player_x
    STA $0203

    ; top right tile (x + 8):
    LDA player_y
    STA $0204
    LDA player_x
    CLC
    ADC #$08
    STA $0207

    ; bottom left tile (y + 8):
    LDA player_y
    CLC
    ADC #$08
    STA $0208
    LDA player_x
    STA $020b

    ; bottom right tile (x + 8, y + 8)
    LDA player_y
    CLC
    ADC #$08
    STA $020c
    LDA player_x
    CLC
    ADC #$08
    STA $020f

    ; Restore processor status and return
    PLA
    TAY
    PLA
    TAX
    PLA
    PLP
    RTS                       ; Return from subroutine
.endproc

.proc read_controller1
  ; Read controller state into pad1
    PHA                       ; Save accumulator
    TXA                       ; Transfer X to accumulator
    PHA                       ; Save accumulator
    PHP                       ; Save processor status

    ; Latch the controller state
    LDA #$01
    STA CONTROLLER1           ; Send latch signal
    LDA #$00
    STA CONTROLLER1           ; Clear latch signal

    LDA #%00000001
    STA pad1                  ; Initialize pad1

  get_buttons:
    LDA CONTROLLER1           ; Read button state
    LSR A                     ; Shift right, move bit 0 to carry flag
    ROL pad1                  ; Rotate left through carry, capture button state in pad1
    BCC get_buttons           ; Loop until all buttons are read

    ; Restore processor status and return
    PLP
    PLA
    TAX
    PLA
    RTS                       ; Return from subroutine
.endproc

.proc reset_handler
  ; Handle system reset
  SEI                       ; Disable interrupts
  CLD                       ; Clear decimal mode

  LDX #$40
  STX $4017                 ; Disable APU frame IRQ
  LDX #$FF
  TXS                       ; Set stack pointer
  INX
  STX $2000                 ; Write to PPUCTRL
  STX $2001                 ; Write to PPUMASK
  STX $4010                 ; Disable DMC IRQ

  ; Wait for vertical blank to ensure no screen tearing
  BIT $2002
vblankwait:
  BIT $2002
  BPL vblankwait

  ; Clear Object Attribute Memory (OAM)
  LDX #$00
  LDA #$FF
clear_oam:
  STA $0200,X               ; Clear OAM entries
  INX
  INX
  INX
  INX
  BNE clear_oam

  ; Initialize player state
  LDA #$00
  STA player_x              ; Set initial player x-coordinate
  LDA #$cf
  STA player_y              ; Set initial player y-coordinate

  LDA #$01
  STA player_index01        ; Set initial sprite indices
  LDA #$02
  STA player_index02
  LDA #$11
  STA player_index03
  LDA #$12
  STA player_index04

  LDA #$00
  STA player_direction      
  STA player_walk_state    
  STA myb
  STA mxb
  STA mi
  STA hb
  STA lb
  STA temp
  STA stage
  STA nametablehb
  STA moving
  STA endflag
  STA collmetatile_x
  STA collmetatile_y
  STA collbyte_index
  STA collbyte_offset
  STA collbyte
  STA collmask
  STA collindex
  STA checkx
  STA checky
  STA collmetatile
  STA screen
  STA screen_metatile_x
  STA behind
  LDA #$00
  STA scroll



  LDA #%00000000
  STA pad1                  ; Initialize gamepad state

vblankwait2:
  BIT $2002
  BPL vblankwait2
  JMP main                  ; Jump to main routine after setup
.endproc

.segment "VECTORS"
.addr nmi_handler, reset_handler, irq_handler ; Set interrupt vectors

.segment "RODATA"
palettes:
  .byte $0f, $00, $01, $30     ; Define palette entries
  .byte $0f, $06, $16, $26
  .byte $0f, $06, $16, $26
  .byte $0f, $09, $19, $29

  .byte $0f, $21, $36, $30
  .byte $0f, $19, $09, $29
  .byte $0f, $19, $09, $29
  .byte $0f, $19, $09, $29


stage1left:
  ; packeted indexes, each 2 bits of a byte form a index when converted to hex(to be able to add 4 incase of stage 2) aka $a6 = 10110110 = $02, $03, $01, $02, each of these would be used to print a metatile  
  .byte $00,$00,$00,$00
  .byte $00,$00,$00,$00
  .byte $55,$55,$55,$55
  .byte $40,$ff,$b0,$00
  .byte $4a,$eb,$ba,$ea
  .byte $43,$80,$3e,$c0
  .byte $43,$ba,$ae,$aa
  .byte $48,$80,$2e,$00
  .byte $40,$aa,$ea,$ea
  .byte $4b,$c0,$2f,$20
  .byte $48,$aa,$be,$ae
  .byte $48,$80,$3a,$00
  .byte $4f,$ba,$ae,$ea
  .byte $0a,$80,$00,$3f
  .byte $55,$55,$55,$55

stage1leftAttribute:
  ; attributes
	.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$f0,$f0,$e0,$00,$00,$00
	.byte $00,$ca,$2b,$0e,$ce,$ba,$3b,$0a,$00,$2c,$2e,$0a,$8a,$bb,$0a,$0a
	.byte $00,$e0,$3a,$0a,$8b,$fa,$8b,$0a,$00,$22,$2a,$0a,$ce,$ab,$0a,$0b
	.byte $00,$af,$2e,$0a,$0a,$0b,$cb,$fa,$00,$00,$00,$00,$00,$00,$00,$00


stage1right:
  .byte $00,$00,$00,$00
  .byte $00,$00,$00,$00
  .byte $55,$55,$55,$55
  .byte $33,$80,$a8,$05
  .byte $aa,$8a,$e8,$85
  .byte $cc,$cf,$08,$85
  .byte $aa,$8a,$80,$a5
  .byte $00,$80,$b8,$05
  .byte $aa,$a2,$ba,$a5
  .byte $0b,$fe,$f8,$05
  .byte $aa,$ab,$e0,$a5
  .byte $03,$3c,$a2,$25
  .byte $aa,$aa,$30,$25
  .byte $00,$00,$20,$01
  .byte $55,$55,$55,$55


stage1rightAttribute:
	.byte $00,$00,$00,$00,$00,$00,$00,$00,$c0,$c0,$20,$00,$a0,$20,$00,$00
	.byte $3a,$3a,$32,$fa,$0b,$22,$22,$00,$0a,$0a,$22,$0a,$e2,$20,$0a,$00
	.byte $0a,$ea,$fa,$b8,$fe,$2a,$0a,$00,$0a,$ca,$ca,$3e,$ab,$80,$8a,$00
	.byte $0a,$0a,$0a,$0a,$8c,$00,$08,$00,$00,$00,$00,$00,$00,$00,$00,$00

stage2left:
  .byte $00,$00,$00,$00
  .byte $00,$00,$00,$00
  .byte $55,$55,$55,$55
  .byte $70,$f8,$80,$2a
  .byte $4a,$ac,$0b,$83
  .byte $48,$fe,$ac,$2a
  .byte $48,$20,$3a,$c3
  .byte $4a,$88,$88,$aa
  .byte $4c,$02,$88,$b0
  .byte $4e,$bb,$80,$88
  .byte $6a,$ba,$ba,$ab
  .byte $4c,$00,$f0,$0e
  .byte $4a,$a8,$ab,$aa
  .byte $0c,$08,$83,$b0
  .byte $55,$55,$55,$55


stage2leftAttribute:
	.byte $00,$00,$00,$00,$00,$00,$00,$00,$c0,$00,$f0,$20,$20,$00,$80,$a0
	.byte $00,$2a,$fa,$b3,$a0,$3e,$82,$ac,$00,$a2,$28,$20,$2c,$2a,$a3,$ac
	.byte $00,$b3,$e0,$e8,$22,$02,$2e,$20,$08,$3a,$0e,$0a,$fe,$0a,$0a,$be
	.byte $00,$3a,$0a,$22,$2a,$ce,$ea,$0a,$00,$00,$00,$00,$00,$00,$00,$00

stage2right:

.byte $00,$00,$00,$00
.byte $00,$00,$00,$00
.byte $55,$55,$55,$55
.byte $80,$3f,$a0,$25
.byte $0b,$bb,$be,$25
.byte $ab,$80,$3e,$05
.byte $00,$8b,$88,$25
.byte $b8,$8b,$a8,$85
.byte $02,$08,$00,$a5
.byte $a2,$af,$ea,$05
.byte $00,$82,$0f,$e5
.byte $88,$8a,$aa,$a5
.byte $8a,$0f,$00,$25
.byte $03,$2a,$a2,$00
.byte $55,$55,$55,$55

stage2rightAttribute:
	.byte $00,$00,$00,$00,$00,$00,$00,$00,$20,$00,$c0,$f0,$a0,$00,$80,$00
	.byte $a0,$ee,$2e,$0e,$ce,$bb,$08,$03,$e0,$20,$22,$ee,$a2,$22,$28,$02
	.byte $a0,$88,$a0,$f2,$b0,$a0,$0a,$03,$20,$20,$22,$a8,$a0,$af,$ab,$03
	.byte $02,$ca,$80,$af,$a0,$80,$08,$02,$00,$00,$00,$00,$00,$00,$00,$00


.segment "CHR"
.incbin "labgraphics.chr"    ; Include character ROM data