; Robert Cory Molloy & Oscar Andrade :: Lab 2

; Assembler equates

PORTS        = $00D6              ; Output Port for LEDs
DDRS         = $00D7			  ; Setting Ports in J as Outputs
LED_MSK_1    = 0b00000011         ; LED_1 Output Pins
LED_MSK_2    = 0b00001100         ; LED_2 Output pins
R_LED_1      = 0b00000001         ; Red LED_1 Output Pin
G_LED_1      = 0b00000010         ; Green LED_1 Output Pin
R_LED_2      = 0b00000100         ; Red LED_2 Output Pin
G_LED_2      = 0b00001000         ; Green LED_2 Output Pin

; RAM area
.area bss
TICKS_1::    .blkb 2              ; Value for COUNT_1 to be set to decrement
COUNT_1::    .blkb 2			  ; Value set by TICKS_1 for decrementation to 
			 	   				  ;	raise DONE_1 flag to move to next t1state
DONE_1::     .blkb 1			  ; Value set to move to next t1state to switch 
			 	   				  ; the LEDs in the first pair on or off 
TICKS_2::    .blkb 2			  ; Value for COUNT_2 to be set to decrement
COUNT_2::    .blkb 2			  ; Value set by TICKS_2 for decrementation to 
			 	   				  ; raise DONE_2 flag to move to next t1state
DONE_2::     .blkb 1			  ; Value set to move to next t4state to switch 
			 	   				  ; the LEDs in the first pair on or off 
t1state::    .blkb 1
t2state::    .blkb 1
t3state::    .blkb 1
t4state::    .blkb 1
t5state::    .blkb 1


;code area
.area text
;
;==============================================================================
;
;   Main Program

_main::

        clr    t1state            ; Initialize all tasks to a value of zero 
			   					  ; (Zero State)
        clr    t2state
        clr    t3state
		clr    t4state
		clr    t5state

;  Normally no code other than that to clear the state variables and call the tasks
;  repeatedly should be in your main program.  However, this week we will make an 
;  exception.  The following code will allow the user to set TICKS_1 and TICKS_2 in
;  the debugger.

        movw   #200, TICKS_1      ; Set default for TICKS_1
        movw   #500, TICKS_2      ; Set default for TICKS_2
        bgnd                      ; Stop in DEBUGGER to allow user to alter 
								  ; TICKS

TOP:    
		jsr    TASK_1			  ; Blinking Pattern of First Pair of LEDs
		
        jsr    TASK_2			  ; Countdown of First Pair of LEDs
		
		jsr    TASK_4			  ; Blinking Pattern of Second Pair of LEDs
		
        jsr    TASK_5			  ; Countdown of Second Pair of LEDs
		 
        jsr    TASK_3		      ; Delays the Led Blinking Pattern
		
        bra    TOP

; End Main
;=============================================================================
;
;    Subroutine TASK_1            ; Blinking Pattern of First Pair of LEDs

TASK_1: ldaa   t1state            ; Get current t1state and branch accordingly
        beq    t1state0
        deca
        beq    t1state1
        deca
        beq    t1state2
        deca
        beq    t1state3
        deca
        beq    t1state4
        deca
        beq    t1state5
        deca
        beq    t1state6
        rts                       ; Undefined state - Do nothing but return

t1state0:                         ; Initialize TASK_1
        bclr   PORTS, LED_MSK_1   ; Ensurensure that LEDs are off when initialized
        bset   DDRS, LED_MSK_1    ; Set LED_MSK_1 pins as PORTS outputs
        movb   #$01, t1state      ; Set next state
        rts

t1state1:                         ; G, not R
        bset   PORTS, G_LED_1     ; Set state1 pattern on LEDs
        tst    DONE_1             ; Check TASK_1 done flag
        beq    exit_t1s1          ; If not done, return
        movb   #$02, t1state      ; If done, set next state
exit_t1s1:
        rts
