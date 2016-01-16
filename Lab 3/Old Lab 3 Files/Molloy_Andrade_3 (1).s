; Robert Cory Molloy & Oscar Andrade :: Lab 3

; RAM area
.area bss 
delayclear::    .blkb 1
;code area
.area text
;
;==============================================================================
;
;   Main Program

_main::
	   jsr  INITLCD				   		  ; Initialize LCD Module
	   jsr  INITKEY
loop:  
	   jsr  FLUSH_BFR
       jsr 	CHARPULL
	   jsr  CHECK
	   jsr  DELAYCLEAR
	   jsr  CLEAR
	   
	   bra loop


; End Main
;==============================================================================
CHARPULL:		
			jsr GETCHAR
			jsr CLEAR	 					;
			rts
; end CHARPULL

CHECK:		
			cmpb #$39	 					;
			beq MESSAGE9OUT
			cmpb #$38
			beq MESSAGE8OUT
			rts
; end CHECK

MESSAGE9OUT:	ldaa #$00 		 	;
				ldx #MESSAGE9		;
				jsr OUTSTRING		;
				rts		
; end MESSAGE9OUT

MESSAGE8OUT:	ldaa #$00 		 	;
				ldx #MESSAGE8		;
				jsr OUTSTRING		;
				rts		
; end MESSAGE8OUT

MESSAGE9:	.ascii 'Hello World!'   ;
			.byte $00	  		    ;	
			
; end MESSAGE9

MESSAGE8:	.ascii 'This is message 8!' ;
			.byte $00	  		 		;	
			
; end MESSAGE8

CLEAR:	        ldaa #$00 		 	;
				ldx #CLEARMESSAGE   ;
				jsr OUTSTRING		;
				rts		
; end CLEAR

CLEARMESSAGE:	.ascii '                                       ' ;
				.byte $00	  		 		;	
			
; end CLEARMESSAGE
					
DELAYCLEAR: ldaa   delayclear            ; Get current t3state and branch accordingly
        	beq    delayclear0
        	deca
        	beq    delayclear1
        	rts                       ; Undefined state - do nothing but return

delayclear0:                         ; Initialization for TASK_3
                                  ; No initialization required
        movb   #$01, delayclear      ; Set next state
        rts

delayclear1:
        jsr    DELAY_1ms
        rts

; end DELAYCLEAR

DELAY_1ms:
        ldy    #$5000
INNER:                            ; Inside loop
        cpy    #0
        beq    EXIT
        dey
        bra    INNER
EXIT:
        rts                       ; Exit DELAY_1ms

; end subroutine DELAY_1ms
;


						  
.area interrupt_vectors (abs)
.org    $FFFE             ; At reset vector location
.word   __start           ; Load starting address												