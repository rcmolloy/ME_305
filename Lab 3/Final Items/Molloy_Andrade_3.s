; Robert Cory Molloy & Oscar Andrade
; ME 305 - 02 :: Intro to Mechatronics
; Labratory 3 ::  

;
;===========================Assembler Equates===================================================
;

PORTS        = $00D6              ; Output Port for LEDs
DDRS         = $00D7			  ; Setting Ports in S as Outputs
LED_MSK_1    = 0b00000011         ; LED_1 Output Pins
LED_MSK_2    = 0b00001100         ; LED_2 Output pins
R_LED_1      = 0b00000001         ; Red LED_1 Output Pin
G_LED_1      = 0b00000010         ; Green LED_1 Output Pin
R_LED_2      = 0b00000100         ; Red LED_2 Output Pin
G_LED_2      = 0b00001000         ; Green LED_2 Output Pin

;
;===============================RAM area================================================
;

.area bss

; Task Variables

mmState::			.blkb 1		; Master Mind State Variable
kpdState::			.blkb 1    	; Key Pad Driver State Variable
displayState::		.blkb 1   	; Display State Variable
pattern1State::		.blkb 1  	; Pattern 1 State Variable
timing1State::		.blkb 1   	; Timing 1 State Variable
pattern2State::		.blkb 1     ; Pattern 2 State Variable
timing2State::		.blkb 1		; Timing 2 State Variable
dlyState::			.blkb 1		; Delay State Variable
backspaceState::	.blkb 1		; Backspace State Variable
errorDelayState::   .blkb 1		; Error Delay State Variable
delayState::		.blkb 1		; Delay State Variable


; Flag Variables

keyFlag::			.blkb 1		; Notify Program a Key Has Been Pressed
F1Flag::			.blkb 1		; Notify Program a F1 Key Has Been Pressed
F2Flag::			.blkb 1		; Notify Program a F2 Key Has Been Pressed
echoFlag::			.blkb 1		; Notify Program that a Key Needs to Be Echoed
enterFlag::			.blkb 1		; Notify Program that Enter Procedure is Done
enterErrorInit::	.blkb 1		; Notify Program an Enter Key Error Has Occured
emptyValuePrint::	.blkb 1		; Notify Program No Value Has Been Entered
firstChar::			.blkb 1		; Notify Program the First Key is Ready
clearFlag::			.blkb 1		; Notify Program that the F1 / F2 Line Needs to Be Cleared
backspaceFlag::		.blkb 1		; Notify Program that the F1 / F2 Line Needs to Be Cleared
pattern1Done::		.blkb 1		; Notify Program that Pattern 1 Delay is Done
pattern2Done::		.blkb 1  	; Notify Program that Pattern 2 Delay is Done
errorDelayFlag::	.blkb 1
errorDelayDone::	.blkb 1
cursorMoveFlag::	.blkb 1
fromPreviousPrint:: .blkb 1

; Print Variables

displayF1Print:: 	.blkb 1		; Notify Program to Move Forward in Displaying F1 Message
displayF2Print:: 	.blkb 1		; Notify Program to Move Forward in Displaying F2 Message 
digitPrint::		.blkb 1		; Notify Program to Move Forward in Displaying F1/F2 Digit
valueTooBigPrint::	.blkb 1		; Notify Program to Move Forward in Displaying Value Too Big
zeroTicksPrint::	.blkb 1		; Notify Program to Move Forward in Displaying Zero Value Message
backSpacePrint::	.blkb 1		; Notify Program the Backspace Key Has Been Pressed

; Storing Variables

digitStore::		.blkb 1		; Store Most Recent Digit Pressed
buffer::			.blkb 5		; Store All Digits for Processing to Ticks
result::			.blkb 2		; Stores
pattern1Ticks::		.blkb 2
pattern2Ticks::		.blkb 2

; Counter Variables

digitCounter::		.blkb 1		; Counts Up Digit Input into buffer
clrBufferCounter::  .blkb 1
errorDelayCounter::	.blkb 2
pattern1Counter::		.blkb 2
pattern2Counter::		.blkb 2

; Other Variables

pointer::		    .blkb 2		
displayPointer::	.blkb 2

.area text

;
;==========================  Main Program  ======================================
;

_main::

	bgnd
	jsr    	INIT        		; Initialization
	
TOP: 
  
	bgnd
	
	jsr    	MASTERMIND			; Mastermind Sub-Routines

	jsr    	KPD		  			; Key Pad Driver Sub-Routines

	jsr    	DISPLAY      		; Display Sub-Routines
	
	jsr    	LED_PATTERN_1       ;
	
	jsr    	LED_TIMING_1        ;
	
	jsr    	LED_PATTERN_2       ;
	
	jsr    	LED_TIMING_2        ;   

	jsr		DELAY				; Delay Sub-Routine
	
    bra		TOP

;
;==========================  Initialization  =======================================
;

INIT:

	clr		mmState				; Initialize  All Sub-Routine State Variables to State 0
	clr	  	kpdState
	clr		displayState
	clr		pattern1State			
	clr		timing1State
	clr		pattern2State
	clr		timing2State
	clr		dlyState
	clr		backspaceState
	rts	
	   
;
;==========================  Mastermind Sub-Routine  ===============================
;

MASTERMIND:

	ldaa	mmState				; Grabbing the current state of Mastermind & Branching
	lbeq	mmstate0			; Initialization of Mastermind & Buffer 
	deca
	lbeq	mmstate1			; Splash Screen and Setting Displays Flags
	deca
	lbeq	mmstate2			; Mastermind Hub
	deca
	lbeq	mmstate3			; F1 State
	deca
	lbeq	mmstate4			; F2 State
	deca
	lbeq	mmstate5			; Backspace State
	deca
	lbeq	mmstate6			; Enter State
	deca
	lbeq	mmstate7			; Digit State
	deca
	lbeq	mmstate8			; Error Wait State
	rts							; Return to Main 

