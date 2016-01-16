eight; Robert Cory Molloy & Oscar Andrade
; ME 305 - 02 :: Intro to Mechatronics
; Labratory 3 ::  

;===========================Assembler Equates===================================================

PORTS        = $00D6              ; Output Port for LEDs
DDRS         = $00D7			  ; Setting Ports in S as Outputs
LED_MSK_1    = 0b00000011         ; LED_1 Output Pins
LED_MSK_2    = 0b00001100         ; LED_2 Output pins
R_LED_1      = 0b00000001         ; Red LED_1 Output Pin
G_LED_1      = 0b00000010         ; Green LED_1 Output Pin
R_LED_2      = 0b00000100         ; Red LED_2 Output Pin
G_LED_2      = 0b00001000         ; Green LED_2 Output Pin

;===============================RAM area================================================

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
firstChar::			.blkb 1		; Notify Program the First Character is Ready to Be Printed
clearFlag::			.blkb 1		; Notify Program that the F1 / F2 Line Needs to Be Cleared
backspaceFlag::		.blkb 1		; Notify Program that a F1 / F2 Entered Digit Needs to Be Cleared
pattern1Done::		.blkb 1		; Notify Program that Pattern 1 Delay is Done
pattern2Done::		.blkb 1  	; Notify Program that Pattern 2 Delay is Done
errorDelayFlag::	.blkb 1     ; Notify Program that error message should be delayed 	
errorDelayDone::	.blkb 1     ; Notify Prgram that delayed message display is done
cursorMoveFlag::	.blkb 1     ; Move the cursor to assigned address
fromPreviousPrint:: .blkb 1     ; Notify program that Previous Print has been executed

; Print Variables

displayF1Print:: 	.blkb 1		; Notify Program to Move Forward in Displaying F1 Message
displayF2Print:: 	.blkb 1		; Notify Program to Move Forward in Displaying F2 Message 
digitPrint::		.blkb 1		; Notify Program to Move Forward in Displaying F1/F2 Digit
valueTooBigPrint::	.blkb 1		; Notify Program to Move Forward in Displaying Value Too Big Error Message
zeroTicksPrint::	.blkb 1		; Notify Program to Move Forward in Displaying Zero Value Message
backSpacePrint::	.blkb 1		; Notify Program the Backspace Needs to Go Through Routine

; Storing Variables

digitStore::		.blkb 1		; Stores Most Recent Digit Pressed
buffer::			.blkb 5		; Stores All Digits for Processing to Ticks
result::			.blkb 2		; Stores converted ASCII numbers
pattern1Ticks::		.blkb 2     ; Hexadecimal Value for first pair of LEDs
pattern2Ticks::		.blkb 2     ; Hexadecimal Value for second pair of LEDs

; Counter Variables

digitCounter::		.blkb 1		; Counts Up Current Digits Input into buffer
clrBufferCounter::  .blkb 1     ; Notify program of how many cycles of clear buffer there are left
errorDelayCounter::	.blkb 2     ; Countdown of delay
pattern1Counter::   .blkb 2     ; Coundown of pattern for first pair of LEDs 
pattern2Counter::   .blkb 2     ; Coundown of pattern for second pair of LEDs  

; Other Variables

pointer::		    .blkb 2     ; Holds the Address of buffer		
displayPointer::	.blkb 2     ; Holds ASCII numbers pressed on keypad

.area text

;==========================  Main Program  ======================================

_main::

	bgnd
	jsr    	INIT        		; Initialization
	
TOP: 
  
	bgnd
	
	jsr    	MASTERMIND			; Mastermind Sub-Routines

	jsr    	KPD		  			; Key Pad Driver Sub-Routines

	jsr    	DISPLAY      		; Display Sub-Routines
	
	jsr    	LED_PATTERN_1       ; Pattern for first pair of LEDs
	
	jsr    	LED_TIMING_1        ; Timing for first pair of LEDs
	
	jsr    	LED_PATTERN_2       ; Pattern for first second of LEDs
	
	jsr    	LED_TIMING_2        ; Timing for second pair of LEDs

	jsr		DELAY				; Delay Sub-Routine
	
    bra		TOP

;==========================  Initialization  =======================================

INIT:

	clr		mmState				; Initialize  All Sub-Routine State Variables to State 0
	clr	  	kpdState            ; Clear Keypad Driver States Variable
	clr		displayState        ; Clear Displaysate State Variable
	clr		pattern1State		; Clear Pattern 1 State Variable
	clr		timing1State        ; Clear Timing 1 State Variable
	clr		pattern2State       ; Clear Pattern 2 State Variable
	clr		timing2State        ; Clear Timing 2 State Variable
	clr		dlyState            ; Clear Delay State Variable
	clr		backspaceState      ; Clear Backspace State Varible
	rts	
	   
;==========================  Mastermind Sub-Routine  ===============================

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

;==========  Mastermind State 0 - Initialization of Mastermind & Buffer  ============

mmstate0:	
					
	movw    #buffer, pointer 		; Stores the first address of buffer into pointer
	clr		buffer					; Clear the buffer Variable
	movw    #$0000, result			; Clear the result Variable
	movb	#$01, mmState			; Set the Mastermind State Variable to 1    
	rts

;===============  Mastermind State 1 - Splash Screen and Setting Displays Flags & Counters  ====

mmstate1:

	movb	 #$01, firstChar     	      ; Set firstChar flag to 1 (True) 
    movb     #$01, displayF1Print	      ; Set displayF1Print flag to 1 (True)
	movb   	 #$01, displayF2Print	      ; Set displayF1Print flag to 1 (True)
    movw     #1500, errorDelayCounter     ; Set Error Delay Counter to 1500
    movb	 #$00, errorDelayFlag         ; Clear Error Delay Flag (False)
    movw	 #0000, pattern1Ticks         ; Clear Pattern 1 Ticks
	movw	 #0000, pattern2Ticks         ; Clear Pattern 2 Ticks
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
	
	movb 	#$02, mmState                 ; If no Key was Pressed Comeback around to M^2 HUB
	rts
	
F1_TRUE:
	
	movb 	#$03, mmState                 ; Set next Mastermind State (mmstate) to F1
	rts	
		
F2_TRUE:
	
	movb 	#$04, mmState                 ; Set next Mastermind State (mmstate) to F2
	rts

BS_TRUE:
	
	movb 	#$05, mmState                 ; Set next Mastermind State (mmstate) to Backspace
	rts
	
ENT_TRUE:
	
	movb 	#$06, mmState                 ; Set next Mastermind State (mmstate) to Enter
	rts

DIGIT_TRUE:

	movb 	#$07, mmState                 ; Set next Mastermind State (mmstate) to Digit
	rts
	
ERROR_DELAY_TRUE:                           

	movb 	#$08, mmState                 ; Set next Mastermind State (mmstate) to Error Delay
	rts

;===============  Mastermind State 3 - F1 State   =================
	
mmstate3:
	
	tst 	F2Flag                        ; Test F2Flag
	bne 	F2_IN_F1                      ; If F2Flag is True, Branch To F2_IN_F1
	tst		F1Flag                        ; Test F1Flag
	bne		F1_PREV                       ; If F1Flag is True, Branch to F1_PREV
	tst		enterFlag                     ; Test enterFlag
	bne		F1_ERASE	                  ; IF enterFlag is True, Branch to F1_ERASE
	ldy		pattern1Ticks                 ; Load Index Register Y with pattern1Ticks
	cpy		#$0000                        ; Compare Index Register Y with 0
	bne		F1_ERASE_TICKS                ; If  Y not Equal to 0, Branch to F1_ERASE_TICKS
	clr		digitCounter                  ; Clear the digitCounter Variable
	clr 	buffer                        ; Clear the buffer Variable
	movb	#$01, F1Flag                  ; Set F1FLAG to True
	movb	#$01, echoFlag                ; Set echoFlag to True
	movb	#$01, firstChar               ; Set firstChar to True
	movb 	#$02, mmState                 ; Set next Mastermind State (mmstate) to M^2 Hub
	rts

