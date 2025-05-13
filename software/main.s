#LED REGISTER 0xRGB - ONLY 24 BITS
.equ RED_LED,       0x00FF0000
.equ GREEN_LED,     0x0000FF00
.equ BLUE_LED,      0x000000FF 
.equ YELLOW_LED,    0x00FFFF00
.equ BLACK,         0x00000000

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
    li a4, GREEN_LED
    li a5, RED_LED
    li a6, BLUE_LED
    li a7, YELLOW_LED

    j IDLE

IDLE: #obtem os dados de configuração 
    lw t0, 0(a2)        # read current sw configs
    andi s0, t0, 0x1F    # saving on s0 with only the 5 first bits
    addi, a3, a3, 1
    li t1, 16
    li s6, 0
    li s4, 0
    li s3, 0
    bge s0, t1, GEN_NUMBER
    j IDLE

GEN_NUMBER: 
    andi t0, s0, 0b1  #verificando se modo jogo é siga ou mando eu t0 = s0 & 1
    beqz t0, USE_RANDOM_NUMBER         #Se modo de jogo == 0, vai para use_random_number
    beqz s4, USE_RANDOM_NUMBER         #Se tamanho da sequencia == 0, vai para use_random_number

    USE_PLAYER_INPUT:
        lw t0, 0(a1)
        lw t1, 4(a1)
        lw t2, 8(a1)
        lw t3, 12(a1)

        # Verifica botão green
        bnez t0, BUTTON_GREEN_PRESSED_MANDO_EU

        # Verifica botão red
        bnez t1, BUTTON_RED_PRESSED_MANDO_EU

        # Verifica botão blue
        bnez t2, BUTTON_BLUE_PRESSED_MANDO_EU

        # Verifica botão yellow
        bnez t3, BUTTON_YELLOW_PRESSED_MANDO_EU

        # Nenhum botão pressionado, repete
        j USE_PLAYER_INPUT

        BUTTON_GREEN_PRESSED_MANDO_EU:
            li t0, 0
            lw t1, 0(a1)
            bnez t1, BUTTON_GREEN_PRESSED_MANDO_EU
            j SELECT_WHERE_SAVE

        BUTTON_RED_PRESSED_MANDO_EU:
            li t0, 1
            lw t1, 4(a1)
            bnez t1, BUTTON_RED_PRESSED_MANDO_EU
            j SELECT_WHERE_SAVE

        BUTTON_BLUE_PRESSED_MANDO_EU:
            li t0, 2
            lw t1, 8(a1)
            bnez t1, BUTTON_BLUE_PRESSED_MANDO_EU
            j SELECT_WHERE_SAVE

        BUTTON_YELLOW_PRESSED_MANDO_EU:
            li t0, 3
            lw t1, 12(a1)
            bnez t1, BUTTON_YELLOW_PRESSED_MANDO_EU
            j SELECT_WHERE_SAVE

    USE_RANDOM_NUMBER:
        li t0, 0          # t0 = feedback bit (zero no início)
        mv t1, a3         # t1 = copia da seed

        # Extrai os bits necessários para o feedback (taps: 31, 21, 1, 0)
        srli t2, t1, 31   # t2 = bit 31
        andi t2, t2, 1

        srli t3, t1, 21   # t3 = bit 21
        andi t3, t3, 1

        srli t4, t1, 1    # t4 = bit 1
        andi t4, t4, 1

        andi t5, t1, 1    # t5 = bit 0

        # XOR dos bits: t2 ^ t3 ^ t4 ^ t5 -> feedback bit
        xor t6, t2, t3
        xor t6, t6, t4
        xor t6, t6, t5    # t6 = feedback

        # Shift à direita e insere o feedback no MSB
        srli t1, t1, 1    # t1 = seed >> 1
        slli t6, t6, 31   # t6 = feedback << 31
        or t1, t1, t6     # t1 = novo valor da seed (com feedback)

        mv s8, t1         # salva o valor em s8
        mv a3, s8         # usa pseudorandom number como proxima seed
        andi t0, s8, 0b11
        andi t0, s8, 0b11           

    SELECT_WHERE_SAVE:
        
        slli    t1, s3, 1         #obtenção do indice na posição no array de 2 bits

        li      t2, 0b11          #criação de uma mascara do tipo 0000110000
        sll    t2, t2, t1        #colocando o 11 na posição da cor a ser inserida
        not     t3, t2            #criação de uma mascará para deixar os bits da posição selecionada ou seja 111001111
        
        li t4, 16
        bge s3, t4, SAVE_LED_SEQUENCE_REG2

        SAVE_LED_SEQUENCE_REG1:
            sll     t1, t0, t1        #coloca a cor na posição correta
            and     s1, s1, t3        #Aplicando mascara
            or      s1, s1, t1        #Atualiza o vetor s1 com a cor na posição de destino
            j CONTINUE_GENERATE


        SAVE_LED_SEQUENCE_REG2:
            sll     t1, t0, t1        #coloca a cor na posição correta
            and     s2, s2, t3        #Aplicando mascara
            or      s2, s2, t1        #Atualiza o vetor s1 com a cor na posição de destino

    CONTINUE_GENERATE:
        addi s4, s4, 1
        li s3, 0

