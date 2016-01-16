; Robert Cory Molloy & Oscar Andrade
; ME 305 - 02 :: Intro to Mechatronics
; Labratory 5 :: Motor Controller 

;==================== Assembler Equates ====================

ENCODER		       = $0280				 ; Encoder Address 
SIX_VOLTS          = $099A               ; Voltage Offset to be Added to A
PORTJ              = $0028               ; Port J Address
DDRJ	   		   = $0029               ; Make Port J an Output Address
pin5           	   = 0b00010000          ; Pin 5 of Port J
TIOS               = $0080               ; Timer Output Compare Address
TFLG1              = $008E               ; Timer Flag Register Address
TSCR               = $0086               ; Timer System Control Register Address
TC0H               = $0090               ; Timer Channel Zero High Address
TCNT               = $0084               ; Timer Count Register High and Low Address
TMSK1              = $008C               ; Timer Mask Address
TCTL2              = $0089               ; Timer Control Register Address
DACA_MSB		   = $0303               ; Most Significant Bit of DAC B
DACA_LSB		   = $0302               ; Least Significant Bit of DAC B
VREF_BUF		   = $BB2
VACT_BUF		   = $BB6
ERROR_BUF		   = $BBA
EFFORT_BUF		   = $BBE
KI_BUF		   	   = $BC2
KP_BUF		   	   = $BC7

;==================== RAM area ====================
.area bss

; Task Variables

mmState::			.blkb 1		         ; Master Mind State Variable
kpdState::			.blkb 1    	         ; Key Pad Driver State Variable
displayState::		.blkb 1   	         ; Display State Variable
backspaceState::	.blkb 1		         ; Backspace State Variable
variableState::		.blkb 1
tc0State::			.blkb 1

; ISR Variables

V_Ref::             .blkb 2              ; Voltage Reference Inputted By User [BDI/BTI]
V_Act::             .blkb 2              ; Actual Voltage at Encoder
New_Error::         .blkb 2              ; V_Ref - V_act
Old_Error::         .blkb 2              ; Previous Calculated Error
E_Sum::             .blkb 2              ; Integral
KiplusKp::          .blkb 2              ; (Kp*Error)+(Ki/s*Esum)
A_Prime::           .blkb 2              ; [A + 2458]
A_Star::            .blkb 2              ; Dac Value 
Ki::                .blkb 2              ; Integral Control
Kp::                .blkb 2              ; Proportional Control
Kpdivs::            .blkb 2              ; Kp*e, After Edivs
Kidivs::            .blkb 2              ; Ki*esum, after Edivs
Dac_Value::         .blkb 2              ; Voltage Value to be Fed to DAC
Theta_New::         .blkb 2              ; New Displacment Interval Read From Encoder
Theta_Old::         .blkb 2              ; Previous Displacement Interval Read From Encoder
Effort::			.blkb 2

;==================== Storing Variables ====================

keyStore::		.blkb 1		; Stores Most Recent Digit Pressed
buffer::			.blkb 6		; Stores All Digits for Processing to Ticks
result::			.blkb 1		; Stores converted ASCII numbers
updateBuffer::		.blkb 6
updatePointer::		.blkb 2
updateResult::		.blkb 2
updateCounter::		.blkb 1

;==================== Counter Variables ====================

digitCounter::		.blkb 1		; Counts Up Current Digits Input into buffer
digitCountOut::		.blkb 1
LCDUpdateCount::	.blkb 1

;==================== Flags ====================

