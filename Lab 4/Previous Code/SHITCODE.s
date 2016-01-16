; Robert Cory Molloy & Oscar Andrade
; ME 305 - 02 :: Intro to Mechatronics
; Labratory 4 :: Function Generator  

;==================================== Assembler Equates ==================================

PORTJ              = $0028
DDRJ	   		   = $0029
pin_5			   = $10
TIOS               = $0080               ; TIMER OUTPUT COMPARE
TFLG1              = $008E               ; TIMER FLAG REGISTER
TSCR               = $0086               ; TIMER SYSTEM CONTROL REGISTER
TC0H               = $0090               ; TIMER CHANNEL ZERO REGISTER HIGH
TCNT               = $0084               ; TIMER COUNT REGISTER HIGH AND LOW
TMSK1              = $008C               ;
TCTL2              = $0089               ; TIMER CONTROL REGISTER 2
DACA_MSB		   = $0303
DACA_LSB		   = $0302


;======================================== RAM area =======================================

.area bss

; Task Variables

mmState::			.blkb 1		; Master Mind State Variable
kpdState::			.blkb 1    	; Key Pad Driver State Variable
displayState::		.blkb 1   	; Display State Variable
delayState::	    .blkb 1		; Delay State Variable
backspaceState::	.blkb 1		; Backspace State Variable
errorDelayState::   .blkb 1		; Error Delay State Variable
fgState:: 			.blkb 1
tc0State:: 			.blkb 1


; Flag Variables

keyFlag::			.blkb 1		; Notify Program a Key Has Been Pressed
echoFlag::			.blkb 1		; Notify Program that a Key Needs to Be Echoed
enterFlag::			.blkb 1		; Notify Program that Enter Procedure is Done
firstChar::			.blkb 1		; Notify Program the First Character is Ready
backspaceFlag::		.blkb 1		; Notify Program that a Entered Digit Needs to Be Cleared
errorDelayFlag::	.blkb 1     ; Notify Program that an Error Message Needs a Delay 	
mmWaitFlag::		.blkb 1		; Notify Program that Mastermind Can Move to Next State	
waveFlag::		    .blkb 1		;
NINTOkFlag::		.blkb 1
digitFlag::			.blkb 1

; Print Variables

displayWaveValues:: .blkb 1		; Notify Program to Move Forward in Displaying Wave Values
displayWave::       .blkb 1		; Notify Program to Move Forward in Displaying Waveform
displayPrompt::		.blkb 1		; Notify Program to Move Forward in Displaying Nint Mess. 
digitPrint::		.blkb 1		; Notify Program to Move Forward in Displaying Digit
emptyValuePrint::	.blkb 1		; Notify Program No Value Has Been Entered
valueTooBigPrint::	.blkb 1		; Notify Program to Move Forward in Displaying Value Too Big Error Message
zeroValuePrint::	.blkb 1		; Notify Program to Move Forward in Displaying Zero Value Message
backspacePrint::	.blkb 1		; Notify Program the Backspace Needs to Go Through Routine

; Storing Variables

digitStore::		.blkb 1		; Stores Most Recent Digit Pressed
buffer::			.blkb 3		; Stores All Digits for Processing to Ticks
result::			.blkb 1		; Stores converted ASCII numbers
INTERVAL::			.blkb 2
waveValue::			.blkb 1
; Counter Variables

digitCounter::		.blkb 1		; Counts Up Current Digits Input into buffer
clrBufferCounter::  .blkb 1     ; Notify program of how many cycles of clear buffer there are left
errorDelayCounter::	.blkb 2     ; Countdown of the Error 

; Other Variables

pointer::		    .blkb 2     ; Holds the Address of buffer		
displayPointer::	.blkb 2     ; Holds ASCII numbers pressed on keypad
WAVEPTR::			.blkb 2		;
SEGPTR::			.blkb 2		;
RUN::				.blkb 1
CSEG::				.blkb 1
LSEG::				.blkb 1
CINT::				.blkb 1
NINT::				.blkb 1
VALUE::				.blkb 2
SEGINC::			.blkb 2
NEWBTI::			.blkb 1

.area text

TRIANGLE::
	.byte 3                   ; number of segments for TRIANGLE
	.word 2048                ; initial DAC input value
	.byte 50                  ; length for segment_1
	.word 30                  ; increment for segment_1
	.byte 100                 ; length for segment_2
	.word -30                 ; increment for segment_2
	.byte 50                  ; length for segment_3
	.word 30                  ; increment for segment_3

;==================================  Main Program  =======================================

_main::

	jsr    	INIT        		; Initialization
	
TOP: 
  
	jsr    	MASTERMIND			; Mastermind Sub-Routines

	jsr    	KPD		  			; Key Pad Driver Sub-Routines

	jsr    	DISPLAY      		; Display Sub-Routines

	jsr		TIMER_C0
	
	jsr		FUNCTION_GENERATOR
	
    bra		TOP

;================================  Initialization  =======================================

INIT:

	clr		mmState				; Initialize All Sub-Routine State Variables to State 0
	clr	  	kpdState            ; Clear Keypad Driver States Variable
	clr		displayState        ; Clear Displaysate State Variable
	clr		backspaceState      ; Clear Backspace State Variable
	clr		delayState			; Clear Delay State Variable
	clr		backspaceState		; Clear Backspace State Variable
	clr 	errorDelayState		; Clear Error Delay State Variable
	rts	
	   
;=============================  Mastermind Sub-Routine  ==================================

