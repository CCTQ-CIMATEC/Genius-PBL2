#LED REGISTER 0xRGB - ONLY 24 BITS
.equ RED_LED,       0x00FF0000
.equ BLUE_LED,      0x000000FF 
.equ GREEN_LED,     0x0000FF00
.equ YELLOW_LED,    0x00FFFF00

.equ BLACK          0x00000000

#COLORS CODE
.equ RED_CODE       0x0
.equ BLUE_CODE      0x1
.equ GREEN_CODE     0x2
.equ YELLOW_CODE    0x3

#GAMEMODE
.equ GM_SIGA        0X0
.equ GM_ME          0X1

.data
led_values:     .word RED_LED, BLUE_LED, GREEN_LED, YELLOW_LED
sequence:       .word 0

.text
.globl main

main:
    li a0, LED_MATRIX_0_BASE
    li a1, D_PAD_0_BASE
    li a2, SWITCHES_0_BASE

    la s2, sequence #address sequence
    li s4, 0x0      #current score
    li s8, 0x0      #seed

    j ST_IDLE

    ret

ST_IDLE:
    
    addi s8, s8, 0x1
    lw t2, 0(a1)     #read up pad = start

    lw t3, 0(a2)     # read current sw configs
    andi s0, t3, 0xF # saving on s0 with only the 4 first bits

    beqz t2, ST_IDLE   

    li s4, 0

    li t0, 0x4
    srli s9, s0, 2
    sll s9, t0, s9    
    
    li t0, 0xA
    srli s10, s0, 1
    andi s10, s10, 0x1
    srl s10, t0, s10

    li t1, BLACK
    sw t1, 0(a0)
    sw t1, 4(a0)
    sw t1, 8(a0)
    sw t1, 12(a0)

ST_GEN:
    #feedback fb = bit0 xor bit1 
    andi t4, s8, 0x1
    srli t5, s8, 1
    andi t5, t5, 0x1
    xor t4, t4, t5

    #sequence update
    srli s8, s8, 1
    slli t5, t4, 3
    or s8, s8, t5

    #rnd [1:0]
    andi t6, s8, 0x3

    slli t1, s4, 2          # t1 = s4 * 4 (word offset)
    add  t2, s2, t1         # t2 = sequence[s4]
    sw   t6, 0(t2)          # store rnd (2 bits)

    addi s4, s4, 1
    li t0, 0

ST_SHOW_LEDS:
    slli t5, t0, 2          # Calculate word offset for sequence index
    add t6, s2, t5          # Address of sequence[t0]
    lw a3, 0(t6)            # Load color code into a3

    la t1, led_values       # Load address of LED values table
    slli t2, a3, 2          # Calculate word offset for color code
    add t1, t1, t2          # Address of led_values[code]
    lw t3, 0(t1)            # Load LED value from table

    slli t4, a3, 2          # Calculate LED matrix offset (code * 4)
    add t4, a0, t4          # Address of LED in matrix
    sw t3, 0(t4)            # Light up the corresponding LED

    addi t6, s10, 0         # Delay counter
    
    DELAY:
        addi t6, t6, -1
        bnez t6, DELAY
        li t1, BLACK
        sw t1, 0(a0)
        sw t1, 4(a0)
        sw t1, 8(a0)
        sw t1, 12(a0)

    RETURN:
        addi t0, t0, 1              # Increment sequence index
        bne s4, t0, ST_SHOW_LEDS    # Loop if not all LEDs shown
        li t0, 0x0                  # restart index
        li t1, 0x0
        li t2, 0x0
        li t3, 0x0
        li t4, 0x0
        li t5, 0x0