RUN::		        .blkb 1
OpenLoop::		    .blkb 1
NegErrorFlag::      .blkb 1              ; Notifies The Program That New_Error is Negative
NegESumFlag::       .blkb 1              ; Notifies the Progream That E_Sum is Negative
KpNegSatFlag::      .blkb 1              ; Notifies The Program that Kp
KpPosSatFlag::      .blkb 1              ; Notifies The Program that Kp
NegVactSign::       .blkb 1
KiFlag::			.blkb 1
KpFlag::			.blkb 1
LCDFlag::			.blkb 1
L2UpdateFlag::		.blkb 1
VRefNeg::			.blkb 1
VRefPos::			.blkb 1
LCDUpdateFlag::		.blkb 1
stateVariableFlag::	.blkb 1
keyFlag::			.blkb 1		; Notify Program a Key Has Been Pressed
echoFlag::			.blkb 1		; Notify Program that a Key Needs to Be Echoed
enterFlag::			.blkb 1		; Notify Program that Enter Procedure is Done
firstChar::			.blkb 1		; Notify Program the First Character is Ready
backspaceFlag::		.blkb 1		; Notify Program that a Entered Digit Needs to Be Cleared
mmWaitFlag::		.blkb 1		; Notify Program that Mastermind Can Move to Next State
loopFlag::			.blkb 1
VRefFlag::			.blkb 1
displayVRefNeg::	.blkb 1
digitFlag::			.blkb 1
autoManualFlag::	.blkb 1
displayVRefPos::	.blkb 1
backspacePrint::	.blkb 1
updateFlag::		.blkb 1	
updateValuesFlag::	.blkb 1
effortFlag::		.blkb 1
errorFlag::		    .blkb 1
VActFlag::			.blkb 1
VRefPromptFlag::	.blkb 1	
KiPromptFlag::      .blkb 1
KpPromptFlag::        .blkb 1

; Other Variables

pointer::		    .blkb 2     ; Holds the Address of buffer
pointerOut::		.blkb 2		
displayPointer::	.blkb 2     ; Holds ASCII numbers pressed on keypad
VRefSign::			.blkb 1
VActSign::			.blkb 1
effortSign::		.blkb 1
errorSign::		.blkb 1	

;==================== Flash ====================
.area text

;==================================  Main Program  =============================

_main::
 
	jsr    	INIT        		         ; Initialization
 
TOP: 
 
 
	jsr    	MASTERMIND			     ; Mastermind Sub-Routines
 
	jsr    	KPD		  			     ; Key Pad Driver Sub-Routines
 
	jsr    	DISPLAY      		     ; Display Sub-Routines
 
	jsr	TIMER_C0                 ; Timer Channel Zero Sub-Routines

	bra		    TOP
	
;================================  Initialization  =============================	
	
INIT:

	clr		mmState				; Initialize All Sub-Routine State Variables to State 0
	clr	  	kpdState            ; Clear Keypad Driver States Variable
	clr		displayState        ; Clear Displaysate State Variable
	clr		backspaceState      ; Clear Backspace State Variable
	rts	
	
;========================== Mastermind Sub-Routine =============================

MASTERMIND:

	ldaa	mmState				         ; Grabbing the current state of Mastermind & Branching
	lbeq	mmstate0			         ; Initialization of Mastermind & Buffer 
	deca
	lbeq	mmstate1			         ; Splash Screen and Setting Displays Flags
	deca
	lbeq	mmstate2			         ; Mastermind Hub
	deca
	;lbeq	mmstate3			         ; Backspace State
	deca
	;lbeq	mmstate4			         ; Enter State
	deca
	;lbeq	mmstate5			         ; Digit State
	deca
	lbeq	mmstate6			         ; Update Values
	rts							         ; Return to Main 

;=========== Mastermind State 0 - Initialization of Mastermind & Buffer ========

mmstate0:	
					
	movw    #buffer, pointer 		   			 ; Stores the first address of buffer into pointer
	movw    #updateBuffer, updatePointer 		 ; Stores the first address of buffer into pointer
	clr		buffer					    		 ; Clear the buffer Variable
	clr		updateBuffer						 ; Clear the buffer Variable
	movb  	#$00, RUN           				 ; Motor stop at intialization
    movw   	#$0001, V_Ref       				 ; Initial VREF value $19=25
    movw   	#$0400, Ki           				 ; Initial KP value $400=1024=1024(1)
    movw   	#$1400, Kp          				 ; Initial KP value $1400=5120=1024(5)
	movb	#$00, LCDUpdateCount
	jsr		CLEAR_TEMPLATE
	movb	#$01, updateValuesFlag				 ;
	movb	#$01, mmState	   					 ; Set the Mastermind State Variable to 1    
	rts

;====  Mastermind State 1 - Splash Screen and Setting Displays Flags & Counters  =========

mmstate1:

	movb   #$01, firstChar     	     	; Set firstChar flag to 1 (True) 
    movb   #$01, VRefFlag      			
	movb   #$01, KiFlag      			
	movb   #$01, KpFlag      			
	movb   #$01, VActFlag      			
	movb   #$01, errorFlag
	movb   #$01, effortFlag
	movb   #$02, mmState			    ; Set the Mastermind State Variable to 2 (Hub)
	rts								    ; Return to Main