F2_IN_F1:

    movb   #$02, mmState                  ; Set next state to: M^2 HUB
    movb   #$00, F1Flag                   ; Clear F1FLAG
	rts
	
F1_PREV:

    movb   #$02, mmState                  ; Set next Mastermind State (mmstate) to BS
	rts
	
F1_ERASE:
	movb   #$01, firstChar                ; Set firstChar to True
	movb   #$01, F1Flag                   ; Set F1FLAG to True
	movb   #$01, clearFlag                ; Set clearFlag to True
	movb   #$02, mmState	              ; Set next Mastermind State (mmstate) to M^2 Hub
	rts
	
F1_ERASE_TICKS:
	movb   #$01, firstChar                ; Set firstChar to True
	movb   #$01, F1Flag                   ; Set F1FLAG to True
	movb   #$01, clearFlag                ; Set clearFlag to True
	movb   #$02, mmState 	              ; Set next Mastermind State (mmstate) to M^2 Hub
	rts
	 
;===============  Mastermind State 4 - F2 State   =================
	
mmstate4:
	
	tst 	F1Flag                        ; Test F1FLAG
	bne 	F1_IN_F2                      ; If F1FLAG is TRUE Branch, to F1_IN_F2
	tst 	F2Flag                        ; Test F2Flag
	bne 	F2_PREV                       ; IF F2Flag is TRUE Branch,  to F2_PREV
	tst		enterFlag                     ; Test enterFlag
	bne		F2_ERASE                      ; If enterFlag is TRUE Branch, to F2_ERASE
	ldy		pattern2Ticks                 ; Load Accumulator Y with pattern1Ticks
	cpy		#$0000                        ; Compare Accumulator Y to 0
	bne		F2_ERASE_TICKS                ; If Y not 0, Branch to F2_ERASE_TICKS
	clr 	digitCounter                  ; Clear the digitCounter
	clr 	buffer                        ; Clear buffer
	movb	#$01, F2Flag                  ; Set F2Flag to TRUE
	movb	#$01, echoFlag                ; Set echoFlag to TRUE
	movb	#$01, firstChar               ; Set firstChar to TRUE
	movb 	#$02, mmState                 ; Set next Mastermind State (mmstate) to M^2 Hub
	rts
	
	
F1_IN_F2:

    movb   #$02, mmState                  ; Set next Mastermind State (mmstate) to M^2 Hub
    movb   #$00, F2Flag                   ; Set F2 to FALSE
	rts

F2_PREV:

    movb   #$02, mmState                  ; Set next Mastermind State (mmstate) to M^2 Hub
	rts	

F2_ERASE:

	movb   #$01, firstChar                ; Set firstChar to TRUE
	movb   #$01, F2Flag                   ; Set F2Flag to TRUE  
	movb   #$01, clearFlag                ; Set clearFlag to TRUE
	movb   #$02, mmState                  ; Set next Mastermind State (mmstate) to M^2 Hub
	rts

F2_ERASE_TICKS:

	movb   #$01, firstChar                ; Set firstChar to TRUE
	movb   #$01, F2Flag                   ; Set F2Flag to TRUE
	movb   #$01, clearFlag                ; Set clearFlag to TRUE
	movb   #$02, mmState 	              ; Set next Mastermind State (mmstate) to M^2 Hub
	rts	

;===============  Mastermind State 5 - Backspace State   =================
	
mmstate5:
	
	tst 	digitCounter                  ; Test digitCounter
	beq 	BSPACE_DONE                   ; If digitCounter is FALSE, Branch to BSPACE_DONE
	dec		digitCounter                  ; Decrement digitCounter
	ldx 	pointer                       ; Load Index Register X with pointer
	dex 	                              ; Decrement Index Register X
	stx		pointer                       ; Store Index Register X into pointer
	movb 	#$01, backspaceFlag           ; Set backspaceFlag to TRUE
	movb 	#$02, mmState                 ; Set next Mastermind State (mmstate) to M^2 Hub
	rts
	
	
BSPACE_DONE:

	movb 	#$02, mmState                 ; Set next Mastermind State (mmstate) to M^2 Hub
	rts

;===============  Mastermind State 6 - Enter State   =================
	
mmstate6:
	
	tst 	F1Flag                        ; Test F1FLAG
	bne 	ENTER_MAIN                    ; If F1FLAG is TRUE , Branch to ENTER_MAIN
	tst 	F2Flag                        ; Test F2Flag
	bne 	ENTER_MAIN                    ; IF F2Flag is TRUE, Branch to ENTER_MAIN
	movb 	#$02, mmState                 ; Set next Mastermind State (mmstate) to M^2 Hub
	rts
	
	
ENTER_MAIN:

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
		bne 	TOO_BIG_INIT              ; If overlflow into Y, Branch to TOO_BIG_INIT         
		std 	result                    ; Store Accumulator D into result    
		ldx 	pointer                   ; Load X with buffer Address Stored In pointer    
		ldab 	0,x                       ; Load Accumulator B with the Contents in X  
		subb 	#$30                      ; Subtract 30 From Accumulator B  
		clra                              ; Clear Accumulator A 
		addd 	result                    ; Add result To D and Store Back Into D   
		std 	result                    ; Store D in result  
		dec 	digitCounter              ; Decrement digitCounter
		tst		digitCounter              ; Test digitCounter         
		beq 	TICKS_PUSH_MAIN           ; If digitCounter is FALSE, Branch to TICKS_PUSH_MAIN        
		inx                               ; Increment Address in X
		stx		pointer                   ; Store Address In X Into Pointer
		bra 	LOOP                      ; Branch Back Into LOOP          

TOO_BIG_INIT:

	movb	#$01, valueTooBigPrint        ; Set valueTooBigPrint to TRUE
	movw	#$0000, result                ; Set result to FALSE
	jsr		CLEAR_BUFFER                  ; Jump to Subroutine CLEAR_BUFFER
	movw    #buffer, pointer              ; Move buffer Address Into Pointer
	movb	#$00, enterFlag               ; Set enterFlag to FALSE
	movb	#$02, mmState                 ; Set next Mastermind State (mmstate) to M^2 Hub
	rts		
	
TICKS_PUSH_MAIN:

	ldx		result                        ; Load Index Register X with result
	cpx		#$0000                        ; Compare Index Register X with 0
	beq		ZERO_TICKS                    ; If Index Register is 0, Branch to ZERO_TICKS
	tst		F1Flag                        ; Test F1FLAG
	bne		F1_TICKS_PUSH                 ; If F1FLAG is TRUE, Branch to F1_TICKS_PUSH
	tst		F2Flag                        ; Test F2Flag
	bne		F2_TICKS_PUSH                 ; If F2Flag is TRUE, Branch to F2_TICKS_PUSH
	bra		ENTER_DONE                    ; Otherwise Branch To ENTER_DONE
	