;
;==========  Mastermind State 0 - Initialization of Mastermind & Buffer  ============
;

mmstate0:	
					
	   movw		#buffer, pointer 		; Stores the
	   clr		buffer					; Clear the buffer Variable
	   movw		#$0000, result			; Clear the result Variable
	   movb		#$01, mmState			; Set the Mastermind State Variable to 1    
	   rts

;
;===============  Mastermind State 1 - Splash Screen and Setting Displays Flags & Counters  ====
;

mmstate1:

	   movb		#$01, firstChar     	  ; Set firstChar flag to 1 (True) 
       movb   	#$01, displayF1Print	  ; Set displayF1Print flag to 1 (True)
	   movb   	#$01, displayF2Print	  ; Set displayF1Print flag to 1 (True)
	   movw     #1500, errorDelayCounter 
	   movb		#$00, errorDelayFlag
	   movw		#0000, pattern1Ticks
	   movw		#0000, pattern2Ticks
	   movb		#$02, mmState			  ; Set the Mastermind State Variable to 2 (Hub)
	   rts								  ; Return to Main


;
;===============  Mastermind State 2 - Hub  ============================
;

mmstate2:

	tst		errorDelayFlag
	bne 	ERROR_DELAY_TRUE
	tst 	keyFlag
	beq		NO_KEY
	clr 	keyFlag
	cmpb 	#$F1
	beq 	F1_TRUE
	cmpb 	#$F2
	beq		F2_TRUE
	cmpb 	#$08
	beq 	BS_TRUE
	cmpb 	#$0A
	beq 	ENT_TRUE
	lbra	DIGIT_TRUE

NO_KEY:
	
	movb 	#$02, mmState
	rts
	
F1_TRUE:
	
	movb 	#$03, mmState
	rts	
		
F2_TRUE:
	
	movb 	#$04, mmState
	rts

BS_TRUE:
	
	movb 	#$05, mmState
	rts
	
ENT_TRUE:
	
	movb 	#$06, mmState
	rts

DIGIT_TRUE:

	movb 	#$07, mmState
	rts
	
ERROR_DELAY_TRUE:

	movb 	#$08, mmState
	rts

;
;===============  Mastermind State 3 - F1 State   =================
;
	
mmstate3:
	
	tst 	F2Flag
	bne 	F2_IN_F1
	tst		F1Flag
	bne		F1_PREV
	tst		enterFlag
	bne		F1_ERASE	
	ldy		pattern1Ticks
	cpy		#$0000
	bne		F1_ERASE_TICKS
	clr		digitCounter
	clr 	buffer 
	movb	#$01, F1Flag
	movb	#$01, echoFlag
	movb	#$01, firstChar
	movb 	#$02, mmState
	rts

F2_IN_F1:

    movb   #$02, mmState       ; Set next state to: M^2 HUB
    movb   #$00, F1Flag        ; Clear F1FLAG
	rts
	
F1_PREV:

    movb   #$02, mmState       ; Set next state to: M^2 HUB
	rts
	
F1_ERASE:
	movb   #$01, firstChar
	movb   #$01, F1Flag
	movb   #$01, clearFlag
	movb   #$02, mmState	   
	rts
	
F1_ERASE_TICKS:
	movb   #$01, firstChar
	movb   #$01, F1Flag
	movb   #$01, clearFlag
	movb   #$02, mmState 	   
	rts
	 
;
;===============  Mastermind State 4 - F2 State   =================
;
	
mmstate4:
	
	tst 	F1Flag
	bne 	F1_IN_F2
	tst 	F2Flag
	bne 	F2_PREV
	tst		enterFlag
	bne		F2_ERASE
	ldy		pattern2Ticks
	cpy		#$0000
	bne		F2_ERASE_TICKS
	clr 	digitCounter
	clr 	buffer
	movb	#$01, F2Flag
	movb	#$01, echoFlag
	movb	#$01, firstChar
	movb 	#$02, mmState
	rts
	
	
F1_IN_F2:

    movb   #$02, mmState       
    movb   #$00, F2Flag        
	rts

F2_PREV:

    movb   #$02, mmState       
	rts	

F2_ERASE:

	movb   #$01, firstChar
	movb   #$01, F2Flag
	movb   #$01, clearFlag
	movb   #$02, mmState
	rts

F2_ERASE_TICKS:

	movb   #$01, firstChar
	movb   #$01, F2Flag
	movb   #$01, clearFlag
	movb   #$02, mmState 	   
	rts	
;
;===============  Mastermind State 5 - Backspace State   =================
;
	
mmstate5:
	
	tst 	digitCounter
	beq 	BSPACE_DONE
	dec		digitCounter
	ldx 	pointer
	dex 	
	stx		pointer
	movb 	#$01, backspaceFlag
	movb 	#$02, mmState
	rts
	
	
BSPACE_DONE:

	movb 	#$02, mmState
	rts

;
;===============  Mastermind State 6 - Enter State   =================
;
	
mmstate6:
	
	tst 	F1Flag
	bne 	ENTER_MAIN
	tst 	F2Flag
	bne 	ENTER_MAIN
	movb 	#$02, mmState
	rts
	
	
ENTER_MAIN:

	tst 	digitCounter
	lbeq 	EMPTY_VALUE
	bra 	ASCII_BCD

ASCII_BCD:

		movw    #buffer, pointer
		
	LOOP:

		ldy 	#$000A                        
		ldd 	result                        
		emul                             
		cpy 	#$0000                        
		bne 	TOO_BIG_INIT                       
		std 	result                        
		ldx 	pointer                       
		ldab 	0,x                          
		subb 	#$30                        
		clra                              
		addd 	result                       
		std 	result                      
		dec 	digitCounter
		tst		digitCounter                       
		beq 	TICKS_PUSH_MAIN                    
		inx                             
		stx		pointer
		bra 	LOOP                                

