; Robert Cory Molloy & Oscar Andrade
; ME 305 - 02 :: Intro to Mechatronics
; Labratory 4 :: Function Generator  

;==================================== Assembler Equates ==================================

;======================================== RAM area =======================================

.area bss

; Task Variables

mmState::			.blkb 1		; Master Mind State Variable
kpdState::			.blkb 1    	; Key Pad Driver State Variable
displayState::		.blkb 1   	; Display State Variable
delayState::	    .blkb 1		; Delay State Variable
backspaceState::	.blkb 1		; Backspace State Variable
errorDelayState::   .blkb 1		; Error Delay State Variable


; Flag Variables

keyFlag::			.blkb 1		; Notify Program a Key Has Been Pressed
echoFlag::			.blkb 1		; Notify Program that a Key Needs to Be Echoed
enterFlag::			.blkb 1		; Notify Program that Enter Procedure is Done
enterErrorInit::	.blkb 1		; Notify Program an Enter Key Error Has Occured
emptyValuePrint::	.blkb 1		; Notify Program No Value Has Been Entered
firstChar::			.blkb 1		; Notify Program the First Character is Ready to Be Printed
clearFlag::			.blkb 1		; Notify Program that the F1 / F2 Line Needs to Be Cleared
backspaceFlag::		.blkb 1		; Notify Program that a F1 / F2 Entered Digit Needs to Be Cleared
errorDelayFlag::	.blkb 1     ; Notify Program that error message should be delayed 	
errorDelayDone::	.blkb 1     ; Notify Prgram that delayed message display is done
cursorMoveFlag::	.blkb 1
mmWaitFlag::		.blkb 1
sawwaveFlag::		.blkb 1
waveFlag::			.blkb 1
sawPromptFlag::		.blkb 1
sine7PromptFlag::	.blkb 1
squarePromptFlag::	.blkb 1
sine15PromptFlag::	.blkb 1		

; Print Variables

displayTopPrint:: 	.blkb 1		; Notify Program to Move Forward in Displaying Top Message
displayWavePrint::  .blkb 1		; Notify Program to Move Forward in Displaying Bottom Message 
digitPrint::		.blkb 1		; Notify Program to Move Forward in Displaying Digit
valueTooBigPrint::	.blkb 1		; Notify Program to Move Forward in Displaying Value Too Big Error Message
zeroValuePrint::	.blkb 1		; Notify Program to Move Forward in Displaying Zero Value Message
backSpacePrint::	.blkb 1		; Notify Program the Backspace Needs to Go Through Routine

; Storing Variables

digitStore::		.blkb 1		; Stores Most Recent Digit Pressed
buffer::			.blkb 3		; Stores All Digits for Processing to Ticks
result::			.blkb 2		; Stores converted ASCII numbers

; Counter Variables

digitCounter::		.blkb 1		; Counts Up Current Digits Input into buffer
clrBufferCounter::  .blkb 1     ; Notify program of how many cycles of clear buffer there are left
errorDelayCounter::	.blkb 2     ; Countdown of delay 

; Other Variables

pointer::		    .blkb 2     ; Holds the Address of buffer		
displayPointer::	.blkb 2     ; Holds ASCII numbers pressed on keypad

.area text

;==================================  Main Program  =======================================

_main::

	bgnd
	jsr    	INIT        		; Initialization
	
TOP: 
  
	bgnd
	
	jsr    	MASTERMIND			; Mastermind Sub-Routines

	jsr    	KPD		  			; Key Pad Driver Sub-Routines

	jsr    	DISPLAY      		; Display Sub-Routines

	;jsr		TIMER_C0
	
	;jsr		FUNCTION_GENERATOR
	
	; jsr		DELAY				; Delay Sub-Routine
	
    bra		TOP

;================================  Initialization  =======================================

INIT:

	clr		mmState				; Initialize  All Sub-Routine State Variables to State 0
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
    movb     #$01, displayTopPrint	      ; Set displayTopPrint flag to 1 (True)
    movw     #1500, errorDelayCounter     ; Set Error Delay Counter to 1500
	movb	 #$00, waveFlag				  ;
	movb	 #$02, mmState			      ; Set the Mastermind State Variable to 2 (Hub)
	rts								      ; Return to Main