;===============  Mastermind State 2 - Hub  ============================

mmstate2:

	tst	   	updateValuesFlag
	lbne	UPDATE_VALUES
	tst 	keyFlag                      ; Test keyFlag
	lbeq	NO_KEY                       ; If keyFlag is False, Branch to NO_KEY
	clr 	keyFlag                      ; Clear keyFlag
	cmpb 	#$F1                         ; Compare Acc. B to Hex Value of 'F1'
	lbeq 	F1_TRUE                      ; If B = '$F1', Branch to F1_TRUE
	cmpb 	#$F2                         ; Compare Acc. B to Hex Value of 'F2'
	lbeq	F2_TRUE                      ; If B = '$F2', Branch to F2_TRUE
	cmpb 	#$08                         ; Compare Acc. B to Hex Value of '08'
	lbeq 	BS_TRUE                      ; If B = '$08', Branch to BS_TRUE
	cmpb 	#$41                         ; Compare Acc. B to Hex Value of 'F1'
	lbeq	A_TRUE
	cmpb 	#$0A                         ; Compare Acc. B to Hex Value of '0A'
	lbeq 	ENT_TRUE                     ; If B = '$0A', Branch to ENT_TRUE
	lbra	DIGIT_TRUE                   ; Otherwise Branch to DIGIT_TRUE

NO_KEY:
	
	tst		backspaceFlag                ; Test backspaceFlag
	bne		BACKSPACE_GO                 ; If backspaceFlag Not $00, Branch to BACKSPACE_GO
	tst		enterFlag                    ; Test enterFlag
	bne		ENTER_GO                     ; If enterFlag Not $00, Branch to ENTER_GO
	tst		digitFlag                    ; Test digitFlag
	bne		DIGIT_GO                     ; If digitFlag Not $00, Branch to DIGIT_GO
	movb 	#$02, mmState                ; If No Key was Pressed, Return to Hub
	rts
	
F1_TRUE:
	
	tst		VRefFlag
	beq		F1_DONE
	movb	#$01, VRefPos
	movb	#$01, displayVRefPos
	movb 	#$02, mmState                ; Set next Mastermind State (mmstate) to Hub
	rts	

F1_DONE:
	
	movb 	#$02, mmState                ; Set next Mastermind State (mmstate) to Hub
	rts	
		
F2_TRUE:

	tst		VRefFlag
	beq		F2_DONE
	movb	#$01, VRefNeg
	movb	#$01, displayVRefNeg
	movb 	#$02, mmState                ; Set next Mastermind State (mmstate) to Hub 
	rts

F2_DONE:
	
	movb 	#$02, mmState                ; Set next Mastermind State (mmstate) to Hub
	rts	

BS_TRUE:
	
	movb 	#$01, backspaceFlag          ; Set next Mastermind State (mmstate) to Backspace
	rts
	
ENT_TRUE:
	
	movb 	#$01, enterFlag              ; Set next Mastermind State (mmstate) to Enter
	rts

DIGIT_TRUE:

	movb 	#$01, digitFlag              ; Set next Mastermind State (mmstate) to Digit
	rts

A_TRUE:

	movb	#$01, RUN
	movb	#$02, mmState
	rts
	
BACKSPACE_GO:

	movb 	#$03, mmState                ; Set next Mastermind State (mmstate) to Backspace
	rts
	
ENTER_GO:

	movb 	#$04, mmState                ; Set next Mastermind State (mmstate) to Backspace
	rts
	
DIGIT_GO:

    clr	 	digitFlag
	movb 	#$05, mmState                ; Set next Mastermind State (mmstate) to Backspace
	rts

UPDATE_VALUES:

	movb 	#$06, mmState                
	rts
	
mmstate6:

LCD_UPDATE:

	tst		VRefFlag
	bne		UPDATE_VREF
	tst 	VActFlag
	bne 	UPDATE_VACT
	tst 	errorFlag
	bne		UPDATE_ERROR
	tst 	effortFlag
	bne		UPDATE_EFFORT
	tst 	KiFlag
	bne		UPDATE_KI
	tst 	KpFlag
	bne 	UPDATE_KP
	rts

