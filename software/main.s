IDLE: //obtem os dados de configuração 
    li s0, 2 // 0010 → modo siga (0), speed 1, dificuldade 00. Obviamente isso terá que vim de algum outro ponto no futuro
    li t0, 1
    bnez t0, GEN_NUMBER
    J IDLE; 

GEN_NUMBER: 
    andi t0, s0, 0b1  //verificando se modo jogo é siga ou mando eu t0 = s0 & 1
    beqz t0, USE_RANDOM_NUMBER         //Se modo de jogo == 0, vai para use_random_number
    beqz s4, USE_RANDOM_NUMBER         //Se tamanho da sequencia == 0, vai para use_random_number

USE_PLAYER_INPUT:
    andi t0, s4, 0b11
    j SELECT_WHERE_SAVE

USE_RANDOM_NUMBER:
    andi t0, s8, 0b11           

SELECT_WHERE_SAVE:
    
    slli    t1, s3, 1         //obtenção do indice na posição no array de 2 bits

    li      t2, 0b11          //criação de uma mascara do tipo 0000110000
    sllv    t2, t2, t1        //colocando o 11 na posição da cor a ser inserida
    not     t3, t2            //criação de uma mascará para deixar os bits da posição selecionada ou seja 111001111
    
    li t4, 16
    bge s3, t4, SAVE_LED_SEQUENCE_REG2

SAVE_LED_SEQUENCE_REG1:
    sllv    t1, t1, t2        //coloca a cor na posição correta
    and     s1, s1, t3        //Aplicando mascara
    or      s1, s1, t1        //Atualiza o vetor s1 com a cor na posição de destino
    j CONTINUE_GENERATE


SAVE_LED_SEQUENCE_REG2:
    sllv    t1, t1, t2        //coloca a cor na posição correta
    and     s2, s2, t3        //Aplicando mascara
    or      s2, s2, t1        //Atualiza o vetor s1 com a cor na posição de destino

CONTINUE_GENERATE:
    addi s4, s4, 1
    li s3, 0

SHOW_LEDS:
    slli t0, s3, 1            //indice
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
    li s6, 1 //nesse ponto t2 possui qual a cor deve ser acionada e s6 informa que o led deve ser acesso, falta apartir disso, exibir, contar 1s e desligar(s6 = 0)
    addi s3, s3, 1 
    bgt s4, s3, SHOW_LEDS 

RESET: 
    li s3, 0  

GET_PLAYER: 
    li s5, 2 //ok, isso ta merda, mas vamos assumir que o usuario sempre vai digitar a cor correspondente a 10 

COMPARE: 
    slli t0, s3, 1            //indice
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
    addi s3, 1
    bgt s3, s5 EVALUATE 
    J GET_PLAYER; 

EVALUATE: 
    srli t0, s0, 2
    andi t0, t0, 0b11
    li t1, 8
    sll t1, t1, t0
    beq s4, t1, VICTORY
    J GEN_NUMBER

VICTORY: 
    li s6, 2 //all  leds habilitados, precisa configurar o tempo que isso vai ficar ligado
    J IDLE 

DEFEAT: 
    li s6, 2 //all  leds habilitados, precisa configurar o tempo que isso vai ficar ligado
    J IDLE; 