SHOW_LEDS:
    slli t0, s3, 1            #indice
    li t4, 16
    bge s3, t4, SHOW_READ_LED_SEQUENCE_REG2

    SHOW_READ_LED_SEQUENCE_REG1:
        srl  t2, s1, t0
        andi t2, t2, 0b11
        j CONTINUE_SHOW_LEDS

    SHOW_READ_LED_SEQUENCE_REG2:
        srl  t2, s2, t0
        andi t2, t2, 0b11

    CONTINUE_SHOW_LEDS:
        li t0, BLACK         # t0 = preto (apagado por padrão)
        
        addi s3, s3, 1
        ble s3, s4, ONE_LED_ON
        j RESET

    ONE_LED_ON:
        li t3, 2           # TEMPO BASE DE DELAY (2)
        andi t4, s0, 2     # Isola o segundo bit menos significativo de s0
        beqz t4, SKIP_SHIFT
        j CHECK_LED

    SKIP_SHIFT:
        slli t3, t3, 1     # Se o bit for 0, dobra t3 (2 -> 4)

    CHECK_LED:
        li t1, 0
        beq t2, t1, SHOW_GREEN_LED
        li t1, 1
        beq t2, t1, SHOW_RED_LED
        li t1, 2
        beq t2, t1, SHOW_BLUE_LED
        li t1, 3
        beq t2, t1, SHOW_YELLOW_LED
        
        j CONTINUE_SHOW_LEDS

    SHOW_GREEN_LED:
        sw a4, 0(a0)     # verde
        sw t0, 4(a0)     # preto
        sw t0, 8(a0)     # preto
        sw t0, 12(a0)    # preto
        j AWAIT_LEDS_TURN_ON

    SHOW_RED_LED:
        sw t0, 0(a0)
        sw a5, 4(a0)
        sw t0, 8(a0)
        sw t0, 12(a0)
        j AWAIT_LEDS_TURN_ON

    SHOW_BLUE_LED:
        sw t0, 0(a0)
        sw t0, 4(a0)
        sw a6, 8(a0)
        sw t0, 12(a0)
        j AWAIT_LEDS_TURN_ON

    SHOW_YELLOW_LED:
        sw t0, 0(a0)
        sw t0, 4(a0)
        sw t0, 8(a0)
        sw a7, 12(a0)
        j AWAIT_LEDS_TURN_ON
        


    AWAIT_LEDS_TURN_ON:
        addi t3, t3, -1
        bnez t3, AWAIT_LEDS_TURN_ON

    TURN_OFF_ALL_LEDS:
        sw t0, 0(a0)
        sw t0, 4(a0)
        sw t0, 8(a0)
        sw t0, 12(a0)
        li t3, 5           # TEMPO BASE DE DELAY (5)
        andi t4, s0, 2     # Isola o segundo bit menos significativo de s0
        beqz t4, SKIP_SHIFT_2
        j AWAIT_LEDS_TURN_OFF

    SKIP_SHIFT_2:
        slli t3, t3, 1 

    AWAIT_LEDS_TURN_OFF:
        addi t3, t3, -1
        bnez t3, AWAIT_LEDS_TURN_OFF
        li t5, 1
        bgt s6, t5, IDLE
        j   SHOW_LEDS

