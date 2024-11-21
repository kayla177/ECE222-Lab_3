 
  .section .text
  .align 2
  .globl _start


  // -------------------------------------------------------------------------------------
  // Name:        Lab_3.S
  // Purpose:     This code has 2 parts: the first part is to create a simple counter
  //              subroutine that increments from 0x00 to 0xFF, wraps to 0 and continues
  //              counting.  There is a 100ms delay between the display of the count. 
  //		The second part is a reflex meter that will measure how fast
  //              a user responds to an event accurate to a 10th of a millisecond.
  //              Initially, all LED's are off and after a random amount of time
  //              (between 2 and 10 seconds), one LED turns on (LED_6) and then the user
  //		presses pushbutton S1.  The press of the button will be monitored by
  //		using "polling".
  //
  // Author:      Julius Olajos
  // -------------------------------------------------------------------------------------


  _start:

  // -------------------------------------------------------------------------------------
  // GPIO Control Registers Memory Mapping

      .equ GPIO_BASE_CTRL_ADDR, 0x10012000    // Base address for the GPIO control registers
      .equ GPIO_OUTPUT_EN,      0x08          // address offset for enabling GPIO outputs
      .equ GPIO_OUTPUT_VAL,     0x0C          // Address offset for writing to GPIO outputs
      .equ GPIO_OUTPUT_XOR,     0x40          // Address offset for GPIO Outputs XOR
      .equ GPIO_INPUT_VAL,      0x00          // Address offset for reading GPIO inputs
      .equ GPIO_INPUT_EN,       0x04          // address offset for enabling GPIO inputs
      .equ GPIO_PUE,            0x10          // address offset for internal GPIO pull-up resistor

  // -------------------------------------------------------------------------------------
  // 8 LEDS, 7 Segment LED Display Pins Register Address Mapping

      .equ GPIO_7SEGLED_PINS,   0x0000023F      // Seven Segment LED Display Pins (7)
      .equ GPIO_LEDBAR_PINS,    0x00FC0C00      // LED Bar Pins (8)
      .equ GPIO_ALL_LED_PINS,   0x00FC0E3F      // All LED Pins (15)
      .equ GPIO_LEDBAR_LED_1,   0x00000800      // LEDBAR LED1

  // -------------------------------------------------------------------------------------
  // Pushbuttons SW(x) Register Address Mapping

      .equ GPIO_SW_1,           0x00001000      // SW1 pushbutton (bit 12)
      .equ GPIO_SW_2,           0x00002000      // SW2 Pushbutton (bit 13)
      .equ GPIO_ALL_PBS,        0x00003000      // All Pushbutton Pins (bits 12, 13)

  // Initialize the GPIO control registers
  // -------------------------------------------------------------------------------------

      li t0, GPIO_BASE_CTRL_ADDR          // Load Base Address for GPIO Control Registers
      li t1, GPIO_ALL_LED_PINS            // Load GPIO Register to set GPIO_OUTPUT_EN and GPIO_OUTPUT_XOR registers for all GPIO LED Pins
      sw t1, GPIO_OUTPUT_EN(t0)           // Enable outputs on all GPIO LED Pins
      li t2, 0xFF03F1C0
      sw t2, GPIO_OUTPUT_VAL(t0)          // Set all LED pins to zero to turn off all LEDS.
      li t1, GPIO_SW_1                    // Load GPIO Register to set GPIO_INPUT_EN for input pins
      sw t1, GPIO_INPUT_EN(t0)            // Enable inputs on all Pushbutton pins

  // -------------------------------------------------------------------------------------


  INITIAL:

  // Initialize random number generator
   	li a7, 0xABCD                   // Initializes register a7 to a 16-bit non-zero value and NOTHING else can write to a7 !!!!
      jal ra, RandomNum       // call random number generator
      li t2, 0                
      jal ra, DISPLAY_NUM     // initialize all display LEDS to off
      li s3, 0x7              // Loads a mask value to extract a random range
      and s3, a7, s3          // Masks the random number to obtain a range from 0-7.
      addi s3, s3, 2          // set offset from 0-7 to 2-9
      li s1, 0
      RANDOM_DELAY_LOOP:
          addi s1, s1, 1      
          jal ra, DELAY_1s    // delay for 1 second
          blt s1, s3, RANDOM_DELAY_LOOP
      li t2, 32               // turn on LED_6 to siganl start of the reflex test
      jal ra, DISPLAY_NUM
      jal ra, COUNTER         // start counter to measure reaction time





  // -------------------------------------------------------------------------------------

  loop:
  //  Generate random number
          mv t2, a0               // move value in a0 into t2 for display
          jal ra, DISPLAY_NUM     // display current number on the LED
          li s3, 2                // set s3 to 2 for 2-second delay
          li s1, 0                // clear the delay counter
          DELAY_LOOP_NUM_1:       // delay for 2 seconds
              addi s1, s1, 1
              jal ra, DELAY_1s
              blt s1, s3, DELAY_LOOP_NUM_1
          srli t2, t2, 8          // shift t2 right by 8 bits for the next display
          jal ra, DISPLAY_NUM     // display the next 8-bit segment
          li s3, 5                // set s3 to 5 for 5-seconds delay
          li s1, 0                // clear the delay counter
          DELAY_LOOP_NUM_2:       // delay for 5 seconds
              addi s1, s1, 1
              jal ra, DELAY_1s
              blt s1, s3, DELAY_LOOP_NUM_2
          j loop                  // jump back to start of the loop
        

  //  Once your number has been generated, it will be stored in register a7. Do not overwrite this!
  //  You will now need to set up delays, subroutines to turn the LED ON and OFF, and for polling whether the Pushbutton S1 has been pressed.
  //  Keep in mind that you will get a 32-bit number back from the random number generator.  You will need to display this 8 bits at a time,
  //  starting with the lowest 8 bits.
 //  You will probably want to rotate 8 bits at a time for display.



 //   --------------- Place your code here ----------------------------------------



  DISPLAY:    

  // Display the 32-bit number on the 8-LED Bar

  // Register t1 holds the value of the number to be displayed
  // Map each bit of the number to the corresponding LED Bar bit
  // MSB to LSB: bits 23, 22, 21, 20, 19, 18, 11, 10
  //

  DISPLAY_NUM:
        addi sp, sp, -16      // save necessary register onto stack
        sw ra, 12(sp)
        sw t3, 0(sp)
        sw t4, 4(sp)

  // Remember, the 8 LEDS are mapped to the GPIO as bits MSB to LSB: bits 23, 22, 21, 20, 19, 18, 11, 10
  // 2 到 7 需要在实际输出的18-23位
        li t3, 0xFC           // load mask for 8-bit display into t3
        and t3, t3, t2        // mask t2 with t3 to isolate display bits
        slli t3, t3, 6        // shift left to align bits with GPIO_LED pins
        li t4, 0x3            // load mask for remaining bits into t4
        and t4, t4, t2        // mask t2 with t4 for lower two bits
        or t3, t4, t3         // conbine t3 and t4 for final display pattern
        slli t3, t3, 10       // shift left to align with GPIO_OUTPUT_VAL
        sw t3, GPIO_OUTPUT_VAL(t0)    // write display pattern to LED output register
      
        lw t4, 4(sp)          // restore register from stack
        lw t3, 0(sp)
        lw ra, 12(sp)
        addi sp, sp, 16
        ret

  // Random Number generator
  // Register a7 holds the random number.
  // You can read this value anywhere in the code, but this register can only be written to by this subroutine
  // Or Else!

  RandomNum:
       addi sp, sp, -16           // allocate 16 bytes on the stack
       sw ra, 12(sp)


       li s4, 0x8000		        // Load upper 20 bits
       and t1, a7, s4  		        // Mask to lower 16 bits
       li s4, 0x2000  		        // Load upper 20 bits
       and t3, a7, s4  		        // Mask to lower 16 bits


       slli t3, t3, 2             
       xor t3, t1, t3
       li s4, 0x1000  		        // Load upper 20 bits
       and t1, a7, t0		        // Mask to lower 16 bits

       slli t1, t1, 3
       xor t3, t3, t1
       andi t1, a7, 0x0400
       slli t1, t1, 5
       xor t3, t3, t1
       srli t3, t3, 15
       slli a7, a7, 1
       or a7, a7, t3		        // Register a7 holds the random number

       lw ra, 12(sp)
       addi sp, sp, 16            // deallocate 16 bytes from the stack
       ret

  DELAY:
       addi sp, sp, -16           // Store necessary registers onto stack
       sw ra, 12(sp)
  	   sw t0, 0(sp)
       sw t1, 4(sp)
     
       li t0, 800                 // delay counter for 0.1ms
       li t1, 0                   // loop counter
       DELAY_LOOP:            
          addi t1, t1, 1          // increment loop counter
          bne t0, t1, DELAY_LOOP  // continue loop until t1 reaches 800

       lw t1, 4(sp)               // restore registers from stack
       lw t0, 0(sp)
       lw ra, 12(sp)
       addi sp, sp, 16            // deallocate 16 bytes from the stack
       ret

  DELAY_1s:
       addi sp, sp, -16           // allocate 16 bytes on the stack
       sw ra, 12(sp)              // Store necessary registers onto stack
  	   sw t0, 0(sp)
       sw t1, 4(sp)
     
       li t0, 8000000             // load 8000000 into t0 as the delay counter
       li t1, 0                   // initializa loop counter to 0
       DELAY_LOOP_1s:              
          addi t1, t1, 1              // Increment counter
          bne t0, t1, DELAY_LOOP_1s   // countinue loop until t1 reaches 8000000

       lw t1, 4(sp)               // restore registers from stack
       lw t0, 0(sp)
       lw ra, 12(sp)
       addi sp, sp, 16            // deallocate 16 bytes from the stack
       ret

  COUNTER:
      addi sp, sp, -16               // allocate 16 bytes on the stack
      sw ra, 8(sp)                   // Store necessary registers onto stack
      sw t2, 4(sp)
      sw t3, 0(sp)
      sw t4, 12(sp)

      li t2, 0                        // initialize t2 as the reaction time counter
      li t4, 0x1000                   // set t4 equal to the bit corrsponding to the GPIO bit of s1
      li t0, GPIO_BASE_CTRL_ADDR  
      COUNTER_LOOP:
          addi t2, t2, 1              // increment time counter
          lw t3, GPIO_INPUT_VAL(t0)   // load GPIO input values into t3
          and t3, t3, t4              // mask t3 to check if s1 is pressed
          beqz t3, END_COUNTER_LOOP   // if t3 = 0 (s1 pressed), break out the counting loop
          jal ra, DELAY               // call delay subroutine
          j COUNTER_LOOP              // if s1 is not pressed, continue counting

      END_COUNTER_LOOP:
      mv a0, t2                       // move t2 into a0 for return value
      lw t3, 0(sp)                    // restore registers from stack
      lw t2, 4(sp)
      lw ra, 8(sp)
      lw t4, 12(sp)
      addi sp, sp, 16                 // deallocate 16 bytes from the stack
        ret