;===============  Mastermind State 2 - Hub  ============================

mmstate2:

	tst		errorDelayFlag                ; Test Error Delay Flag
	bne 	ERROR_DELAY_TRUE              ; If errorDelayFlag is True, Branch to ERROR_DELAY_TRUE
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
	
	movb 	#$02, mmState                 ; If No Key was Pressed, Return to Hub
	rts
	
F1_TRUE:
	
	movb 	#$02, mmState                 ; Set next Mastermind State (mmstate) to Hub
	rts	
		
F2_TRUE:
	
	movb 	#$02, mmState                 ; Set next Mastermind State (mmstate) to Hub 
	rts

BS_TRUE:
	
	movb 	#$03, mmState                 ; Set next Mastermind State (mmstate) to Backspace
	rts
	
ENT_TRUE:
	
	movb 	#$04, mmState                 ; Set next Mastermind State (mmstate) to Enter
	rts

DIGIT_TRUE:

	movb 	#$05, mmState                 ; Set next Mastermind State (mmstate) to Digit
	rts
	
ERROR_DELAY_TRUE:                           

	movb 	#$06, mmState                 ; Set next Mastermind State (mmstate) to Err Dly
	rts

;========================= Mastermind State 3 - Backspace State ==========================
	
mmstate3:

	tst 	digitCounter                  ; Test digitCounter
	beq 	BSPACE_DONE                   ; If digitCounter is FALSE, Branch to BSPACE_DONE
	tst 	backspaceFlag                 ; Test digitCounter
	beq 	BSPACE_INIT                   ; If digitCounter is FALSE, Branch to BSPACE_DONE
	tst		mmWaitFlag
	beq		BSPACE_DONE
	rts
	
BSPACE_INIT:
	
	dec		digitCounter                  ; Decrement digitCounter
	ldx 	pointer                       ; Load Index Register X with pointer
	dex 	                              ; Decrement Index Register X
	stx		pointer                       ; Store Index Register X into pointer
	movb 	#$01, backspaceFlag           ; Set backspaceFlag to TRUE
	movb	#$01, mmWaitFlag			  ; Set 
	rts
	
BSPACE_DONE:

	movb 	#$02, mmState                 ; Set next Mastermind State (mmstate) to M^2 Hub
	rts

;===============  Mastermind State 4 - Enter State   =================
	
mmstate4:
	
	tst	 	waveFlag
	lbeq		ENTER_DONE
	tst	    mmWaitFlag
	lbne	ENTER_WAIT		
	tst 	digitCounter                  ; Test digitCounter
	lbeq 	EMPTY_VALUE                   ; If digitCounter is FALSE, Branch to EMPTY_VALUE
	bra 	ASCII_BCD                     ; Otherwise Branch to ASCII_BCD

ASCII_BCD:

	movw    #buffer, pointer              ; Load buffer Adress Into pointer
		
	LOOP:

		ldy 	#$000A                    ; Load Index Register Y with 10    
		ldd 	result                    ; Load Accumulator D with result    
		emul                              ; Multiply Y and D, Store in Y:D
		cpy 	#$0000                    ; Compare Index Register Y with 0   
		bne 	TOO_BIG_VALUE		      ; If overlflow into Y, Branch to TOO_BIG_VALUE         
		std 	result                    ; Store Accumulator D into result    
		ldx 	pointer                   ; Load X with buffer Address Stored In pointer    
		ldab 	0,x                       ; Load Accumulator B with the Contents in X  
		subb 	#$30                      ; Subtract 30 From Accumulator B  
		clra                              ; Clear Accumulator A 
		addd 	result                    ; Add result To D and Store Back Into D   
		std 	result                    ; Store D in result  
		dec 	digitCounter              ; Decrement digitCounter
		tst		digitCounter              ; Test digitCounter         
		beq 	VALUE_PUSH_MAIN           ; If digitCounter is zero, Branch to VALUE_PUSH_MAIN        
		inx                               ; Increment Address in X
		stx		pointer                   ; Store Address In X Into Pointer
		bra 	LOOP                      ; Branch Back Into LOOP          	
	