UPDATE_VREF:
	
	ldaa  	VRefSign            
	cmpa  	#$01
	beq    	NEGATIVE_VREF    
    ldd    	V_Ref
    bra    	BINARY_ASCII         

NEGATIVE_VREF:
	   
    ldd    	#$0000             
    subd   	V_Ref               
    bra    	BINARY_ASCII 

UPDATE_VACT:
	
	ldaa  	VActSign            
	cmpa  	#$01
	beq    	NEGATIVE_VACT    
    ldd    	V_Act
    bra    	BINARY_ASCII         

NEGATIVE_VACT:
	   
    ldd    	#$0000             
    subd   	V_Act               
    bra    	BINARY_ASCII

UPDATE_KI:

	ldy    #KI_BUF 
	movb   #'0',0,y    
    ldd    	Ki
    bra   	BINARY_ASCII
	
UPDATE_KP:

	ldy    #KP_BUF 
	movb   #'0',0,y    
    ldd    	Kp
    bra   	BINARY_ASCII	

UPDATE_ERROR:
	
	ldaa  	errorSign            
	cmpa  	#$01
	beq    	NEGATIVE_ERROR    
    ldd    	New_Error
    bra    	BINARY_ASCII         

NEGATIVE_ERROR:
	   
    ldd    	#$0000             
    subd   	New_Error               
    bra    	BINARY_ASCII
	
UPDATE_EFFORT:
	
	ldaa  	effortSign            
	cmpa  	#$01
	beq    	NEGATIVE_EFFORT   
    ldd    	Effort
    bra    	BINARY_ASCII         

NEGATIVE_EFFORT:
	   
    ldd    	#$0000             
    subd   	Effort               
    bra    	BINARY_ASCII
	
BINARY_ASCII:
	  
	movw   	#updateBuffer, updatePointer 	
	movb	#$00, digitCounter
	   
BINARY_ASCII_LOOP:

    ldx    	#$000A              
    ldy    	#$0000              
    edivs                      
    sty   	updateResult              
    addb   	#$30                
    clra                       
    ldx    	updatePointer            
    stab   	0,x                 
    inc    	updateCounter       
    cpy    	#$0000             
    lbeq   	SIGN_CHECK          
    inx                       
    stx    	updatePointer         
	ldd    	updateResult      
	bra    	BINARY_ASCII_LOOP  

SIGN_CHECK:


	tst VRefFlag
	bne	VREF_SIGN_CHECK
	tst VActFlag
	bne VACT_SIGN_CHECK
	tst errorFlag
	bne	ERROR_SIGN_CHECK
	tst effortFlag
	bne	EFFORT_SIGN_CHECK
	bra	KI_KP_CHECK
				  
VREF_SIGN_CHECK:
     
	   movb	  #$00, VRefFlag
	   ldx	  #updateBuffer
       ldy    #VREF_BUF         
       ldaa   VRefSign           
	   cmpa   #$01
	   bne    POS_SIGN
	   bra	  NEG_SIGN                                      	   

VACT_SIGN_CHECK:
     
	   movb	  #$00, VActFlag
	   ldx	  #updateBuffer
       ldy    #VACT_BUF         
       ldaa   VActSign           
	   cmpa   #$01
	   bne    POS_SIGN
	   bra	  NEG_SIGN                                      
	   
ERROR_SIGN_CHECK:
     
	   movb	  #$00, errorFlag
	   ldx	  #updateBuffer
       ldy    #ERROR_BUF         
       ldaa   errorSign           
	   cmpa   #$01
	   bne    POS_SIGN
	   bra	  NEG_SIGN                                                    		   

EFFORT_SIGN_CHECK:
     
	   movb	  #$00, effortFlag
	   ldx	  #updateBuffer
       ldy    #EFFORT_BUF         
       ldaa   effortSign           
	   cmpa   #$01
	   bne    POS_SIGN
	   bra	  NEG_SIGN	   
	   
POS_SIGN:

	   movb	  #'+',0,y
	   bra    UPDATE_OUT
	   
NEG_SIGN:   
	   	  
	   movb   #'-',0,Y              
	   bra    UPDATE_OUT

