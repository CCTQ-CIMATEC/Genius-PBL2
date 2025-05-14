# ============= DEFINI��ES DE CORES (24-bit RGB) =============
.equ RED_LED,       0x00FF0000
.equ GREEN_LED,     0x0000FF00
.equ BLUE_LED,      0x000000FF 
.equ YELLOW_LED,    0x00FFFF00
.equ BLACK,         0x00000000

.data
sequence: .word 0, 0    # Espa�o para armazenar a sequ�ncia (n�o utilizado no c�digo atual)

.text
.globl main

main:
    # Inicializa��o dos registradores e endere�os base
    # a0: endere�o memoria base: led matrix
    # a1: endere�o memoria base: D PAD
    # a2: endere�o memoria base: switchs
    li a0, LED_MATRIX_0_BASE
    li a1, D_PAD_0_BASE
    li a2, SWITCHES_0_BASE
    li a3, 1               #seed inicial
    li a4, GREEN_LED
    li a5, RED_LED
    li a6, BLUE_LED
    li a7, YELLOW_LED
    
    #inicializa os registradores s1 e s2 que armazenar�o a sequ�ncia
    li s1, 0
    li s2, 0

    j ST_IDLE

# ===== ESTADO: INICIALIZA��O (AGUARDA START) =====
ST_IDLE: 
    lw t0, 0(a2)            # L� as configura��es atuais das chaves
    andi s0, t0, 0x1F       # Salva em s0 apenas os 5 primeiros bits
    addi a3, a3, 1          # Incrementa seed para o gerador de n�meros aleat�rios
    li t1, 16               # Valor m�nimo para iniciar o jogo
    li s6, 0                # Inicializa flag para controle de estados do jogo
    li s4, 0                # Inicializa tamanho da sequ�ncia atual
    li s3, 0                # Inicializa �ndice atual da sequ�ncia
    bge s0, t1, GEN_NUMBER  # Inicia o jogo se configura��o >= 16
    j ST_IDLE                  # Caso contr�rio, continua no estado IDLE

# ===== ESTADO: GERA SEQU�NCIA =====
GEN_NUMBER: 
    andi t0, s0, 0b1          # Verificando modo de jogo (bit 0 de s0)
                             # t0 = 0: modo "Siga" (sequ�ncia aleat�ria)
                             # t0 = 1: modo "Mando eu" (sequ�ncia add pelo jogador)
    beqz t0, USE_RANDOM_NUMBER  # Se modo de jogo == 0, gera n�mero aleat�rio
    beqz s4, USE_RANDOM_NUMBER  # Se tamanho da sequ�ncia == 0, gera n�mero aleat�rio

# ===== ESTADO: AGUARDA INPUT DO JOGADOR =====
PLAYER_INPUT:         # Modo "Mando eu" - jogador define a sequ�ncia
    lw t0, 0(a1)          # L� bot�o verde
    lw t1, 4(a1)          # L� bot�o vermelho
    lw t2, 8(a1)          # L� bot�o azul
    lw t3, 12(a1)         # L� bot�o amarelo

# Verifica qual bot�o foi pressionado
    bnez t0, BUTTON_GREEN_PRESSED_MANDO_EU
    bnez t1, BUTTON_RED_PRESSED_MANDO_EU
    bnez t2, BUTTON_BLUE_PRESSED_MANDO_EU
    bnez t3, BUTTON_YELLOW_PRESSED_MANDO_EU

#verifica se tem bot�o pressionado se nao, continua a verifica��o
    j PLAYER_INPUT

BUTTON_GREEN_PRESSED_MANDO_EU:
    li t0, 0           # C�digo 0 para verde