MASTERMIND:

	ldaa	mmState				; Grabbing the current state of Mastermind & Branching
	lbeq	mmstate0			; Initialization of Mastermind & Buffer 
	deca
	lbeq	mmstate1			; Splash Screen and Setting Displays Flags
	deca
	lbeq	mmstate2			; Mastermind Hub
	deca
	lbeq	mmstate3			; Backspace State
	deca
	lbeq	mmstate4			; Enter State
	deca
	lbeq	mmstate5			; Digit State
	deca
	lbeq	mmstate6			; Error Wait State
	rts							; Return to Main 

;============  Mastermind State 0 - Initialization of Mastermind & Buffer  ===============

mmstate0:	
					
	movw    #buffer, pointer 		; Stores the first address of buffer into pointer
	clr		buffer					; Clear the buffer Variable
	movw    #$0000, result			; Clear the result Variable
	movb	#$01, mmState			; Set the Mastermind State Variable to 1    
	rts

;====  Mastermind State 1 - Splash Screen and Setting Displays Flags & Counters  =========

mmstate1:

	movb	 #$01, firstChar     	      ; Set firstChar flag to 1 (True) 
    movb     #$01, displayWaveValues	      ; Set displayTopPrint flag to 1 (True)
    movw     #25000, errorDelayCounter     ; Set Error Delay Counter to 1500
	clr      NINT
	movb	 #$01, waveFlag				  ;
	movb	 #$01, NEWBTI
	movb	 #$02, mmState			      ; Set the Mastermind State Variable to 2 (Hub)
	ldx		 #TRIANGLE
	stx		 WAVEPTR
	rts								      ; Return to Main

;===============  Mastermind State 2 - Hub  ============================

mmstate2:

	tst 	keyFlag                       ; Test keyFlag
	beq		NO_KEY                        ; If keyFlag is False, Branch to NO_KEY
	clr 	keyFlag                       ; Clear keyFlag
	cmpb 	#$F1                          ; Compare Acc. B to Hex Value of 'F1'
	beq 	F1_TRUE                       ; If B = '$F1', Branch to F1_TRUE
	cmpb 	#$F2                          ; Compare Acc. B to Hex Value of 'F2'
	beq		F2_TRUE                       ; If B = '$F2', Branch to F2_TRUE
	cmpb 	#$08                          ; Compare Acc. B to Hex Value of '08'
	beq 	BS_TRUE                       ; If B = '$08', Branch to BS_TRUE
	cmpb 	#$0A                          ; Compare Acc. B to Hex Value of '0A'
	beq 	ENT_TRUE                      ; If B = '$0A', Branch to ENT_TRUE
	lbra	DIGIT_TRUE                    ; Otherwise Branch to DIGIT_TRUE

NO_KEY:
	
	tst		backspaceFlag
	bne		BACKSPACE_GO
	tst		enterFlag
	bne		ENTER_GO
	tst		digitFlag
	bne		DIGIT_GO
	tst		errorDelayFlag
	bne 	ERROR_DELAY_TRUE
	movb 	#$02, mmState                 ; If No Key was Pressed, Return to Hub
	rts
	
F1_TRUE:
	
	movb 	#$02, mmState                 ; Set next Mastermind State (mmstate) to Hub
	rts	
		
F2_TRUE:
	
	movb 	#$02, mmState                 ; Set next Mastermind State (mmstate) to Hub 
	rts

BS_TRUE:
	
	movb 	#$01, backspaceFlag           ; Set next Mastermind State (mmstate) to Backspace
	rts
	
ENT_TRUE:
	
	movb 	#$01, enterFlag                 ; Set next Mastermind State (mmstate) to Enter
	rts

DIGIT_TRUE:

	movb 	#$01, digitFlag                 ; Set next Mastermind State (mmstate) to Digit
	rts
	
BACKSPACE_GO:

	movb 	#$03, mmState                 ; Set next Mastermind State (mmstate) to Backspace
	rts
	
ENTER_GO:

	movb 	#$04, mmState                 ; Set next Mastermind State (mmstate) to Backspace
	rts
	
DIGIT_GO:

    clr	 	digitFlag
	movb 	#$05, mmState                 ; Set next Mastermind State (mmstate) to Backspace
	rts


;========================= Mastermind State 3 - Backspace State ==========================
	
mmstate3:
		 
	tst 	digitCounter                  ; Test digitCounter
	beq 	BSPACE_DONE                   ; If digitCounter is FALSE, Branch to BSPACE_DONE
	tst 	backspaceFlag                 ; Test digitCounter
	beq 	BSPACE_DONE                   ; If digitCounter is FALSE, Branch to BSPACE_DONE
	movb 	#$01, backspacePrint          ; Set backspaceFlag to TRUE
	rts

BSPACE_DONE:
	movb	#$00, backspaceFlag
	movb 	#$02, mmState                 ; Set next Mastermind State (mmstate) to M^2 Hub
	rts

;=========================== Mastermind State 4 - Enter State ============================
	
mmstate4:
	
	tst	 	RUN
	lbne	WAVE_RUNNING
	tst	 	enterFlag
	bne		ENTER_INIT
	tst		errorDelayFlag
	bne 	ERROR_DELAY_TRUE
	lbeq	ENTER_DONE
	rts
	
ERROR_DELAY_TRUE:
                          
	movb   #$06, mmState                 ; Set next Mastermind State (mmstate) to Err Dly
	rts	
	
ENTER_INIT:
			
	tst 	digitCounter                  ; Test digitCounter
	lbeq 	EMPTY_VALUE                   ; If digitCounter is FALSE, Branch to EMPTY_VALUE
	bra 	ASCII_BCD                     ; Otherwise Branch to ASCII_BCD