KI_KP_CHECK:

	tst	KiFlag
	bne	KI_CHECK
	tst	KpFlag
	bne KP_CHECK
	movb #$02, mmState
	rts

KI_CHECK:

	   movb	  #$00, KiFlag
	   ldx	  #updateBuffer
       ldy    #KI_BUF                      
	   bra    UPDATE_OUT

KP_CHECK:

	   movb	  #$00, KpFlag
	   ldx	  #updateBuffer
       ldy    #KP_BUF                      
	   bra    UPDATE_OUT 
				   	   
UPDATE_OUT:

       dec    updateCounter
       beq    ONE_DIGIT           ; If one digit, branch
       dec    updateCounter
       beq    TWO_DIGITS	      ; If two digits, branch   
       dec    updateCounter
       beq    THREE_DIGITS        ; If three digits, branch	
       dec    updateCounter
       beq    FOUR_DIGITS         ; If four digits, branch		   	   
       dec    updateCounter
       beq    FIVE_DIGITS	      ; If five digits, branch
	   rts
    
ONE_DIGIT:                        
       movb   0,x,3,y
	   movb   #'0',2,y
	   movb   #'0',1,y            
       bra    UPDATE_VALUES_DONE

TWO_DIGITS:
       movb   0,x,3,y             ; Move the first digit into fourth slot
       movb   1,x,2,y             ; Move the second digit into third slot
	   movb   #'0',1,y
       bra    UPDATE_VALUES_DONE

THREE_DIGITS:
       movb   0,x,3,y             ; Move the first digit into fourth slot
       movb   1,x,2,y             ; Move the second digit into third slot
       movb   2,x,1,y             ; Move the third digit into second slot
       bra    UPDATE_VALUES_DONE

FOUR_DIGITS:
       movb   0,x,4,y             ; Move the first digit into fifth slot
       movb   1,x,3,y             ; Move the second digit into fourth slot
       movb   2,x,2,y             ; Move the third digit into third slot
       movb   3,x,1,y             ; Move the fourth digit into second slot
       bra    UPDATE_VALUES_DONE

FIVE_DIGITS:
       movb   0,x,4,y             ; Move the first digit into fifth slot
       movb   1,x,3,y             ; Move the second digit into fourth slot
       movb   2,x,2,y             ; Move the third digit into third slot
       movb   3,x,1,y             ; Move the fourth digit into second slot
       movb   4,x,0,y             ; Move the fifth digit into first slot
       bra    UPDATE_VALUES_DONE

UPDATE_VALUES_DONE:

	   jsr UPDATELCDL1
	   jsr UPDATELCDL2
	   tst VRefFlag
	   lbne LCD_UPDATE
	   tst VActFlag
	   lbne LCD_UPDATE
	   tst KiFlag
	   lbne LCD_UPDATE
	   tst KpFlag
	   lbne LCD_UPDATE
	   tst errorFlag
	   lbne LCD_UPDATE
	   movb	#$00, updateValuesFlag
	   movb #$02, mmState
	   rts
	   	
;=========  Mastermind - Miscellaneous Sub-Rountines / Branches   ==============

BUFFER_STORE:

	ldaa   digitCounter                   ; Load Accumulator A with digitCounter
	cmpa   #$03                           ; Compater Accumulator with $03
	bhi    BUFFER_STORE_LIMIT             ; If A is higher or equal than $03, Branch to BUFFER_STORE_LIMIT
	ldx    pointer                        ; Load X with pointer
	ldab   keyStore				      ; Load B with digitStore
	stab   0,x                            ; Store Contents of B into X
	inx                                   ; Increment X
	stx     pointer                       ; Store X in Pointer
	movb	#$01, echoFlag                ; Set echoFlag to TRUE
	movb	#$00, keyFlag	              ; Set keyFlag to FALSE
	movb	#$02, mmState				  ; Set next Mastermind State (mmstate) to M^2 Hub
	rts
	
BUFFER_STORE_LIMIT:

	dec	   digitCounter
	clr	   keyFlag
	clr	   echoFlag
	movb   #$02, mmState				  ; Set next Mastermind State (mmstate) to M^2 Hub
	rts	