TOO_BIG_INIT:

	movb	#$01, valueTooBigPrint
	movw	#$0000, result
	jsr		CLEAR_BUFFER
	movw    #buffer, pointer
	movb	#$00, enterFlag
	movb	#$02, mmState
	rts		
	
TICKS_PUSH_MAIN:

	ldx		result
	cpx		#$0000
	beq		ZERO_TICKS
	tst		F1Flag
	bne		F1_TICKS_PUSH
	tst		F2Flag
	bne		F2_TICKS_PUSH
	bra		ENTER_DONE
	
ZERO_TICKS:
	movb	#$01, zeroTicksPrint
	movw	#$0000, result
	jsr		CLEAR_BUFFER
	movw    #buffer, pointer
	movb	#$00, enterFlag
	movb	#$02, mmState
	movb	#$01, errorDelayFlag
	rts
	
F1_TICKS_PUSH:
	
	movw	result, pattern1Ticks
	bra		ENTER_DONE
	
F2_TICKS_PUSH:
	
	movw	result, pattern2Ticks
	bra		ENTER_DONE
		
EMPTY_VALUE:
	
	movb	#$01, emptyValuePrint
	movb 	#02,  mmState	
	rts
	
ENTER_DONE:

	clr		F1Flag
	clr		F2Flag
	movw	#$0000, result
	jsr		CLEAR_BUFFER
	clr	digitCounter
	movw    #buffer, pointer
	movb	#$00, enterFlag
	movb	#$02, mmState
	rts          			

;
;====================  Mastermind State 7 - Digit True   ======================
;

mmstate7:

	cmpb	#$41				
	lblo	DIGIT				
	bra		NOTDIGIT			
	
DIGIT:

	jsr		BUFFER_STORE
	movb	#$02, mmState		
	movb	#$01, echoFlag
	movb	#$00, keyFlag	
	rts

NOTDIGIT:

	movb	#$02, mmState	
	movb	#$00, keyFlag	
	rts

;
;====================  Mastermind State 8 - Error Delay State   ================
;	
	
mmstate8: 
		
		ldaa   errorDelayState
        beq    errordelaystate0
        deca
        beq    errordelaystate1
        rts                       

errordelaystate0:                         
        movb   #$01, errorDelayState      
		rts
		
errordelaystate1:                         
        ldx    errorDelayCounter
		cpx	   #$0000
		beq	   ERROR_DELAY_DONE
        dex                       
        stx    errorDelayCounter               
        rts
	
ERROR_DELAY_DONE:
		tst      F1Flag
		bne		 F1_DELAY_DONE
		tst      F2Flag
		bne		 F2_DELAY_DONE
  		movw     #1500, errorDelayCounter		 
        movb     #$00, errorDelayState
		movb     #$00, errorDelayFlag
		movb     #$01, errorDelayDone
		movb     #$02, mmState
		movb     #$01, clearFlag
		movb     #$01, firstChar
		rts
		
F1_DELAY_DONE:

		ldy		 pattern1Ticks
		cpy		 #$0000
		beq		 FIRST_AROUND_1
  		movw     #1500, errorDelayCounter		 
        movb     #$00, errorDelayState
		movb     #$00, errorDelayFlag
		movb     #$01, errorDelayDone
		movb     #$02, mmState
		movb     #$01, clearFlag
		movb     #$01, firstChar
		rts
		
F2_DELAY_DONE:

		ldy		 pattern2Ticks
		cpy		 #$0000
		beq		 FIRST_AROUND_2
  		movw     #1500, errorDelayCounter		 
        movb     #$00, errorDelayState
		movb     #$00, errorDelayFlag
		movb     #$01, errorDelayDone
		movb     #$02, mmState
		movb     #$01, clearFlag
		movb     #$01, firstChar
		rts
		
FIRST_AROUND_1:
  		movw     #1500, errorDelayCounter		 
        movb     #$00, errorDelayState
		movb     #$00, errorDelayFlag
		movb     #$02, mmState
		movb     #$01, clearFlag
		movb     #$01, firstChar
		rts
		
FIRST_AROUND_2:
  		movw     #1500, errorDelayCounter		 
        movb     #$00, errorDelayState
		movb     #$00, errorDelayFlag
		movb     #$02, mmState
		movb     #$01, clearFlag
		movb     #$01, firstChar
		rts
;
;=========  Mastermind - Miscellaneous Sub-Rountines / Branches   ==============
;

BUFFER_STORE:

	ldaa digitCounter
	cmpa #$05
	bhi BUFFER_STORE_LIMIT
	ldx  pointer                    
	ldab digitStore					
	stab 0,x                        
	inc  digitCounter               
	inx                             
	stx  pointer                    
	rts								
	
BUFFER_STORE_LIMIT:

	dec digitCounter
	rts	
	
CLEAR_BUFFER:
		
		movb 	   #$00, clrBufferCounter
		movw 	   #buffer, pointer
		
	C_B_LOOP:
	
		 ldx  	   pointer
		 ldab	   #$00
		 stab 	   0,x
		 inc	   clrBufferCounter
		 ldaa	   clrBufferCounter
		 cmpa	   #$05
		 beq	   CLEAR_BUFFER_DONE
		 ldx	   pointer
		 inx  	   
		 stx	   pointer
		 bra	   C_B_LOOP
		 
CLEAR_BUFFER_DONE:
		
		clr		  digitCounter		  
		rts
		 
	
;
;=========================  Key Pad Driver Sub-Routine   =======================
;

KPD:

	   ldaa		kpdState			
	   lbeq		kpdstate0			
	   deca
	   lbeq		kpdstate1			
	   rts							 

;
;========  Key Pad Driver State 0 - Initialization of Key Pad Driver   =========
;