VALUE_PUSH_MAIN:

	ldx		result                        ; Load Index Register X with result
	cpx		#$0000                        ; Compare Index Register X with 0
	beq		ZERO_VALUE                    ; If Index Register is 0, Branch to ZERO_TICKS
	cpx		#$0001                        ; Compare Index Register X with 1
	beq		SAW_ENT                 	  ; If Index Register is 1, Branch to SAW_ENT
	bra		ENTER_DONE                    ; Otherwise Branch To ENTER_DONE
	
ZERO_VALUE:
	movb	#$01, zeroValuePrint          ; Set zeroTicksPrint to TRUE
	movw	#$0000, result                ; Set result to 0
	movw    #buffer, pointer              ; Move Buffer Address into pointer
			
EMPTY_VALUE:
	
	movb	#$01, emptyValuePrint         ; Set emptyValuePrint to TRUE
	movw	#$0000, result                ; Set result to FALSE
	movw    #buffer, pointer              ; Move buffer Address Into Pointer

TOO_BIG_VALUE:

	movb	#$01, valueTooBigPrint        ; Set valueTooBigPrint to TRUE
	movw	#$0000, result                ; Set result to FALSE
	movw    #buffer, pointer              ; Move buffer Address Into Pointer

SAW_ENT:

	movb #$01, sawwaveFlag				  ; Set sawwaveFlag to 1 for Function Generator
	SPIN:
		bra SPIN
			
ENTER_DONE:

	movw	#$0000, result                ; Set result to 0
	clr	    digitCounter                  ; Clear the digitCounter
	movw    #buffer, pointer              ; Move buffer Address Into pointer
	movb	#$00, enterFlag               ; Set enterFlag to FALSE
	clr		mmWaitFlag
	movb	#$02, mmState                 ; Set next Mastermind State (mmstate) to M^2 Hub
	rts          			

ENTER_WAIT:

	tst clearFlag
	beq	ENTER_DONE
	rts   
	
;====================  Mastermind State 7 - Digit Entered   ====================

mmstate5:

 	tst	    waveFlag
	beq		WAVE_SELECT
	tst		mmWaitFlag
	bne		DIGIT_WAIT
	tst		echoFlag
	beq		DIGIT_DONE				
	cmpb	#$41				          ; Compare Hexadecimal Value In B to $41
	lblo	DIGIT				          ; If Value in B < $40, Branch to DIGIT
	bra		NOTDIGIT			          ; Otherwise Value in B is not a Digit, Branch to NOTDIGIT
	
WAVE_SELECT:

	cmpb	#$31
	beq		WAVE_SELECT
	cmpb	#$32
	beq		WAVE_SELECT
	cmpb	#$33
	beq		WAVE_SELECT
	cmpb	#$34
	beq		WAVE_SELECT
	rts
	
WAVE_SELECT:
	
	clr    	waveFlag
	stab	0,waveValue
	rts
  
DIGIT:

	jsr		BUFFER_STORE                  ; Jump To Subroutine BUFFER_STORE
	movb	#$01, echoFlag                ; Set echoFlag to TRUE
	movb	#$00, keyFlag	              ; Set keyFlag to FALSE
	movb	#$02, mmState				  ; Set next Mastermind State (mmstate) to M^2 Hub
	rts

NOTDIGIT:

	movb	#$00, keyFlag	              ; Set keyFlag to FALSE
	movb	#$02, mmState				  ; Set next Mastermind State (mmstate) to M^2 Hub
	rts

DIGIT_WAIT:

	tst     clearFlag
	lbeq	ENTER_DONE
	rts
	
DIGIT_DONE:

	movb 	#$02, mmState                 ; Set next Mastermind State (mmstate) to M^2 Hub
	rts 
		
	
;====================  Mastermind State 8 - Error Delay State   ================	
	
