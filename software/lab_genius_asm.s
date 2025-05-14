#.section .text

#.global genius_game

.equ GAME_MODE   , 0b00000000    # Bit  0 = 0       (modo siga)
.equ SPEED_GAME  , 0b00000000    # Bit  1 = 0       (velocidade lenta)
.equ DIFFICULTY  , 0b00000000    # Bits 2 e 3 = 00  (fácil)
.equ START_BIT   , 0b00000000    # Bit  4 = 0       (start pressionado)

genius_game:

#########################################################
#   estado IDLE                                                                                #
#########################################################

ST_IDLE:                             

#########################################################
#   Definindo condição inicial dos registradores        
#      (Caso seja iniciado um novo jogo)                
#########################################################  
 
    li s1, 0                                # reset inicial
    li s2, 0                                # reset inicial
    li s3, 0                                # reset inicial 
    li s4, 0                                # reset inicial 
    li s5, 0                                # reset inicial 
    li s6, 0                                # reset inicial
    li s7, 0                                # reset inicial

#########################################################
#   Configurações do Game                                                                     #
#########################################################

    li  s0, 0                              # Reseta o registrador de configuração do jogo
    ori s0, s0, GAME_MODE                  # Modo        = Siga  (bit0 = 0) 
    ori s0, s0, SPEED_GAME                 # Velocidade  = Lenta (bit1 = 0)
    ori s0, s0, DIFFICULTY                 # Dificuldade = Fácil (bit2 e 3 = 0)         
  
#########################################################
#   Aguarda START para iniciar o jogo                   
#########################################################

    li     t0,  START_BIT                    # Aguarda botão START ser pressionado

    addi   t1,  t1, 0                        # Contador responsável por gerar a SEED

    beqz   t0,  ST_GEN                       # Se start pressionado, vai para ST_GEN
    j           ST_IDLE                      # Se não, continua no estado de IDLE

#########################################################
#   ST_GEN:Estado para geração do número aleatório                                                                                   #
#########################################################

ST_GEN:

    li     s1, 0                             # s1: led_sequence_reg1 vai armazenar os 16 bits gerados (cores
    li     t3, 0                             # contador de quantas iterações já fizemos
    li     s4, 8                             # s4: Sequence_size (define o tamanho da sequência de acordo com o nível de dificuldade)	

#########################################################
#   PRNG: Gerador de números aleatórios                                                                                    #
#########################################################

PRNG:
    
    addi t1, t1, 3                           # Gera a seed
    andi t2, t1, 0b11                        # Mascara para obter 2 bits (0-3)

    slli t4, t3, 1                           # Desloca os dois bits para esquerda
    sll  t5, t2, t4                          # Desloca os bits da nova cor para a posição atual
    or   s1, s1, t5                          # Adiciona ao registrador s1
    addi t3, t3, 1                           # Incrementa contador de geração aleatória

    addi s3, s3, 1                           # Contador que indica quantas rodadas foram feitas
    
#########################################################
#   Verifica entrada do jogador ou exibe sequência de LEDs    
#########################################################

ST_VERIFY_INPUT_PLAYER_OR_SHOW_LED:
      
    li   s7, 0                               # Reseta s7 (Apaga todos os leds)
    li   s6, 0                               # Desabilita pino (Enable LED) 
   
    blt  t0, s3, ST_SHOW_LEDS                # Verifica se ainda há cores para mostrar
    j            ST_PLAYER_INPUT             # Quando terminar, vai para entrada do jogador

#########################################################
#   Exibe a sequência de LEDs para o jogador memorizar               
#########################################################

ST_SHOW_LEDS:
    
    addi t2, s1, 0                           # Copia o registrador s1 para o t2
    sll  t2, s1, t0                          # Rotaciona os bits de acordo com t0
    andi t2, t2, 0b11                        # Aplica a máscara ao conjunto de bits
    addi t0, t0, 1                           # Incrementa contador de posição

    # Verifica qual cor está em t2 e configura os bits correspondentes

    beqz t2,     SHOW_BLUE_LED               # Se cor = 00 (Blue)
    li   t5, 1                              
    beq  t2, t5, SHOW_GREEN_LED              # Se cor = 01 (Green)
    li   t5, 2
    beq  t2, t5, SHOW_YELLOW_LED             # Se cor = 10 (Yellow)
    li   t5, 3
    beq  t2, t5, SHOW_RED_LED                # Se cor = 11 (Red)
    
