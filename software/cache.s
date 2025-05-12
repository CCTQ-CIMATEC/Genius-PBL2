# LED Matrix and D-Pad Control Program
# Based on the provided C code example
# For use with Ripes simulator (https://ripes.me/)

# Define base addresses

# Define color constant
.equ LED_COLOR, 0x0FF0000              # The color used in the C code (0x08DBF0)

.text
.globl main

main:
    # Registers:
    # t0 = LED matrix base address
    # t1 = D-pad UP button address
    # t2 = Button state
    # t3 = LED color

    # Load base addresses
    lui t0, 0xf0000                   # LED matrix base
    lui t1, 0xf0000
    addi t1, t1, 0x010                # D-pad UP button (0xf0000010)

outer_loop:
    # Check D-pad UP button state
    lw t2, 0(t1)                      # Read button state

    # If button not pressed, turn LED off and continue checking
    beq t2, zero, led_off

    # Button is pressed, enter inner loop
inner_loop:
    # Load the LED color (0x08DBF0)
    addi t3, zero, 0x000              # Load lower part (limited by 12-bit)
    slli t3, t3, 4                    # Shift left to get 0x0DB00
    addi t3, t3, 0xf00                 # Add to get 0x0DBF0
    lui t4, 0x00009                   # Load upper part (0x09000)
    or t3, t3, t4                     # Combine to get 0x08DBF0

    # Update LED with the color
    sw t3, 0(t0)                      # Set LED to color

    # Check if button is still pressed
    lw t2, 0(t1)                      # Read button state again
    bne t2, zero, inner_loop          # If still pressed, continue inner loop

led_off:
    # Turn LED off
    add t3, zero, zero                # Set color to black (0)
    sw t3, 0(t0)                      # Update LED

    j outer_loop                      # Return to main loop

# The program never reaches here (infinite loop)