mmstate6: 
		
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

  	movw   #1500, errorDelayCounter       ; Set errorDelayCounter to 1500		 
    movb   #$00, errorDelayState          ; Set errorDelayState to $0
    movb   #$00, errorDelayFlag           ; Set errorDelayFlag to FALSE
	movb   #$01, clearFlag                ; Set clearFlag to TRUE
	movb   #$01, firstChar                ; Set firstChar to TRUE
	rts

;=========  Mastermind - Miscellaneous Sub-Rountines / Branches   ==============

BUFFER_STORE:

	ldaa   digitCounter                   ; Load Accumulator A with digitCounter
	cmpa   #$03                           ; Compater Accumulator with $03
	bhs    BUFFER_STORE_LIMIT             ; If A is higher or equal than $03, Branch to BUFFER_STORE_LIMIT
	ldx    pointer                        ; Load X with pointer
	ldab   digitStore				      ; Load B with digitStore
	stab   0,x                            ; Store Contents of B into X
	inc    digitCounter                   ; Increment digitCounter
	inx                                   ; Increment X
	stx    pointer                        ; Store X in Pointer
	rts								
	
BUFFER_STORE_LIMIT:

	ldx	   pointer
	movb   #$00,pointer                   ; Store Zero Value into Buffer Addr
	dex	  
	stx	   pointer
	clr	   keyFlag
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
	lbeq   displaystate2                  ; Display Top Prompt 
	deca
	lbeq   displaystate3                  ; Display Wave Prompt
	deca
	lbeq   displaystate4                  ; Initializing & Printing Digit
	deca
	lbeq   displaystate5                  ; Clearing & Printing Prompt
	deca
	lbeq   displaystate6                  ; Backspace
	deca
    lbeq   displaystate7                  ; No Digit Entered Print
	deca
	lbeq   displaystate8                  ; All Zeroes Entered Print
	deca
	lbeq   displaystate9                  ; Value Too Big Print
    rts							
	   
;=============  Display State 0 - Initialize LCD Screen & Cursor   =============
	   
displaystate0: 	
			
	jsr	   INITLCD                        ; Initalize LCD Screen
	jsr    CLRSCREEN                      ; Clear LCD Screen
	jsr    CURSOR                         ; Show Cursor in LCD Screen
	movb   #$01, displayState             ; Return to Display Hub
	rts

;=============  Display State 1 - Display Hub   =============
	   
displaystate1:

	bgnd
	tst    displayTopPrint                 ; Test displayF1Print Flag   
    bne    TOP_INIT_PRINT                  ; If displayF1Print Flag TRUE, Branch to F1_INIT_PRINT
    tst	   displayWavePrompt                 ; Test displayF2Print Flag 
	bne    WAVE_PROMPT                  ; If displayF2Print Flag TRUE, Branch to F2_INIT_PRINT
	tst	   echoFlag                       ; Test echoFlag
	bne	   KEY_INIT_PRINT                 ; If echoFlag TRUE, Branch to KEY_INIT_PRINT
	tst	   clearFlag                      ; Test clearFlag
	bne	   CLEAR_PRINT                    ; If clearFlag TRUE, Branch to CLEAR_PRINT
    tst	   backspaceFlag                  ; Test backspaceFlag
	bne	   BACKSPACE_PRINT                ; If backspaceFlag TRUE, Branch to BACKSPACE_PRINT
    tst    emptyValuePrint                ; Test emptyValuePrint
	bne    EMPTY_VALUE_PRINT              ; If emptyValuePrint TRUE
	tst    zeroValuePrint                 ; Test zeroTicksPrint
	bne    ZERO_VALUE_PRINT               ; If zeroTicksPrint TRUE, Branch to ZERO_TICKS_PRINT
	tst    valueTooBigPrint               ; Test valueTooBigPrint
	bne    VALUE_TOO_BIG                  ; IF valueTooBigPrint TRUE, Branch to VALUE_TOO_BIG
    movb   #$01, displayState             ; Return to Display Hub
    rts

TOP_INIT_PRINT:
	
	movb   #$02, displayState             ; Display Initial Top Prompt Message 
	rts