t1state2:                         ; Not G, Not R
        bclr   PORTS, G_LED_1     ; Set state2 pattern on LEDs
        tst    DONE_1             ; Check TASK_1 done flag
        beq    exit_t1s2          ; If not done, return
        movb   #$03, t1state      ; If done, set next state
exit_t1s2:
        rts
t1state3:                         ; Not G, R
        bset   PORTS, R_LED_1     ; Set state3 pattern on LEDs
        tst    DONE_1             ; Check TASK_1 done flag
        beq    exit_t1s3          ; If not done, return
        movb   #$04, t1state      ; If done, set next state
exit_t1s3:
        rts
t1state4:                         ; Not G, not R
        bclr   PORTS, R_LED_1     ; Set state4 pattern on LEDs
        tst    DONE_1             ; Check TASK_1 done flag
        beq    exit_t1s4          ; If not done, return
        movb   #$05, t1state      ; If done, set next state
exit_t1s4:
       rts	   		 			  ;
t1state5:                         ; G, R
        bset   PORTS, LED_MSK_1   ; Set state5 pattern on LEDs
        tst    DONE_1             ; Check TASK_1 done flag
        beq    exit_t1s5          ; If not done, return
        movb   #$06, t1state      ; If done, set next state
exit_t1s5:
        rts

t1state6:                         ; Not G, not R
        bclr   PORTS, LED_MSK_1   ; Set state6 pattern on LEDs
        tst    DONE_1             ; Check TASK_1 done flag
        beq    exit_t1s6          ; If not done, return
        movb   #$01, t1state      ; If done, set next state
exit_t1s6:
        rts

; end TASK_1
;
;=============================================================================
;
;    Subroutine TASK_2            ; Countdown of First Pair of LEDs

TASK_2: ldaa   t2state            ; Get current t2state and branch accordingly
        beq    t2state0
        deca
        beq    t2state1
		deca
		beq    t2state2
        rts                       ; Undefined state - do nothing but return

t2state0:                         ; Initialization for TASK_2
        clr    DONE_1
        movb   #$01, t2state      ; Set next state
		rts
t2state1:                         ; (Re)initialize COUNT_1
        movw   TICKS_1, COUNT_1
        ldx    COUNT_1
        dex                       ; Decrement COUNT_1
        stx    COUNT_1            ; Store decremented COUNT_1
		clr    DONE_1
        movb   #$02, t2state      ; Set next state
        rts

t2state2:                         ; Count down COUNT_1
        ldx    COUNT_1
        beq    setdone_1          ; Test to see if COUNT_1 is already zero
        dex                       ; Decrement COUNT_1
        stx    COUNT_1            ; Store decremented COUNT_1
        bne    exit_t2s2          ; If not done, return
setdone_1:
        movb   #$01, DONE_1       ; If done, set DONE_1 flag
        movb   #$01, t2state      ; Set next state
exit_t2s2:
        rts

; end TASK_2
; 
;=============================================================================
;
;    Subroutine TASK_4            ; Blinking Pattern of Second Pair of LEDs

TASK_4: ldaa   t4state            ; Get current t4state and branch accordingly
        beq    t4state0
        deca
        beq    t4state1
        deca
        beq    t4state2
        deca
        beq    t4state3
        deca
        beq    t4state4
        deca
        beq    t4state5
        deca
        beq    t4state6
        rts                       ; Undefined state - do nothing but return

t4state0:                         ; Initialize TASK_4
        bclr   PORTS, LED_MSK_2   ; Ensure that LEDs are off when initialized
        bset   DDRS, LED_MSK_2    ; Set LED_MSK_2 pins as PORTS outputs
        movb   #$01, t4state      ; Set next state
        rts

t4state1:                         ; G, not R
        bset   PORTS, G_LED_2     ; Set state1 pattern on LEDs
        tst    DONE_2             ; Check TASK_4 done flag
        beq    exit_t4s1          ; If not done, return
        movb   #$02, t4state      ; If done, set next state