# Espera soltar o bot�o
WAIT_GREEN_RELEASE_ME:
    lw t1, 0(a1)
    bnez t1, WAIT_GREEN_RELEASE_ME
    j SELECT_WHERE_SAVE

        BUTTON_RED_PRESSED_MANDO_EU:
            li t0, 1           # C�digo 1 para vermelho
            # Espera soltar o bot�o
            WAIT_RED_RELEASE_ME:
                lw t1, 4(a1)
                bnez t1, WAIT_RED_RELEASE_ME
            j SELECT_WHERE_SAVE

        BUTTON_BLUE_PRESSED_MANDO_EU:
            li t0, 2           # C�digo 2 para azul
            # Espera soltar o bot�o
            WAIT_BLUE_RELEASE_ME:
                lw t1, 8(a1)
                bnez t1, WAIT_BLUE_RELEASE_ME
            j SELECT_WHERE_SAVE

        BUTTON_YELLOW_PRESSED_MANDO_EU:
            li t0, 3           # C�digo 3 para amarelo
            # Espera soltar o bot�o
            WAIT_YELLOW_RELEASE_ME:
                lw t1, 12(a1)
                bnez t1, WAIT_YELLOW_RELEASE_ME
            j SELECT_WHERE_SAVE

    USE_RANDOM_NUMBER:
        # Implementa��o de um gerador de n�meros pseudo-aleat�rios LFSR
        # (Linear Feedback Shift Register)
        li t0, 0          # t0 = feedback bit (zero no in�cio)
        mv t1, a3         # t1 = copia da seed

        # Extrai os bits necess�rios para o feedback (taps: 31, 21, 1, 0)
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

        # Shift � direita e insere o feedback no MSB
        srli t1, t1, 1    # t1 = seed >> 1
        slli t6, t6, 31   # t6 = feedback << 31
        or t1, t1, t6     # t1 = novo valor da seed (com feedback)

        mv a3, t1         # atualiza a seed
        andi t0, t1, 0b11 # t0 = n�mero aleat�rio entre 0-3

    SELECT_WHERE_SAVE:
        # Calcula a posi��o onde salvar o valor na sequ�ncia
        slli t1, s3, 1    # t1 = s3 * 2 (�ndice em bits)

        li t2, 0b11       # t2 = m�scara 0b11
        sll t2, t2, t1    # posiciona a m�scara no local correto
        not t3, t2        # inverte a m�scara para limpar os bits

        li t4, 16
        bge s3, t4, SAVE_LED_SEQUENCE_REG2  # Se �ndice >= 16, usa reg2

        SAVE_LED_SEQUENCE_REG1:
            sll t1, t0, t1    # posiciona o valor no local correto
            and s1, s1, t3    # limpa os bits na posi��o
            or s1, s1, t1     # insere o novo valor
            j CONTINUE_GENERATE

        SAVE_LED_SEQUENCE_REG2:
            sll t1, t0, t1    # posiciona o valor no local correto
            and s2, s2, t3    # limpa os bits na posi��o
            or s2, s2, t1     # insere o novo valor
            j CONTINUE_GENERATE

    CONTINUE_GENERATE:
        addi s4, s4, 1    # incrementa o tamanho da sequ�ncia
        li s3, 0          # reinicia o �ndice
        j SHOW_LED       # vai para exibi��o da sequ�ncia