ZERO_TICKS:
	movb	#$01, zeroTicksPrint          ; Set zeroTicksPrint to TRUE
	movw	#$0000, result                ; Set result to 0
	jsr		CLEAR_BUFFER                  ; Jump to Subroutine CLEAR_BUFFER
	movw    #buffer, pointer              ; Move Buffer Address into pointer
	movb	#$00, enterFlag               ; Set enterFlag to FALSE
	movb	#$02, mmState                 ; Set next Mastermind State (mmstate) to M^2 Hub
	movb	#$01, errorDelayFlag          ; Set errorDelayFlag to TRUE
	rts
	
F1_TICKS_PUSH:
	
	movw	result, pattern1Ticks         ; Move result into pattern1Ticks
	bra		ENTER_DONE                    ; Branch to ENTER_DONE
	
F2_TICKS_PUSH:
	
	movw	result, pattern2Ticks         ; Move result into pattern2Ticks
	bra		ENTER_DONE                    ; Branch to ENTER_DONE
		
EMPTY_VALUE:
	
	movb	#$01, emptyValuePrint         ; Set emptyValuePrint to TRUE
	movb 	#02,  mmState	              ; Set next Mastermind State (mmstate) to M^2 Hub
	rts
	
ENTER_DONE:

	clr		F1Flag                        ; Set F1FLAG to FALSE
	clr		F2Flag                        ; Set F2Flag to FALSE
	movw	#$0000, result                ; Set result to 0
	jsr		CLEAR_BUFFER                  ; Jump To Subroutine CLEAR_BUFFER
	clr	    digitCounter                  ; Clear the digitCounter
	movw    #buffer, pointer              ; Move buffer Address Into pointer
	movb	#$00, enterFlag               ; Set enterFlag to FALSE
	movb	#$02, mmState                 ; Set next Mastermind State (mmstate) to M^2 Hub
	rts          			

;====================  Mastermind State 7 - Digit True   ======================

mmstate7:

	cmpb	#$41				          ; Compare Hexadecimal Value In B to $41
	lblo	DIGIT				          ; If Value in B < $40, Branch to DIGIT
	bra		NOTDIGIT			          ; Otherwise Value in B is not a Digit, Branch to NOTDIGIT
	
DIGIT:

	jsr		BUFFER_STORE                  ; Jump To Subroutine BUFFER_STORE
	movb	#$02, mmState		          ; Set next Mastermind State (mmstate) to M^2 Hub
	movb	#$01, echoFlag                ; Set echoFlag to TRUE
	movb	#$00, keyFlag	              ; Set keyFlag to FALSE
	rts

NOTDIGIT:

	movb	#$02, mmState	              ; Set next Mastermind State (mmstate) to M^2 Hub
	movb	#$00, keyFlag	              ; Set keyFlag to FALSE
	rts

;====================  Mastermind State 8 - Error Delay State   ================	
	
mmstate8: 
		
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
	tst    F1Flag                         ; Test F1FLAG 
	bne	   F1_DELAY_DONE                  ; If F1FLAG is TRUE, Branch to F1_DELAY_DONE
	tst    F2Flag                         ; Test F2Flag
	bne	   F2_DELAY_DONE                  ; IF F2Flag is TRUE, Branch to F2_DELAY_DONE
  	movw   #1500, errorDelayCounter       ; Set errorDelayCounter to 1500		 
    movb   #$00, errorDelayState          ; Set errorDelayState to $0
    movb   #$00, errorDelayFlag           ; Set errorDelayFlag to FALSE
	movb   #$01, errorDelayDone           ; Set errorDelayDone to TRUE
	movb   #$02, mmState                  ; Set next Mastermind State (mmstate) to M^2 Hub
	movb   #$01, clearFlag                ; Set clearFlag to TRUE
	movb   #$01, firstChar                ; Set firstChar to TRUE
	rts
	
F1_DELAY_DONE:

	ldy	   pattern1Ticks                  ; Load Accumulator Y with pattern1Ticks
	cpy	   #$0000                         ; Compare Accumulator Y with $0000
	beq	   FIRST_AROUND_1                 ; If Accumulator=$0000, Branch to FIRST_AROUND_1
  	movw   #1500, errorDelayCounter	      ; Set errorDelayCounter to 1500	 
    movb   #$00, errorDelayState          ; Set errorDelayState to $00
	movb   #$00, errorDelayFlag           ; Set errorDelayFlag to FALSE
	movb   #$01, errorDelayDone           ; Set errorDelayDone to TRUE
	movb   #$02, mmState                  ; Set next Mastermind State (mmstate) to M^2 Hub
	movb   #$01, clearFlag                ; Set clearFlag to TRUE
	movb   #$01, firstChar                ; Set firstChar to TRUE
	rts 
		
F2_DELAY_DONE:

	ldy	   pattern2Ticks                  ; Load Accumulator Y with pattern2Ticks
	cpy	   #$0000                         ; Compare Accumulator Y with $0000
	beq	   FIRST_AROUND_2                 ; IF y=$0000 , Branch to FIRST_AROUND_2
  	movw   #1500, errorDelayCounter	      ; Set errorDelayCounter to 1500	 
    movb   #$00, errorDelayState          ; Set errorDelayState to $00
    movb   #$00, errorDelayFlag           ; Set errorDelayFlag to FALSE
	movb   #$01, errorDelayDone           ; Set errorDelayDone to $01
	movb   #$02, mmState                  ; Set next Mastermind State (mmstate) to M^2 Hub
	movb   #$01, clearFlag                ; Set clearFlag to TRUE
	movb   #$01, firstChar                ; Set firstChar to TRUE
	rts
		
FIRST_AROUND_1:
  	movw   #1500, errorDelayCounter	      ; Set errorDelayCounter to 1500	 
    movb   #$00, errorDelayState          ; Set errorDelayState to $00
	movb   #$00, errorDelayFlag           ; Set errorDelayFlag to FALSE
	movb   #$02, mmState                  ; Set next Mastermind State (mmstate) to M^2 Hub
	movb   #$01, clearFlag                ; Set clearFlag to TRUE
	movb   #$01, firstChar                ; Set firstChar to TRUE
	rts
		
FIRST_AROUND_2:
  	movw   #1500, errorDelayCounter	      ; Set errorDelayCounter to 1500 
    movb   #$00, errorDelayState          ; Set errorDelayState to $00
    movb   #$00, errorDelayFlag           ; Set errorDelayFlag
	movb   #$02, mmState                  ; Set next Mastermind State (mmstate) to M^2 Hub
	movb   #$01, clearFlag                ; Set clearFlag to TRUE
	movb   #$01, firstChar                ; Set firstChar to TRUE
	rts

;=========  Mastermind - Miscellaneous Sub-Rountines / Branches   ==============

BUFFER_STORE:

	ldaa   digitCounter                   ; Load Accumulator A with digitCounter
	cmpa   #$05                           ; Compater Accumulator with $05
	bhi    BUFFER_STORE_LIMIT             ; IF A is higher than $05, Branch to BUFFER_STORE_LIMIT
	ldx    pointer                        ; Load X with pointer
	ldab   digitStore				      ; Load B with digitStore
	stab   0,x                            ; Store Contents of B into X
	inc    digitCounter                   ; Increment digitCounter
	inx                                   ; Increment X
	stx    pointer                        ; Store X in Pointer
	rts								
	