ASCII_BCD:

	movw    #buffer, pointer              ; Load buffer Address Into pointer
		
	LOOP:

		ldaa 	#$0A                      ; Load Accumulator A with 10    
		ldab 	result                    ; Load Accumulator B with result    
		mul                               ; Multiply A and B, Store in A:B or D
		cmpa 	#$00                      ; Compare Accumulator D with 0   
		bhi 	TOO_BIG_VALUE		      ; If greater than 255 hex, Branch to TOO_BIG_VALUE         
		stb 	result                    ; Store Accumulator D into result    
		ldx 	pointer                   ; Load X with buffer Address Stored In pointer    
		ldab 	0,x                       ; Load Accumulator B with the Contents in X  
		subb 	#$30                      ; Subtract 30 From Accumulator B  
		clra                              ; Clear Accumulator A 
		addb 	result                    ; Add result To B and Store Back Into B
		bcs 	TOO_BIG_VALUE		      ; If greater than 255 hex, Branch to TOO_BIG_VALUE  
		stb 	result                    ; Store D in result 
		dec 	digitCounter              ; Decrement digitCounter
		tst		digitCounter              ; Test digitCounter         
		beq 	VALUE_PUSH_MAIN           ; If digitCounter is zero, Branch to VALUE_PUSH_MAIN        
		inx                               ; Increment Address in X
		stx		pointer                   ; Store Address In X Into Pointer
		bra 	LOOP                      ; Branch Back Into LOOP          	
	
VALUE_PUSH_MAIN:

	ldx		result                        ; Load Index Register X with result
	cpx		#$0000                        ; Compare Index Register X with 0
	beq		ZERO_VALUE                    ; If Index Register is 0, Branch to ZERO_VALUE
	bne		NINT_ENT                 	  ; If Index Register is 1, Branch to NINT_ENT
	bra		ENTER_DONE                    ; Otherwise Branch To ENTER_DONE
	
ZERO_VALUE:

	movb	#$01, zeroValuePrint          ; Set zeroTicksPrint to TRUE
	movb    #$01, errorDelayFlag           ; Set errorDelayFlag to TRUE
	movw	#$0000, result                ; Set result to 0
	movw    #buffer, pointer              ; Move Buffer Address into pointer
	clr	    digitCounter                  ; Clear the digitCounter
	movb	#$00, enterFlag               ; Set enterFlag to FALSE
	rts
		
EMPTY_VALUE:
	
	movb	#$01, emptyValuePrint         ; Set emptyValuePrint to TRUE
	movb    #$01, errorDelayFlag           ; Set errorDelayFlag to TRUE
	movw	#$0000, result                ; Set result to FALSE
	movw    #buffer, pointer              ; Move buffer Address Into Pointer
	clr	    digitCounter                  ; Clear the digitCounter
	movb	#$00, enterFlag               ; Set enterFlag to FALSE
	rts		
	
TOO_BIG_VALUE:

	movb	#$01, valueTooBigPrint        ; Set valueTooBigPrint to TRUE
	movb    #$01, errorDelayFlag           ; Set errorDelayFlag to TRUE
	movw	#$0000, result                ; Set result to FALSE
	movw    #buffer, pointer              ; Move buffer Address Into Pointer
	clr	    digitCounter                  ; Clear the digitCounter
	movb	#$00, enterFlag               ; Set enterFlag to FALSE
	rts
	
NINT_ENT:

    movb	#$00, enterFlag               ; Set enterFlag to FALSE
	movb 	result, NINT
	bra		ENTER_DONE
		 	
WAVE_RUNNING:

	clr		enterFlag		 
	movb	#$02, mmState                 ; Set next Mastermind State (mmstate) to M^2 Hub
	rts  
	 		
ENTER_DONE:

	movw	#$0000, result                ; Set result to 0
	clr	    digitCounter                  ; Clear the digitCounter
	movw    #buffer, pointer              ; Move buffer Address Into pointer
	movb	#$00, enterFlag               ; Set enterFlag to FALSE
	movb	#$01, NINTOkFlag
	movb	#$02, mmState                 ; Set next Mastermind State (mmstate) to M^2 Hub
	rts          			
 
	
;====================  Mastermind State 5 - Digit Entered   ====================

mmstate5:

	tst	    waveValue
	beq		WAVE_SELECT
 	tst	    RUN
	bne		CANCEL_RUN
	tst		digitFlag
	bne		DIGIT_WAIT				
	cmpb	#$41				          ; Compare Hexadecimal Value In B to $41
	lblo	DIGIT				          ; If Value in B < $40, Branch to DIGIT
	bra		NOTDIGIT			          ; Otherwise Value in B is not a Digit, Branch to NOTDIGIT
	
CANCEL_RUN:

    cmpb   #$34
	bhi	   NOTDIGIT
	cmpb   #$30
	beq	   NOTDIGIT
	movb   #$00, RUN
	bra	   WAVE_SELECT	
	
WAVE_SELECT:

	cmpb	#$31
	beq		WAVE_SELECT_DONE
	cmpb	#$32
	beq		WAVE_SELECT_DONE
	cmpb	#$33
	beq		WAVE_SELECT_DONE
	cmpb	#$34
	beq		WAVE_SELECT_DONE
	clr		keyFlag
	movb	#$02, mmState
	rts
	
WAVE_SELECT_DONE:
	
	clr    	waveFlag
	stab	waveValue
	movb	#$01, digitFlag
	movb	#$01, displayWave
	rts
  
DIGIT:

    inc		digitCounter
	movb	#$01, digitFlag
	bra		BUFFER_STORE                  ; Jump To Subroutine BUFFER_STORE

NOTDIGIT:

	movb	#$00, keyFlag	              ; Set keyFlag to FALSE
	movb	#$02, mmState				  ; Set next Mastermind State (mmstate) to M^2 Hub
	rts

DIGIT_WAIT:

	tst     echoFlag
	lbeq	DIGIT_DONE
	rts
	