CLEAR_TEMPLATE:

	movw	#$0000, $BB2
	movw	#$0000, $BB4
	movw	#$0000, $BB6
	movw	#$0000, $BB8
	movw	#$0000, $BBB
	movw	#$0000, $BBD
	movw	#$0000, $BBF
	movw	#$0000, $BC2
	movw	#$0000, $BC4
	movw	#$0000, $BC6
	movw	#$0000, $BC8
	movw	#$0000, $BCB
	movw	#$0000, $BCD
	rts


;=========================  Key Pad Driver Sub-Routine   =======================

KPD:

	ldaa   kpdState			             ; Load Accumulator A with kpdState
	lbeq   kpdstate0			         ; If Accumulator A =$00, Branch to kpdstate0
	deca                                 ; Decrement A
	lbeq   kpdstate1			         ; If Accumulator A =$00, Branch to kpdstate1
	rts							 

;========  Key Pad Driver State 0 - Initialization of Key Pad Driver   =========

kpdstate0: 	
			
    jsr    INITKEY                       ; Jump to Subroutine INITKEY
    jsr    FLUSH_BFR                     ; Jump to Subroutine FLUSH_BFR
    jsr    KP_ACTIVE                     ; Jump to Subroutine KP_ACTIVE
    movb   #$01, kpdState                ; Set Keypad Driver to kpdstate1
    rts

;== Key Pad Driver State 1 - Wait for the Key Press to Be Stored in Buffer   ===

kpdstate1:
       
    tst    L$KEY_FLG                     ; Check if Key has Been Pressed
	bne	   NOKEYPRESS			         ; If no Key Pressed, Branch to NOKEYPRESS
    jsr    GETCHAR                       ; If Key Has Been Pressed, get Character
	stab   keyStore                    ; Store Character from B into digitStore
	movb   #$01, keyFlag                 ; Set KeyFlag to TRUE
	movb   #$01, kpdState		         ; Set Keypad Driver to kpdstate1
	rts

NOKEYPRESS:

	movb   #$01,kpdState			     ; Set Keypad Driver to kpdstate1
	rts

	;=============================  Display Sub-Routine   ==========================

DISPLAY:

	ldaa   displayState                  ; Display to be Branched to Depending on Value
	lbeq   displaystate0                 ; Initalize LCD Screen & Cursor
	deca
	lbeq   displaystate1                 ; Display Hub
	;deca
	;lbeq   displaystate2                 ; Display Ref Velocity Prompt 
	;deca
	;lbeq   displaystate3                 ; Display Ki Prompt
	;deca
	;lbeq   displaystate4                 ; Display Kp Prompt
	;deca
	;lbeq   displaystate5                 ; Initializing & Printing Digit
	;deca
	;lbeq   displaystate6                 ; Backspace
	;deca
	;lbeq   displaystate7                 ; Backspace
    rts		

;==================== Display State 0 - Initialize LCD Screen & Cursor ===================
	
displaystate0:

	jsr	   INITLCD                       ; Initalize LCD Screen
	jsr    CLRSCREEN                     ; Clear LCD Screen
	jsr    CURSOR                        ; Show Cursor in LCD Screen
	jsr	   LCDTEMPLATE					 ;		      
	movb   #$01, displayState		     
	rts

;============================= Display State 1 - Display Hub =============================
	
displaystate1:

    tst		VRefPromptFlag	         ; Test to see if C Character (V_Ref) has been Pressed
    bne		DISPLAY_VREF       ; Branch VREFFLAG if true
    tst		KiPromptFlag             ; Test KIFLAG
    bne		DISPLAY_KI          ; Branch to KI_DISPLAY, if true
    tst		KpPromptFlag           ; TEST WAVE_FLAG
    bne		DISPLAY_KP          ; If it is true then branch and display
    tst		LCDUpdateFlag
    lbne	UPDATE_LCD
    tst		echoFlag            ; Test ECHOFLAG
    lbne	KEY_PRINT                ; If ECHOFLAG is TRUE, branch to ECHO
    tst		backspacePrint          ; Test BSPACEFLAG
    lbne	BACKSPACE_PRINT           ; If BSPACEFLAG is TRUE, branch to DISPBSPACE
	tst	    stateVariableFlag
	lbne	STATE_VARIABLE_PRINT  
    rts
	
DISPLAY_VREF:

       movb   #$02, displayState       ; Set state to display DISP VREF message
       rts	
	   	
DISPLAY_KI: 

       movb   #$03, displayState       ; Set state to KI display
       rts
	   