ST_PLAYER_IN:
    li s1, 0    #sequence index counter
    
    LOOP_IN:
        slli t0, s1, 2
        add t0, s2, t0
        lw t6, 0(t0)    # expected color

        lw t1, D_PAD_0_UP       #UP - RED
        bnez t1, BLINK_RED
        lw t1, D_PAD_0_RIGHT    # RIGH - BLUE
        bnez t1, BLINK_BLUE
        lw t1, D_PAD_0_LEFT     # LEFT - GREEN
        bnez t1, BLINK_GREEN
        lw t1, D_PAD_0_DOWN     # DOWN - YELLOW
        bnez t1, BLINK_YELLOW

        j LOOP_IN

    BLINK_RED:
        li t2, RED_LED
        sw t2, 0(a0)
        RR: lw t1, D_PAD_0_UP
            bnez t1 RR
        li t3, RED_CODE
        j COMP

    BLINK_BLUE:
        li t2, BLUE_LED
        sw t2, 4(a0)
        RB: lw t1, D_PAD_0_RIGHT
            bnez t1 RB
        li t3, BLUE_CODE
        j  COMP

    BLINK_GREEN:
        li t2, GREEN_LED
        sw t2, 8(a0)
        RG: lw t1, D_PAD_0_LEFT
            bnez t1 RG
        li t3, GREEN_CODE
        j  COMP

    BLINK_YELLOW:
        li t2, YELLOW_LED
        sw t2, 12(a0)         
        RY: lw t1, D_PAD_0_DOWN
            bnez t1 RY
        li t3, YELLOW_CODE
        j  COMP

    COMP:
        li t1, BLACK
        sw t1, 0(a0)
        sw t1, 4(a0)
        sw t1, 8(a0)
        sw t1, 12(a0)
        bne t3, t6, LOST
        addi s1, s1, 1
        bne s1, s4, LOOP_IN

ST_EVAL:
    beq s4, s9, VICTORY 
    andi s11, s0, 0x1
    beqz s11, ST_GEN
    j ST_ADD_COLOR

ST_ADD_COLOR:

    LOOP_ADD:
        lw t1, D_PAD_0_UP       # UP - RED
        bnez t1, ADD_RED
        lw t1, D_PAD_0_RIGHT    # RIGH - BLUE
        bnez t1, ADD_BLUE
        lw t1, D_PAD_0_LEFT     # LEFT - GREEN
        bnez t1, ADD_GREEN
        lw t1, D_PAD_0_DOWN     # DOWN - YELLOW
        bnez t1, ADD_YELLOW

        j LOOP_ADD

    ADD_RED:
        li t2, RED_LED
        sw t2, 0(a0)
        RR2: lw t1, D_PAD_0_UP
            bnez t1, RR2
        li t3, RED_CODE
        j STORE 

    ADD_BLUE:
        li t2, BLUE_LED
        sw t2, 4(a0)
        RB2: lw t1, D_PAD_0_UP
            bnez t1, RB2
        li t3, BLUE_CODE
        j STORE

    ADD_GREEN:
        li t2, GREEN_LED
        sw t2, 8(a0)
        RG2: lw t1, D_PAD_0_UP
            bnez t1, RG2
        li t3, GREEN_CODE
        j STORE
    
    ADD_YELLOW:
        li t2, RED_LED
        sw t2, 12(a0)
        RY2: lw t1, D_PAD_0_UP
            bnez t1, RY2
        li t3, RED_CODE

    STORE:

        li t1, BLACK
        sw t1, 0(a0)
        sw t1, 4(a0)
        sw t1, 8(a0)
        sw t1, 12(a0)

        #STORE COLOR
        slli t1, s4, 2          # t1 = s4 * 4 (word offset)
        add  t2, s2, t1         # t2 = sequence[s4]
        sw   t3, 0(t2)          # store rnd (2 bits)

        addi s4, s4, 1
        li t0, 0
        j ST_PLAYER_IN

ST_END:
    LOST:
        li t1, RED_LED
        sw t1, 0(a0)
        sw t1, 4(a0)
        sw t1, 8(a0)
        sw t1, 12(a0)
        j ST_IDLE

    VICTORY:
        li t1, GREEN_LED
        sw t1, 0(a0)
        sw t1, 4(a0)
        sw t1, 8(a0)
        sw t1, 12(a0)
        j ST_IDLE