kpdstate0: 	
			
       jsr      INITKEY             
       jsr      FLUSH_BFR           
       jsr      KP_ACTIVE           
       movb     #$01, kpdState      
       rts

;
;==  Key Pad Driver State 1 - Wait for the Key Press to Be Stored in Buffer   ==
;

kpdstate1:
       
       tst      L$KEY_FLG           
	   bne		NOKEYPRESS			
       jsr      GETCHAR             
	   stab		digitStore
	   movb		#$01, keyFlag
	   movb		#$01, kpdState		
	   rts

NOKEYPRESS:

	   movb #$01,kpdState			
	   rts	  	   
	   
;
;=============================  Display Sub-Routine   ==========================
;

DISPLAY:

	   ldaa		displayState
	   lbeq		displaystate0
	   deca
	   lbeq		displaystate1 
	   deca
	   lbeq		displaystate2
	   deca
	   lbeq		displaystate3
	   deca
	   lbeq		displaystate4
	   deca
	   lbeq		displaystate5
	   deca
	   lbeq		displaystate6     
	   deca
	   lbeq     displaystate7
	   deca
	   lbeq     displaystate8
	   deca
	   lbeq     displaystate9
	   rts							
	   
;
;=============  Display State 0 - Initialize LCD Screen & Cursor   =============
;
	   
displaystate0: 	
			
	   jsr		INITLCD               
	   jsr  	CLRSCREEN             
	   jsr  	CURSOR               
	   movb		#$01, displayState    
	   rts

;
;=============  Display State 1 - Display Hub   =============
;
	   
displaystate1:

	   bgnd
	   tst    	displayF1Print           
       bne    	F1_INIT_PRINT
	   tst		displayF2Print
	   bne    	F2_INIT_PRINT
	   tst		echoFlag
	   bne		KEY_INIT_PRINT
	   tst		clearFlag
	   bne		CLEAR_PRINT
	   tst		backspaceFlag
	   bne		BACKSPACE_PRINT 
	   tst      emptyValuePrint
	   bne      EMPTY_VALUE_PRINT 
	   tst      zeroTicksPrint
	   bne      ZERO_TICKS_PRINT 
	   tst      valueTooBigPrint
	   bne      VALUE_TOO_BIG   
       movb 	#$01, displayState     
       rts

F1_INIT_PRINT:
	
	   movb     #$02, displayState
	   rts

F2_INIT_PRINT:
	
	   movb     #$03, displayState
	   rts

KEY_INIT_PRINT:
	
	   movb     #$04, displayState
	   rts
	   
CLEAR_PRINT:
			
	   movb		#$05, displayState
	   rts

BACKSPACE_PRINT:

	   movb		#$06, displayState
	   rts	   
	   
EMPTY_VALUE_PRINT:
				  
		movb    #$07, displayState
		rts
		
ZERO_TICKS_PRINT:
		
		movb    #$08, displayState
		rts
		
VALUE_TOO_BIG:
		
		movb    #$09, displayState
		rts
	   
;
;===============  Display State 2 - Display Initial F1 Message   ===============
;

displaystate2:

       ldaa   	#$00                    
       ldx    	#F1_INIT_MESSAGE    
       jsr    	DISPLAY_CHAR   	
       ldx    	displayPointer    
       ldab   	0,x               
       lbeq   	DONE_F1_INIT_PRINT  
       rts

F1_INIT_MESSAGE:

       .ascii 	'TIME1=        <F1> TO UPDATE LED1 PERIOD'
       .byte  	$00
	   rts               

DONE_F1_INIT_PRINT:
				
	   clr		displayF1Print
	   movb		#$01, displayState
	   movb		#$01, firstChar
	   rts
	   
;
;===============  Display State 3 - Display Initial F2 Message   ===============
;

displaystate3:

       ldaa   	#$40                    
       ldx    	#F2_INIT_MESSAGE    
       jsr    	DISPLAY_CHAR   	
       ldx    	displayPointer    
       ldab   	0,x               
       lbeq   	DONE_F2_INIT_PRINT  
       rts

F2_INIT_MESSAGE:

       .ascii 	'TIME2=        <F2> TO UPDATE LED2 PERIOD'
       .byte  	$00               
	   rts
	   
DONE_F2_INIT_PRINT:
				
	   clr		displayF2Print
	   movb		#$01, displayState
	   movb		#$01, firstChar
	   rts

;
;======  Display State 4 - Initializing & Printing Digit for F1 / F2   =========
;

displaystate4:

	   tst	  F1Flag
	   bne	  F1_PRINT
	   tst	  F2Flag
	   bne	  F2_PRINT
	   movb	  #$01, displayState
	   rts
	   
F1_PRINT:

	   tst	    errorDelayDone
	   bne		F1_PRINT_ERROR_DONE
	   tst		cursorMoveFlag
	   bne		F1_CURSOR_MOVE_PRINT_DONE
       ldaa   	digitCounter
	   cmpa		#$00
	   bne		DIGIT_NOT_FIRST
	   ldaa		#$07
	   jsr		SETADDR
	   tst		fromPreviousPrint
	   bne		INIT_PRINT_DONE
	   cmpb		#$F1
	   beq		INIT_PRINT_DONE
	   bra		PRINT_FIRST_DIGIT
	   
F2_PRINT:

	   tst	    errorDelayDone
	   bne		F2_PRINT_ERROR_DONE
	   tst		cursorMoveFlag
	   bne		F1_CURSOR_MOVE_PRINT_DONE
       ldaa   	digitCounter
	   cmpa		#$00
	   bne		DIGIT_NOT_FIRST
	   ldaa		#$47
	   jsr		SETADDR
	   tst		fromPreviousPrint
	   bne		INIT_PRINT_DONE
	   cmpb		#$F2
	   beq		INIT_PRINT_DONE
	   bra		PRINT_FIRST_DIGIT
       