DIGIT_DONE:

    movb   	#$00, digitFlag
	movb 	#$02, mmState                 ; Set next Mastermind State (mmstate) to M^2 Hub
	rts 
		
	
;====================  Mastermind State 6 - Error Delay State   ================	
	
mmstate6:

	tst    errorDelayFlag
	beq	   ERROR_DELAY_HANDOFF
	ldaa   errorDelayState                ; Load Accumulator A with errorDelayState
    beq    errordelaystate0               ; If errorDelayState is $0, Branch to errordelaystate0
    deca                                  ; Otherwise Decrement Accumulator A
    beq    errordelaystate1               ; If errorDelayState is $0, Branch to errordelaystate0
    rts                       

errordelaystate0:                         
    movb   #$01, errorDelayState          ; Set errorDelayState to $0
    rts
		
errordelaystate1:                         
    ldx    errorDelayCounter              ; Load Index Register X with errorDelayCounter
	cpx	   #$0000                         ; Compare Index Register X with $0
	beq	   ERROR_DELAY_DONE               ; If X=$0 , Branch to ERROR_DELAY_DONE
    dex                                   ; Otherwise Decrement Index Register X
    stx    errorDelayCounter              ; Store Index Register X with errorDelayCounter    
    rts
	
ERROR_DELAY_DONE:

  	movw   #25000, errorDelayCounter       ; Set errorDelayCounter to 1500		 
    movb   #$00, errorDelayState          ; Set errorDelayState to $0
    movb   #$00, errorDelayFlag           ; Set errorDelayFlag to FALSE
    movb   #$01, displayPrompt			  ; Set displayPrompt to TRUE
	movb   #$01, firstChar                ; Set firstChar to TRUE
	rts

ERROR_DELAY_HANDOFF:

  	movb	#$02, mmState
	rts

;=========  Mastermind - Miscellaneous Sub-Rountines / Branches   ==============

BUFFER_STORE:

	ldaa   digitCounter                   ; Load Accumulator A with digitCounter
	cmpa   #$03                           ; Compater Accumulator with $03
	bhi    BUFFER_STORE_LIMIT             ; If A is higher or equal than $03, Branch to BUFFER_STORE_LIMIT
	ldx    pointer                        ; Load X with pointer
	ldab   digitStore				      ; Load B with digitStore
	stab   0,x                            ; Store Contents of B into X
	inx                                   ; Increment X
	stx     pointer                       ; Store X in Pointer
	movb	#$01, echoFlag                ; Set echoFlag to TRUE
	movb	#$00, keyFlag	              ; Set keyFlag to FALSE
	rts
								
	
BUFFER_STORE_LIMIT:

	dec	   digitCounter
	clr	   keyFlag
	clr	   echoFlag
	rts	
	
CLEAR_BUFFER:
		
	movb   #$00, clrBufferCounter         ; Clear clrBufferCounter
	movw   #buffer, pointer               ; Move buffer Address into pointer
		  
	C_B_LOOP:
	
		 ldx  	   pointer                ; Load Index Register X with pointer
		 ldab	   #$00                   ; Load Accumulator B with $00
		 stab 	   0,x                    ; Store Contents Of B into X
		 inc	   clrBufferCounter       ; Increment clrBufferCounter
		 ldaa	   clrBufferCounter       ; Load clrBufferCounter Into Accumulator A
		 cmpa	   #$05                   ; Compare A with $05
		 beq	   CLEAR_BUFFER_DONE      ; If A=$00,  Branch to CLEAR_BUFFER_DONE
		 ldx	   pointer                ; Load Index Register X with pointer
		 inx  	                          ; Increment X
		 stx	   pointer                ; Store Contents of X into pointer
		 bra	   C_B_LOOP               ; Branch to C_B_LOOP
		 
CLEAR_BUFFER_DONE:
		
	clr	   digitCounter		              ; Clear the digitCounter
	rts
		 
;=========================  Key Pad Driver Sub-Routine   =======================

KPD:

	ldaa   kpdState			              ; Load Accumulator A with kpdState
	lbeq   kpdstate0			          ; If Accumulator A =$00, Branch to kpdstate0
	deca                                  ; Decrement A
	lbeq   kpdstate1			          ; If Accumulator A =$00, Branch to kpdstate1
	rts							 

;========  Key Pad Driver State 0 - Initialization of Key Pad Driver   =========

kpdstate0: 	
			
    jsr    INITKEY                        ; Jump to Subroutine INITKEY
    jsr    FLUSH_BFR                      ; Jump to Subroutine FLUSH_BFR
    jsr    KP_ACTIVE                      ; Jump to Subroutine KP_ACTIVE
    movb   #$01, kpdState                 ; Set Keypad Driver to kpdstate1
    rts

;=======  Key Pad Driver State 1 - Wait for the Key Press to Be Stored in Buffer   ==

kpdstate1:
       
    tst    L$KEY_FLG                      ; Check if Key has Been Pressed
	bne	   NOKEYPRESS			          ; If no Key Pressed, Branch to NOKEYPRESS
    jsr    GETCHAR                        ; If Key Has Been Pressed, get Character
	stab   digitStore                     ; Store Character from B into digitStore
	movb   #$01, keyFlag                  ; Set KeyFlag to TRUE
	movb   #$01, kpdState		          ; Set Keypad Driver to kpdstate1
	rts

NOKEYPRESS:

	movb   #$01,kpdState			      ; Set Keypad Driver to kpdstate1
	rts	  	   
	   
;=============================  Display Sub-Routine   ==========================