BUFFER_STORE_LIMIT:

	dec    digitCounter                   ; Decrement digitCounter
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
	lbeq   displaystate2                  ; Display Initial F1 Message 
	deca
	lbeq   displaystate3                  ; Display Initial F2 Message
	deca
	lbeq   displaystate4                  ; Initializing & Printing Digit for F1 / F2
	deca
	lbeq   displaystate5                  ; Clearing & Printing Prompt for F1 / F2
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
	tst    displayF1Print                 ; Test displayF1Print Flag   
    bne    F1_INIT_PRINT                  ; If displayF1Print Flag TRUE, Branch to F1_INIT_PRINT
    tst	   displayF2Print                 ; Test displayF2Print Flag 
	bne    F2_INIT_PRINT                  ; If displayF2Print Flag TRUE, Branch to F2_INIT_PRINT
	tst	   echoFlag                       ; Test echoFlag
	bne	   KEY_INIT_PRINT                 ; If echoFlag TRUE, Branch to KEY_INIT_PRINT
	tst	   clearFlag                      ; Test clearFlag
	bne	   CLEAR_PRINT                    ; If clearFlag TRUE, Branch to CLEAR_PRINT
    tst	   backspaceFlag                  ; Test backspaceFlag
	bne	   BACKSPACE_PRINT                ; If backspaceFlag TRUE, Branch to BACKSPACE_PRINT
    tst    emptyValuePrint                ; Test emptyValuePrint
	bne    EMPTY_VALUE_PRINT              ; If emptyValuePrint TRUE
	tst    zeroTicksPrint                 ; Test zeroTicksPrint
	bne    ZERO_TICKS_PRINT               ; If zeroTicksPrint TRUE, Branch to ZERO_TICKS_PRINT
	tst    valueTooBigPrint               ; Test valueTooBigPrint
	bne    VALUE_TOO_BIG                  ; IF valueTooBigPrint TRUE, Branch to VALUE_TOO_BIG
    movb   #$01, displayState             ; Return to Display Hub
    rts

F1_INIT_PRINT:
	
	movb   #$02, displayState             ; Display Initial F1 Message 
	rts

F2_INIT_PRINT:
	
	movb   #$03, displayState             ; Display Initial F2 Message
	rts

KEY_INIT_PRINT:
	
	movb   #$04, displayState             ; Initializing & Printing Digit for F1 / F2
	rts
	   
CLEAR_PRINT:
			
	movb   #$05, displayState             ; Clearing & Printing Prompt for F1 / F2
	rts

BACKSPACE_PRINT:

	movb   #$06, displayState             ; Backspace
	rts	   
	   
EMPTY_VALUE_PRINT:
				  
    movb   #$07, displayState             ; No Digits Entered Print
	rts
		
ZERO_TICKS_PRINT:
		
	movb   #$08, displayState             ; No Digits Entered Print
	rts
		
VALUE_TOO_BIG:
		
	movb   #$09, displayState             ; Value Too Print
	rts 
	   
;===============  Display State 2 - Display Initial F1 Message   ===============

displaystate2:

    ldaa   #$00                           ; Load Accumulator A with $00
    ldx    #F1_INIT_MESSAGE               ; Load Index Register X Address of F1_INIT_MESSAGE
    jsr    DISPLAY_CHAR   	              ; Jump to Subroutine DISPLAY_CHAR
    ldx    displayPointer                 ; Load Index Register X with value in displayPointer
    ldab   0,x                            ; Load B with the Contents of X
    lbeq   DONE_F1_INIT_PRINT             ; If X= $00, Branch to DONE_F1_INIT_PRINT
    rts

F1_INIT_MESSAGE:

    .ascii 'TIME1=        <F1> TO UPDATE LED1 PERIOD'
    .byte  $00
	rts               

DONE_F1_INIT_PRINT:
				
	clr	   displayF1Print                 ; Clear displayF1Print
    movb   #$01, displayState             ; Return to Display Hub
	movb   #$01, firstChar                ; Set firstchart to TRUE
	rts
	   
;===============  Display State 3 - Display Initial F2 Message   ===============

displaystate3:

    ldaa   #$40                           ; Load Accumulator A with $40
    ldx    #F2_INIT_MESSAGE               ; Load Index Register X with Address of F2_INIT_MESSAGE
    jsr    DISPLAY_CHAR   	              ; Jump to Subroutine DISPLAY_CHAR
    ldx    displayPointer                 ; Load Index Register X with value in displayPointer
    ldab   0,x                            ; Load B with the Contents of X
    lbeq   DONE_F2_INIT_PRINT             ; If X = $00, Branch to DONE_F2_INIT_PRINT
    rts

F2_INIT_MESSAGE:

    .ascii 'TIME2=        <F2> TO UPDATE LED2 PERIOD'
    .byte  $00               
	rts
	   
DONE_F2_INIT_PRINT:
				
	clr	   displayF2Print                 ; Clear displayF2Print
	movb   #$01, displayState             ; Return to Display Hub
	movb   #$01, firstChar                ; Set firstChar to TRUE
	rts

;======  Display State 4 - Initializing & Printing Digit for F1 / F2   =========

displaystate4:

	tst	   F1Flag                         ; Test F1FLAG
	bne	   F1_PRINT                       ; If F1FLAG TRUE, Branch to F1_PRINT
	tst	   F2Flag                         ; Test F2FLAG
	bne	   F2_PRINT                       ; If F2FLAG TRUE, Branch to F2_PRINT
	movb   #$01, displayState             ; Return to Display Hub
	rts
	   
F1_PRINT:

	tst	   errorDelayDone                 ; Test errorDelayDone
	bne	   F1_PRINT_ERROR_DONE            ; If errorDelayDone TRUE, Branch to F1_PRINT_ERROR_DONE
	tst	   cursorMoveFlag                 ; Test cursorMoveFlag
	bne	   F1_CURSOR_MOVE_PRINT_DONE      ; If cursorMoveFlag TRUE, Branch to F1_CURSOR_MOVE_PRINT_DONE
    ldaa   digitCounter                   ; Load Accumulator A with digitCounter
    cmpa   #$00                           ; Compare A with $00 
	bne	   DIGIT_NOT_FIRST                ; If A not $00, Branch to DIGIT_NOT_FIRST
    ldaa   #$07                           ; Load A with $07
    jsr	   SETADDR                        ; Set the Cursor in the Address Value Stored in A
	tst	   fromPreviousPrint              ; Test fromPreviousPrint 
	bne	   INIT_PRINT_DONE                ; If fromPreviousPrint TRUE, Branch to INIT_PRINT_DONE
	cmpb   #$F1                           ; Compare Value in Accumulator In B with $F1
	beq	   INIT_PRINT_DONE                ; If Value in A = $F1, Branch to INIT_PRINT_DONE
	bra	   PRINT_FIRST_DIGIT              ; Otherwise, Branch to PRINT_FIRST_DIGIT
	   
F2_PRINT:

	tst	   errorDelayDone                 ; Test errorDelayDone
	bne	   F2_PRINT_ERROR_DONE            ; If errorDelayDone TRUE, Branch to F2_PRINT_ERROR_DONE
	tst	   cursorMoveFlag                 ; Test cursorMoveFlag
	bne	   F1_CURSOR_MOVE_PRINT_DONE      ; If cursorMoveFlag TRUE, Branch to F1_PRINT_ERROR_DONE
    ldaa   digitCounter                   ; Load Accumulator A with digitCounter
	cmpa   #$00                           ; Compare Value in A with $00
	bne	   DIGIT_NOT_FIRST                ; If Value in A not $00, Branch to DIGIT_NOT_FIRST
	ldaa   #$47                           ; Load A with $47 (LCD Address)
	jsr	   SETADDR                        ; Set the Cursor In Address Stored in A
	tst	   fromPreviousPrint              ; Test fromPreviousPrint
    bne	   INIT_PRINT_DONE                ; If fromPreviousPrint TRUE, Branch to INIT_PRINT_DONE
	cmpb   #$F2                           ; Compare Value In Accumulator With $F2
	beq	   INIT_PRINT_DONE                ; If Value in B = $F2, Branch to INIT_PRINT_DONE
	bra	   PRINT_FIRST_DIGIT              ; Otherwise, Branch to PRINT_FIRST_DIGIT
       