PRINT_FIRST_DIGIT:

	   ldab 	digitStore
	   jsr		OUTCHAR
	   bra		INIT_PRINT_DONE
	   
DIGIT_NOT_FIRST:

	   ldaa		digitCounter
	   cmpa		#$05
	   bgt		INIT_PRINT_DONE		
	   ldab		digitStore
	   jsr		OUTCHAR 
	   bra		INIT_PRINT_DONE
	   
INIT_PRINT_DONE:

	   clr		echoFlag
	   movb		#01, displayState
	   rts
	   
F1_PRINT_ERROR_DONE:

	   movb	    #$00, errorDelayDone
	   movb		#$00, F1Flag
	   movb		#$01, displayState
	   rts
	   
F2_PRINT_ERROR_DONE:

	   movb	    #$00, errorDelayDone
	   movb		#$00, F2Flag
	   movb		#01, displayState
	   rts
	   
F1_CURSOR_MOVE_PRINT_DONE:

	   movb	    #$00, cursorMoveFlag
	   movb		#$01, F1Flag
	   movb		#$01, displayState
	   rts

F2_CURSOR_MOVE_PRINT_DONE:

	   movb	    #$00, cursorMoveFlag
	   movb		#$01, F2Flag
	   movb		#$01, displayState
	   rts
	   	   
;
;======  Display State 5 - Clearing & Printing Prompt for F1 / F2   ================
;

displaystate5:

	  tst	  F1Flag
	  bne	  F1_CLEAR
	  tst	  F2Flag
	  lbne	  F2_CLEAR
	  lbra	  ERROR_CLEAR_PRINT
	  
F1_CLEAR:

       ldaa   	#$06                   
       ldx    	#F1_PROMPT_MESSAGE    
       jsr    	DISPLAY_CHAR   	
       ldx    	displayPointer    
       ldab   	0,x               
       lbeq   	DONE_F1_CLEAR_PRINT  
       rts

F1_PROMPT_MESSAGE:

       .ascii 	'        <F1> TO UPDATE LED1 PERIOD'
       .byte  	$00
	   rts 
	   
DONE_F1_CLEAR_PRINT:
			
	   ldy	    pattern1Ticks
	   cpy		#$0000
	   lbne		DONE_F1_CLEAR_PRINT_TICKS		
	   clr		enterFlag
	   clr		clearFlag
	   movb		#$00, F1Flag
	   movb		#$04, displayState
	   movb		#$01, firstChar
	   movb	    #$01, cursorMoveFlag
	   jsr		CLEAR_BUFFER
	   movw		#buffer, pointer
	   rts 

DONE_F1_CLEAR_PRINT_TICKS:

	   clr		enterFlag
	   clr		clearFlag
	   movb		#$01, F1Flag
	   movb		#$04, displayState
	   movb		#$01, firstChar
	   movb		#$01, fromPreviousPrint
	   jsr		CLEAR_BUFFER
	   movw		#buffer, pointer
	   rts
	     
F2_CLEAR:
	
       ldaa   	#$46                    
       ldx    	#F2_PROMPT_MESSAGE    
       jsr    	DISPLAY_CHAR   	
       ldx    	displayPointer    
       ldab   	0,x               
       lbeq   	DONE_F2_CLEAR_PRINT  
       rts

F2_PROMPT_MESSAGE:

       .ascii 	'        <F2> TO UPDATE LED2 PERIOD'
       .byte  	$00
	   rts               

DONE_F2_CLEAR_PRINT:
	
	   ldy	    pattern2Ticks
	   cpy		#$0000
	   lbne		DONE_F2_CLEAR_PRINT_TICKS						
	   clr		enterFlag
	   clr		clearFlag
	   movb		#$00, F2Flag
	   movb		#$04, displayState
	   movb		#$01, firstChar
	   movb	    #$01, cursorMoveFlag
	   jsr		CLEAR_BUFFER
	   movw		#buffer, pointer
	   rts

DONE_F2_CLEAR_PRINT_TICKS:

	   clr		enterFlag
	   clr		clearFlag
	   movb		#$01, F2Flag
	   movb		#$04, displayState
	   movb		#$01, firstChar
	   movb		#$01, fromPreviousPrint
	   jsr		CLEAR_BUFFER
	   movw		#buffer, pointer
	   rts
	   
ERROR_CLEAR_PRINT:

	   movb		#$00, mmState
	   rts	   
;	   
;======================== Display State 6 - Backspace   ============================
;

displaystate6:
		
		ldaa backspaceState
		lbeq backspacestate0
		deca
		lbeq backspacestate1
		deca
		lbeq backspacestate2
		
backspacestate0:
		
		ldab #$08
		jsr	 OUTCHAR
		movb #$01, backspaceState
		rts
		
backspacestate1:

		ldab #$20
		jsr	 OUTCHAR
		movb #$02, backspaceState
		rts
		
backspacestate2:	
		
		ldab #$08
		jsr	 OUTCHAR
		movb #$00, backspaceState
		movb #$01, displayState
		clr	 backspaceFlag
		rts
		
;======================== Display State 7 - No Digits Entered Print ============

displaystate7:

	   tst		F1Flag
	   bne		F1_NO_DIGITS
	   tst		F2Flag
	   bne		F2_NO_DIGITS
	   movb		#$01, displayState
	   rts
	   
F1_NO_DIGITS:	
   
       ldaa   	#$07                    
       ldx    	#NO_DIGITS_PRINT    
       jsr    	DISPLAY_CHAR   	
       ldx    	displayPointer    
       ldab   	0,x               
       lbeq   	DONE_NO_DIGITS_PRINT  
       rts
	   
F2_NO_DIGITS:	
   
       ldaa   	#$47                    
       ldx    	#NO_DIGITS_PRINT    
       jsr    	DISPLAY_CHAR   	
       ldx    	displayPointer    
       ldab   	0,x               
       lbeq   	DONE_NO_DIGITS_PRINT  
       rts