DISPLAY:

	ldaa   displayState                   ; Display to be Branched to Depending on Value
	lbeq   displaystate0                  ; Initalize LCD Screen & Cursor
	deca
	lbeq   displaystate1                  ; Display Hub
	deca
	lbeq   displaystate2                  ; Display Input Wave Values 
	deca
	lbeq   displaystate3                  ; Display Waveform
	deca
	lbeq   displaystate4                  ; Display Input Prompt
	deca
	lbeq   displaystate5                  ; Initializing & Printing Digit
	deca
	lbeq   displaystate6                  ; Backspace
	deca
    lbeq   displaystate7                  ; No Digit Entered Error
	deca
	lbeq   displaystate8                  ; All Zeroes Entered Error
	deca
	lbeq   displaystate9                  ; Value Too Big Error
    rts							
	   
;==================== Display State 0 - Initialize LCD Screen & Cursor ===================
	   
displaystate0: 	
			
	jsr	   INITLCD                        ; Initalize LCD Screen
	jsr    CLRSCREEN                      ; Clear LCD Screen
	jsr    CURSOR                         ; Show Cursor in LCD Screen
	movb   #$01, displayState             ; Return to Display Hub
	rts

;============================= Display State 1 - Display Hub =============================
	   
displaystate1:

	tst    displayWaveValues              ; Test displayWaveValues  
    bne    DISPLAY_WAVE_VALUES            ; If displayWaveValues is TRUE, Branch to State
    tst	   displayWave                    ; Test displayWave
	bne    DISPLAY_WAVE                   ; If displayWave is TRUE, Branch to State
	tst	   displayPrompt                  ; Test displayPrompt
	bne    DISPLAY_PROMPT                 ; If displayPrompt is TRUE, Branch to State
	tst	   echoFlag                       ; Test echoFlag
	bne	   KEY_PRINT                 	  ; If echoFlag TRUE, Branch to State
    tst	   backspacePrint                 ; Test backspacePrint
	bne	   BACKSPACE_PRINT                ; If backspaceFlag TRUE, Branch to State
    tst    emptyValuePrint                ; Test emptyValuePrint
	bne    EMPTY_VALUE_PRINT              ; If emptyValuePrint TRUE, Branch to State
	tst    zeroValuePrint                 ; Test zeroTicksPrint
	bne    ZERO_VALUE_PRINT               ; If zeroTicksPrint TRUE, Branch to State
	tst    valueTooBigPrint               ; Test valueTooBigPrint
	bne    VALUE_TOO_BIG                  ; IF valueTooBigPrint TRUE, Branch to State
    rts

DISPLAY_WAVE_VALUES:
	
	movb   #$02, displayState             ; Display Wave Input Value 
	rts

DISPLAY_WAVE:
	
	movb   #$03, displayState             ; Display Waveform
	rts
	
DISPLAY_PROMPT:
	
	movb   #$04, displayState             ; Display Prompt
	rts

KEY_PRINT:
	
	movb   #$05, displayState             ; Initializing & Printing Digit
	rts

BACKSPACE_PRINT:

	movb   #$06, displayState             ; Backspace
	rts	   
	   
EMPTY_VALUE_PRINT:
				  
    movb   #$07, displayState             ; Empty Value Entered Print
	rts
		
ZERO_VALUE_PRINT:
		
	movb   #$08, displayState             ; No Digits Entered Print
	rts
		
VALUE_TOO_BIG:
		
	movb   #$09, displayState             ; Value Too Big Print
	rts 
	   
;===============  Display State 2 - Display Wave Input Values   ===============

displaystate2:

    ldaa   #$00                           ; Load Accumulator A with $00
    ldx    #WAVE_INPUT_MESSAGE            ; Load Index Register X Address of F1_INIT_MESSAGE
    jsr    DISPLAY_CHAR   	              ; Jump to Subroutine DISPLAY_CHAR
    ldx    displayPointer                 ; Load Index Register X with value in displayPointer
    ldab   0,x                            ; Load B with the Contents of X
    lbeq   DISPLAY_WAVE_VALUES_DONE       ; If X= $00, Branch to DONE_F1_INIT_PRINT
    rts

WAVE_INPUT_MESSAGE:

	.ascii '1: SAW; 2: SINE-7; 3: SQUARE; 4: SINE-15'
    .byte  $00
	rts               

DISPLAY_WAVE_VALUES_DONE:
				
	clr	   displayWaveValues              ; Clear displayF1Print
    movb   #$01, displayState             ; Return to Display Hub
	movb   #$01, firstChar                ; Set firstchart to TRUE
	rts
	   
;===============  Display State 3 - Display Wave Prompt Message   ===============

displaystate3:

	ldaa   waveValue
	cmpa   #$31
	beq    SAW_WAVEFORM_PRINT
	cmpa   #$32
	beq   SINE7_WAVEFORM_PRINT
	cmpa   #$33
	beq   SQUARE_WAVEFORM_PRINT
	cmpa   #$34
	beq   SINE15_WAVEFORM_PRINT
	rts
	
SAW_WAVEFORM_PRINT:

    ldaa   #$40                           ; Load Accumulator A with $40
    ldx    #SAW_WAVEFORM_MESSAGE            ; Load Index Register X with Address of F2_INIT_MESSAGE
    jsr    DISPLAY_CHAR   	              ; Jump to Subroutine DISPLAY_CHAR
    ldx    displayPointer                 ; Load Index Register X with value in displayPointer
    ldab   0,x                            ; Load B with the Contents of X
    lbeq   DONE_WAVEFORM_PRINT             ; If X = $00, Branch to DONE_F2_INIT_PRINT
    rts

SAW_WAVEFORM_MESSAGE:

	.ascii 'SAWTOOTH WAVEFORM   '
    .byte  $00               
	rts