/*

  .section .text
  .align 2
  .globl _start


  // -------------------------------------------------------------------------------------
  // Name:        Lab_3.S
  // Purpose:     This code has 2 parts: the first part is to create a simple counter
  //              subroutine that increments from 0x00 to 0xFF, wraps to 0 and continues
  //              counting.  There is a 100ms delay between the display of the count. 
  //		The second part is a reflex meter that will measure how fast
  //              a user responds to an event accurate to a 10th of a millisecond.
  //              Initially, all LED's are off and after a random amount of time
  //              (between 2 and 10 seconds), one LED turns on (LED_6) and then the user
  //		presses pushbutton S1.  The press of the button will be monitored by
  //		using "polling".
  //
  // Author:      Julius Olajos
  // -------------------------------------------------------------------------------------


  _start:

  // -------------------------------------------------------------------------------------
  // GPIO Control Registers Memory Mapping

      .equ GPIO_BASE_CTRL_ADDR, 0x10012000    // Base address for the GPIO control registers
      .equ GPIO_OUTPUT_EN,      0x08          // address offset for enabling GPIO outputs
      .equ GPIO_OUTPUT_VAL,     0x0C          // Address offset for writing to GPIO outputs
      .equ GPIO_OUTPUT_XOR,     0x40          // Address offset for GPIO Outputs XOR
      .equ GPIO_INPUT_VAL,      0x00          // Address offset for reading GPIO inputs
      .equ GPIO_INPUT_EN,       0x04          // address offset for enabling GPIO inputs
      .equ GPIO_PUE,            0x10          // address offset for internal GPIO pull-up resistor

  // -------------------------------------------------------------------------------------
  // 8 LEDS, 7 Segment LED Display Pins Register Address Mapping

      .equ GPIO_7SEGLED_PINS,   0x0000023F      // Seven Segment LED Display Pins (7)
      .equ GPIO_LEDBAR_PINS,    0x00FC0C00      // LED Bar Pins (8)
      .equ GPIO_ALL_LED_PINS,   0x00FC0E3F      // All LED Pins (15)
      .equ GPIO_LEDBAR_LED_1,   0x00000800      // LEDBAR LED1

  // -------------------------------------------------------------------------------------
  // Pushbuttons SW(x) Register Address Mapping

      .equ GPIO_SW_1,           0x00001000      // SW1 pushbutton (bit 12)
      .equ GPIO_SW_2,           0x00002000      // SW2 Pushbutton (bit 13)
      .equ GPIO_ALL_PBS,        0x00003000      // All Pushbutton Pins (bits 12, 13)

  // Initialize the GPIO control registers
  // -------------------------------------------------------------------------------------

      li t0, GPIO_BASE_CTRL_ADDR          // Load Base Address for GPIO Control Registers
      li t1, GPIO_ALL_LED_PINS            // Load GPIO Register to set GPIO_OUTPUT_EN and GPIO_OUTPUT_XOR registers for all GPIO LED Pins
      sw t1, GPIO_OUTPUT_EN(t0)           // Enable outputs on all GPIO LED Pins
      li t2, 0xFF03F1C0
      sw t2, GPIO_OUTPUT_VAL(t0)          // Set all LED pins to zero to turn off all LEDS.
      li t1, GPIO_SW_1                    // Load GPIO Register to set GPIO_INPUT_EN for input pins
      sw t1, GPIO_INPUT_EN(t0)            // Enable inputs on all Pushbutton pins

  // -------------------------------------------------------------------------------------


  INITIAL:

  // Initialize random number generator
   	li a7, 0xABCD                   // Initializes register a7 to a 16-bit non-zero value and NOTHING else can write to a7 !!!!
  COUNTER:
          addi sp, sp, -12
          sw ra, 8(sp)
          sw t2, 4(sp)
          sw t3, 0(sp)

          li t2, 0                      // initialize counter to 0
          li t3, 0xFF                   // max value of counter
          COUNTER_LOOP:             
              addi t2, t2, 1            // increment counter
              jal ra, DISPLAY_NUM       // display current number
              bne t2, t3, DONT_SET_ZERO // if counter reaches max, reset counter
                  li t2, 0              
              DONT_SET_ZERO:
              jal ra, DELAY             // call delay subroutine
              j COUNTER_LOOP            // jump back to loop, repeat

          lw t3, 0(sp)
          lw t2, 4(sp)
          lw ra, 8(sp)
          addi sp, sp, 16
          ret

  // -------------------------------------------------------------------------------------

  loop:
  //  Generate random number
          jal ra, RandomNum

  //  Once your number has been generated, it will be stored in register a7. Do not overwrite this!
  //  You will now need to set up delays, subroutines to turn the LED ON and OFF, and for polling whether the Pushbutton S1 has been pressed.
  //  Keep in mind that you will get a 32-bit number back from the random number generator.  You will need to display this 8 bits at a time,
  //  starting with the lowest 8 bits.
  //  You will probably want to rotate 8 bits at a time for display.



  //   --------------- Place your code here ----------------------------------------
  jal ra, COUNTER          


  DISPLAY:    

// Display the 32-bit number on the 8-LED Bar

// Register t1 holds the value of the number to be displayed
// Map each bit of the number to the corresponding LED Bar bit
// MSB to LSB: bits 23, 22, 21, 20, 19, 18, 11, 10
//

DISPLAY_NUM:
      addi sp, sp, -16
      sw ra, 12(sp)
      sw t3, 0(sp)
      sw t4, 4(sp)

// Remember, the 8 LEDS are mapped to the GPIO as bits MSB to LSB: bits 23, 22, 21, 20, 19, 18, 11, 10
      li t3, 0xFC                   // load mask for for the upper 6 bit (1111 1100)
      and t3, t3, t2                // mask t2 with t3 to isolate display bits
      slli t3, t3, 6                // shift left 6 bits to align with the GPIO_LED pins
      li t4, 0x3                    // load mask for remaining bits into t4 (0000 0011)
      and t4, t4, t2                // mask to isolate the lower 2 bits
      or t3, t4, t3                 // combine t3 and t4
      slli t3, t3, 10               // shift left to align with GPIO_OUTPUT_VAL
      sw t3, GPIO_OUTPUT_VAL(t0)    // write display pattern to LED output register
      
      lw t4, 4(sp)          
      lw t3, 0(sp)
      lw ra, 12(sp)
      addi sp, sp, 16
      ret

// Random Number generator
// Register a7 holds the random number.
// You can read this value anywhere in the code, but this register can only be written to by this subroutine
// Or Else!

RandomNum:
     addi sp, sp, -16
     sw ra, 12(sp)


     li s4, 0x8000		     // Load upper 20 bits
     and t1, a7, s4  		     // Mask to lower 16 bits
     li s4, 0x2000  		     // Load upper 20 bits
     and t3, a7, s4  		     // Mask to lower 16 bits


     slli t3, t3, 2
     xor t3, t1, t3
     li s4, 0x1000  		     // Load upper 20 bits
     and t1, a7, t0		     // Mask to lower 16 bits

     slli t1, t1, 3
     xor t3, t3, t1
     andi t1, a7, 0x0400
     slli t1, t1, 5
     xor t3, t3, t1
     srli t3, t3, 15
     slli a7, a7, 1
     or a7, a7, t3		     // Register a7 holds the random number

     lw ra, 12(sp)
     addi sp, sp, 16
     ret

DELAY:
     addi sp, sp, -16       // allocate space for saving register onto stack
     sw ra, 12(sp)
	 sw t0, 0(sp)
     sw t1, 4(sp)
     
     li t0, 800000          // delay count, represent about 50ms
     li t1, 0               // delay counter

     DELAY_LOOP:
        addi t1, t1, 1              // increment delay counter
        bne t0, t1, DELAY_LOOP      // If t1 is not equal to t0, branch back to DELAY_LOOP to continue counting.
     lw t1, 4(sp)           // Restore values from the stack.
     lw t0, 0(sp)           
     lw ra, 12(sp)
     addi sp, sp, 16        // deallocate the 16 bytes of stack space
     ret

*/



