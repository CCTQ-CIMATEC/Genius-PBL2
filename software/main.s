IDLE: //obtem os dados de configuração 

li s0, 2 //isso corresponde a 0010, 0 para o modo jogo siga, 1 para o modo de jogo rapido e 00 para dificuldade, obviamente isso terá que vim de algum outro ponto no futuro
li t0, 1
bnez  GEN_NUMBER
J IDLE; 

 

GEN_NUMBER: 
    andi t0, s0, 0b1  //verificando se modo jogo é siga ou mando eu t0 = s0 & 1
    beqz t0, use_random_number         //Se modo de jogo == 0, vai para use_random_number
    beqz s4, use_random_number         //Se tamanho da sequencia == 0, vai para use_random_number

use_player_input:
    andi t0, s4, 0b11   
    j select_where_save

use_random_number:
    andi t0, s8, 0b11           

select_where_save:
    
    slli    t1, s3, 1         //obtenção do indice na posição no array de 2 bits

    li      t2, 0b11          //criação de uma mascara do tipo 0000110000
    sllv    t2, t2, t1        //colocando o 11 na posição da cor a ser inserida
    not     t3, t2            //criação de uma mascará para deixar os bits da posição selecionada ou seja 111001111
    
    li t4, 16
    bge s3, t4, save_led_sequence_reg2

save_led_sequence_reg1:
    sllv    t1, t1, t2        //coloca a cor na posição correta
    and     s1, s1, t3        //Aplicando mascara
    or      s1, s1, t1        //Atualiza o vetor s1 com a cor na posição de destino
    j continue_generate


save_led_sequence_reg2:
    sllv    t1, t1, t2        //coloca a cor na posição correta
    and     s2, s2, t3        //Aplicando mascara
    or      s2, s2, t1        //Atualiza o vetor s1 com a cor na posição de destino

continue_generate:
    addi s4, s4, 1
    li s3, 0

SHOW_LEDS:
    slli t0, s3, 1            //indice
    li t4, 16
    bge s3, t4, read_led_sequence_reg2

read_led_sequence_reg1:
    srl  t2, s1, t0
    andi t2, t2, 0b11 
    j continue_show_leds

read_led_sequence_reg2:
    srl  t2, s2, t0
    andi t2, t2, 0b11

continue_show_leds:
    li s6, 1 //nesse ponto t2 possui qual a cor deve ser acionada e s6 informa que o led deve ser acesso, falta apartir disso, exibir, contar 1s e desligar(s6 = 0)
    addi s3, s3, 1 
    bgt s3, s5 SHOW_LEDS 


RESET: 
    li s3, 0  

GET_PLAYER: 
    li s5, 2 //ok, isso ta merda, mas vamos assumir que o usuario sempre vai digitar a cor correspondente a 10
... //obtem o valor do player em s5,  

COMPARE: 
    slli t0, s3, 1            //indice
    li t4, 16
    bge s3, t4, read_led_sequence_reg2

read_led_sequence_reg1:
    srl  t2, s1, t0
    andi t2, t2, 0b11 
    j continue_compare

read_led_sequence_reg2:
    srl  t2, s2, t0
    andi t2, t2, 0b11

continue_compare:

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