PRINT_FIRST_DIGIT:

	ldab   digitStore                     ; Load Accumulator B With digitStore
	jsr	   OUTCHAR                        ; Print Character Stored in B
	bra	   INIT_PRINT_DONE                ; Branch to INIT_PRINT_DONE
	   
DIGIT_NOT_FIRST:

	ldaa   digitCounter                   ; Load Accumulator A with digitCounter
	cmpa   #$05                           ; Compare A with $05
    bgt    INIT_PRINT_DONE                ; If Value in A > $05, Branch to INIT_PRINT_DONE
	ldab   digitStore                     ; Load Accumulator B with digitStore
	jsr	   OUTCHAR                        ; Print Character of ASCII Value in Stored in B
	bra	   INIT_PRINT_DONE                ; Branch to INIT_PRINT_DONE
	   
INIT_PRINT_DONE:

	clr	   echoFlag                       ; Set echoFlag to FALSE
	movb   #01, displayState              ; Return Back to Display Hub
	rts
	   
F1_PRINT_ERROR_DONE:

	movb   #$00, errorDelayDone           ; Set errorDelayDone to $00
    movb   #$00, F1Flag                   ; Set F1FLAG to FALSE
	movb   #$01, displayState             ; Return Back to Display Hub
	rts
	   
F2_PRINT_ERROR_DONE:

	movb   #$00, errorDelayDone           ; Set errorDelayDone to $00 s
	movb   #$00, F2Flag                   ; Set F2FLAG to FALSE
	movb   #01, displayState              ; Return Back to Display Hub
	rts
	   
F1_CURSOR_MOVE_PRINT_DONE:

	movb   #$00, cursorMoveFlag           ; Set cursorMoveFlag to FALSE
	movb   #$01, F1Flag                   ; Set F1FLAG to TRUE
	movb   #$01, displayState             ; Return Back to Display Hub 
	rts 

F2_CURSOR_MOVE_PRINT_DONE:

	movb   #$00, cursorMoveFlag           ; Set cursorMoveFlag to FALSE
	movb   #$01, F2Flag                   ; Set F2Flag to TRUE
	movb   #$01, displayState             ; Return Back to Display Hub
	rts
	   	   
;======  Display State 5 - Clearing & Printing Prompt for F1 / F2   ================

displaystate5:

	tst	   F1Flag                         ; Test F1Flag
	bne	   F1_CLEAR                       ; If F1Flag TRUE, Branch to F1_CLEAR
	tst	   F2Flag                         ; Test F2Flag
	lbne   F2_CLEAR                       ; If F2Flag TRUE, Branch to F2_CLEAR
	lbra   ERROR_CLEAR_PRINT              ; Otherwise, Branch to ERROR_CLEAR_PRINT
	  
F1_CLEAR:

    ldaa   #$06                           ; Load Accumulator A with $06
    ldx    #F1_PROMPT_MESSAGE             ; Load Index Register X with F1_PROMPT_MESSAGE Address
    jsr    DISPLAY_CHAR   	              ; Jump to Subroutine DISPLAY_CHAR
    ldx    displayPointer                 ; Load X with displayPointer
    ldab   0,x                            ; Load B with the Contents of X
    lbeq   DONE_F1_CLEAR_PRINT            ; Branch to DONE_F1_CLEAR_PRINT
    rts

F1_PROMPT_MESSAGE:

    .ascii 	'        <F1> TO UPDATE LED1 PERIOD'
    .byte  	$00
    rts 
	   
DONE_F1_CLEAR_PRINT:
			
	ldy	   pattern1Ticks                  ; Load Index Register Y with pattern1Ticks
	cpy	   #$0000                         ; Compare Value in Y with $0000
	lbne   DONE_F1_CLEAR_PRINT_TICKS	  ; If Value in Y not $0000 Branch to DONE_F1_CLEAR_PRINT_TICKS
	clr	   enterFlag                      ; Set enterFlag to FALSE
	clr	   clearFlag                      ; Set clearFlag to FALSE
	movb   #$00, F1Flag                   ; Set F1Flag to FALSE
	movb   #$04, displayState             ; Return to Display State 4
	movb   #$01, firstChar                ; Set firstChar to TRUE
	movb   #$01, cursorMoveFlag           ; Set the cursorMoveFlag to TRUE
    jsr	   CLEAR_BUFFER                   ; Jump to Subroutine CLEAR_BUFFER
	movw   #buffer, pointer               ; Move buffer Address Into Pointer
	rts 

DONE_F1_CLEAR_PRINT_TICKS:

	clr	   enterFlag                      ; Set enterFlag to FALSE
	clr	   clearFlag                      ; Set clearFlag to FALSE
	movb   #$01, F1Flag                   ; Set F1FLAG to TRUE
	movb   #$04, displayState             ; Return to Display State 4
	movb   #$01, firstChar                ; Set firstChar to TRUE
	movb   #$01, fromPreviousPrint        ; Set fromPreviousPrint to TRUE
	jsr	   CLEAR_BUFFER                   ; Jump to Subroutine CLEAR_BUFFER
    movw   #buffer, pointer               ; Move buffer Address into Pointer
	rts
	     
F2_CLEAR:
	
    ldaa   #$46                           ; Load Accumulator A with $46
    ldx    #F2_PROMPT_MESSAGE             ; Load X with Address of F2_PROMPT_MESSAGE
    jsr    DISPLAY_CHAR   	              ; Jump to Subroutine DISPLAY_CHAR
    ldx    displayPointer                 ; Load X with displayPointer
    ldab   0,x                            ; Load B with the Contents of X
    lbeq   DONE_F2_CLEAR_PRINT            ; If B = $00, Branch to DONE_F2_CLEAR_PRINT
    rts

F2_PROMPT_MESSAGE:

    .ascii 	'        <F2> TO UPDATE LED2 PERIOD'
    .byte  	$00
	rts               

DONE_F2_CLEAR_PRINT:
	
    ldy	   pattern2Ticks                  ; Load Accumulator Y with pattern2Ticks
	cpy	   #$0000                         ; Compare Y with $0000
	lbne   DONE_F2_CLEAR_PRINT_TICKS	  ; If Y = $0000, Branch to DONE_F2_CLEAR_PRINT_TICKS					
	clr	   enterFlag                      ; Set enterFlag to TRUE
	clr	   clearFlag                      ; Set clearFlag to TRUE
	movb   #$00, F2Flag                   ; Set F2Flag to FALSE
	movb   #$04, displayState             ; Return to Display State 4
    movb   #$01, firstChar                ; Set firstchart to TRUE
	movb   #$01, cursorMoveFlag           ; Set cursorMoveFlag to TRUE
	jsr	   CLEAR_BUFFER                   ; Jump to Subroutine to CLEAR_BUFFER
	movw   #buffer, pointer               ; Move buffer Address Into Pointer
	rts