exit_t4s1:
        rts
t4state2:                         ; Not G, not R
        bclr   PORTS, G_LED_2     ; Set state2 pattern on LEDs
        tst    DONE_2             ; Check TASK_4 done flag
        beq    exit_t4s2          ; If not done, return
        movb   #$03, t4state      ; If done, set next state
exit_t4s2:
        rts
t4state3:                         ; Not G, R
        bset   PORTS, R_LED_2     ; Set state3 pattern on LEDs
        tst    DONE_2             ; Check TASK_4 done flag
        beq    exit_t4s3          ; If not done, return
        movb   #$04, t4state      ; If done, set next state
exit_t4s3:
        rts
t4state4:                         ; Not G, not R
        bclr   PORTS, R_LED_2     ; Set state4 pattern on LEDs
        tst    DONE_2             ; Check TASK_4 done flag
        beq    exit_t4s4          ; If not done, return
        movb   #$05, t4state      ; If done, set next state
exit_t4s4:
       rts	   		 			  ;
t4state5:                         ; G, R
        bset   PORTS, LED_MSK_2   ; Set state5 pattern on LEDs
        tst    DONE_2             ; Check TASK_4 done flag
        beq    exit_t4s5          ; If not done, return
        movb   #$06, t4state      ; If done, set next state
exit_t4s5:
        rts

t4state6:                         ; Not G, not R
        bclr   PORTS, LED_MSK_2   ; Set state6 pattern on LEDs
        tst    DONE_2             ; Check TASK_4 done flag
        beq    exit_t4s6          ; If not done, return
        movb   #$01, t4state      ; If done, set next state
exit_t4s6:
        rts

; end TASK_4
;
;=============================================================================
;
;    Subroutine TASK_5            ; Countdown of Second Pair of LEDs

TASK_5: ldaa   t5state            ; Get current t5state and branch accordingly
        beq    t5state0
        deca
        beq    t5state1
		deca
		beq    t5state2
        rts                       ; Undefined state - do nothing but return

t5state0:                         ; Initialization for TASK_5
        clr    DONE_2
        movb   #$01, t5state      ; Set next state
		rts
t5state1:                         ; (Re)initialize COUNT_2
        movw   TICKS_2, COUNT_2
        ldx    COUNT_2
        dex                       ; Decrement COUNT_2
        stx    COUNT_2            ; Store decremented COUNT_2
		clr    DONE_2
        movb   #$02, t5state      ; Set next state
        rts

t5state2:                         ; Count down COUNT_2
        ldx    COUNT_2
        beq    setdone_2          ; Test to see if COUNT_2 is already zero
        dex                       ; Decrement COUNT_2
        stx    COUNT_2            ; Store decremented COUNT_2
        bne    exit_t5s2          ; If not done, return
setdone_2:
        movb   #$01, DONE_2       ; If done, set DONE_2 flag
        movb   #$01, t5state      ; Set next state
exit_t5s2:
        rts

; end TASK_5
;=============================================================================
;
;    Subroutine TASK_3            ; Delay 1.00ms

TASK_3: ldaa   t3state            ; Get current t3state and branch accordingly
        beq    t3state0
        deca
        beq    t3state1
        rts                       ; Undefined state - do nothing but return

t3state0:                         ; Initialization for TASK_3
                                  ; No initialization required
        movb   #$01, t3state      ; Set next state
        rts

t3state1:
        jsr    DELAY_1ms
        rts

; end TASK_3
;
;=============================================================================
;
;    Subroutine Delay_1ms delays for ~1.00ms
;
DELAY_1ms:
        ldy    #$0262
INNER:                            ; Inside loop
        cpy    #0
        beq    EXIT
        dey
        bra    INNER
EXIT:
        rts                       ; Exit DELAY_1ms

; end subroutine DELAY_1ms
;
;==============================================================================


.area interrupt_vectors (abs)
.org    $FFFE             ; At reset vector location
.word   __start           ; Load starting address
