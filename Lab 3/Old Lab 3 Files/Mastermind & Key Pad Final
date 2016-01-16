; ME 305-02: Intro to Mechatronics :: Robert Cory Molloy & Oscar Andrade
; Display Test Program for Labratory 3

;
;==============================================================================
;

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

; Flag Variables

keyFlag::			.blkb 1		; Notify Program a Key Has Been Pressed
F1Flag::			.blkb 1		; Notify Program a F1 Key Has Been Pressed
F2Flag::			.blkb 1		; Notify Program a F2 Key Has Been Pressed
enterErrorInit::	.blkb 1		; Notify Program an Enter Key Error Has Occured

; Print Variables

digitPrintF1::		.blkb 1		; Notify Program to Move Forward in Displaying F1 Digit
digitPrintF2::		.blkb 1		; Notify Program to Move Forward in Displaying F2 Digit

; Storing Variables

digitStore::		.blkb 1		; Store Most Recent Digit Pressed
buffer::			.blkb 5		; Store All Digits for Processing to Ticks
digitCounter::		.blkb 1		; Counts Up Digit Input into buffer
displayCounter::	.blkb 1		; Counts Up Amount of Spots Display has Input a Digit

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
	bgnd
	jsr    	KPD		  			; Key Pad Driver Sub-Routines
	bgnd
	jsr    	DISPLAY      		; Display Sub-Routines
	bgnd
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
	lbeq	mmstate2			; F1 State
	deca
	lbeq	mmstate3			; F2 State
	deca
	lbeq	mmstate4			; Backspace State
	deca
	lbeq	mmstate5			; Enter State
	deca
	lbeq	mmstate6			; Display & Keypad Activation
	deca
	lbeq	mmstate7			; Display & Keypad Activation
	rts							; Return to Main 

;
;==========  Mastermind State 0 - Initialization of Mastermind & Buffer  ============
;

mmstate0:	
					
	   movw		#BUFFER, POINTER 	; Stores the
	   clr		BUFFER				; Clear the BUFFER Variable
	   clr		RESULT				; Clear the RESULT Variable
	   movb		#$01, mmstate		; Set the Mastermind State Variable to 1
	   rts

;
;===============  Mastermind State 1 - Splash Screen and Setting Displays Flags  ====
;

mmstate1:

	   movb   	#$01, firstChar     ; Set firstChar flag to 1 (True) 
       movb   	#$01, displayTime1  ; Set displayTime1 flag to 1 (True)
	   movb   	#$01, displayTime2  ; Set displayTime1 flag to 1 (True)
	   movb		#$02, mmstate		; Set the Mastermind State Variable to 2 (Hub)
	   rts							; Return to Main


;
;===============  Mastermind State 2 - Hub  ============================
;

mmState2:

	tst 	keyFlag
	beq		N0_KEY
	clr 	keyFlag
	ldab 	keyStore
	cmpb 	#$F1
	beq 	F1_TRUE
	cmpb 	#$F2
	beq		F2_TRUE
	cmpb 	#$08
	beq 	BS_TRUE
	cmpb 	#$0A
	beq 	ENT_TRUE
	bra		DIGIT_CHECK

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

DIGIT_CHECK

	movb 	#$07, mmState
	rts

;
;===============  Mastermind State 3 - F1 State   =================
;
	
mmState3:
	
	tst 	F2Flag
	bne 	F2_IN_F1
	jsr 	CLEAR_COUNTERS
	clr 	buffer
	movb	$01, digitPrintF1
	movb 	$02, mmState
	rts
	
	
F2_IN_F1:

	movb 	$01, F1Flag
	movb 	$00, F2Flag
	rts
	
;
;===============  Mastermind State 4 - F2 State   =================
;
	
mmState4:
	
	tst 	F1Flag
	bne 	F1_IN_F2
	jsr 	CLEAR_COUNTERS
	clr 	buffer
	movb 	$01, digitPrintF2
	movb 	$02, mmState
	rts
	
	