DISPLAY_KP:

       movb   #$04, displayState       ; Set state to KP display
       rts
	   
KEY_PRINT:

       movb   #$05, displayState       ; Set state to echo digits pressed
       rts
	   
BACKSPACE_PRINT:

       movb   #$06, displayState       ; Set state to display Backspace
       rts

UPDATE_LCD:

       movb   #$07, displayState       ; Set state to Update LCD screen
       rts

STATE_VARIABLE_PRINT:

       movb   #$08, displayState       ; Set state to Update LCD screen
       rts
	   
;========================= Timer Channel 0 Sub-Routine =========================
	
TIMER_C0:
	
	ldaa   tc0State                     ; Load Accumulator A with tc0State
	beq    tc0state0                    ; Branch to Timer Channel 0 State 0
	deca                                ; Decrement Accumulator A
	beq    tc0state1                    ; Branch to Timer Channel 0 State 1
	rts
	
;================ Timer Channel 0 State 0 - Timer Initialization ===============

tc0state0:
	
	bset     PORTJ, $10        ; initialize to off
    bset     DDRJ, $10         ; set PORTJ to output
	
	bset   TIOS, #$01                   ; Setting TC0 for Output Compare
	
	bset   TCTL2, #$01                  ; Initialize OC0 to Toggle on Successful Compare   
	
	bclr   TCTL2, #$02                  ; Initialize OC0 to Toggle on Successful Compare
	
	bset   TFLG1, #$0001                ; Clearing the Timer Output Compare Flage if Set
	   
    bset   TMSK1, #$01            		; Enabling Timer Channel 0 Output Compare Interrupts

	movb   #$01, tc0State               ; Set Next Interrupt State to 1
	
	movb   #$A0, TSCR                   ; Enable the Timer and Stopping While in BGND Mode
	
	cli                                 ; Enable Maskable Interrupts
	
	ldd    TCNT                         ; Reads Current Count and Stores it in D
	
	addd   #$0320                       ; Adds Interval Value 800 to Current Timer Count
	
	std    TC0H						    ; Stores Interval + TCNT
	   
	rts                                 ; Return from Subroutine
	
;================== Timer Channel 0 State 1 - Arbitrary State ==================

tc0state1:

	rts   	                            ; Return from Subroutine
	
;==================== Interrupt Service Routine & Branches =====================
	  
TC0_ISR:

   tst     RUN
   
   beq     STOP_MOTOR
   
   tst     OpenLoop
   
   bne     RUNOPENLOOP  
    
   ldd     V_Ref
   
   subd    V_Act
   
   std     New_Error
   
   tst     New_Error
   
   bmi     NEG_ERROR_SIGN
   
   bra     POS_ERROR_SIGN
   
STOP_MOTOR:
    
   movw    #$099A, Dac_Value
   lbra    COMPLETE_ISR  
   
RUNOPENLOOP:
   
   movw    #$00, Ki
   movw    V_Ref, New_Error
   tst     New_Error
   bmi     NEG_ERROR_SIGN
   bra     POS_ERROR_SIGN
    
NEG_ERROR_SIGN:
    
   movb    #$01, NegErrorFlag
	
POS_ERROR_SIGN:
   
   ldd     New_Error
   bra     KP_CALC
             
KP_CALC:

   ldy     New_Error
   ldd     Kp
   emuls
   ldx     #$0400
   edivs  
   bvc     NO_SAT_Kp_DIV
   bvs     SAT_Kp_DIV
   
SAT_Kp_DIV:
   
   tst     NegErrorFlag
   beq     POS_Kp_SAT
   movw    #$7FFF, Kpdivs
   bra     EMUL_CALC
   
POS_Kp_SAT:

   movw    #$0800, Kpdivs
   bra     EMUL_CALC
      
NO_SAT_Kp_DIV:
   
   sty     Kpdivs
   bra     EMUL_CALC
   
EMUL_CALC:

   ldd     New_Error
   addd    E_Sum
   bvs     SDBA_ESUM
   bvc     NO_SDBA_ESUM
	
SDBA_ESUM:

   ldy     New_Error
   cpy     #$00
   bpl     POS_ESUM_SAT
   bmi     NEG_ESUM_SAT
	