SINE7_WAVEFORM_PRINT:

    ldaa   #$40                           ; Load Accumulator A with $40
    ldx    #SINE7_WAVEFORM_MESSAGE            ; Load Index Register X with Address of F2_INIT_MESSAGE
    jsr    DISPLAY_CHAR   	              ; Jump to Subroutine DISPLAY_CHAR
    ldx    displayPointer                 ; Load Index Register X with value in displayPointer
    ldab   0,x                            ; Load B with the Contents of X
    lbeq   DONE_WAVEFORM_PRINT             ; If X = $00, Branch to DONE_F2_INIT_PRINT
    rts

SINE7_WAVEFORM_MESSAGE:

	.ascii 'SINE-7 WAVEFORM   '
    .byte  $00               
	rts
	
SQUARE_WAVEFORM_PRINT:

    ldaa   #$40                           ; Load Accumulator A with $40
    ldx    #SQUARE_WAVEFORM_MESSAGE            ; Load Index Register X with Address of F2_INIT_MESSAGE
    jsr    DISPLAY_CHAR   	              ; Jump to Subroutine DISPLAY_CHAR
    ldx    displayPointer                 ; Load Index Register X with value in displayPointer
    ldab   0,x                            ; Load B with the Contents of X
    lbeq   DONE_WAVEFORM_PRINT             ; If X = $00, Branch to DONE_F2_INIT_PRINT
    rts

SQUARE_WAVEFORM_MESSAGE:

    .ascii 'SQUARE WAVEFORM   '
    .byte  $00               
	rts
	
SINE15_WAVEFORM_PRINT:

    ldaa   #$40                           ; Load Accumulator A with $40
    ldx    #SINE15_WAVEFORM_MESSAGE         ; Load Index Register X with Address of F2_INIT_MESSAGE
    jsr    DISPLAY_CHAR   	              ; Jump to Subroutine DISPLAY_CHAR
    ldx    displayPointer                 ; Load Index Register X with value in displayPointer
    ldab   0,x                            ; Load B with the Contents of X
    lbeq   DONE_WAVEFORM_PRINT         ; If X = $00, Branch to DONE_F2_INIT_PRINT
    rts

SINE15_WAVEFORM_MESSAGE:

    .ascii 'SINE-15 WAVEFORM   '
    .byte  $00               
	rts
	   
DONE_WAVEFORM_PRINT:
	
	clr	   displayWave			    ; Clears displayWave				
	movb   #$01, displayState       ; Return to Display Hub
	movb   #$01, firstChar          ; Set firstChar to TRUE
	rts

;======================== Display State 4 - Display Prompt Message =======================

displaystate4:

    ldaa   #$51                     ; Load Accumulator A with $55
    ldx    #PROMPT_MESSAGE			; Load Index Register X with Address of PROMPT_MESSAGE
    jsr    DISPLAY_CHAR   	        ; Jump to Subroutine DISPLAY_CHAR
    ldx    displayPointer           ; Load Index Register X with value in displayPointer
    ldab   0,x                      ; Load B with the Contents of X
    lbeq   DONE_PROMPT_PRINT        ; If X = $00, Branch to DONE_PROMPT_PRINT
    rts

PROMPT_MESSAGE:

	.ascii '    NINT:     [1-->255]'
    .byte  $00               
	rts
	   
DONE_PROMPT_PRINT:
	
	clr	   displayPrompt
	ldaa   #$5B
	jsr	   SETADDR
	movb   #$00, mmWaitFlag								
	movb   #$01, displayState             ; Return to Display Hub
	movb   #$01, firstChar                ; Set firstChar to TRUE
	clr	   echoFlag
	rts


;================ Display State 5 - Initializing & Printing Digit for Entry ==============

displaystate5:

    ldaa   digitCounter                   ; Load Accumulator A with digitCounter
    cmpa   #$00                           ; Compare A with $00 
	bne	   DIGIT_NOT_FIRST                ; If A not $00, Branch to DIGIT_NOT_FIRST
    ldaa   #$5B                           ; Load A with $5B
    jsr	   SETADDR                        ; Set the Cursor in the Address Value Stored in A
	bra	   PRINT_FIRST_DIGIT              ; Otherwise, Branch to PRINT_FIRST_DIGIT
	   
PRINT_FIRST_DIGIT:

	ldab   digitStore                     ; Load Accumulator B With digitStore
	jsr	   OUTCHAR                        ; Print Character Stored in B
	bra	   DIGIT_PRINT_DONE               ; Branch to INIT_PRINT_DONE
	   
DIGIT_NOT_FIRST:

	ldaa   digitCounter                   ; Load Accumulator A with digitCounter
	cmpa   #$03                           ; Compare A with $03
    bgt    DIGIT_PRINT_DONE               ; If Value in A > $03, Branch to DIGIT_PRINT_DONE
	ldab   digitStore                     ; Load Accumulator B with digitStore
	jsr	   OUTCHAR                        ; Print Character of ASCII Value in Stored in B
	bra	   DIGIT_PRINT_DONE               ; Branch to INIT_PRINT_DONE
	   
DIGIT_PRINT_DONE:

	clr	   echoFlag                       ; Set echoFlag to FALSE
	movb   #01, displayState              ; Return Back to Display Hub
	rts
	   
;============================ Display State 6 - Backspace ================================

displaystate6:
		
	ldaa   backspaceState
	lbeq   backspacestate0                ; Backs up Cursor 
	deca
	lbeq   backspacestate1                ; Space Print
	deca
	lbeq   backspacestate2                ; Backs up Cursor and Return to Display State 1
		