F1_IN_F2:

	movb 	$00, F1Flag
	movb 	$01, F2Flag
	rts

;
;===============  Mastermind State 5 - Backspace State   =================
;
	
mmState5:
	
	tst 	digitCount
	beq 	BSPACE_DONE
	jsr 	DEC_COUNTERS
	dec 	pointer
	movb 	#$01, bSpaceInit
	movb 	#$02, mmState
	rts
	
	
BSPACE_DONE:

	clr  	bSpaceFlag
	movb 	$02, mmState
	rts

;
;===============  Mastermind State 6 - Enter State   =================
;
	
mmState6:
	
	tst 	F1Flag
	bne 	ENTER_MAIN
	tst 	F2Flag
	bne 	ENTER_MAIN
	movb 	#$02, mmState
	rts
	
	
ENTER_MAIN:

	tst 	digitCounter
	beq 	EMPTY_VALUE
	bra 	ASCII_BCD

ASCII_BCD:

	LOOP:
		movw 	#BUFFER, POINTER
		ldy 	#$000A                        
		ldd 	result                        
		emul                             
		cpy 	#$0000                        
		bne 	TOO_BIG_INT                       
		std 	result                        
		ldx 	pointer                       
		ldab 	0,x                          
		subb 	#$30                        
		clra                              
		addd 	result                       
		std 	result                      
		dec 	digitCount                        
		beq 	TICKS_PUSH_MAIN                    
		inx                             
		stx		pointer
		bra 	LOOP                                

TOO_BIG_INIT:

	movb	#$01, valueTooBig
	clr		buffer
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
	
F1_TICKS_PUSH
	
	movw	result, TICKS1
	bra		ENTER_DONE
	
F2_TICKS_PUSH
	
	movw	result, TICKS2
	bra		ENTER_DONE
	
ENTER_ERROR:
	
	movb #$01, enterErrorInit
	movb #$02, mmState
	rts	
	
EMPTY_VALUE:
	
	clr		result
	clr		buffer
	jsr		CLEAR_COUNTERS
	movb	#$02, mmState
	rts  
	
ENTER_DONE
	
	clr		F1Flag
	clr		F2Flag
	clr		result
	clr		buffer
	jsr		CLEAR_COUNTERS
	movb	#$02, mmState
	rts          			

;
;===============  Mastermind - Miscellaneous Sub-Rountines / Branches   =================
;

CLEAR_COUNTERS:

	clr 	digitCounter
	clr 	displayCounter
	rts
	
DEC_COUNTERS:

	dec 	digitCounter
	dec 	displayCounter
	rts

;
;=========================  Key Pad Driver Sub-Routine   ================================
;

KPD:

	   ldaa		kpdState			; Grabbing the current state of Key Pad Driver & Branching
	   lbeq		kpdstate0			; Initialize Key Pad Driver
	   deca
	   lbeq		kpdstate1			; 
	   rts							; Return to Main 

;
;===============  Key Pad Driver State 0 - Initialization of Key Pad Driver   ===========
;

kpdState0: 	
			
       jsr      INITKEY             ; Library Command to Initialize Keypad
       jsr      FLUSH_BFR           ; Library Command to Flush the Buffer
       jsr      KP_ACTIVE           ; Libary Command to Unmask the Keypad Interrupts
       movb     #$01, kpdState      ; Set the KPD State Variable to 1
       rts

;
;=====  Key Pad Driver State 1 - Wait for the Key Press to Be Stored in Buffer   ========
;

kpdstate1:
       
       tst      L$KEY_FLG           ; Test Key Available Flag
	   bne		NOKEYPRESS			;
       jsr      GETCHAR             ; Library Command to Get the Character & Store in B
	   stab		keyStore
	   movb		#$01, keyPressed	; Set keyPressed Variable to 1 (True)
	   movb		#$01, kpdState		; Return Back to Key Pad Driver State 1
	   rts

NOKEYPRESS:

	   movb #$01,kpdState			; Return Back to Key Pad Driver State 1
	   rts	  	   