POS_ESUM_SAT:
   
   movw    #$7FFF, E_Sum
   bra     KI_CALC
 
NEG_ESUM_SAT:
   
   movb    #$01, NegESumFlag
   movw    #8000, E_Sum
   bra     KI_CALC  
   
NO_SDBA_ESUM:

   std     E_Sum
   bra     KI_CALC
	
KI_CALC:

   ldy     E_Sum
   ldd     Ki
   emuls
   ldx     #$0400
   edivs  
   bvc     NO_SAT_Ki_DIV
   bvs     SAT_Ki_DIV
   
SAT_Ki_DIV:
   
   tst     NegESumFlag
   beq     POS_Ki_SAT
   movw    #$7FFF, Kidivs
   bra     CALCULATE_A
   
POS_Ki_SAT:

   movw    #$0800, Kidivs
   bra     CALCULATE_A
      
NO_SAT_Ki_DIV:
   
   sty     Kidivs
   bra     CALCULATE_A
   
CALCULATE_A:

   ldd     Kpdivs
   addd    Kidivs
   bvc     NO_A_SAT
   bvs     SAT_A
   
NO_A_SAT:

   std     KiplusKp
   bra     CALCUALTE_A_PRIME

SAT_A:

   ldy     Kpdivs
   cpy     #$00
   bpl     POS_A_SAT
   movw    #$0800, KiplusKp
   bra     CALCUALTE_A_PRIME
   
POS_A_SAT:

   movw    #$7FFF, KiplusKp
   bra     CALCUALTE_A_PRIME

CALCUALTE_A_PRIME:

   ldd     KiplusKp
   addd    #$099A
   bvc     NO_APRIME_SAT
   bvs     SAT_APRIME
      
SAT_APRIME:
   
   ldy     KiplusKp
   cpy     #$00
   bpl     POS_APRIME_SAT
   bmi     NEG_APRIME_SAT
   
POS_APRIME_SAT:

   movw    #$7FFF, A_Prime
   bra     GET_ASTAR
   
NEG_APRIME_SAT:

   movw    #$0800, A_Prime
   bra     GET_ASTAR

NO_APRIME_SAT:

   std     A_Prime
   bra     GET_ASTAR

GET_ASTAR:
   
   ldd     A_Prime
   cpd     #$0D9A
   bgt     HIGH_SAT
   cpd     #$059A
   blt     LOW_SAT
   std     Dac_Value
   bra     READ_ENCODER
   
HIGH_SAT:
   
   movw    #$0D9A, Dac_Value
   bra     READ_ENCODER
     
LOW_SAT:

   movw    #$059A, Dac_Value
   bra     READ_ENCODER
   
READ_ENCODER:
    
	ldd    ENCODER
	std    Theta_New
	subd   Theta_Old
	bmi    NEG_VACT_SIGN
    bra    GET_VACT
	
NEG_VACT_SIGN:
  
    movb   #01, NegVactSign
	
GET_VACT: 

    std    V_Act
	movw   Theta_New, Theta_Old
    bra    COMPLETE_ISR

COMPLETE_ISR:

	jsr	OUTDAC
	ldd	TC0H				; Grab the Timer Count Corresponding to ISR
  	addd #$0320		; Add the Interval to The Current Timer Count
	std	TC0H				; Store the New Timer Count Into the TC0 CR
	ldaa TFLG1               ; LOAD TIMER FLAG ONTO ACC. A 
	oraa #01                 ; CLEAR CONTENTS (TIMER FLAG) OF ACC. A
	staa TFLG1               ; LOAD ACC. A BACK INTO TIMER FLAG
	rti
 
OUTDAC:
	
   ldd     Dac_Value                      ; Load Accumulator D With VALUE
   staa    $0303                          ; Store Address of DACs MSB in A
   stab    $0302                          ; Store Address of DACs LSB in B
   bclr    PORTJ, pin5                    ; Clear pin 5 in Port J
   bset    PORTJ, pin5                    ; Set pin 5 in Port J
   rts

  	   
;===============================================================================

.area interrupt_vectors (abs)
	  .org   $FFEE                        ; Address of Next Interrupt        
	  .word  TC0_ISR                      ; Load Interrupt Address
	  .org    $FFFE                       ; At Reset Vector Location
	  .word   __start                     ; Load Starting Address