DONE_F2_CLEAR_PRINT_TICKS:

	clr	   enterFlag                      ; Set enterFlag to FALSE
	clr	   clearFlag                      ; Set clearFlag to FALSE
	movb   #$01, F2Flag                   ; Set F2Flag to TRUE
	movb   #$04, displayState             ; Return to Display State 4
	movb   #$01, firstChar                ; Set firstChar to TRUE
	movb   #$01, fromPreviousPrint        ; Set fromPreviousPrint to TRUE
	jsr	   CLEAR_BUFFER                   ; Jump to Subroutine CLEAR_BUFFER
	movw   #buffer, pointer               ; Move buffer Address Into Pointer
	rts
	   
ERROR_CLEAR_PRINT:

	movb   #$00, mmState                  ; Reinitialize Mastermind
	rts	   
   
;======================== Display State 6 - Backspace   ============================

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
	rts
		
;======================== Display State 7 - No Digits Entered Print ============

displaystate7:

	tst	   F1Flag                         ; Test F1Flag
	bne	   F1_NO_DIGITS                   ; If F1Flag TRUE, Branch to F1_NO_DIGITS
	tst	   F2Flag                         ; Test F2Flag
	bne	   F2_NO_DIGITS                   ; IF F2Flag TRUE, Branch to F2_NO_DIGITS
	movb   #$01, displayState             ; Return to Display State 1
	rts
	   
F1_NO_DIGITS:	
   
    ldaa   #$07                           ; Load Accumulator A with LCD Address $07
    ldx    #NO_DIGITS_PRINT               ; Load Index Register X with Address of NO_DIGITS_PRINT
    jsr    DISPLAY_CHAR   	              ; Jump to Subroutine DISPLAY_CHAR
    ldx    displayPointer                 ; Load X with displayPointer
    ldab   0,x                            ; Load B with the Contents in X
    lbeq   DONE_NO_DIGITS_PRINT           ; If B=$00, Branch to DONE_NO_DIGITS_PRINT
    rts
	   
F2_NO_DIGITS:	
   
    ldaa   #$47                           ; Load Accumulator A with LCD Address $47    
    ldx    #NO_DIGITS_PRINT               ; Load X with Address Of NO_DIGITS_PRINT      
    jsr    DISPLAY_CHAR   	              ; Jump to Subroutine DISPLAY_CHAR
    ldx    displayPointer                 ; Load X with displayPointer
    ldab   0,x                            ; Load B with the Contents in X
    lbeq   DONE_NO_DIGITS_PRINT           ; If the B=$00, Branch to DONE_NO_DIGITS_PRINT
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
	   
;======================== Display State 8 - All Zeros Entered Print ============

displaystate8:

	tst	  F1Flag                          ; Test F1Flag	
	bne	  F1_ALL_ZEROS					  ; If F1Flag TRUE, Branch to F1_ALL_ZEROS
	tst	  F2Flag                          ; Test F2FLAG
	bne   F2_ALL_ZEROS                    ; If F2Flag TRUE, Branch to F2_ALL_ZEROS
	movb  #$01, displayState              ; Return to Display State 1
	rts
	   
F1_ALL_ZEROS:
	   
    ldaa  #$07                            ; Load Accumulator A with LCD Address $07  
    ldx   #ZERO_DIGITS_PRINT              ; Load X with Address of ZERO_DIGITS_PRINT
    jsr   DISPLAY_CHAR   	              ; Jump to subroutine DISPLAY_CHAR
    ldx   displayPointer                  ; Load X with displayPointer
    ldab  0,x                             ; Load B with the Contents of X
    lbeq  DONE_ZERO_DIGITS_PRINT          ; If B=$00, Branch to DONE_ZERO_DIGITS_PRINT
    rts
	   
F2_ALL_ZEROS:
	    
    ldaa   #$47                           ; Load Accumulator A with LCD Address $47   
    ldx    #ZERO_DIGITS_PRINT             ; Load X with Address of ZERO_DIGITS_PRINT
    jsr    DISPLAY_CHAR   	              ; Jump to subroutine DISPLAY_CHAR
    ldx    displayPointer                 ; Load X with displayPointer
    ldab   0,x                            ; Load B with the Contents of X
    lbeq   DONE_ZERO_DIGITS_PRINT         ; If B=$00, Branch to DONE_ZERO_DIGITS_PRINT
    rts

ZERO_DIGITS_PRINT:

    .ascii 	'ZERO MAGNITUDE INVALID!          '
    .byte  	$00
	rts               

DONE_ZERO_DIGITS_PRINT:
				
	clr	   zeroTicksPrint                 ; Clear zeroTicksPrint
	movb   #$01, errorDelayFlag           ; Set errorDelayFlag to TRUE
	movb   #$01, displayState             ; Return to Display State 1
	rts
			
;======================== Display State 9 - Value Too Big Print    ====================

displaystate9:

	tst	   F1Flag                         ; Test F1Flag
	lbne   F1_TOO_BIG                     ; If F1FLAG TRUE, Branch to F1_TOO_BIG
	tst	   F2Flag                         ; Test F2Flag
	lbne   F2_TOO_BIG                     ; If F2FLAG TRUE, Branch to F2_TOO_BIG
	movb   #$01, displayState
	rts
	   
F1_TOO_BIG:
	   
    ldaa   #$07                           ; Load A with LCD Address $07
    ldx    #TOO_BIG_PRINT                 ; Load X with TOO_BIG_PRINT Address
    jsr    DISPLAY_CHAR   	              ; Jump to Subroutine DISPLAY
    ldx    displayPointer                 ; Load X with displayPointer
    ldab   0,x                            ; Load B with the Contents of X
    lbeq   DONE_TOO_BIG_PRINT             ; If B=$00, Branch to DONE_TOO_BIG_PRINT
    rts
	   
F2_TOO_BIG:
	   
    ldaa   #$47                           ; Load A with LCD Address $47
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
      
;=========  LED Pattern 1 - Sub-Rountine  =====================

LED_PATTERN_1: 
            
    ldaa   pattern1State                  ; get current pattern1State and branch accordingly
    beq    pattern1state0              
    deca
    beq    pattern1state1                 ; G, not R
    deca
    beq    pattern1state2                 ; not G, not R
    deca
    lbeq   pattern1state3                 ; not G, R
    deca
    lbeq   pattern1state4                 ; not G, not R
    deca
    lbeq   pattern1state5                 ; G, R
    deca
    lbeq   pattern1state6                 ; not G, not R
    deca
    lbeq   pattern1state7
    rts                                   ; Undefined state - Do Nothing but Return
                         
;======================== LED Pattern 1 State 0 - Initializing Ports    ====================
         
pattern1state0: 
                        
    bclr   PORTS, LED_MSK_1               ; Not G, Not R
    bset   DDRS, LED_MSK_1                ; Set Specified Pins in LED_MSK1 as Outputs in Port S
    movb   #$01, pattern1State        
    rts
                       
;======================== LED Pattern 1 State 1 - Green On and Red Off    ====================
                           
pattern1state1:					        
                        
    tst    F1Flag                         ; Test F1Flag 
    beq    PATTERN_1_1                    ; If F1Flag TRUE, Branch to PATTERN_1_1
    movb   #$07, pattern1State            ; Return to LED Pattern 1 Reset State
    rts  
                      
PATTERN_1_1: 
            
    bset   PORTS, G_LED_1                 ; G, Not R
    tst    pattern1Done                   ; Test pattern1Done
    lbeq   EXIT_P1                        ; If pattern1Done FALSE, Branch to EXIT_P1
    movb   #$02, pattern1State            ; Return to Pattern_1 State 2
    rts
                          
;======================== LED Pattern 1 State 2 - Green Off and Red Off ====================
        