SHOW_LED:
    slli t0, s3, 1            # t0 = �ndice * 2 (posi��o em bits)
    li t4, 16
    bge s3, t4, SHOW_READ_LED_SEQUENCE_REG2  # Se �ndice >= 16, usa reg2

    SHOW_READ_LED_SEQUENCE_REG1:
        srl t2, s1, t0        # t2 = s1 >> t0 (desloca para direita)
        andi t2, t2, 0b11     # t2 = t2 & 0b11 (obt�m apenas os 2 bits)
        j CONTINUE_SHOW_LEDS

    SHOW_READ_LED_SEQUENCE_REG2:
        srl t2, s2, t0        # t2 = s2 >> t0 (desloca para direita)
        andi t2, t2, 0b11     # t2 = t2 & 0b11 (obt�m apenas os 2 bits)
        j CONTINUE_SHOW_LEDS

    CONTINUE_SHOW_LEDS:
        li t0, BLACK          # t0 = preto (LEDs apagados)
        
        addi s3, s3, 1        # incrementa o �ndice
        ble s3, s4, ONE_LED_ON  # se �ndice <= tamanho, mostra LED
        j RESET               # sen�o, termina de mostrar a sequ�ncia

    ONE_LED_ON:
        li t3, 2              # TEMPO BASE DE DELAY (2)
        andi t4, s0, 2        # Isola o segundo bit de s0 (configura��o de velocidade)
        beqz t4, SKIP_SHIFT   # Se bit == 0, velocidade normal
        j CHECK_LED           # Sen�o, velocidade r�pida

    SKIP_SHIFT:
        slli t3, t3, 1        # Se bit == 0, dobra o tempo (velocidade mais lenta)

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
        sw a4, 0(a0)      # LED 0 = verde
        sw t0, 4(a0)      # LED 1 = preto
        sw t0, 8(a0)      # LED 2 = preto
        sw t0, 12(a0)     # LED 3 = preto
        j AWAIT_LEDS_TURN_ON

    SHOW_RED_LED:
        sw t0, 0(a0)      # LED 0 = preto
        sw a5, 4(a0)      # LED 1 = vermelho
        sw t0, 8(a0)      # LED 2 = preto
        sw t0, 12(a0)     # LED 3 = preto
        j AWAIT_LEDS_TURN_ON

    SHOW_BLUE_LED:
        sw t0, 0(a0)      # LED 0 = preto
        sw t0, 4(a0)      # LED 1 = preto
        sw a6, 8(a0)      # LED 2 = azul
        sw t0, 12(a0)     # LED 3 = preto
        j AWAIT_LEDS_TURN_ON

    SHOW_YELLOW_LED:
        sw t0, 0(a0)      # LED 0 = preto
        sw t0, 4(a0)      # LED 1 = preto
        sw t0, 8(a0)      # LED 2 = preto
        sw a7, 12(a0)     # LED 3 = amarelo
        j AWAIT_LEDS_TURN_ON

    AWAIT_LEDS_TURN_ON:
        addi t3, t3, -1        # decrementa contador de delay
        bnez t3, AWAIT_LEDS_TURN_ON  # espera at� contador = 0

    TURN_OFF_ALL_LEDS:
        sw t0, 0(a0)      # Apaga todos os LEDs
        sw t0, 4(a0)
        sw t0, 8(a0)
        sw t0, 12(a0)
        li t3, 5          # TEMPO BASE DE DELAY (5)
        andi t4, s0, 2    # Isola o segundo bit de s0 (configura��o de velocidade)
        beqz t4, SKIP_SHIFT_2   # Se bit == 0, velocidade normal
        j AWAIT_LEDS_TURN_OFF   # Sen�o, velocidade r�pida

    SKIP_SHIFT_2:
        slli t3, t3, 1    # Se bit == 0, dobra o tempo (velocidade mais lenta)

    AWAIT_LEDS_TURN_OFF:
        addi t3, t3, -1   # decrementa contador de delay
        bnez t3, AWAIT_LEDS_TURN_OFF   # espera at� contador = 0
        
        # Verifica se estamos em um estado especial (vit�ria/derrota)
        li t5, 1
        bgt s6, t5, ST_IDLE      # Se s6 > 1, volta para IDLE (fim de jogo)
        j SHOW_LED           # Sen�o, continua mostrando a sequ�ncia

RESET: 
    li s3, 0              # Reinicia o �ndice para leitura da entrada do jogador

GET_PLAYER: 
    lw t0, 0(a1)          # L� bot�o verde
    lw t1, 4(a1)          # L� bot�o vermelho
    lw t2, 8(a1)          # L� bot�o azul
    lw t3, 12(a1)         # L� bot�o amarelo

    # Verifica qual bot�o foi pressionado
    bnez t0, GREEN_PRESS
    bnez t1, RED_PRESS
    bnez t2, BLUE_PRESS
    bnez t3, YELLOW_PRESS

    # Nenhum bot�o pressionado, repete a verifica��o
    j GET_PLAYER

    GREEN_PRESS:
        li s5, 0          # C�digo 0 para verde
        sw a4, 0(a0)      # LED 0 = verde
        
        # Espera soltar o bot�o
        WAIT_GREEN:
            lw t0, 0(a1)
            bnez t0, WAIT_GREEN
            
        #apaga o LED
        sw t0, 0(a0)
        j COMPARE

    RED_PRESS:
        li s5, 1          # C�digo 1 para vermelho
        # Acende o LED enquanto o bot�o est� pressionado
        sw a5, 4(a0)      # LED 1 = vermelho
        
        # Espera soltar o bot�o
        WAIT_RED_RELEASE:
            lw t1, 4(a1)
            bnez t1, WAIT_RED_RELEASE
            
        # Apaga o LED
        sw t0, 4(a0)
        j COMPARE

    BLUE_PRESS:
        li s5, 2   
 
        sw a6, 8(a0)      # LED 2 = azul
        
        WAIT_BLUE_RELEASE:
            lw t2, 8(a1)
            bnez t2, WAIT_BLUE_RELEASE
        
        sw t0, 8(a0)
        j COMPARE

    YELLOW_PRESS:
        li s5, 3 
        sw a7, 12(a0) 
        
        WAIT_YELLOW_RELEASE:
            lw t3, 12(a1)
            bnez t3, WAIT_YELLOW_RELEASE
            
        # Apaga o LED
        sw t0, 12(a0)
        j COMPARE