//1- If a 32-bit register is counting user reaction time in 0.1 milliseconds increments, what is the maximum amount of time which can be stored in 8 bits, 16-bits, 24-bits and 32-bits?
    // 8-bit: 2^8 − 1 = 255 increments, giving a max time of 255 × 0.1 ms = 25.5 ms.
    // 16-bit: 2^16 − 1 = 65535 increments, giving a max time of 65535 × 0.1 ms = 6.5535 seconds.
    // 24-bit: = 2^24 − 1 = 16777215 increments, giving a max time of 16777215 × 0.1 ms = 1677.7215 seconds.
    // 32-bit: 2^32 − 1 = 4294967295 increments, giving a max time of 4294967295 × 0.1 ms = 429496.7295 seconds.

//2- Considering typical human reaction time, which size would be the best for this task (8, 16, 24, or 32 bits)?
    // Since the typical human reaction time is about 250ms, a 16-bit register should be sufficient, as it can represent up to 6.5535 seconds, which covers the range of expected reaction times comfortably.

//3- Prove time delay meets 2 to 10 sec +/- 5% spec.
    // We achieve the 2 to 10-second ±5% delay by first generating a random 16-bit seed in register a7, processed by the RandomNum subroutine.
    // We then set s3 to 7 to mask the last three bits of a7 (and s3, a7, s3), which extracts a value between 0 and 7, and applied an offset (addi s3, s3, 2) to ensure the delay falls between 2 and 9 seconds.
    // The RANDOM_DELAY_LOOP runs for s3 iterations, calling a 1-second delay subroutine each time, resulting in a total delay of precisely s3 seconds.
    // This method produces delays between 2 and 9 seconds, and since each iteration is accurately timed, the delay remains within ±5% of the required range.