pattern1state2: 				         
                                    		  
    tst    F1Flag                         ; Test F1Flag
    beq    PATTERN_1_2                    ; If F1Flag FALSE, Branch to PATTERN_1_2
    movb   #$07, pattern1State            ; Return to Pattern_1 State 7
    rts  
                     
PATTERN_1_2:
            
    bclr   PORTS, G_LED_1                 ; Not G
    tst    pattern1Done                   ; Test pattern1Done   
    lbeq   EXIT_P1                        ; If pattern1Done FALSE, Branch to EXIT_P1
    movb   #$03, pattern1State            ; Return to Pattern_1 State 3
    rts
                                          
;======================== LED Pattern 1 State 3 - Green Off and Red On ====================
                  
pattern1state3:                         
                              
    tst    F1Flag                         ; Test F1Flag
    beq    PATTERN_1_3                    ; If F1Flag FALSE, Branch to PATTERN_1_3
    movb   #$07, pattern1State            ; Return to Pattern_1 State 7
    rts  
                      
PATTERN_1_3:
            
    bset   PORTS, R_LED_1                 ; R, NOT G
    tst    pattern1Done                   ; Test pattern1Done
    beq    EXIT_P1                        ; If pattern1Done FALSE, Branch to EXIT_P1
    movb   #$04, pattern1State            ; Return to Pattern_1 State 4
    rts
                                    
;======================== LED Pattern 1 State 4 - Green Off and Red Off ====================
                        
pattern1state4:  
                                         
    tst    F1Flag                         ; Test F1Flag
    beq    PATTERN_1_4                    ; If F1Flag FALSE, Branch to PATTERN_1_4
    movb   #$07, pattern1State            ; Return to Pattern_1 State 7
    rts  
                      
PATTERN_1_4:
            
    bclr   PORTS, LED_MSK_1               ; NOT G , NOT R
    tst    pattern1Done                   ; Test pattern1Done
    beq    EXIT_P1                        ; If pattern1Done FAlSE, Branch to EXIT_P1
    movb   #$05, pattern1State            ; Return to Pattern_1 State 5
    rts
            
;======================== LED Pattern 1 State 5 - Green On and Red On ====================
        
pattern1state5:  
                                 
    tst    F1Flag                         ; Test F1Flag   
    lbeq   PATTERN_1_5                    ; If F1Flag FALSE, Branch to PATTERN_1_5
    movb   #$07, pattern1State            ; Return to Pattern_1 State 7
    rts   
                    
PATTERN_1_5:
         
    bset   PORTS, LED_MSK_1               ; G, R
    tst    pattern1Done                   ; Test pattern1Done
    beq    EXIT_P1                        ; If pattern1Done FAlSE, Branch to EXIT_P
    movb   #$06, pattern1State            ; Return to Pattern_1 State 6
    rts
                                            
;======================== LED Pattern 1 State 6 - Green Off and Red Off ====================
                    
pattern1state6:     

    tst    F1Flag                         ; Test F1Flag 
    beq    PATTERN_1_6                    ; If F1Flag FALSE, Branch to PATTERN_1_6
    movb   #$07, pattern1State            ; Return to Pattern_1 State 7
    rts  
                            
PATTERN_1_6:
           
    bclr   PORTS, LED_MSK_1               ; NOT G, NOT R
    tst    pattern1Done                   ; Test pattern1Done
    beq    EXIT_P1                        ; If pattern1Done FAlSE, Branch to EXIT_P
    movb   #$01, pattern1State            ; Return to Pattern_1 State 1
    rts
                          
;======================== LED Pattern 1 State 7- LED Pattern 1 Reset ====================
            
pattern1state7:
           
    bclr   PORTS, LED_MSK_1               ; set not green not red
    clr    pattern1Done                   ; Set pattern1Done to FALSE
    tst    F1Flag                         ; Test F1Flag
    beq    RESET_P1                       ; If F1Flag FALSE, Branch to RESET_P1
    rts
                     
;======================== LED Pattern 1 - Miscellaneous Sub-Rountines / Branches ====================
			  
RESET_P1:
            
    movb   #$01, pattern1State            ; Return to Pattern_1 State 1             
    rts
      
EXIT_P1:        
            
    rts
                          
;======================== LED Timing 1 - Sub-Rountine ====================
          
LED_TIMING_1: 
           
    ldaa   timing1State                   ; get current t5state and branch accordingly
    beq    timing1state0                  ; Initialization
    deca
    beq    timing1state1                  ; Re-Intialization of Count
    deca
    beq    timing1state2                  ; Decrement Count & Run Loop
    rts                                   ; undefined state - do nothing but return
                 
;======================== LED Timing 1 State 1 - Intialization ====================
         
timing1state0:                            ; initialization for TASK_5
         
    clr    pattern1Done
    ldy    pattern1Ticks
    cpy    #$0000
    lbne   PATTERN_1_TICKS_ENT
    movb   #$00, timing1State            ; set next state
    rts
                           
;======================== LED Timing 1 State 2 - Re-Intialization of Count ====================
           
timing1state1:                            ; (re)initialize COUNT_1
        
    movw   pattern1Ticks, pattern1Counter; Move pattern1Ticks to pattern1Counter
    ldx    pattern1Counter 
    dex                                   ; decrement COUNT_1
    stx    pattern1Counter                ; store decremented COUNT_1
    clr    pattern1Done
    movb   #$02, timing1State             ; set next state
    rts
                                         
;======================== LED Timing 1 State 2 - Decrement Count & Run Loop ====================
                                     
timing1state2:
              ; count down COUNT_1
    ldx    pattern1Counter
    beq    SET_DONE_1                     ; test to see if COUNT_1 is already zero
    dex                                   ; decrement COUNT_1
    stx    pattern1Counter                ; store decremented COUNT_1
    bne    EXIT_TIMING_1                  ; if not done, return
    rts
                        
;======================== LED Timing 1 - Miscellaneous Sub-Rountines / Branches ====================
                  
PATTERN_1_TICKS_ENT:
            
    movb   #$01, timing1State
    rts
            
SET_DONE_1:
           
    movb   #$01, pattern1Done             ; if done, set DONE_1 flag
    movb   #$01, timing1State             ; set next state
    rts
                           
EXIT_TIMING_1:
              
    rts
            
                      
;=========  LED Pattern 2 - Sub-Rountine  =====================
            
LED_PATTERN_2: 
           
    ldaa   pattern2State                  ; Get current pattern2State and branch accordingly
    beq    pattern2state0                 ; If Accumulator A = $00, Branch to pattern2state0
    deca                                 
    beq    pattern2state1                 ; G, not R
    deca                                
    beq    pattern2state2                 ; not G, not R
    deca                                 
    lbeq   pattern2state3                 ; not G, R
    deca                                 
    lbeq   pattern2state4                 ; not G, not R
    deca                                 
    lbeq   pattern2state5                 ; G, R
    deca                                 
    lbeq   pattern2state6                 ; not G, not R
    deca                               
    lbeq   pattern2state7                 ; If Accumulator A = $00, Branch to pattern2state7
    rts                                   ; Undefined state - Do Nothing but Return
            
        
;======================== LED Pattern 2 State 0 - Initializing Ports    ====================
    
pattern2state0:  
                       
    bclr   PORTS, LED_MSK_2               ; NOT G, NOT R 
    bset   DDRS, LED_MSK_2                ; Set Pins Addressed in LED_MSK_2 as Outputs in Port S
    movb   #$01, pattern2State            ; Return to Pattern_2 State 1
    rts
            