backspacestate0:

	dec		digitCounter                  ; Decrement digitCounter
	ldx 	pointer                       ; Load Index Register X with pointer
	dex 	                              ; Decrement Index Register X
	stx		pointer                       ; Store Index Register X into pointer	
	ldab   #$08                           ; Load Accumulator B with ASCII Value of Backspace
	jsr	   OUTCHAR                        ; Moves the Cursor Back One Space On LCD
	movb   #$01, backspaceState           ; Return to backspaceState 1
	rts
		
backspacestate1:

	ldab   #$20                           ; Load Accumulator B with ASCII Value of Space
	jsr	   OUTCHAR                        ; Prints a Space on LCD and Moves the Cursor to Next Address
	movb   #$02, backspaceState           ; Return to backspaceState 2
	rts
		
backspacestate2:	
		
	ldab   #$08                           ; Load Accumulator B with ASCII Value of Backspace
	jsr	   OUTCHAR                        ; Moves the Cursor Back One Space On LCD
	movb   #$00, backspaceState           ; Return to backspace state 0
	movb   #$01, displayState             ; Return to Display State 1
	clr	   backspaceFlag                  ; Set backspaceFlag to FALSE
	clr	   backspacePrint                  ; Set backspaceFlag to FALSE	
	rts
		
;======================== Display State 7 - No Digits Entered Print ======================

displaystate7:

    ldaa   #$51                           ; Load Accumulator A with LCD Address $07
    ldx    #NO_DIGITS_PRINT               ; Load Index Register X with Address of NO_DIGITS_PRINT
    jsr    DISPLAY_CHAR   	              ; Jump to Subroutine DISPLAY_CHAR
    ldx    displayPointer                 ; Load X with displayPointer
    ldab   0,x                            ; Load B with the Contents in X
    lbeq   DONE_NO_DIGITS_PRINT           ; If B=$00, Branch to DONE_NO_DIGITS_PRINT
    rts

NO_DIGITS_PRINT:

	.ascii 	'     NO DIGITS ENTERED!'
    .byte  	$00
    rts               
	   
DONE_NO_DIGITS_PRINT:
				
    clr	   emptyValuePrint                ; Clear emptyValuePrint
    movb   #$01, displayState             ; Return to Display State 1
	rts
	   
;======================= Display State 8 - All Zeros Entered Print =======================

displaystate8:
	   
    ldaa  #$51                            ; Load Accumulator A with LCD Address $07  
    ldx   #ZERO_DIGITS_PRINT              ; Load X with Address of ZERO_DIGITS_PRINT
    jsr   DISPLAY_CHAR   	              ; Jump to subroutine DISPLAY_CHAR
    ldx   displayPointer                  ; Load X with displayPointer
    ldab  0,x                             ; Load B with the Contents of X
    lbeq  DONE_ZERO_DIGITS_PRINT          ; If B=$00, Branch to DONE_ZERO_DIGITS_PRINT
    rts

ZERO_DIGITS_PRINT:

    .ascii 	'     ZERO MAG. INVALID!'			  
    .byte  	$00
	rts               

DONE_ZERO_DIGITS_PRINT:
				
	clr	   zeroValuePrint                 ; Clear zeroTicksPrint
	movb   #$01, displayState             ; Return to Display State 1
	rts
			
;======================== Display State 9 - Value Too Big Print ==========================

displaystate9:
	   
    ldaa   #$51                           ; Load A with LCD Address $07
    ldx    #TOO_BIG_PRINT                 ; Load X with TOO_BIG_PRINT Address
    jsr    DISPLAY_CHAR   	              ; Jump to Subroutine DISPLAY
    ldx    displayPointer                 ; Load X with displayPointer
    ldab   0,x                            ; Load B with the Contents of X
    lbeq   DONE_TOO_BIG_PRINT             ; If B=$00, Branch to DONE_TOO_BIG_PRINT
    rts
	   
TOO_BIG_PRINT:

    .ascii 	'        MAG. TOO LARGE!'
    .byte  	$00
	rts               

DONE_TOO_BIG_PRINT:
				
	movb   #$00, valueTooBigPrint         ; Set valueTooBigPrint = $00 
	movb   #$01, displayState             ; Return to Display State 1
	rts
	  	   
;=========  Display - Miscellaneous Sub-Rountines / Branches   =====================

DISPLAY_CHAR:

    tst    firstChar                      ; Test firstChar to Raise Flags
    beq    DISPLAY_WRITE                  ; Branch to DISPLAY_WRITE if firstChar = 0 (FALSE)
    stx    displayPointer                 ; Store value of x into displayPointer
	jsr    SETADDR                        ; Set cursor to particular LCD address in A
    clr    firstChar                      ; Clear firstChar
    rts

DISPLAY_WRITE:
    ldx    displayPointer                 ; Load x with value in Display Pointer
    inx                                   ; Increment x
    stx    displayPointer                 ; Store Display Pointer with incremented x
    jsr    OUTCHAR                        ; Print character
    rts  

;========================= Timer Channel 0 Sub-Routine =========================
	
TIMER_C0:
	
	ldaa   tc0State
	beq    tc0state0
	deca
	beq    tc0state1
	rts
	
;================ Timer Channel 0 State 0 - Timer Initialization ===============

tc0state0:
	
	bset   TIOS, #$01                     ; SETTING TC0 FOR OUTPUT COMPARE
	
	bset   TCTL2, #$01                    ; INITIALIZE OC0 TO TOGGLE ON SUCCESSFUL COMPARE   
	
	bclr   TCTL2, #$02                    ; INITIALIZE OC0 TO TOGGLE ON SUCCESSFUL COMPARE
	
	bset   TFLG1, #$0001                  ; CLEARING THE TIMER OUTPUT COMPARE FLAG IF SET
	   
    bset   TMSK1, #$01            		  ; ENABLING TIMER CHANNEL 0 OUTPUT COMPARE INTERRUPTS
	
	movb   #$01, tc0State                 ; Set Next Interrupt State to 1
	
	movb   #$A0, TSCR                     ; ENABLING THE TIMER AND STOPPING IT WHILE IN BGND MODE
	
	cli
	
	ldd    TCNT                           ; READS THE CURRENT COUNT AND STORE IN D
	
	addd   #$0320                         ; ADDS INTERVAL TO THE CURRENT TIMER CURRENT
	
	std    TC0H							  ; STORES INTERVAL + TCNT INTO TC0H
	
	cli
	    
	rts                                   ; RETURN FROM SUBROUTINE
	