WAVE_PROMPT:
	
	movb   #$03, displayState             ; Display Initial Bottom Prompt Message
	rts

KEY_INIT_PRINT:
	
	movb   #$04, displayState             ; Initializing & Printing Digit
	rts
	   
CLEAR_PRINT:
			
	movb   #$05, displayState             ; Clearing & Printing Bottom Prompt
	rts

BACKSPACE_PRINT:

	movb   #$06, displayState             ; Backspace
	rts	   
	   
EMPTY_VALUE_PRINT:
				  
    movb   #$07, displayState             ; No Digits Entered Print
	rts
		
ZERO_VALUE_PRINT:
		
	movb   #$08, displayState             ; No Digits Entered Print
	rts
		
VALUE_TOO_BIG:
		
	movb   #$09, displayState             ; Value Too Print
	rts 
	   
;===============  Display State 2 - Display Initial Top Message   ===============

displaystate2:

    ldaa   #$00                           ; Load Accumulator A with $00
    ldx    #TOP_INIT_MESSAGE               ; Load Index Register X Address of F1_INIT_MESSAGE
    jsr    DISPLAY_CHAR   	              ; Jump to Subroutine DISPLAY_CHAR
    ldx    displayPointer                 ; Load Index Register X with value in displayPointer
    ldab   0,x                            ; Load B with the Contents of X
    lbeq   DONE_TOP_INIT_PRINT             ; If X= $00, Branch to DONE_F1_INIT_PRINT
    rts

TOP_INIT_MESSAGE:

	.ascii '1: SAW; 2: SINE-7; 3: SQUARE; 4: SINE-15'
    .byte  $00
	rts               

DONE_TOP_INIT_PRINT:
				
	clr	   displayTopPrint                 ; Clear displayF1Print
    movb   #$01, displayState             ; Return to Display Hub
	movb   #$01, firstChar                ; Set firstchart to TRUE
	rts
	   
;===============  Display State 3 - Display Wave Prompt Message   ===============

displaystate3:

	tst	   sawWaveFlag
	lbne   SAW_PROMPT_PRINT
	tst	   sine7WaveFlag
	lbne   SINE7_PROMPT_PRINT
	tst	   squareWaveFlag
	lbne   SQUARE_PROMPT_PRINT
	tst	   sine15WaveFlag
	lbne   SINE15_PROMPT_PRINT
	rts
	
SAW_PROMPT_PRINT:

    ldaa   #$40                           ; Load Accumulator A with $40
    ldx    #SAW_PROMPT_MESSAGE            ; Load Index Register X with Address of F2_INIT_MESSAGE
    jsr    DISPLAY_CHAR   	              ; Jump to Subroutine DISPLAY_CHAR
    ldx    displayPointer                 ; Load Index Register X with value in displayPointer
    ldab   0,x                            ; Load B with the Contents of X
    lbeq   DONE_WAVE_PROMPT_PRINT             ; If X = $00, Branch to DONE_F2_INIT_PRINT
    rts

SAW_PROMPT_MESSAGE:
	
	.ascii 'SAWTOOTH WAVE        NINT:     [1-->255]'
    .byte  $00               
	rts

SINE7_PROMPT_PRINT:

    ldaa   #$40                           ; Load Accumulator A with $40
    ldx    #SINE7_PROMPT_MESSAGE            ; Load Index Register X with Address of F2_INIT_MESSAGE
    jsr    DISPLAY_CHAR   	              ; Jump to Subroutine DISPLAY_CHAR
    ldx    displayPointer                 ; Load Index Register X with value in displayPointer
    ldab   0,x                            ; Load B with the Contents of X
    lbeq   DONE_WAVE_PROMPT_PRINT             ; If X = $00, Branch to DONE_F2_INIT_PRINT
    rts

SINE7_PROMPT_MESSAGE:

	.ascii 'SINE-7 WAVE          NINT:     [1-->255]'
    .byte  $00               
	rts
	
