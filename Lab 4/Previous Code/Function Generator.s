;=============== Assembler Equates ===============

PORTJ          =  $0028                   ; Address of PORTJ
DDRJ           =  $0029                   ;
Pin_5          =  0b00010000              ; Mask for pin 5

DACA_LSB       =  $0300                   ; DAC A LS Input Latch Transparent
DACA_MSB       =  $0301                   ; DAC A MS Input Latch Transparent
DACB_LSB       =  $0310                   ; DAC B LS Input Latch Transparent
DACB_MSB       =  $0311                   ; DAC B MS Input Latch Transparent

TIOS           =  $0080                   ; TIMER OUTPUT COMPARE
CHANNEL_ZERO   =  $01                     ; CHANNEL ZERO
TFLG1          =  $008E                   ; TIMER FLAG REGISTER
TFB            =  $01                     ; TIMER FLAG BIT
TSBK           =  $A0                     ; IF BIT IS SET, IT STOPS THE TIMER WHILE BGND MODE
TSCR           =  $0086                   ; TIMER SYSTEM CONTROL REGISTER
TC0H           =  $0090                   ; TIMER CHANNEL ZERO REGISTER HIGH
TCNT           =  $0085                   ; TIMER COUNT REGISTER HIGH AND LOW
TMSK1          =  $008C                   ;
TCTL2          =  $0089                   ; TIMER CONTROL REGISTER 2
ISR            =  $001E

;=============== RAM Area ===============

.area bss

interval:: .blkb 2                        ; Clocks Variable

;=============== Main ===============

_main::
	    
		jsr INTERRUPTS
		
		Jsr FUNCTION_GENERATOR
		
SPIN::
      BRA SPIN



;================ Task 4: Timer_C0 ================ 

INTERRUPTS:
	
	ldaa   intState
	beq    intState0
	deca
	beq    intState1
	deca
	beq    intState2
	rts
	
;================ Interrupt State 0: Timer Initialization ================

intState0:
	
	movw   #0320, Interval                ; Setting the Interval for the number of ticks per 0.1ms
	
	bset   TIOS, CHANNEL_ZERO             ; SETTING TC0 FOR OUTPUT COMPARE
	   
	bset   TCTL2, CHANNEL_ZERO            ; INITIALIZE OC0 TO TOGGLE ON SUCCESSFUL COMPARE
	
	bset   TFLG1, #$0001                  ; CLEARING THE TIMER OUTPUT COMPARE FLAG IF SET
	   
	cli                                   ; ENABLING MASKABLE INTERRUPTS
	   
    bset   TMSK1, CHANNEL_ZERO            ; ENABLING TIMER CHANNEL 0 OUTPUT COMPARE INTERRUPTS
	
	movb   #$01, intState                 ; Set Next Interrupt State to 1
	    
	rts                                   ; RETURN FROM SUBROUTINE
	
;================ Interrupt State 1: First Interrupt ================

intState1:
		    
	bset TSCR, $A0                        ; ENABLING THE TIMER AND STOPPING IT WHILE IN BGND MODE
		
	ldd   TCNT                            ; READS THE CURRENT COUNT AND STORE IN D
	
	addd  INTERVAL                        ; ADDS INTERVAL TO THE CURRENT TIMER CURRENT
	
	std   TC0H                            ; STORES INTERVAL + TCNT INTO TC0H
	
	movb #$02, intState                   ; Set Next Interrupt State to 2
		
	rts                                   ; RETURN TO MAIN FROM SUBROUTINE
	
;================ Interrupt State 2: Subsequent Interrupts ================

intState2:
	
	ldd  TC0H                             ; STORE TC0H INTO D
	
	addd INTERVAL                         ; ADDS INTERVAL TO TC0CH
	
	std  TC0H                             ; LOADS THE TCOH + INTERVAL BACK INTO D
		
	ldaa TFLG1                            ; LOAD TIMER FLAG ONTO ACC. A
	
	oraa #01                              ; CLEAR CONTENTS (TIMER FLAG) OF ACC. A
	
	staa TFLG1                            ; LOAD ACC. A BACK INTO TIMER FLAG
		
	rti                                   ; Return From Interrupt

	
;================ Task 5: Function Generator ================ 

FUNCTION_GENERATOR:
	
	ldaa   fgState
	beq    fgState0
	deca 
	beq    fgState1
	deca
	beq    fgstate2
	deca
	beq    fgstate3
	deca
	beq    fgState4
	rts
	
;================ Function Generator State 0: Initialization ================ 

fgState0:
	
	movb $01, fgState
	
	rts
	
;================ Function Generator State 1: Wait for Wave ================ 

fgState1:

	rts

;================ Function Generator State 2: New Wave ================ 

fgState2:

	rts

;================ Function Generator State 3: Wait for NINT ================ 

fgState3:

	rts

;================ Function Generator State 4: Display Wave ================ 

fgState4:

	rts
	
;=============================================================================

.area interrupt_vectors (abs)
        .org   $FFEE                                 
        .word  intState2                  ; Address of Next Interrupt
        .org   $FFFE                      ; At reset vector location 
        .word  __start                    ; Load starting address

	