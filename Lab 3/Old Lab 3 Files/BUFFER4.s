;reading a sequence of digits from the keypad and store them in buffer
;Contants
ENT_KEY =$000A

; RAM area
.area bss 

COUNT::      .blkb 1
POINTER::    .blkb 2
BUFFER::     .blkb 6
RESULT::     .blkb 2

 
;code area
;==============================================================================
.area text

;Main Program

_main::   
	   jsr  INITKEY                       ;Library command to initialize the keypad
	   jsr  FLUSH_BFR                     ;Library Command to flush the buffer
	   jsr  BUFFER_STR                    ;Storing numbers into buffer
	   jsr  ASCII_BCD                     ;Convert ASCII to BCD
;end main	
;========================================================================
BUFFER_STR:
		   bgnd
		   movb #$00, COUNT                ;Sets COUNT=6
	  	   movw #$00, RESULT               ;Sets RESULT=0
	  	   movw #BUFFER, POINTER           ;Stores BUFFER address into POINTER
	  LOOP:
	  	   jsr GETCHAR                     ;Wait for button on keypad has been pressed
		   bgnd
	  	   cmpb #ENT_KEY                   ;Check if enter key has been pressed
	       beq  RETURN                     ;If return key entered branch out
	       ldx  POINTER                    ;Load index register "X" with Pointer address
	       stab 0,x                        ;Stores the contents of B into X
	       inc  COUNT                      ;Increment the digit count
	       inx                             ;increment X
	       stx  POINTER                    ;Store X into pointer
	       bra  LOOP                       ;Branch Back to loop
	       
	
;END BUFFER_STR
;===========================================================================
RETURN:
      rts
;END RETURN
;============================================================================
ASCII_BCD:
		  movw #BUFFER, POINTER
		  bgnd
    LOOP2:
		  bgnd
		  ldy #$000A                        ;Load index register Y with 10
		  ldd RESULT                        ;Load accumualtor D with Result
		  EMUL                              ;Y*D = Y:D
		  CPY #$0000                        ;compare y to zero, to check for overflow
		  bne TOOBIG                        ;If too big, not a valid number
		  std RESULT                        ;Store contents of D in Result
		  ldx POINTER                       ;Load index register X with Result
		  ldab 0,x                          ;Loads Accumulator B with contents of X
		  subb #$30                         ;subtract 30 from the contents of B
		  clra                              ;Clear accumulator A, clearing the first two bits in accumulator D
		  addd RESULT                       ;Add the contents of D with the argment of Result and store back in D
		  std RESULT                        ;Store the contents of D into Result
		  dec COUNT                         ;Decrement the Digit Count
		  beq EXIT_CONV                     ;If Count=0, Get OUT!
		  inx                             ;Increment X, incremting the BUFFER address to be read from POINTER
		  stx POINTER                       ;Store X back into pointer
		  bne LOOP2                         ;Loop back
	
	 
;end ASCII_BCD 

TOOBIG:
	   bra TOOBIG	   
;end TOOBIG

EXIT_CONV:
	   bra EXIT_CONV   
;end EXIT_CONV



.area interrupt_vectors (abs)
.org    $FFFE             ; At reset vector location
.word   __start           ; Load starting address												