SQUARE_PROMPT_PRINT:

    ldaa   #$40                           ; Load Accumulator A with $40
    ldx    #SQUARE_PROMPT_MESSAGE            ; Load Index Register X with Address of F2_INIT_MESSAGE
    jsr    DISPLAY_CHAR   	              ; Jump to Subroutine DISPLAY_CHAR
    ldx    displayPointer                 ; Load Index Register X with value in displayPointer
    ldab   0,x                            ; Load B with the Contents of X
    lbeq   DONE_WAVE_PROMPT_PRINT             ; If X = $00, Branch to DONE_F2_INIT_PRINT
    rts

SQUARE_PROMPT_MESSAGE:

    .ascii 'SQUARE WAVE          NINT:     [1-->255]'
    .byte  $00               
	rts
	
SINE15_PROMPT_PRINT:

    ldaa   #$40                           ; Load Accumulator A with $40
    ldx    #SINE15_PROMPT_MESSAGE            ; Load Index Register X with Address of F2_INIT_MESSAGE
    jsr    DISPLAY_CHAR   	              ; Jump to Subroutine DISPLAY_CHAR
    ldx    displayPointer                 ; Load Index Register X with value in displayPointer
    ldab   0,x                            ; Load B with the Contents of X
    lbeq   DONE_WAVE_PROMPT_PRINT             ; If X = $00, Branch to DONE_F2_INIT_PRINT
    rts

SINE15_PROMPT_MESSAGE:

    .ascii 'SINE-15 WAVE         NINT:     [1-->255]'
    .byte  $00               
	rts
	   
DONE_WAVE_PROMPT_PRINT:
						
	ldaa   #$5B
	jsr	   SETADDR			
	clr	   displayWavePrint                 ; Clear displayF2Print
	movb   #$01, displayState             ; Return to Display Hub
	movb   #$01, firstChar                ; Set firstChar to TRUE
	rts

;================ Display State 4 - Initializing & Printing Digit for Entry ==============

displaystate4:

	tst	   cursorMoveFlag                 ; Test cursorMoveFlag
	bne	   CURSOR_MOVE_PRINT_DONE      	  ; If cursorMoveFlag TRUE, Branch to CURSOR_MOVE_PRINT_DONE
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
	   
CURSOR_MOVE_PRINT_DONE:

	movb   #$00, cursorMoveFlag           ; Set cursorMoveFlag to FALSE
	movb   #$01, displayState             ; Return Back to Display Hub 
	rts 

;=================== Display State 5 - Clearing & Printing Bottom Prompt =================
	  
displaystate5:

    ldaa   #$40                           ; Load Accumulator A with $06
    ldx    #BTM_PROMPT_MESSAGE            ; Load Index Register X with F1_PROMPT_MESSAGE Address
    jsr    DISPLAY_CHAR   	              ; Jump to Subroutine DISPLAY_CHAR
    ldx    displayPointer                 ; Load X with displayPointer
    ldab   0,x                            ; Load B with the Contents of X
    lbeq   DONE_BTM_CLEAR_PRINT            ; Branch to DONE_F1_CLEAR_PRINT
    rts

BTM_PROMPT_MESSAGE:

    .ascii '                     NINT:     [1-->255]'
    .byte  	$00
    rts 
	   
DONE_BTM_CLEAR_PRINT:
			
	clr	   clearFlag                      ; Set clearFlag to FALSE
	movb   #$04, displayState             ; Return to Display State 4
	movb   #$01, firstChar                ; Set firstChar to TRUE
	movb   #$01, cursorMoveFlag           ; Set the cursorMoveFlag to TRUE
	movw   #buffer, pointer               ; Move buffer Address Into Pointer
	rts 

ERROR_CLEAR_PRINT:

	movb   #$00, mmState                  ; Reinitialize Mastermind
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
	clr	   mmWaitFlag					  ;	
	rts
		
;======================== Display State 7 - No Digits Entered Print ======================