RESET: 
    li s3, 0  

GET_PLAYER: 
    lw t0, 0(a1)
    lw t1, 4(a1)
    lw t2, 8(a1)
    lw t3, 12(a1)

    # Verifica botão green
    bnez t0, BUTTON_GREEN_PRESSED

    # Verifica botão red
    bnez t1, BUTTON_RED_PRESSED

    # Verifica botão blue
    bnez t2, BUTTON_BLUE_PRESSED

    # Verifica botão yellow
    bnez t3, BUTTON_YELLOW_PRESSED

    # Nenhum botão pressionado, repete
    j GET_PLAYER

    BUTTON_GREEN_PRESSED:
        li s5, 0
        lw t0, 0(a1)
        bnez t0, BUTTON_GREEN_PRESSED
        j COMPARE

    BUTTON_RED_PRESSED:
        li s5, 1
        lw t1, 4(a1)
        bnez t1, BUTTON_RED_PRESSED
        j COMPARE

    BUTTON_BLUE_PRESSED:
        li s5, 2
        lw t2, 8(a1)
        bnez t2, BUTTON_BLUE_PRESSED
        j COMPARE

    BUTTON_YELLOW_PRESSED:
        li s5, 3
        lw t3, 12(a1)
        bnez t3, BUTTON_YELLOW_PRESSED
        j COMPARE


COMPARE: 
    slli t0, s3, 1            #indice
    li t4, 16
    bge s3, t4, READ_LED_SEQUENCE_REG2

    READ_LED_SEQUENCE_REG1:
        srl  t2, s1, t0
        andi t2, t2, 0b11 
        j CONTINUE_COMPARE

    READ_LED_SEQUENCE_REG2:
        srl  t2, s2, t0
        andi t2, t2, 0b11

    CONTINUE_COMPARE:
        bne t2, s5, DEFEAT
        addi s3, s3, 1
        bge s3, s4 EVALUATE 
        j GET_PLAYER

EVALUATE: 
    srli t0, s0, 2
    andi t0, t0, 0b11
    li t1, 8
    sll t1, t1, t0
    beq s4, t1, VICTORY
    j GEN_NUMBER

VICTORY: 
    li t3, 5
    li s6, 2 #all  leds habilitados, precisa configurar o tempo que isso vai ficar ligado
    j ALL_LED_VICTORY

    ALL_LED_VICTORY:
        sw a4, 0(a0)     # LED 0 = verde
        sw a5, 4(a0)     # LED 1 = vermelho
        sw a6, 8(a0)     # LED 2 = azul
        sw a7, 12(a0)    # LED 3 = amarelo

        j AWAIT_LEDS_TURN_ON_VICTORY

    CONTINUE_VICTORY:
        sw a4, 0(a0)     # LED 0 = verde
        sw a5, 4(a0)     # LED 1 = vermelho
        sw a6, 8(a0)     # LED 2 = azul
        sw a7, 12(a0)    # LED 3 = amarelo

        li t3, 5
        j AWAIT_LEDS_TURN_ON
    
    AWAIT_LEDS_TURN_ON_VICTORY:
        addi t3, t3, -1
        bnez t3, AWAIT_LEDS_TURN_ON_VICTORY

    TURN_OFF_LEDS_VICTORY:
        sw t0, 0(a0)
        sw t0, 4(a0)
        sw t0, 8(a0)
        sw t0, 12(a0)
        li t3, 5           # TEMPO BASE DE DELAY (5)
        j AWAIT_LEDS_TURN_OFF_VICTORY

    AWAIT_LEDS_TURN_OFF_VICTORY:
        addi t3, t3, -1
        bnez t3, AWAIT_LEDS_TURN_OFF_VICTORY
        j   CONTINUE_VICTORY

DEFEAT: 
    li t3, 10
    li s6, 2 #all  leds habilitados, precisa configurar o tempo que isso vai ficar ligado
    j ALL_LED_DEFEAT

    ALL_LED_DEFEAT:
        sw a4, 0(a0)     # LED 0 = verde
        sw a5, 4(a0)     # LED 1 = vermelho
        sw a6, 8(a0)     # LED 2 = azul
        sw a7, 12(a0)    # LED 3 = amarelo

        j AWAIT_LEDS_TURN_ON