#########################################################
#   Acende o LED verde             
#########################################################

SHOW_GREEN_LED:
    
    ori  s7, s7, 0b0001                      # Verde [1:0] = 01 -> saída 0001 (bit 0)
    li   s6, 1                               # Enable_Led
    j    ST_VERIFY_INPUT_PLAYER_OR_SHOW_LED  # Vai para o estado de mostrar os leds

#########################################################
#   Acende o LED azul             
#########################################################

SHOW_BLUE_LED:

    ori  s7, s7, 0b0010                      # Azul [2:1] = 00 -> saída 0010 (bit 1)
    li   s6, 1                               # Enable_Led
    j    ST_VERIFY_INPUT_PLAYER_OR_SHOW_LED  # Vai para o estado de mostrar os leds

#########################################################
#   Acende o LED vermelho            
#########################################################

SHOW_RED_LED:

    ori  s7, s7, 0b0100                      # Vermelho [3:2] = 11 -> saída 0100 (bit 2)
    li   s6, 1                               # Enable_Led
    j    ST_VERIFY_INPUT_PLAYER_OR_SHOW_LED  # Vai para o estado de mostrar os leds

#########################################################
#   Acende o LED amarelo             
#########################################################

SHOW_YELLOW_LED:

    ori  s7, s7, 0b1000                      # Amarelo [4:3] = 10 -> saída 1000 (bit 3)
    li   s6, 1                               # Enable_Led
    j    ST_VERIFY_INPUT_PLAYER_OR_SHOW_LED  # Vai para o estado de mostrar os leds
 
#########################################################
#   Aguarda a entrada do jogador e verifica se está correta            
#########################################################

ST_PLAYER_INPUT:

    li    t0, 0                              # Reseta o contador de jogadas do jogador
    li    s5, 0                              # Reseta registrador 

    # Simula a entrada do jogador 
    # (Implementar no simulador futuramente)

    li   t5,     0b11                        # Simula jogador apertando botão da cor amarela
    beq  t5, t2  ST_EVALUATE                 # Jogada 1: Vermelho (11)
    
    li   t5,     0b10                        # Simula jogador apertando botão da cor amarela  
    beq  t5, t2  ST_EVALUATE                 # Jogada 2: Amarelo (10)

    li   t5,     0b01                        # Simula jogador apertando botão da cor verde   
    beq  t5, t2  ST_EVALUATE                 # Jogada 3: Verde (00)
   
    li   t5,     0b00                        # Simula jogador apertando botão da cor azul     
    beq  t5, t2  ST_EVALUATE                 # Jogada 4: Azul (01)


#########################################################
#   Avalia se a jogada do jogador está correta
#   e verifica se o jogo terminou         
#########################################################

ST_EVALUATE:
   
    addi s5, s5, 1                           # Registra jogada do jogador
    addi t2, s1, 0                           # Copia o registrador s1 para o t2
    sll  t2, s1, t0                          # Rotaciona os bits de acordo com t0
    andi t2, t2, 0b11                        # Aplica a máscara ao conjunto de bits

    beq   t5, t2, ST_INPUT_PLAYER_OR_PRNG    # Entrada errada → derrota
    j     ST_END

#########################################################
#   Estado que verifica se é a vez do jogador ou de gerar a PRNG          
#########################################################

ST_INPUT_PLAYER_OR_PRNG:

   beq s3, s5, PRNG                           # Se o contador de jogadas do jogador for igual ao contador de jogadas do PRNG, vai para o estado de gerar a sequência
   j           ST_PLAYER_INPUT                # Se não, continua no estado de entrada do jogador

#########################################################
#   Estado que verifica se o jogador venceu ou perdeu         
#########################################################

ST_END:

   bne t5, t2, DEFEAT                          # Entrada errada → derrota

VICTORY: 

   li s6, 2                                   # Configura o led de vitória
   j ST_IDLE                                  # Retorna para o estado de IDLE

DEFEAT: 

   li s6, 2                                   # configura o led de derrota
   j ST_IDLE                                  # Retorna para o estado de IDLE