displaystate7:

    ldaa   #$40                           ; Load Accumulator A with LCD Address $07
    ldx    #NO_DIGITS_PRINT               ; Load Index Register X with Address of NO_DIGITS_PRINT
    jsr    DISPLAY_CHAR   	              ; Jump to Subroutine DISPLAY_CHAR
    ldx    displayPointer                 ; Load X with displayPointer
    ldab   0,x                            ; Load B with the Contents in X
    lbeq   DONE_NO_DIGITS_PRINT           ; If B=$00, Branch to DONE_NO_DIGITS_PRINT
    rts

NO_DIGITS_PRINT:

    .ascii 	'NO DIGITS ENTERED!               '
    .byte  	$00
    rts               
	   
DONE_NO_DIGITS_PRINT:
				
    clr	   emptyValuePrint                ; Clear emptyValuePrint
	movb   #$01, errorDelayFlag           ; Set errorDelayFlag to TRUE
    movb   #$01, displayState             ; Return to Display State 1
	rts
	   
;======================== Display State 8 - All Zeros Entered Print ======================

displaystate8:
	   
    ldaa  #$40                            ; Load Accumulator A with LCD Address $07  
    ldx   #ZERO_DIGITS_PRINT              ; Load X with Address of ZERO_DIGITS_PRINT
    jsr   DISPLAY_CHAR   	              ; Jump to subroutine DISPLAY_CHAR
    ldx   displayPointer                  ; Load X with displayPointer
    ldab  0,x                             ; Load B with the Contents of X
    lbeq  DONE_ZERO_DIGITS_PRINT          ; If B=$00, Branch to DONE_ZERO_DIGITS_PRINT
    rts

ZERO_DIGITS_PRINT:

    .ascii 	'ZERO MAGNITUDE INVALID!          '
    .byte  	$00
	rts               

DONE_ZERO_DIGITS_PRINT:
				
	clr	   zeroValuePrint                 ; Clear zeroTicksPrint
	movb   #$01, errorDelayFlag           ; Set errorDelayFlag to TRUE
	movb   #$01, displayState             ; Return to Display State 1
	rts
			
;======================== Display State 9 - Value Too Big Print ==========================

displaystate9:
	   
    ldaa   #$40                           ; Load A with LCD Address $07
    ldx    #TOO_BIG_PRINT                 ; Load X with TOO_BIG_PRINT Address
    jsr    DISPLAY_CHAR   	              ; Jump to Subroutine DISPLAY
    ldx    displayPointer                 ; Load X with displayPointer
    ldab   0,x                            ; Load B with the Contents of X
    lbeq   DONE_TOO_BIG_PRINT             ; If B=$00, Branch to DONE_TOO_BIG_PRINT
    rts
	   
TOO_BIG_PRINT:

    .ascii 	'MAGNITUDE TOO LARGE!             '
    .byte  	$00
	rts               

DONE_TOO_BIG_PRINT:
				
	movb   #$00, valueTooBigPrint         ; Set valueTooBigPrint = $00 
	movb   #$01, errorDelayFlag           ; Set errorDelayFlag to TRUE
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
	deca
	beq    tc0state2
	rts
	
;================ Timer Channel 0 State 0 - Timer Initialization ===============

tc0State0:
	
	movw   #0320, Interval                ; Setting the Interval for the number of ticks per 0.1ms
	
	bset   TIOS, CHANNEL_ZERO             ; SETTING TC0 FOR OUTPUT COMPARE
	   
	bset   TCTL2, CHANNEL_ZERO            ; INITIALIZE OC0 TO TOGGLE ON SUCCESSFUL COMPARE
	
	bset   TFLG1, #$0001                  ; CLEARING THE TIMER OUTPUT COMPARE FLAG IF SET
	   
	cli                                   ; ENABLING MASKABLE INTERRUPTS
	   
    bset   TMSK1, CHANNEL_ZERO            ; ENABLING TIMER CHANNEL 0 OUTPUT COMPARE INTERRUPTS
	
	movb   #$01, tc0State                 ; Set Next Interrupt State to 1
	
	bset TSCR, $A0                        ; ENABLING THE TIMER AND STOPPING IT WHILE IN BGND MODE
		
	ldd   TCNT                            ; READS THE CURRENT COUNT AND STORE IN D
	
	addd  INTERVAL                        ; ADDS INTERVAL TO THE CURRENT TIMER CURRENT
	
	std   TC0H                            ; STORES INTERVAL + TCNT INTO TC0H
	    
	rts                                   ; RETURN FROM SUBROUTINE
	