;======================== LED Pattern 2 State 1 - Green On and Red Off    ====================
                            
pattern2state1:					
                       
    tst    F2Flag                         ; Test F2Flag
    beq    PATTERN_2_1                    ; If F2Flag FALSE, Branch to PATTERN_2_1
    movb   #$07, pattern2State            ; Return to Pattern_2 State 7
    rts  
                      
PATTERN_2_1:
            
    bset   PORTS, G_LED_2                 ; NOT R, G
    tst    pattern2Done                   ; Test pattern2Done
    lbeq   EXIT_P2                        ; If pattern2Done FALSE, Branch to EXIT_P2
    movb   #$02, pattern2State            ; Return to Pattern_2 State 2
    rts
           
                     
;======================== LED Pattern 2 State 2 - Green Off and Red Off ====================
            
pattern2state2: 				  
                                    		  
    tst    F2Flag                         ; Test F2Flag
    beq    PATTERN_2_2                    ; If F2Flag FALSE, Branch to PATTERN_2_2
    movb   #$07, pattern2State            ; Return to Pattern_2 State 7
    rts  
                      
PATTERN_2_2:
            
    bclr   PORTS, G_LED_2                 ; NOT G, 
    tst    pattern2Done                   ; Test pattern2Done     
    lbeq   EXIT_P2                        ; If pattern2Done FALSE, Branch to EXIT_P2
    movb   #$03, pattern2State            ; Return to Pattern_2 State 3
    rts
                      
;======================== LED Pattern 2 State 3 - Green Off and Red On ====================
                         
pattern2state3: 
                              
    tst    F2Flag                         ; Test F2Flag
    beq    PATTERN_2_3                    ; If F2Flag FALSE, Branch to PATTERN_2_3
    movb   #$07, pattern2State            ; Return to Pattern_2 State 7
    rts  
                     
    PATTERN_2_3:
           
    bset   PORTS, R_LED_2                 ; NOT G, R
    tst    pattern2Done                   ; Test pattern2Done 
    beq    EXIT_P2                        ; If pattern2Done FALSE, Branch to EXIT_P2
    movb   #$04, pattern2State            ; Return to Pattern_2 State 4
    rts
                            
;======================== LED Pattern 2 State 4 - Green Off and Red Off ====================
                                
pattern2state4:  
                            
    tst    F2Flag                         ; Test F2Flag
    beq    PATTERN_2_4                    ; If F2Flag FALSE, Branch to PATTERN_2_4
    movb   #$07, pattern2State            ; Return to Pattern_2 State 7
    rts  
                      
PATTERN_2_4:
           
    bclr   PORTS, LED_MSK_2               ; NOT G,  NOT R   
    tst    pattern2Done                   ; Test pattern2Done       
    beq    EXIT_P2                        ; If pattern2Done FALSE, Branch to EXIT_P2
    movb   #$05, pattern2State            ; Return to Pattern_2 State 4
    rts
                    
;======================== LED Pattern 2 State 5 - Green On and Red On ====================
            
pattern2state5:  
                                  
    tst    F2Flag                         ; Test F2Flag
    lbeq   PATTERN_2_5                    ; If F2Flag FALSE, Branch to PATTERN_2_5
    movb   #$07, pattern2State            ; Return to Pattern_2 State 7
    rts  
                    
PATTERN_2_5:
          
    bset   PORTS, LED_MSK_2               ; G, R
    tst    pattern2Done                   ; Test pattern2Done      
    beq    EXIT_P2                        ; If pattern2Done FALSE, Branch to EXIT_P2
    movb   #$06, pattern2State            ; Return to Pattern_2 State 6
    rts
                      
;======================== LED Pattern 2 State 6 - Green Off and Red Off ====================
                     
pattern2state6:     
                               
    tst    F2Flag                         ; Test F2Flag
    beq    PATTERN_2_6                    ; If F2Flag FALSE, Branch to PATTERN_2_6
    movb   #$07, pattern2State            ; Return to Pattern_2 State 7
    rts  
                           
PATTERN_2_6:
           
    bclr   PORTS, LED_MSK_2               ; NOT G, NOT R
    tst    pattern2Done                   ; Test pattern2Done 
    beq    EXIT_P2                        ; If pattern2Done FALSE, Branch to EXIT_P2
    movb   #$01, pattern2State            ; Return to Pattern_2 State 1     
    rts
                            
;======================== LED Pattern 1 State 7- LED Pattern 1 Reset ====================
                  
pattern2state7:
           
    bclr   PORTS, LED_MSK_2               ; NOT Red, NOT Green
    clr    pattern2Done                   ; Set pattern2Done to FALSE
    tst    F2Flag                         ; Test F2Flag
    beq    RESET_P2                       ; If F2Flag FALSE, Branch to RESET_P2
    rts
                           
;======================== LED Pattern 1 - Miscellaneous Sub-Rountines / Branches ====================
           
RESET_P2:
         
    movb   #$01, pattern2State            ; Return to Pattern_2 State 1           
    rts
           
EXIT_P2:        
            
    rts
            
;======================== LED Timing 2 - Sub-Rountine ====================
            
LED_TIMING_2: 
           
    ldaa   timing2State                   ; get current t5state and branch accordingly
    beq    timing2state0                  ; Initialization
    deca
    beq    timing2state1                  ; Re-Intialization of Count
    deca
    beq    timing2state2                  ; Decrement Count & Run Loop
    rts                                   ; undefined state - do nothing but return
               
;======================== LED Timing 2 State 1 - Intialization ====================
                        
timing2state0: 

    clr    pattern2Done                   ; Clear pattern2Done 
    ldy    pattern2Ticks                  ; Load Index Register Y with pattern1Ticks
    cpy    #$0000                         ; Compare Y with $0000
    lbne   PATTERN_2_TICKS_ENT            ; IF Y not = $0000, Branch to PATTERN_2_TICKS_ENT
    movb   #$00, timing2State             ; Return to Timing 2 State 0
    rts
                                            
 ;======================== LED Timing 2 State 2 - Re-Intialization of Count ====================
             
timing2state1: 
                       
    movw   pattern2Ticks, pattern2Counter ; Move pattern2Ticks into pattern2Counter 
    ldx    pattern2Counter                ; Decrement pattern2Counter
    dex                                   ; decrement COUNT_1
    stx    pattern2Counter                ; store decremented COUNT_1
    clr    pattern2Done                   ; Clear pattern2Counter
    movb   #$02, timing2State             ; set next state
    rts
                                                
;======================== LED Timing 1 State 2 - Decrement Count & Run Loop ====================
                                                 
timing2state2:
           			                     
    ldx    pattern2Counter
    beq    SET_DONE_2                     ; test to see if COUNT_1 is already zero
    dex                                   ; decrement COUNT_1
    stx    pattern2Counter                ; store decremented COUNT_1
    bne    EXIT_TIMING_2                  ; if not done, return
    rts
                     
;======================== LED Timing 2 - Miscellaneous Sub-Rountines / Branches ====================
                            
PATTERN_2_TICKS_ENT:
            
    movb   #$01, timing2State             ; Return to LED Timing State 1
    rts     
                           
SET_DONE_2:
           
    movb   #$01, pattern2Done             ; Set Pattern2Done to TRUE
    movb   #$01, timing2State             ; Return to Timing 2 State 1
                            
EXIT_TIMING_2:

    rts
	       
;============================  Delay Sub-Routine   =================================
          
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

;=====================================================================================
.area interrupt_vectors (abs)
.org    $FFFE                             ; At reset vector location
.word   __start                           ; Load starting address