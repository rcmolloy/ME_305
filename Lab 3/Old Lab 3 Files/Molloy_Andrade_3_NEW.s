; Robert Cory Molloy & Oscar Andrade :: Lab 3

; RAM area
.area bss 
delayclear::    .blkb 1
mult:: 	.blkb 2
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
	   bgnd
	   
	   bra loop


; End Main
;==============================================================================
CHARPULL:		
			jsr GETCHAR	 					;
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

CLEAR:	       
				ldaa #$00 		 	;
				ldx #CLEARMESSAGE   ;
				jsr OUTSTRING		;
				rts		
; end CLEAR

CLEARMESSAGE:	.ascii '                                       ' ;
				.byte $00	  		 		;	
			
; end CLEARMESSAGE
					
DELAYCLEAR:     

				bgnd
	
					  				movw #5000, mult
	
				DELAYLOOP:			jsr DELAY
									
									bgnd
									
									ldx    mult
      								dex                   ; Decrement MULT
        							stx    mult     	  ; Store decremented MULT
									
									bne DELAYLOOP
									
						  			rts
; End DELAYCLEAR
				

; end subroutine DELAYCLEAR
;

DELAY:

				ldy    #$0262

		INNER:                            ; Inside loop
        		cpy    #0
                beq    EXIT
                dey
                bra    INNER
        EXIT:
                rts                       ; Exit DELAY_1ms

; End DELAY

						  
.area interrupt_vectors (abs)
.org    $FFFE             ; At reset vector location
.word   __start           ; Load starting address												