;================== Timer Channel 0 State 1 - Arbitrary State ==================

tc0State1:

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

	stab DACA_LSB
	
	staa DACA_MSB
	
	bclr PORTJ, pin_5
	
	bset PORTJ, pin_5
	
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

fgstate2: ; NEW WAVE

	tst DWAVE 		  		; wait for display of wave message
	bne NEW_WAVE_DONE  		;
	ldx WAVEPTR 	  		; point to start of data for wave
	movb 0,X, CSEG 			; get number of wave segments
	movw 1,X, VALUE 		; get initial value for DAC
	movb 3,X, LSEG 			; load segment length
	movw 4,X, SEGINC 		; load segment increment
	inx  	  				; inc SEGPTR to next segment
	inx
	inx
	inx
	inx
	inx
	stx SEGPTR 				; store incremented SEGPTR for next segment
	movb #$01, displayPrompt; set flag for display of NINT prompt
	movb #$03, fgState 		; set next state

NEW_WAVE_DONE: 
			   
	rts
	
;================== Function Generator State 3 - Wait For NINT =================

fgstate3:

	ldx NINT
	cpx	#$0000
	bne	WAIT_NINT_DONE
	rts

WAIT_WAVE_DONE:
	
	movb #$01, run
	movb #$04, fgState
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
	bra SKIP_REINIT_WAVE
	
DNU_RUN: 

	movb #$01, t5state ; set next state
	
SKIP_REINIT_WAVE: 

	clr NEWBTI
	
DNU_NEWBTI: 

	rts


      
;============================  Delay Sub-Routine   =============================
          
DELAY: 
           
 	ldaa   delayState           
	beq    delaystate0                    ; Initialization of Delay
	deca
	beq    delaystate1                    ; Run 1ms Delay
	rts                                     
               
;=====================  Delay State 0 - Initialize Delay   =========================
            
delaystate0:                  
                                               
	movb   #$01, delayState               ; Return to Delay State 1     
	rts

;=====================  Delay State 1 - Run 1ms Delay   ============================              
            
delaystate1:
           
	jsr    DELAY_1MS                      ; Jump to Subroutine DELAY_1MS
	rts
            
DELAY_1MS:
           
	ldy    #$0262                         ; Load Index Register Y with #$0262
                            
INNER:                         
            
	cpy    #0                             ; Compare Y to #0
	beq    EXIT                           ; If Y = $0, Branch to Exit
	dey                                   ; Decrement Y
    bra    INNER                          ; Branch to INNER
                            
EXIT:
	  rts                       

;==================== Interrupt Service Routine & Branches =====================
	  
TC0_ISR:

	tst run
	
	beq NOT_YET
	
	dec CINT
	
	bne NOT_YET
	
	ldd VALUE
	
	jsr OUTDAC
	
	movb NINT, CINT
	
	movb #01, NEWBTI
	
NOT_YET:

	ldd  TC0H                   ; STORE TC0H INTO D
	
	add INTERVAL               	; ADDS INTERVAL TO TC0CH
	
	std  TC0H                   ; LOADS THE TCOH + INTERVAL BACK INTO D
		
	ldaa TFLG1                  ; LOAD TIMER FLAG ONTO ACC. A
	
	oraa #01                    ; CLEAR CONTENTS (TIMER FLAG) OF ACC. A
	
	staa TFLG1                  ; LOAD ACC. A BACK INTO TIMER FLAG
		
	rti

OUTDAC:
	
	stab DACA_LSB
	
	staa DACA_MSB
	
	bclr PORTJ, pin_5
	
	bset PORTJ, pin_5
	
	rts
	  
;===============================================================================

.area interrupt_vectors (abs)
	  .org   $FFEE                                 
	  .word  TC0_ISR                  ; Address of Next Interrupt
	  .org    $FFFE                             ; At reset vector location
	  .word   __start                           ; Load starting address