COMPARE: 
    slli t0, s3, 1        # t0 = �ndice * 2 (posi��o em bits)
    li t4, 16
    bge s3, t4, READ_LED_SEQUENCE_REG2   # Se �ndice >= 16, usa reg2

    READ_LED_SEQUENCE_REG1:
        srl t2, s1, t0    # t2 = s1 >> t0 (desloca para direita)
        andi t2, t2, 0b11 # t2 = t2 & 0b11 (obt�m apenas os 2 bits)
        j CONTINUE_COMPARE

    READ_LED_SEQUENCE_REG2:
        srl t2, s2, t0    # t2 = s2 >> t0 (desloca para direita)
        andi t2, t2, 0b11 # t2 = t2 & 0b11 (obt�m apenas os 2 bits)
        j CONTINUE_COMPARE

    CONTINUE_COMPARE:
        bne t2, s5, ST_LOST   # Se entrada != sequ�ncia, derrota
        addi s3, s3, 1       # incrementa o �ndice
        bge s3, s4, EVALUATE # Se �ndice >= tamanho, avalia o resultado
        j GET_PLAYER         # Sen�o, continua obtendo entradas

EVALUATE: 
    srli t0, s0, 2        # t0 = s0 >> 2 (obt�m bits de n�vel)
    andi t0, t0, 0b11     # t0 = t0 & 0b11 (obt�m apenas os 2 bits)
    li t1, 8              # tamanho base da sequ�ncia
    sll t1, t1, t0        # t1 = 8 << t0 (tamanho ajustado pelo n�vel)
    beq s4, t1, ST_WIN   # Se tamanho == objetivo, vit�ria
    j GEN_NUMBER          # Sen�o, gera pr�ximo n�mero

ST_WIN:
    # Anima��o de vit�ria - pisca todos os LEDs
    li t3, 5              # tempo de delay
    li s6, 2              # flag de estado especial (vit�ria)
    j ALL_LED_VICTORY

    ALL_LED_VICTORY:
        # Acende todos os LEDs
        sw a4, 0(a0)      # LED 0 = verde
        sw a5, 4(a0)      # LED 1 = vermelho
        sw a6, 8(a0)      # LED 2 = azul
        sw a7, 12(a0)     # LED 3 = amarelo
        j AWAIT_LEDS_TURN_ON_VICTORY

    WIN_CONTINUE:
        sw a4, 0(a0)   
        sw a5, 4(a0)  
        sw a6, 8(a0)  
        sw a7, 12(a0)  
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
        li t3, 5         
        j AWAIT_LEDS_TURN_OFF_VICTORY

    AWAIT_LEDS_TURN_OFF_VICTORY:
        addi t3, t3, -1 
        bnez t3, AWAIT_LEDS_TURN_OFF_VICTORY
        

        addi s6, s6, 1
        li t4, 10
        bge s6, t4, ST_IDLE 
        j WIN_CONTINUE 

ST_LOST: 
  
    li t3, 3            
    li s6, 2             
    j ALL_LED_DEFEAT

    ALL_LED_DEFEAT:
        # Acende todos os LEDs
        sw a5, 0(a0)      
        sw a5, 4(a0)     
        sw a5, 8(a0)     
        sw a5, 12(a0)   
        j AWAIT_LEDS_TURN_ON_DEFEAT

    AWAIT_LEDS_TURN_ON_DEFEAT:
        addi t3, t3, -1
        bnez t3, AWAIT_LEDS_TURN_ON_DEFEAT

    TURN_OFF_LEDS_DEFEAT:

        sw t0, 0(a0)
        sw t0, 4(a0)
        sw t0, 8(a0)
        sw t0, 12(a0)
        li t3, 3          # tempo de delay
        j AWAIT_LEDS_TURN_OFF_DEFEAT

    AWAIT_LEDS_TURN_OFF_DEFEAT:
        addi t3, t3, -1 
        bnez t3, AWAIT_LEDS_TURN_OFF_DEFEAT
        
        addi s6, s6, 1
        li t4, 10
        bge s6, t4, ST_IDLE
        j ALL_LED_DEFEAT 