;================== Timer Channel 0 State 1 - Arbitrary State ==================

tc0state1:

	rts                                   ; RETURN TO MAIN FROM SUBROUTINE

;======================== Function Generator Sub-Routine =======================

FUNCTION_GENERATOR:

	ldaa   fgState
	beq    fgstate0
	deca
	beq    fgstate1
	deca
	beq    fgstate2
	deca
	beq    fgstate3
	deca
	beq    fgstate4
	rts

;================= Function Generator State 0 - Initialization =================

fgstate0:

    bset     PORTJ, $10        ; initialize to off
       
	bset     DDRJ, $10         ; set PORTJ to output
	
	movb #$01, fgState
	
	rts

;================== Function Generator State 1 - Wait For Wave =================

fgstate1:

	tst waveValue
	bne	WAIT_WAVE_DONE
	rts

WAIT_WAVE_DONE:
	
	movb #$01, displayWave
	movb #$02, fgState
	rts
	
;==================== Function Generator State 2 - New Wave ====================

fgstate2:

	tst displayWave 		    ; wait for display of wave message
	bne WAVE_MESSAGE_NOT_DONE   ;
	ldx WAVEPTR 	  			; point to start of data for wave
	movb 0,X, CSEG ; get number of wave segments
	movw 1,X, VALUE ; get initial value for DAC
	movb 3,X, LSEG ; load segment length
	movw 4,X, SEGINC ; load segment increment
	inx  	  					; inc SEGPTR to next segment
	inx
	inx
	inx
	inx
	inx
	stx SEGPTR 					; store incremented SEGPTR for next segment
	movb #$01, displayPrompt	; set flag for display of NINT prompt
	movb #$03, fgState 			; set next state

WAVE_MESSAGE_NOT_DONE: 
			   
	rts
	
;================== Function Generator State 3 - Wait For NINT =================

fgstate3:

	tst displayPrompt 		    ; wait for display of wave message
	bne PROMPT_MESSAGE_NOT_DONE	;
	tst NINTOkFlag
	bne	WAIT_NINT_DONE
	rts

WAIT_NINT_DONE:
	
	movb #$01, RUN
	movb #$00, NINTOkFlag
	movb NINT, CINT
	movb #$04, fgState
	rts

PROMPT_MESSAGE_NOT_DONE: 
			   
	rts	

;=================== Function Generator State 4 - Display Wave =================

fgstate4:

	tst RUN
	beq DNU_RUN 	 		; do not update function generator if RUN=0
	tst NEWBTI
	beq DNU_NEWBTI 	 		; do not update function generator if NEWBTI=0
	dec LSEG 				; decrement segment length counter
	bne UPDATE_DACOUT 		; if not at end, simply update DAC output
	dec CSEG 				; if at end, decrement segment counter
	bne SKIP_REINIT_WAVE 	; if not last segment, skip reinit of wave
	ldx WAVEPTR 			; point to start of data for wave
	movb 0,X, CSEG 			; get number of wave segments
	inx  	  				; inc SEGPTR to start of first segment
	inx
	inx
	stx SEGPTR 				; store incremented SEGPTR

SKIP_REINIT_WAVE: 

    ldx SEGPTR 	  			; point to start of new segment
	movb 0,X, LSEG 			; initialize segment length counter
	movw 1,X, SEGINC 		; load segment increment
	inx  	  				; inc SEGPTR to next segment
	inx
	inx
	stx SEGPTR 				; store incremented SEGPTR
	
UPDATE_DACOUT: 

	ldd VALUE  				; get current DAC input value
	addd SEGINC 			; add SEGINC to current DAC input value
	std VALUE 				; store incremented DAC input value
	bra DACOUT_DONE
	
DNU_RUN: 

	movb #$01, fgState     ; set next state
	
DACOUT_DONE: 

	clr NEWBTI
	
DNU_NEWBTI: 

	rts
                     
;==================== Interrupt Service Routine & Branches =====================
	  
TC0_ISR:

    bgnd
	
	tst RUN
	
	beq NOT_YET
	
	dec CINT
	
	bne NOT_YET
	
	jsr OUTDAC
	
	movb NINT, CINT
	
	movb #01, NEWBTI
	
	bset	TFLG1, #$0001   	; Clear the TC0 Compare Interrupt Flag
	
	rti
	
NOT_YET:

	ldd  TC0H                   ; STORE TC0H INTO D
	
	addd INTERVAL               ; ADDS INTERVAL TO TC0CH
	
	std  TC0H                   ; LOADS THE TCOH + INTERVAL BACK INTO D
		
	bset	TFLG1, #$0001   	; Clear the TC0 Compare Interrupt Flag
		
	rti

OUTDAC:
	
	ldd VALUE
	
	staa $0303
	
	stab $0302
	
	bclr PORTJ, pin_5
	
	bset PORTJ, pin_5
	
	rts		
	
;===============================================================================

.area interrupt_vectors (abs)
	  .org   $FFEE                                 
	  .word  TC0_ISR                  ; Address of Next Interrupt
	  .org    $FFFE                             ; At reset vector location
	  .word   __start                           ; Load starting address