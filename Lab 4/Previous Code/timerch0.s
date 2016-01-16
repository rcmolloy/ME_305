;=============== Assembler Equates ===============

PORTJ          =  $0028                   ; Address of PORTJ
DDRJ           =  $0029                   ;
pin_5          =  0b00010000              ; Mask for pin 5

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

WAVEPTR::    .blkb 1                           ; Address for First Line Of Data For Selected Wave
CSEG::      .blkb 1                              ; # of Segments in the Waveform (remaining), Countdown to zero.
LSEG::     .blkb 1                               ; # of BTI's Remaining In This Segment
SEGINC::  .blkb 2                         ; 16-Bit Segment Increment (slope:dac counts/bti)
NINT::    .blkb 2                                ; # of Interrupts Per BTI 
CINT::    .blkb 2                                ; # of Interrrupts Remaining (copy of NINT)
VALUE::                                   ; 16-Bit DAC Input value
NEWBTI::                                  ; Flag Raised By Interrupt
SEGPTR::                                  ; Address for First Line of Data for Next Segement

;=============== Main ===============

_main::
	    
		
;=============== Interrupts ===============
TC0_ISR:

	tst run
	
	beq NOT_YET
	
	dec CINT
	
	bne NOT_YET
	
	ldd VALUE
	
	jsr OUTDAC
	
	movb NINT, CINT
	
	movb #01, NEWBTI
	
;===============================================	
NOT_YET:

		LDD  TC0H                   ; STORE TC0H INTO D
		ADDD INTERVAL               ; ADDS INTERVAL TO TC0CH
		STD  TC0H                   ; LOADS THE TCOH + INTERVAL BACK INTO D
		
		LDAA TFLG1                  ; LOAD TIMER FLAG ONTO ACC. A
		ORAA #01                    ; CLEAR CONTENTS (TIMER FLAG) OF ACC. A
		STAA TFLG1                  ; LOAD ACC. A BACK INTO TIMER FLAG
		
		RTI

;===============================================		
OUTDAC:
	
	stab DACA_LSB
	
	staa DACA_MSB
	
	bclr PORTJ, pin_5
	
	bset PORTJ, pin_5
	
	rts

;=============================================================================

.area interrupt_vectors (abs)
        .org   $FFEE                                 
        .word  intState2                  ; Address of Next Interrupt
        .org   $FFFE                      ; At reset vector location 
        .word  __start                    ; Load starting address

	
	
	
	