NO_DIGITS_PRINT:

       .ascii 	'NO DIGITS ENTERED!               '
       .byte  	$00
	   rts               

DONE_NO_DIGITS_PRINT:
				
	   clr		emptyValuePrint
	   movb		#$01, errorDelayFlag
	   movb		#$01, displayState
	   rts
	   
;======================== Display State 8 - All Zeros Entered Print ============

displaystate8:

	   tst		F1Flag
	   bne		F1_ALL_ZEROS
	   tst		F2Flag
	   bne		F2_ALL_ZEROS
	   movb		#$01, displayState
	   rts
	   
F1_ALL_ZEROS:
	   
       ldaa   	#$07                    
       ldx    	#ZERO_DIGITS_PRINT    
       jsr    	DISPLAY_CHAR   	
       ldx    	displayPointer    
       ldab   	0,x               
       lbeq   	DONE_ZERO_DIGITS_PRINT  
       rts
	   
F2_ALL_ZEROS:
	   
       ldaa   	#$47                    
       ldx    	#ZERO_DIGITS_PRINT    
       jsr    	DISPLAY_CHAR   	
       ldx    	displayPointer    
       ldab   	0,x               
       lbeq   	DONE_ZERO_DIGITS_PRINT  
       rts

ZERO_DIGITS_PRINT:

       .ascii 	'ZERO MAGNITUDE INVALID!          '
       .byte  	$00
	   rts               

DONE_ZERO_DIGITS_PRINT:
				
	   clr		zeroTicksPrint
	   movb		#$01, errorDelayFlag
	   movb		#$01, displayState
	   rts
		
;		
;======================== Display State 9 - Value Too Big Print    ====================
;

displaystate9:

	   tst		F1Flag
	   lbne		F1_TOO_BIG
	   tst		F2Flag
	   lbne		F2_TOO_BIG
	   movb		#$01, displayState
	   rts
	   
F1_TOO_BIG:
	   
       ldaa   	#$07                    
       ldx    	#TOO_BIG_PRINT    
       jsr    	DISPLAY_CHAR   	
       ldx    	displayPointer    
       ldab   	0,x               
       lbeq   	DONE_TOO_BIG_PRINT  
       rts
	   
F2_TOO_BIG:
	   
       ldaa   	#$47                    
       ldx    	#TOO_BIG_PRINT    
       jsr    	DISPLAY_CHAR   	
       ldx    	displayPointer    
       ldab   	0,x               
       lbeq   	DONE_TOO_BIG_PRINT  
       rts

TOO_BIG_PRINT:

       .ascii 	'MAGNITUDE TOO LARGE!             '
       .byte  	$00
	   rts               

DONE_TOO_BIG_PRINT:
				
	   movb		#$00, valueTooBigPrint
	   movb		#$01, errorDelayFlag
	   movb		#$01, displayState
	   rts
	  
;	   
;=========  Display - Miscellaneous Sub-Rountines / Branches   =====================
;

DISPLAY_CHAR:

      tst    firstChar              ; Test firstChar to Raise Flags
      beq    DISPLAY_WRITE          ; Branch to DISPLAY_WRITE if firstChar = 0 (FALSE)
      stx    displayPointer         ; Store value of x into displayPointer
	  jsr    SETADDR                ; Set cursor to particular LCD address in A
      clr    firstChar              ; Clear firstChar
      rts

DISPLAY_WRITE:
      ldx    displayPointer         ; Load x with value in Display Pointer
      inx                           ; Increment x
      stx    displayPointer         ; Store Display Pointer with incremented x
      jsr    OUTCHAR                ; Print character
      rts  

            ;          
            ;=========  LED Pattern 1 - Sub-Rountine  =====================
            ;
            
            LED_PATTERN_1: 
            
          ldaa   pattern1State        ; get current pattern1State and branch accordingly
            beq    pattern1state0              
             deca
           beq    pattern1state1       ; G, not R
             deca
            beq    pattern1state2       ; not G, not R
             deca
        lbeq   pattern1state3       ; not G, R
             deca
       lbeq   pattern1state4       ; not G, not R
             deca
       lbeq   pattern1state5       ; G, R
             deca
       lbeq   pattern1state6       ; not G, not R
             deca
           lbeq   pattern1state7
             rts                         ; Undefined state - Do Nothing but Return
            
           ;               
            ;======================== LED Pattern 1 State 0 - Initializing Ports    ====================
           ;         
            
           pattern1state0:                         
        bclr   PORTS, LED_MSK_1     
        bset   DDRS, LED_MSK_1     
       movb   #$01, pattern1State        
              rts
           
            ;               
            ;======================== LED Pattern 1 State 1 - Green On and Red Off    ====================
           ;                 
            
           pattern1state1:					; G, not R 
                        
          tst    F1Flag
           beq    PATTERN_1_1 
          movb   #$07, pattern1State 
                  rts  
                      
           PATTERN_1_1:
            
        bset   PORTS, G_LED_1     
          tst    pattern1Done               
        lbeq   EXIT_P1           
        movb   #$02, pattern1State        
              rts
            
            ;               
            ;======================== LED Pattern 1 State 2 - Green Off and Red Off ====================
            ;
                            
            pattern1state2: 				  ; not G, not R
                                    		  
         tst    F1Flag
           beq    PATTERN_1_2 
          movb   #$07, pattern1State
              rts  
                     
            PATTERN_1_2:
            
        bclr   PORTS, G_LED_1      
         tst    pattern1Done               
        lbeq    EXIT_P1           
       movb   #$03, pattern1State     
              rts
                      
           ;               
            ;======================== LED Pattern 1 State 3 - Green Off and Red On ====================
             ;               
                             
             pattern1state3: 
                              ; not G, R
         tst    F1Flag
            beq    PATTERN_1_3 
          movb   #$07, pattern1State 
             rts  
                      
           PATTERN_1_3:
            
        bset   PORTS, R_LED_1       
          tst    pattern1Done              
           beq    EXIT_P1           
       movb   #$04, pattern1State      
                  rts
                    
           ;               
            ;======================== LED Pattern 1 State 4 - Green Off and Red Off ====================
           ;                       
                            
            pattern1state4:  
                             ; not G, not R
          tst    F1Flag
            beq    PATTERN_1_4
       movb   #$07, pattern1State 
                  rts  
                      
            PATTERN_1_4:
            
       bclr   PORTS, LED_MSK_1     
          tst    pattern1Done              
           beq    EXIT_P1            
       movb   #$05, pattern1State       
           rts
            
            ;               
            ;======================== LED Pattern 1 State 5 - Green On and Red On ====================
            ;
                                           
            pattern1state5:  
                                   ; G, R
        tst    F1Flag
      lbeq   PATTERN_1_5
         movb   #$07, pattern1State 
                 rts  
                    
           PATTERN_1_5:
         
       bset   PORTS, LED_MSK_1     
    tst    pattern1Done               
           beq    EXIT_P1            
       movb   #$06, pattern1State        
             rts
                    
            ;               
           ;======================== LED Pattern 1 State 6 - Green Off and Red Off ====================
           ;         
                            
           pattern1state6:     
                               ; not G, not R
            tst     F1Flag
                     beq             PATTERN_1_6
                movb    #$07, pattern1State 
                        rts  
                            
           PATTERN_1_6:
           
          bclr    PORTS, LED_MSK_1   
            tst     pattern1Done             
              beq     EXIT_P1          
         movb           #$01, pattern1State      
                       rts
                          
           ;               
           ;======================== LED Pattern 1 State 7- LED Pattern 1 Reset ====================
           ;       
                           
            pattern1state7:
           
          bclr   PORTS, LED_MSK_1   ; set not green not red
                    clr    pattern1Done
                    tst    F1Flag
                      beq    RESET_P1
                        rts
            
            ;               
            ;======================== LED Pattern 1 - Miscellaneous Sub-Rountines / Branches ====================
			           ;
                           
            RESET_P1:
            
        movb  #$01, pattern1State              
                        rts
          
           EXIT_P1:        
            
                       rts
            
           ;               
            ;======================== LED Timing 1 - Sub-Rountine ====================
            ;
                            
            LED_TIMING_1: 
           
            ldaa   timing1State            ; get current t5state and branch accordingly
             beq    timing1state0
                deca
              beq    timing1state1
                        deca
                     beq    timing1state2
                rts                       ; undefined state - do nothing but return
           
           ;               
            ;======================== LED Timing 1 State 1 - Intialization ====================
           ;               
           
           timing1state0:                         ; initialization for TASK_5
          clr    pattern1Done
                ldy    pattern1Ticks
                     cpy    #$0000
                   lbne   PATTERN_1_TICKS_ENT
         movb   #$00, timing1State      ; set next state
                rts
                           
           ;               
            ;======================== LED Timing 1 State 2 - Re-Intialization of Count ====================
            ;
                           
           timing1state1:                         ; (re)initialize COUNT_1
        movw   pattern1Ticks, pattern1Counter
           ldx    pattern1Counter
               dex                       ; decrement COUNT_1
            stx    pattern1Counter            ; store decremented COUNT_1
            clr    pattern1Done
         movb   #$02, timing1State      ; set next state
               rts
                           
           ;               
           ;======================== LED Timing 1 State 2 - Decrement Count & Run Loop ====================
           ;               
                           
           timing1state2:
              ; count down COUNT_1
           ldx    pattern1Counter
              beq    SET_DONE_1          ; test to see if COUNT_1 is already zero
               dex                       ; decrement COUNT_1
            stx    pattern1Counter           ; store decremented COUNT_1
			              bne    EXIT_TIMING_1          ; if not done, return
                       rts
            ;               
             ;======================== LED Timing 1 - Miscellaneous Sub-Rountines / Branches ====================
            ;       
                   
            PATTERN_1_TICKS_ENT:
            
         movb   #$01, timing1State
                       rts
            
            SET_DONE_1:
           
         movb   #$01, pattern1Done       ; if done, set DONE_1 flag
         movb   #$01, timing1State      ; set next state
                        rts
                           
            EXIT_TIMING_1:
               rts
            
            ;          
            ;=========  LED Pattern 2 - Sub-Rountine  =====================
            ;
            
           LED_PATTERN_2: 
           
         ldaa   pattern2State        ; get current pattern1State and branch accordingly
            beq    pattern2state0              
              deca
            beq    pattern2state1       ; G, not R
              deca
           beq    pattern2state2       ; not G, not R
             deca
        lbeq   pattern2state3       ; not G, R
             deca
       lbeq   pattern2state4       ; not G, not R
             deca
        lbeq   pattern2state5       ; G, R
              deca
       lbeq   pattern2state6       ; not G, not R
             deca
         lbeq   pattern2state7
              rts                         ; Undefined state - Do Nothing but Return
            
;               
;======================== LED Pattern 2 State 0 - Initializing Ports    ====================
;         
           
           pattern2state0:                         
       bclr   PORTS, LED_MSK_2     
       bset   DDRS, LED_MSK_2     
       movb   #$01, pattern2State        
              rts
            
            ;               
           ;======================== LED Pattern 2 State 1 - Green On and Red Off    ====================
            ;                 
            
           pattern2state1:					; G, not R 
                       
          tst    F2Flag
            beq    PATTERN_2_1 
          movb   #$07, pattern2State 
                  rts  
                      
            PATTERN_2_1:
            
        bset   PORTS, G_LED_2     
          tst    pattern2Done               
        lbeq    EXIT_P2            
       movb   #$02, pattern2State        
              rts
           
            ;               
            ;======================== LED Pattern 2 State 2 - Green Off and Red Off ====================
            ;
                            
            pattern2state2: 				  ; not G, not R
                                    		  
          tst    F2Flag
            beq    PATTERN_2_2 
         movb   #$07, pattern2State
              rts  
                      
            PATTERN_2_2:
            
        bclr   PORTS, G_LED_2      
           tst    pattern2Done               
       lbeq    EXIT_P2           
      movb   #$03, pattern2State     
             rts
                      
            ;               
            ;======================== LED Pattern 2 State 3 - Green Off and Red On ====================
            ;               
                          
            pattern2state3: 
                              ; not G, R
          tst    F2Flag
            beq    PATTERN_2_3 
          movb   #$07, pattern2State 
              rts  
                     
            PATTERN_2_3:
           
        bset   PORTS, R_LED_2       
          tst    pattern2Done              
            beq    EXIT_P2           
       movb   #$04, pattern2State      
                  rts
                   
            ;               
            ;======================== LED Pattern 2 State 4 - Green Off and Red Off ====================
           ;                       
                           
           pattern2state4:  
                            ; not G, not R
          tst    F2Flag
            beq    PATTERN_2_4
       movb   #$07, pattern2State 
                  rts  
                      
            PATTERN_2_4:
           
       bclr   PORTS, LED_MSK_2     
         tst    pattern2Done              
           beq    EXIT_P2            
       movb   #$05, pattern2State       
             rts
     
            ;               
            ;======================== LED Pattern 2 State 5 - Green On and Red On ====================
            ;
                                            
           pattern2state5:  
                                  ; G, R
         tst    F2Flag
      lbeq   PATTERN_2_5
          movb   #$07, pattern2State
                  rts  
                    
           PATTERN_2_5:
          
        bset   PORTS, LED_MSK_2     
         tst    pattern2Done               
            beq    EXIT_P2            
       movb   #$06, pattern2State        
             rts
                      
            ;               
            ;======================== LED Pattern 2 State 6 - Green Off and Red Off ====================
            ;         
                           
            pattern2state6:     
                                ; not G, not R
            tst     F2Flag
                      beq             PATTERN_2_6
                movb    #$07, pattern2State 
                       rts  
                           
            PATTERN_2_6:
           
         bclr    PORTS, LED_MSK_2   
           tst     pattern2Done             
             beq     EXIT_P2          
        movb           #$01, pattern2State      
                       rts
                            
            ;               
           ;======================== LED Pattern 1 State 7- LED Pattern 1 Reset ====================
           ;       
                          
            pattern2state7:
           
         bclr   PORTS, LED_MSK_2   ; set not green not red
                    clr    pattern2Done
                   tst    F2Flag
                       beq    RESET_P2
                        rts
            
           ;               
          ;======================== LED Pattern 1 - Miscellaneous Sub-Rountines / Branches ====================
            ;
                           
          RESET_P2:
         
        movb  #$01, pattern2State              
            rts
           
            EXIT_P2:        
            
                       rts
            
            ;               
            ;======================== LED Timing 2 - Sub-Rountine ====================
            ;
                           
            LED_TIMING_2: 
           
           ldaa   timing2State            ; get current t5state and branch accordingly
              beq    timing2state0
                deca
              beq    timing2state1
                        deca
                     beq    timing2state2
                rts                       ; undefined state - do nothing but return
            
            ;               
           ;======================== LED Timing 2 State 1 - Intialization ====================
            ;               
            
             timing2state0: 
           clr    pattern2Done
                ldy    pattern2Ticks
                    cpy    #$0000
                  lbne   PATTERN_2_TICKS_ENT
         movb   #$00, timing2State     ; set next state
                rts
                             
             ;               
           ;======================== LED Timing 2 State 2 - Re-Intialization of Count ====================
             ;
                           
          timing2state1:                         ; (re)initialize COUNT_1
         movw   pattern2Ticks, pattern2Counter
            ldx    pattern2Counter
             dex                       ; decrement COUNT_1
            stx    pattern2Counter            ; store decremented COUNT_1
             clr    pattern2Done
         movb   #$02, timing2State      ; set next state
               rts
                            
           ;               
           ;======================== LED Timing 1 State 2 - Decrement Count & Run Loop ====================
          ;               
                           
          timing2state2:
           			                             ; count down COUNT_1
           ldx    pattern2Counter
              beq    SET_DONE_2          ; test to see if COUNT_1 is already zero
                dex                       ; decrement COUNT_1
           stx    pattern2Counter           ; store decremented COUNT_1
             bne    EXIT_TIMING_2          ; if not done, return
                       rts
            ;               
            ;======================== LED Timing 2 - Miscellaneous Sub-Rountines / Branches ====================
           ;       
                   
          PATTERN_2_TICKS_ENT:
           
         movb   #$01, timing2State
                       rts     
                           
            SET_DONE_2:
           
         movb   #$01, pattern2Done       
        movb   #$01, timing2State      
                            
           EXIT_TIMING_2:
               rts
	       
;
;============================  Delay Sub-Routine   =================================
;
           
DELAY: 
           
 	  ldaa   delayState           
	  beq    delaystate0
	  deca
	  beq    delaystate1
	  rts                                     
               
;
;=====================  Delay State 0 - Initialize Delay   =========================
;
            
delaystate0:                  
                                               
	  movb   #$01, delayState     
	  rts

;
;=====================  Delay State 1 - Run 1ms Delay   ============================
;               
            
delaystate1:
           
	  jsr    DELAY_1MS
	  rts
            
DELAY_1MS:
           
	  ldy    #$0262
                            
INNER:                         
                   
	  cpy    #0
	  beq    EXIT
	  dey
      bra    INNER
                            
EXIT:
	  rts                       

;=====================================================================================
.area interrupt_vectors (abs)
.org    $FFFE             ; At reset vector location
.word   __start           ; Load starting address