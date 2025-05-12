#ifndef RIPES_IO_HEADER
#define RIPES_IO_HEADER
// *****************************************************************************
// * SWITCHES_0
// *****************************************************************************
#define SWITCHES_0_BASE	(0xf0000020)
#define SWITCHES_0_SIZE	(0x4)
#define SWITCHES_0_N	(0x8)

// *****************************************************************************
// * LED_MATRIX_0
// *****************************************************************************
#define LED_MATRIX_0_BASE	(0xf0000000)
#define LED_MATRIX_0_SIZE	(0x10)
#define LED_MATRIX_0_WIDTH	(0x2)
#define LED_MATRIX_0_HEIGHT	(0x2)

// *****************************************************************************
// * D_PAD_0
// *****************************************************************************
#define D_PAD_0_BASE	(0xf0000010)
#define D_PAD_0_SIZE	(0x10)
#define D_PAD_0_UP_OFFSET	(0x0)
#define D_PAD_0_UP	(0xf0000010)
#define D_PAD_0_DOWN_OFFSET	(0x4)
#define D_PAD_0_DOWN	(0xf0000014)
#define D_PAD_0_LEFT_OFFSET	(0x8)
#define D_PAD_0_LEFT	(0xf0000018)
#define D_PAD_0_RIGHT_OFFSET	(0xc)
#define D_PAD_0_RIGHT	(0xf000001c)


#endif // RIPES_IO_HEADER

#LED REGISTER 0xRGB - ONLY 24 BITS
.equ RED_LED,       0x00FF0000
.equ GREEN_LED,     0x0000FF00
.equ BLUE_LED,      0x000000FF 
.equ YELLOW_LED,    0x00FFFF00

#GAMEMODE
.equ GM_SIGA        0X0
.equ GM_ME          0X1

#VELOCITY
.equ SLOW           0X0
.equ FAST           0X1

#DIFFICULTY
.equ veasy          0x00
.equ easy           0x01
.equ medium         0x10
.equ hard           0x11

.data
sequence: .word 0, 0

.text
.globl main

main:
    # a0: base memory address of led matrix
    # a1: base memory address of D PAD
    # a2: base memory address of the switchs
    li a0, LED_MATRIX_0_BASE
    li a1, D_PAD_0_BASE
    li a2, SWITCHES_0_BASE



    j ST_IDLE

    ret

ST_IDLE:
    li, s
    lw t2, 0(a1)     #read up pad = start

    lw t3, 0(a2)     # read current sw configs
    andi s0, t3, 0xF # saving on s0 with only the 4 first bits

    beq t2, zero, ST_IDLE   

ST_GEN:

    ret


lfsr: