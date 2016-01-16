; ME 305-02: Intro to Mechatronics :: Robert Cory Molloy & Oscar Andrade
; Display Test Program for Labratory 3

;
;==============================================================================
;Assembler Equates

PORTS        = $00D6              ; Output Port for LEDs
DDRS         = $00D7			  ; Setting Ports in J as Outputs
LED_MSK_1    = 0b00000011         ; LED_1 Output Pins
LED_MSK_2    = 0b00001100         ; LED_2 Output pins
R_LED_1      = 0b00000001         ; Red LED_1 Output Pin
G_LED_1      = 0b00000010         ; Green LED_1 Output Pin
R_LED_2      = 0b00000100         ; Red LED_2 Output Pin
G_LED_2      = 0b00001000         ; Green LED_2 Output Pin

===============================================================================
; RAM area
.area bss

; Task Variables

mmState::			.blkb 1		; Master Mind State Variable
kpdState::			.blkb 1    	; Key Pad Driver State Variable
displayState::		.blkb 1   	; Display State Variable
pat1State::			.blkb 1  	; Pattern 1 State Variable
time1State::		.blkb 1   	; Timing 1 State Variable
pat2State::			.blkb 1     ; Pattern 2 State Variable
time2State::		.blkb 1		; Timing 2 State Variable
dlyState::			.blkb 1		; Delay State Variable
backspaceState::	.blkb 1		; Backspace State Variable
timingState::           .blkb 1  

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
DelayMessageFlag::  .blkb 1
No_Delay::          .blkb 1

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
TICKS1::			.blkb 2
TICKS2::			.blkb 2
COUNT_1::           .blkb 2
DONE_1::            .blkb 1
COUNT_2::           .blkb 2
DONE_2::            .blkb 1
TICKS_1::			.blkb 2
TICKS_2::			.blkb 2

; Counter Variables

digitCounter::		.blkb 1		; Counts Up Digit Input into buffer
clrBufferCounter::  .blkb 1

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
    
	;jsr     PATTERN_1
	
    jsr     TIMING_1
	
    ;jsr     PATTERN_2

    ;jsr     TIMING_2
	
	jsr     DELAY

	
    bra		TOP

;
;==========================  Initialization  =======================================
;

INIT:

	clr		mmState				; Initialize  All Sub-Routine State Variables to State 0
	clr	  	kpdState
	clr		displayState
	clr		pat1State			
	clr		time1State
	clr		pat2State
	clr		time2State
	clr		dlyState
	clr     timingState
	clr     COUNT_1
	clr     TICKS_1
	
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
	rts							; Return to Main 

;
;==========  Mastermind State 0 - Initialization of Mastermind & Buffer  ============
;

mmstate0:	
					
	   movw		#buffer, pointer 	; Stores the
	   clr		buffer				; Clear the BUFFER Variable
	   clr		result				; Clear the RESULT Variable
	   movb		#$01, mmState		; Set the Mastermind State Variable to 1
	   movb     #$00, No_Delay      ; Setting No Delay to Zero
	   movw     #999, TICKS_1      ; Set default for TICKS_1
       movw     #999, TICKS_2      ; Set default for TICKS_2
	   rts

;
;===============  Mastermind State 1 - Splash Screen and Setting Displays Flags  ====
;

mmstate1:

	   movb		#$01, firstChar     ; Set firstChar flag to 1 (True) 
       movb   	#$01, displayF1Print; Set displayF1Print flag to 1 (True)
	   movb   	#$01, displayF2Print; Set displayF1Print flag to 1 (True)
	   movb		#$02, mmState		; Set the Mastermind State Variable to 2 (Hub)
	   rts							; Return to Main


;
;===============  Mastermind State 2 - Hub  ============================
;

mmstate2:

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
	 
;
;===============  Mastermind State 4 - F2 State   =================
;
	
mmstate4:
	
	tst 	F1Flag
	bne 	F1_IN_F2
	tst 	F2Flag
	bne 	F1_IN_F2
	tst		enterFlag
	bne		F2_ERASE
	clr 	digitCounter
	clr 	buffer
	movb	#$01, F2Flag
	movb	#$01, echoFlag
	movb	#$01, firstChar
	movb 	#$02, mmState
	rts
	
	
F1_IN_F2:

    movb   #$02, mmState       ; Set next state to: M^2 HUB
    movb   #$00, F2Flag        ; Clear F2FLAG
	rts

F2_PREV:

    movb   #$02, mmState       ; Set next state to: M^2 HUB
	rts	

F2_ERASE:
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
	dec 	pointer
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
	jsr		CLEAR_BUFFER
	bra		ENTER_DONE		
	
TICKS_PUSH_MAIN:

	ldx		result
	cpx		#$0000
	beq		ZERO_TICKS_ERROR
	tst		F1Flag
	bne		F1_TICKS_PUSH
	tst		F2Flag
	bne		F2_TICKS_PUSH
	bra		ENTER_DONE
	
ZERO_TICKS_ERROR:
	movb	#$01, zeroTicksPrint
	bra		ENTER_DONE
	
F1_TICKS_PUSH:
	
	movw	result, TICKS1
	bra		ENTER_DONE
	
F2_TICKS_PUSH:
	
	movw	result, TICKS2
	bra		ENTER_DONE
		
EMPTY_VALUE:
	
	movb	#$01, emptyValuePrint 
	bra     ENTER_DONE
	
ENTER_DONE:
	
	clr		F1Flag
	clr		F2Flag
	clr		result
	jsr		CLEAR_BUFFER
	clr 	digitCounter
	movb	#$01, enterFlag
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
;=========  Mastermind - Miscellaneous Sub-Rountines / Branches   ==============
;

BUFFER_STORE:

	ldx  pointer                    
	ldab digitStore					
	stab 0,x                        
	inc  digitCounter               
	inx                             
	stx  pointer                    
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

       ldaa   	digitCounter
	   cmpa		#$00
	   bne		DIGIT_NOT_FIRST
	   ldaa		#$07
	   jsr		SETADDR
	   cmpb		#$F1
	   beq		INIT_PRINT_DONE
	   bra		PRINT_FIRST_DIGIT
	   
F2_PRINT:

       ldaa   	digitCounter
	   cmpa		#$00
	   bne		DIGIT_NOT_FIRST
	   ldaa		#$47
	   jsr		SETADDR
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
;
;======  Display State 5 - Clearing & Printing Prompt for F1 / F2   ================
;

displaystate5:

	  tst	  F1Flag
	  bne	  F1_CLEAR
	  tst	  F2Flag
	  bne	  F2_CLEAR
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
				
	   clr		enterFlag
	   clr		clearFlag
	   ldab		#$F1
	   movb		#$04, displayState
	   movb		#$01, firstChar
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
				
	   clr		enterFlag
	   clr		clearFlag
	   ldab		#$F2
	   movb		#$04, displayState
	   movb		#$01, firstChar
	   rts

ERROR_CLEAR_PRINT:

	   movb		#$00, mmState
	   rts	   
	   
;======================== Display State 6 - Backspace   ============================

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
		
;======================== Display State 7 - No digits Entered   ====================

displaystate7:

       ldaa   	#$07                    
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
	   movb     #$01, DelayMessageFlag
	   movb		#$01, displayState
	   movb		#$01, firstChar
	   rts
	   
;======================== Display State 8 - All Zeros Entered   ====================

displaystate8:

       ldaa   	#$07                    
       ldx    	#ZERO_DIGITS_PRINT    
       jsr    	DISPLAY_CHAR   	
       ldx    	displayPointer    
       ldab   	0,x               
       lbeq   	DONE_ZERO_DIGITS_PRINT  
       rts

ZERO_DIGITS_PRINT:

       .ascii 	'ALL ZEROS ENTERED!                 '
       .byte  	$00
	   rts               

DONE_ZERO_DIGITS_PRINT:
				
	   clr		zeroTicksPrint
	   movb     #$01, DelayMessageFlag
	   movb		#$01, displayState
	   movb		#$01, firstChar
	   rts
	   

;=========  Display - Miscellaneous Sub-Rountines / Branches   =====================

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
	
;================= Display Pattern for First Pair of LED's======================

;======================= Timing of First Pair of LED's =========================

TIMING_1: 
		ldaa   timingState         ; Get current t2state and branch accordingly
        beq    t2state0
        deca
        beq    t2state1
		deca
		beq    t2state2
        rts                       ; Undefined state - do nothing but return

t2state0:                         ; Initialization for TASK_2
        clr    DONE_1
        movb   #$01, timingState      ; Set next state
		rts
t2state1:                         ; (Re)initialize COUNT_1
        movw   TICKS_1, COUNT_1
        ldx    COUNT_1
        dex                       ; Decrement COUNT_1
        stx    COUNT_1            ; Store decremented COUNT_1
		clr    DONE_1
        movb   #$02, timingState      ; Set next state
        rts
t2state2:                         ; Count down COUNT_1
        ldx    COUNT_1
        beq    setdone_1          ; Test to see if COUNT_1 is already zero
        dex                       ; Decrement COUNT_1
        stx    COUNT_1            ; Store decremented COUNT_1
        bne    exit_t2s2          ; If not done, return
		
setdone_1:
        movb   #$01, DONE_1       ; If done, set DONE_1 flag
        movb   #$01, timingState  ; Set next state
		rts
exit_t2s2:
        rts

; end TIME_1


;========================= Delay Subroutine ====================================

DELAY:  
        tst  DelayMessageFlag
		bne  DELAY_MESSAGE
		tst  No_Delay
		beq  EXIT_1

DELAY_MESSAGE:
		bgnd
        ldy    #$0262
		movb   #$00, DelayMessageFlag    
INNER:                            ; Inside loop
        cpy    #0
        beq    EXIT_2
        dey
        bra    INNER
		
EXIT_1:
        rts                       ; Exit DELAY_1ms	
EXIT_2:
	   	movb     #$01, F1Flag
	    movb     #$01, clearFlag 
        rts                       ; Exit DELAY_1ms

;=====================================================================================
.area interrupt_vectors (abs)
.org    $FFFE             ; At reset vector location
.word   __start           ; Load starting address