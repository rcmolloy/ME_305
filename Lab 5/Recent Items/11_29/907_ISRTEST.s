; Robert Cory Molloy & Oscar Andrade
; ME 305 - 02 :: Intro to Mechatronics
; Labratory 5 :: Motor Controller 

;==================== Assembler Equates ====================

ENCODER		       = $0280				 ; Encoder Address 
SIX_VOLTS          = $009A               ; Voltage Offset to be Added to A
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
stateVariableState::.blkb 1
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
slopeTimesDacValue::.blkb 2
bConstant::			.blkb 2

;==================== Storing Variables ====================

keyStore::		.blkb 1		; Stores Most Recent Digit Pressed
buffer::			.blkb 6		; Stores All Digits for Processing to Ticks
result::			.blkb 2		; Stores converted ASCII numbers
updateBuffer::		.blkb 5
updatePointer::		.blkb 2
updateResult::		.blkb 2
updateCounter::		.blkb 1
cursorAddress::		.blkb 1

;==================== Counter Variables ====================

digitCounter::		.blkb 1		; Counts Up Current Digits Input into buffer
digitCountOut::		.blkb 1
LCDUpdateCount::	.blkb 1
LCDUpdateCounter::	.blkb 1

;==================== Flags ====================

RUN::		        .blkb 1
loopSetFlag::		.blkb 1
NegErrorFlag::      .blkb 1     ; Notifies The Program That New_Error is Negative
NegESumFlag::       .blkb 1     ; Notifies the Progream That E_Sum is Negative
KpNegSatFlag::      .blkb 1     ; Notifies The Program that Kp
KpPosSatFlag::      .blkb 1     ; Notifies The Program that Kp
NegVactSign::       .blkb 1
LCDFlag::			.blkb 1
L2UpdateFlag::		.blkb 1
VRefNeg::			.blkb 1
VRefPos::			.blkb 1
stateVariableFlag::	.blkb 1
keyFlag::			.blkb 1		; Notify Program a Key Has Been Pressed
echoFlag::			.blkb 1		; Notify Program that a Key Needs to Be Echoed
enterFlag::			.blkb 1		; Notify Program that Enter Procedure is Done
firstChar::				  .blkb 1		; Notify Program the First Character is Ready
backspaceFlag::			  .blkb 1		; Notify Program that a Entered Digit Needs to Be Cleared
loopFlag::				  .blkb 1

digitFlag::				  .blkb 1
autoManualFlag::		  .blkb 1

backspacePrint::		  .blkb 1
updateFlag::			  .blkb 1	
LCDUpdateFlag::			  .blkb 1
effortFlag::			  .blkb 1
errorFlag::		    	  .blkb 1
VActFlag::				  .blkb 1
VRefFlag::		  .blkb 1	
KiFlag::      	  .blkb 1
KpFlag::      	  .blkb 1
charFlag::				  .blkb 1
AFlag::					  .blkb 1
BFlag::					  .blkb 1
CFlag::					  .blkb 1
DFlag::					  .blkb 1
EFlag::					  .blkb 1
FFlag::					  .blkb 1
onPrintFlag::			  .blkb 1
offPrintFlag::			  .blkb 1
openLoopPrintFlag::		  .blkb 1
closedLoopPrintFlag::	  .blkb 1
autoPrintFlag::			  .blkb 1
manualPrintFlag::		  .blkb 1
VRefPromptFlag::		  .blkb 1
KiPromptFlag::			  .blkb 1
KpPromptFlag::			  .blkb 1
digitAllowed::			  .blkb 1
VRefSignFlag::			  .blkb	1
signBackspaceFlag::		  .blkb 1

updateValuesFlag::		  .blkb 1
updateLine1Flag::		  .blkb 1
updateLine2Flag::		  .blkb 1
promptUpFlag::			  .blkb 1

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

    bgnd

	jsr    	MASTERMIND			     ; Mastermind Sub-Routines
 
	jsr    	KPD		  			     ; Key Pad Driver Sub-Routines
 
	jsr    	DISPLAY      		     ; Display Sub-Routines
 
	jsr		TIMER_C0                 ; Timer Channel Zero Sub-Routines

	bra		TOP
	
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
	lbeq	mmstate3			         ; Backspace State
	deca
	lbeq	mmstate4			         ; Enter State
	deca
	lbeq	mmstate5			         ; Digit State
	deca
	lbeq	mmstate6			         ; Character State
	deca	
	lbeq    mmstate7			         ; Update Values State
	rts							         ; Return to Main 

;=========== Mastermind State 0 - Initialization of Mastermind & Buffer ========

mmstate0:	
					
	movw    #buffer, pointer 		   			 ; Stores the first address of buffer into pointer
	movw    #updateBuffer, updatePointer 		 ; Stores the first address of buffer into pointer
	clr		buffer					    		 ; Clear the buffer Variable
	clr		updateBuffer						 ; Clear the buffer Variable
	movw  	#$0000,  result
	movb  	#$00, RUN           				 ; Motor stop at intialization
    movw   	#$0019, V_Ref       				 ; Initial VREF value $19=25
    movw   	#$0400, Ki           				 ; Initial KP value $400=1024=1024(1)
    movw   	#$1400, Kp          				 ; Initial KP value $1400=5120=1024(5)
	jsr		CLEAR_TEMPLATE
	movb	#$01, autoManualFlag
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
	movb   #$01, offPrintFlag
	movb   #$01, closedLoopPrintFlag
	movb   #$01, autoPrintFlag
	movb   #$01, updateValuesFlag
	movb   #$02, mmState			    ; Set the Mastermind State Variable to 2 (Hub)
	rts								    ; Return to Main

;===============  Mastermind State 2 - Hub  ============================

mmstate2:

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
	lbeq	A_TRUE						 ; If B = '$41', Branch to ENT_TRUE
	cmpb 	#$42                         ; Compare Acc. B to Hex Value of 'F1'
	lbeq	B_TRUE						 ; If B = '$41', Branch to ENT_TRUE
	cmpb 	#$43                         ; Compare Acc. B to Hex Value of 'F1'
	lbeq	C_TRUE						 ; If B = '$41', Branch to ENT_TRUE
	cmpb 	#$44                         ; Compare Acc. B to Hex Value of 'F1'
	lbeq	D_TRUE						 ; If B = '$41', Branch to ENT_TRUE
	cmpb 	#$45                         ; Compare Acc. B to Hex Value of 'F1'
	lbeq	E_TRUE					 	 ; If B = '$41', Branch to ENT_TRUE
	cmpb 	#$46                         ; Compare Acc. B to Hex Value of 'F1'
	lbeq	F_TRUE						 ; If B = '$41', Branch to ENT_TRUE
	cmpb 	#$0A                         ; Compare Acc. B to Hex Value of '0A'
	lbeq 	ENT_TRUE                     ; If B = '$0A', Branch to ENT_TRUE
	lbra	DIGIT_TRUE                   ; Otherwise Branch to DIGIT_TRUE

NO_KEY:

	tst		backspaceFlag                ; Test backspaceFlag
	lbne	BACKSPACE_GO                 ; If backspaceFlag Not $00, Branch to BACKSPACE_GO
	tst		enterFlag                    ; Test enterFlag
	lbne	ENTER_GO                     ; If enterFlag Not $00, Branch to ENTER_GO
	tst		digitFlag                    ; Test digitFlag
	lbne	DIGIT_GO                     ; If digitFlag Not $00, Branch to DIGIT_GO
	tst		charFlag                    ; Test digitFlag
	lbne	CHAR_GO                     ; If digitFlag Not $00, Branch to CHAR_GO
	tst		updateValuesFlag
	lbne	UPDATE_VALUES_GO
	movb 	#$02, mmState                ; If No Key was Pressed, Return to Hub
	rts
	
F1_TRUE:

	tst		VRefSignFlag
	lbne	F1_DONE
	tst		VRefFlag
	beq		F1_DONE
	tst		digitCounter
	bne		F1_DONE
	movb	#$01, VRefPos
	movb	#$01, echoFlag
	movb 	#$02, mmState                ; Set next Mastermind State (mmstate) to Hub
	rts	

F1_DONE:
	
	movb 	#$02, mmState                ; Set next Mastermind State (mmstate) to Hub
	rts	
		
F2_TRUE:

	tst		VRefSignFlag
	lbne	F2_DONE
	tst		VRefFlag
	beq		F2_DONE
	tst		digitCounter
	bne		F2_DONE
	movb	#$01, VRefNeg
	movb	#$01, echoFlag
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

	movb	#$01, charFlag
	movb	#$01, AFlag
	rts
	
B_TRUE:

	movb	#$01, charFlag
	movb	#$01, BFlag
	rts	
	
C_TRUE:

	movb	#$01, charFlag
	movb	#$01, CFlag
	movb   #$01, promptUpFlag
	rts	
	
D_TRUE:

	movb	#$01, charFlag
	movb	#$01, DFlag
	movb   #$01, promptUpFlag
	rts	
	
E_TRUE:

	movb	#$01, charFlag
	movb	#$01, EFlag
	movb   #$01, promptUpFlag
	rts

F_TRUE:

	movb	#$01, charFlag
	movb	#$01, FFlag
	rts		
	
	
BACKSPACE_GO:

	movb 	#$03, mmState                ; Set next Mastermind State (mmstate) to Backspace
	rts
	
ENTER_GO:

	movb 	#$04, mmState                ; Set next Mastermind State (mmstate) to Enter
	rts
	
DIGIT_GO:
	
	clr     digitFlag
	movb 	#$05, mmState                ; Set next Mastermind State (mmstate) to Digit
	rts
	
CHAR_GO:

    clr	 	charFlag
	movb 	#$06, mmState                ; Set next Mastermind State (mmstate) to Character
	rts

UPDATE_VALUES_GO:

    clr	 	updateValuesFlag
	movb 	#$07, mmState                ; Set next Mastermind State (mmstate) to Character
	rts

	
;===================== Mastermind State 3 - Backspace State ====================

mmstate3:

    tst	 	VRefSignFlag
	bne		SIGN_BACKSPACE_TRUE
	tst  	digitCounter                  ; Test digitCounter
	beq 	BACKSPACE_DONE            ; If digitCounter is FALSE, Branch to BSPACE_DONE
	tst 	backspaceFlag                 ; Test digitCounter
	beq 	BACKSPACE_DONE                   ; If digitCounter is FALSE, Branch to BSPACE_DONE
	bra 	BACKSPACE_SET

SIGN_BACKSPACE_TRUE:

    tst	    signBackspaceFlag
	lbne	BACKSPACE_DONE
	movb	#$01, signBackspaceFlag
	movb	#$00, VRefSignFlag
	movb	#$00, VRefPos
	movb	#$00, VRefNeg
	bra		BACKSPACE_SET
	
BACKSPACE_SET:

	movb 	#$01, backspacePrint          ; Set backspaceFlag to TRUE
	rts
	
BACKSPACE_DONE:

	movb	#$00, backspaceFlag
	movb 	#$02, mmState                 ; Set next Mastermind State (mmstate) to M^2 Hub
	rts

;===================== Mastermind State 4 - Enter State ========================

mmstate4:

	tst	 	enterFlag
	bne		ENTER_INIT
	lbeq	ENTER_DONE
	rts
	
ENTER_INIT:
		
	tst 	digitCounter                  ; Test digitCounter
	lbeq 	EMPTY_VALUE                   ; If digitCounter is FALSE, Branch to EMPTY_VALUE
	bra 	ASCII_BCD                     ; Otherwise Branch to ASCII_BCD

ASCII_BCD:

	movw    #buffer, pointer              ; Load buffer Address Into pointer
	movw	#$0000, result                ; Set result to 0	
	LOOP:

		ldy 	#$0A                      ; Load Accumulator A with 10    
		ldd 	result                    ; Load Accumulator B with result    
		emul                               ; Multiply A and B, Store in A:B or D
		cmpy 	#$0000                      ; Compare Accumulator D with 0 
		bne 	TOO_BIG_VALUE          
		std 	result                    ; Store Accumulator D into result    
		ldx 	pointer                   ; Load X with buffer Address Stored In pointer    
		ldab 	0,x                       ; Load Accumulator B with the Contents in X  
		subb 	#$30                      ; Subtract 30 From Accumulator B  
		clra                              ; Clear Accumulator A 
		addd 	result                    ; Add result To B and Store Back Into B
		bvs 	TOO_BIG_VALUE		      ; If greater than 255 hex, Branch to TOO_BIG_VALUE  
		std 	result                    ; Store D in result 
		dec 	digitCounter              ; Decrement digitCounter
		tst		digitCounter              ; Test digitCounter         
		beq 	VALUE_PUSH_MAIN           ; If digitCounter is zero, Branch to VALUE_PUSH_MAIN        
		inx                               ; Increment Address in X
		stx		pointer                   ; Store Address In X Into Pointer
		bra 	LOOP                      ; Branch Back Into LOOP         	
	
VALUE_PUSH_MAIN:

    tst		VRefFlag
	bne		VREF_STORE
	tst		KiFlag
	bne		KI_STORE
	tst		KpFlag
	bne    	KP_STORE
	bra		ENTER_DONE                    ; Otherwise Branch To ENTER_DONE
	
TOO_BIG_VALUE:

	movw	 #$7FFF, result
	bra		 VALUE_PUSH_MAIN
		
EMPTY_VALUE:
	
	movw	#$0000, result                ; Set result to FALSE
	movw    #buffer, pointer              ; Move buffer Address Into Pointer
	clr	    digitCounter                  ; Clear the digitCounter
	movb	#$00, enterFlag               ; Set enterFlag to FALSE
	rts		

VREF_STORE:

    tst	   VRefSign
	bne	   VREF_NEG_STORE
	movw   result, V_Ref
	bra	   ENTER_DONE 

VREF_NEG_STORE:

    ldd     #$0000             ; loading D with 0 value
    subd    result             ; subracting result from zero to get a negative value
	std     V_Ref
	bra		ENTER_DONE 
	
KI_STORE:

	movw	result, Ki
	bra		ENTER_DONE 

KP_STORE:

	movw	result, Kp
	bra		ENTER_DONE  			
	
ENTER_DONE:

	movw	#$0000, result                ; Set result to 0
	clr	    digitCounter                  ; Clear the digitCounter
	movw    #buffer, pointer              ; Move buffer Address Into pointer
	movb	#$00, enterFlag               ; Set enterFlag to FALSE
	movb	#$00, digitAllowed			   
	movb	#$02, mmState
	movb	#$01, updateValuesFlag
	movb    #$00, promptUpFlag			              
	rts 

;====================  Mastermind State 5 - Digit Entered   ====================

mmstate5:

	tst		digitAllowed
	lbeq	DIGIT_DONE
	tst		digitFlag
	bne		DIGIT_WAIT				
	cmpb	#$41				          ; Compare Hexadecimal Value In B to $41
	lblo	DIGIT				          ; If Value in B < $40, Branch to DIGIT
	bra		NOTDIGIT			          ; Otherwise Value in B is not a Digit, Branch to NOTDIGIT
  
DIGIT:

	movb	#$01, digitFlag
	lbra	BUFFER_STORE                  ; Jump To Subroutine BUFFER_STORE

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

;===================== Mastermind State 6 - Character Entered ==================

mmstate6:

    tst  VRefFlag
	lbne VALUE_CHAR_DONE
	tst	 KiFlag
	lbne VALUE_CHAR_DONE
	tst	 KpFlag
	lbne VALUE_CHAR_DONE
	tst	 AFlag
	lbne AFLAG_GO
	tst	 BFlag
	lbne BFLAG_GO
	tst	 CFlag
	lbne CFLAG_GO
	tst	 DFlag
	lbne DFLAG_GO
	tst	 EFlag
	lbne EFLAG_GO
	tst	 FFlag
	lbne FFLAG_GO
	movb #$02, mmState
	rts
	
AFLAG_GO:

    tst	 RUN
	lbne MOTOR_OFF
	lbra MOTOR_ON
	
MOTOR_OFF:
	
	movb  #$00, RUN
	movb  #$01, offPrintFlag
	movb  #$00, onPrintFlag
	movb  #$00, AFlag
	lbra	  STATE_CHAR_DONE
	
MOTOR_ON:
	
	movb  #$01, RUN
	movb  #$00, offPrintFlag
	movb  #$01, onPrintFlag
	movb  #$00, AFlag
	lbra  STATE_CHAR_DONE
	
BFLAG_GO:

    tst	 loopSetFlag
	lbeq OPEN_LOOP_SET
	lbne CLOSED_LOOP_SET
	
OPEN_LOOP_SET:

	movb #$00, closedLoopPrintFlag
	movb #$01, openLoopPrintFlag
	movb #$01, loopSetFlag
	movb #$00, BFlag
	lbra STATE_CHAR_DONE

CLOSED_LOOP_SET:

	movb #$01, closedLoopPrintFlag
	movb #$00, openLoopPrintFlag
	movb #$00, loopSetFlag
	movb #$00, BFlag
	lbra STATE_CHAR_DONE		
		
CFLAG_GO:

	movb #$01, VRefFlag
	movb #$01, VRefPromptFlag
	movb #$00, CFlag
	lbra VALUE_CHAR_DONE	
		
DFLAG_GO:
	
	movb #$00, RUN
	movb #$01, offPrintFlag
	movb #$01, stateVariableFlag
	movb #$01, KiFlag
	movb #$01, KiPromptFlag
	movb #$00, DFlag
	lbra VALUE_CHAR_DONE	

EFLAG_GO:

	movb #$00, RUN
	movb #$01, offPrintFlag
	movb #$01, stateVariableFlag
	movb #$01, KpFlag
	movb #$01, KpPromptFlag
	movb #$00, EFlag
	lbra VALUE_CHAR_DONE	

FFLAG_GO:

    tst	 autoManualFlag
	lbeq AUTO_SET
	lbne MANUAL_SET
	
AUTO_SET:

	movb #$01, autoPrintFlag
	movb #$00, manualPrintFlag
	movb #$01, autoManualFlag
	movb #$00, FFlag
	lbra STATE_CHAR_DONE

MANUAL_SET:

	movb #$00, autoPrintFlag
	movb #$01, manualPrintFlag
	movb #$00, autoManualFlag
	movb #$00, FFlag
	lbra STATE_CHAR_DONE	

STATE_CHAR_DONE:

	movb  #$01, stateVariableFlag
	movb  #$02,	mmState
	rts
	
VALUE_CHAR_DONE:

	movb  #$02,	mmState
	rts

;===================== Mastermind State 7 - Update Values ======================

mmstate7:
       
	tst	   VRefFlag
	lbne   UPDATE_VREF
	tst    KiFlag
	lbne   UPDATE_KI
	tst    KpFlag
	lbne   UPDATE_KP
	
SKIP_ENTRY_VALUES:

	tst 	VActFlag
	lbne 	UPDATE_VACT
	tst 	errorFlag
	lbne	UPDATE_ERROR
	tst 	effortFlag
	lbne	UPDATE_EFFORT
	movb    #$02, mmState
	rts

UPDATE_VREF:
	
	tst  	VRefSign            
	bne    	NEGATIVE_VREF    
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
    ldd    Kp
    bra   BINARY_ASCII	

UPDATE_ERROR:
	
	tst  	errorSign            
	bne    	NEGATIVE_ERROR    
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
	movb	#$00, updateCounter
	   
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


	tst     VRefFlag
	bne		VREF_SIGN_CHECK
	tst		KiFlag
	lbne	KI_KP_CHECK
	tst		KpFlag
	lbne	KI_KP_CHECK
	tst 	VActFlag
	lbne 	VACT_SIGN_CHECK
	tst 	errorFlag
	lbne	ERROR_SIGN_CHECK
	tst 	effortFlag
	lbne	EFFORT_SIGN_CHECK
	lbra    UPDATE_BUFFER_DONE
				  
VREF_SIGN_CHECK:

       movb	  #$00, VRefFlag
	   movb	  #$01, updateLine1Flag
	   movb   #$01, updateLine2Flag
	   ldx	  #updateBuffer
       ldy    #VREF_BUF        
       tst	  VRefSign
	   bne	  NEG_SIGN
	   bra	  POS_SIGN                                      	   

VACT_SIGN_CHECK:
     
	   movb	  #$00, VActFlag
	   ldx	  #updateBuffer
       ldy    #VACT_BUF          
       tst    VActSign           
	   beq    POS_SIGN
	   movb   #$00, VActSign
	   bra	  NEG_SIGN   
	                                      	    
ERROR_SIGN_CHECK:
       
	   movb	  #$00, errorFlag
	   ldx	  #updateBuffer
       ldy    #ERROR_BUF         
       tst    errorSign           
	   beq    POS_SIGN
	   movb   #$00, errorSign
	   bra	  NEG_SIGN                                                    		   

EFFORT_SIGN_CHECK:
       
	   movb	  #$00, effortFlag
	   ldx	  #updateBuffer
       ldy    #EFFORT_BUF          
       ldaa   effortSign           
	   cmpa   #$01
	   bne    POS_SIGN
	   movb   #$00, effortSign
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
	   movb	  #$01, updateLine2Flag
	   ldx	  #updateBuffer
       ldy    #KI_BUF
	   jsr	  CLEAR_BOTTOM_BUFF                       
	   bra    UPDATE_OUT

KP_CHECK:
		 
	   movb	  #$00, KpFlag
	   movb	  #$01, updateLine2Flag
	   ldx	  #updateBuffer
       ldy    #KP_BUF
	   jsr	  CLEAR_BOTTOM_BUFF                       
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
       bra    UPDATE_BUFFER_DONE

TWO_DIGITS:
       movb   0,x,3,y             ; Move the first digit into fourth slot
       movb   1,x,2,y             ; Move the second digit into third slot
	   movb   #'0',1,y
       bra    UPDATE_BUFFER_DONE

THREE_DIGITS:
       movb   0,x,3,y             ; Move the first digit into fourth slot
       movb   1,x,2,y             ; Move the second digit into third slot
       movb   2,x,1,y             ; Move the third digit into second slot
       bra    UPDATE_BUFFER_DONE

FOUR_DIGITS:
       movb   0,x,4,y             ; Move the first digit into fifth slot
       movb   1,x,3,y             ; Move the second digit into fourth slot
       movb   2,x,2,y             ; Move the third digit into third slot
       movb   3,x,1,y             ; Move the fourth digit into second slot
       bra    UPDATE_BUFFER_DONE

FIVE_DIGITS:
       movb   0,x,4,y             ; Move the first digit into fifth slot
       movb   1,x,3,y             ; Move the second digit into fourth slot
       movb   2,x,2,y             ; Move the third digit into third slot
       movb   3,x,1,y             ; Move the fourth digit into second slot
       movb   4,x,0,y             ; Move the fifth digit into first slot
       bra    UPDATE_BUFFER_DONE

UPDATE_BUFFER_DONE:

       tst    VRefFlag
	   lbne	  UPDATE_VREF
	   tst    KiFlag
	   lbne	  UPDATE_KI
	   tst    KpFlag
	   lbne	  UPDATE_KP
       tst    VActFlag
       lbne   UPDATE_VACT         
       tst    errorFlag
       lbne   UPDATE_ERROR        
       tst    effortFlag
       lbne   UPDATE_EFFORT
	   
UPDATE_BUFFER_EXIT: 

       movb	  #$00, updateValuesFlag
	   movb   #$02, mmState       		  
       rts
	
;=========  Mastermind - Miscellaneous Sub-Rountines / Branches   ==============

BUFFER_STORE:

	tst	   VRefFlag
	bne	   BUFFER_STORE_VREF		 
	ldaa   digitCounter                   ; Load Accumulator A with digitCounter
	cmpa   #$05                           ; Compater Accumulator with $05
	bge    BUFFER_STORE_LIMIT             ; If A is higher or equal than $05, Branch to BUFFER_STORE_LIMIT
	inc    digitCounter
	ldx    pointer                        ; Load X with pointer
	ldab   keyStore				      ; Load B with digitStore
	stab   0,x                            ; Store Contents of B into X
	inx                                   ; Increment X
	stx     pointer                       ; Store X in Pointer
	movb	#$01, echoFlag                ; Set echoFlag to TRUE
	movb	#$00, keyFlag	              ; Set keyFlag to FALSE
	movb	#$02, mmState				  ; Set next Mastermind State (mmstate) to M^2 Hub
	rts

BUFFER_STORE_VREF:

	ldaa   digitCounter                   ; Load Accumulator A with digitCounter
	cmpa   #$03                           ; Compater Accumulator with $03
	bge    BUFFER_STORE_LIMIT             ; If A is higher or equal than $03, Branch to BUFFER_STORE_LIMIT
	inc    digitCounter
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

	ldab    #$00
	clr	   keyFlag
	clr	   echoFlag
	clr	   digitFlag
	movb   #$02, mmState				  ; Set next Mastermind State (mmstate) to M^2 Hub
	rts	

CLEAR_TEMPLATE:

       ldx    VREF_BUF         ; Moves Zeros into L$VREF_BUF
       movb   #'+',0,x
       movb   #'0',1,x
       movb   #'0',2,x
       movb   #'0',3,x
       ldx    VACT_BUF         ; Moves Zeros into L$VACT_BUF
       movb   #'+',0,x
       movb   #'0',1,x
       movb   #'0',2,x
       movb   #'0',3,x
       ldx    ERROR_BUF          ; Moves Zeros into L$ERR_BUF
       movb   #'+',0,x
       movb   #'0',1,x
       movb   #'0',2,x
       movb   #'0',3,x
       ldx    EFFORT_BUF         ; Moves Zeros into L$EFRT_BUF
       movb   #'+',0,x
       movb   #'0',1,x
       movb   #'0',2,x
       movb   #'0',3,x
       ldx    KI_BUF           ; Moves Zeros into L$KI_BUF
       movb   #'0',0,x
       movb   #'0',1,x
       movb   #'0',2,x
       movb   #'0',3,x
       movb   #'0',4,x	   
       ldx    KP_BUF           ; Moves Zeros into L$KP_BUF
       movb   #'0',0,x
       movb   #'0',1,x
       movb   #'0',2,x
       movb   #'0',4,x
       jsr    UPDATELCDL1         ; Jump to subtrountine to Update Line 1 of LCD
       jsr    UPDATELCDL2         ; Jump to subtrountine to Update Line 2 of LCD
       rts
	rts


CLEAR_TOP_BUFF:                     ; Clears the Buffer for the 4 digit values
       movb   #' ',0,y
       movb   #' ',1,y
       movb   #' ',2,y
       movb   #' ',3,y
       rts
CLEAR_BOTTOM_BUFF:                     ; Clears the Buffer for the 5 digit values
       movb   #' ',0,y
       movb   #' ',1,y
       movb   #' ',2,y
       movb   #' ',3,y
       movb   #' ',4,y	   
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
	deca
	lbeq   displaystate2                 ; Update LCD Template Values
	deca
	lbeq   displaystate3                 ; Display Ref Velocity Prompt 
	deca
	lbeq   displaystate4                 ; Display Ki Prompt
	deca
	lbeq   displaystate5                 ; Display Kp Prompt
	deca
	lbeq   displaystate6                 ; Initializing & Printing Digit
	deca
	lbeq   displaystate7                 ; Backspace	
	deca
	lbeq   displaystate8                 ; LCD Update
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
    bne		DISPLAY_VREF_PROMPT       ; Branch VREFFLAG if true
    tst		KiPromptFlag             ; Test KIFLAG
    bne		DISPLAY_KI_PROMPT          ; Branch to KI_DISPLAY, if true
    tst		KpPromptFlag           ; TEST WAVE_FLAG
    bne		DISPLAY_KP_PROMPT          ; If it is true then branch and display
    tst		echoFlag            ; Test ECHOFLAG
    lbne	KEY_PRINT                ; If ECHOFLAG is TRUE, branch to ECHO
    tst		backspacePrint          ; Test BSPACEFLAG
    lbne	BACKSPACE_PRINT           ; If BSPACEFLAG is TRUE, branch to DISPBSPACE
	tst	    stateVariableFlag
	lbne	STATE_VARIABLE_PRINT
	tst	    LCDUpdateFlag
	lbne	LCD_UPDATE_PRINT 
    rts
	
DISPLAY_VREF_PROMPT:

       movb   #$02, displayState       ; Set state to display DISP VREF message
       rts	
	   	
DISPLAY_KI_PROMPT: 

       movb   #$03, displayState       ; Set state to KI display
       rts
	   
DISPLAY_KP_PROMPT:

       movb   #$04, displayState       ; Set state to KP display
       rts
	   
KEY_PRINT:

       movb   #$05, displayState       ; Set state to echo digits pressed
       rts
	   
BACKSPACE_PRINT:

       movb   #$06, displayState       ; Set state to display Backspace
       rts

STATE_VARIABLE_PRINT:

       movb   #$07, displayState       ; Set state to Update LCD screen
       rts
	   
LCD_UPDATE_PRINT:

       movb   #$08, displayState       ; Set state to Update LCD screen
       rts


;===================== Display State 2 - VRef Prompt Print =====================
	
displaystate2:

    ldaa   #$40                           ; Load Accumulator A with LCD Address $07
    ldx    #VREF_PRINT_MESSAGE            ; Load Index Register X with Address of NO_DIGITS_PRINT
    jsr    DISPLAY_CHAR   	              ; Jump to Subroutine DISPLAY_CHAR
    ldx    displayPointer                 ; Load X with displayPointer
    ldab   0,x                            ; Load B with the Contents in X
    lbeq   DONE_VREF_PRINT				  ; If B=$00, Branch to DONE_NO_DIGITS_PRINT
    rts

VREF_PRINT_MESSAGE:

	.ascii 	'ENTER VREF:                         '
    .byte  	$00
    rts               
	   
DONE_VREF_PRINT:
	
	ldaa   #$4C
	jsr	   SETADDR
	movb   #$00, VRefPromptFlag
	movb   #$01, firstChar
	movb   #$01, digitAllowed		          
    movb   #$01, displayState             ; Return to Display State 1
	rts
	
;===================== Display State 3 - Ki Prompt Print =======================
	
displaystate3:

    ldaa   #$40                           ; Load Accumulator A with LCD Address $07
    ldx    #KI_PRINT_MESSAGE            ; Load Index Register X with Address of NO_DIGITS_PRINT
    jsr    DISPLAY_CHAR   	              ; Jump to Subroutine DISPLAY_CHAR
    ldx    displayPointer                 ; Load X with displayPointer
    ldab   0,x                            ; Load B with the Contents in X
    lbeq   DONE_KI_PRINT				  ; If B=$00, Branch to DONE_NO_DIGITS_PRINT
    rts

KI_PRINT_MESSAGE:

	.ascii 	'ENTER 1024*KI:                     '
    .byte  	$00
    rts               
	   
DONE_KI_PRINT:
	
	ldaa   #$4F
	jsr	   SETADDR
	movb   #$00, KiPromptFlag
	movb   #$01, firstChar
	movb   #$01, digitAllowed				           
    movb   #$01, displayState             ; Return to Display State 1
	rts
	
;===================== Display State 4 - Ki Prompt Print =======================
	
displaystate4:

    ldaa   #$40                           ; Load Accumulator A with LCD Address $07
    ldx    #KP_PRINT_MESSAGE            ; Load Index Register X with Address of NO_DIGITS_PRINT
    jsr    DISPLAY_CHAR   	              ; Jump to Subroutine DISPLAY_CHAR
    ldx    displayPointer                 ; Load X with displayPointer
    ldab   0,x                            ; Load B with the Contents in X
    lbeq   DONE_KP_PRINT				  ; If B=$00, Branch to DONE_NO_DIGITS_PRINT
    rts

KP_PRINT_MESSAGE:

	.ascii 	'ENTER 1024*KP:                     '
    .byte  	$00
    rts               
	   
DONE_KP_PRINT:
	
	ldaa   #$4F
	jsr	   SETADDR
	movb   #$00, KpPromptFlag
	movb   #$01, firstChar
	movb   #$01, digitAllowed		          
    movb   #$01, displayState             ; Return to Display State 1
	rts
	
;================ Display State 5 - Initializing & Printing Digit for Entry ====
	
displaystate5:

	tst	   VRefSignFlag
	lbne   PRINT_INIT
	tst    VRefPos
	lbne   PRINT_POSITIVE
	tst	   VRefNeg
	lbne   PRINT_NEG
	lbra   PRINT_INIT
	
PRINT_POSITIVE:

	ldab   #$2B
	jsr	   OUTCHAR                        ; Print Character Stored in B
	lbra   SIGN_PRINT_DONE
	
PRINT_NEG:
	
	ldab   #$2D
	jsr	   OUTCHAR                        ; Print Character Stored in B
	lbra   SIGN_PRINT_DONE
	
PRINT_INIT:	
	  
    ldaa   digitCounter                   ; Load Accumulator A with digitCounter
    cmpa   #$00                           ; Compare A with $00 
	bne	   DIGIT_NOT_FIRST                ; If A not $00, Branch to DIGIT_NOT_FIRST
	bra	   PRINT_FIRST_DIGIT              ; Otherwise, Branch to PRINT_FIRST_DIGIT
  
PRINT_FIRST_DIGIT:

	ldab   keyStore                     ; Load Accumulator B With digitStore
	jsr	   OUTCHAR                        ; Print Character Stored in B
	bra	   DIGIT_PRINT_DONE               ; Branch to INIT_PRINT_DONE
	   
DIGIT_NOT_FIRST:

	tst	   VRefFlag
	lbne   DIGIT_NOT_FIRST_VREF
	ldaa   digitCounter                   ; Load Accumulator A with digitCounter
	cmpa   #$06                           ; Compare A with $03
    bge    DIGIT_PRINT_DONE               ; If Value in A > $03, Branch to DIGIT_PRINT_DONE
	ldab   keyStore                     ; Load Accumulator B with digitStore
	jsr	   OUTCHAR                        ; Print Character of ASCII Value in Stored in B
	bra	   DIGIT_PRINT_DONE               ; Branch to INIT_PRINT_DONE
	
DIGIT_NOT_FIRST_VREF:

	ldaa   digitCounter                   ; Load Accumulator A with digitCounter
	cmpa   #$04                           ; Compare A with $03
    bge    DIGIT_PRINT_DONE               ; If Value in A > $03, Branch to DIGIT_PRINT_DONE
	ldab   keyStore                     ; Load Accumulator B with digitStore
	jsr	   OUTCHAR                        ; Print Character of ASCII Value in Stored in B
	bra	   DIGIT_PRINT_DONE               ; Branch to INIT_PRINT_DONE 
	
DIGIT_PRINT_DONE:

	clr	   echoFlag                       ; Set echoFlag to FALSE
	movb   #$01, digitFlag
	movb   #$01, displayState              ; Return Back to Display Hub
	rts

SIGN_PRINT_DONE:

	clr	   echoFlag                       ; Set echoFlag to FALSE
	movb   #$01, VRefSignFlag 
	movb   #$01, displayState              ; Return Back to Display Hub
	rts

;============================ Display State 6 - Backspace ======================

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

SIGN_BACKSPACE:

	ldx 	pointer                       ; Load Index Register X with pointer
	dex 	                              ; Decrement Index Register X
	stx		pointer                       ; Store Index Register X into pointer	
	ldab   #$08                           ; Load Accumulator B with ASCII Value of Backspace
	jsr	   OUTCHAR                        ; Moves the Cursor Back One Space On LCD
	movb   #$01, backspaceState           ; Return to backspaceState 1
	movb   #$00, signBackspaceFlag
	rts
	
backspacestate1:

	ldab   #$20                           ; Load Accumulator B with ASCII Value of Space
	jsr	   OUTCHAR                        ; Prints a Space on LCD and Moves the Cursor to Next Address
	movb   #$02, backspaceState           ; Return to backspaceState 2
	rts
		
backspacestate2:	
	
	ldab   	#$08                           ; Load Accumulator B with ASCII Value of Backspace
	jsr	   	OUTCHAR                        ; Moves the Cursor Back One Space On LCD
	movb   	#$00, backspaceState           ; Return to backspace state 0
	movb   	#$01, displayState             ; Return to Display State 1
	clr	   	backspaceFlag                  ; Set backspaceFlag to FALSE
	clr	   	backspacePrint                 ; Set backspaceFlag to FALSE
	rts
  
;===================== Display State 7 - State Variable Print ==================
	   
displaystate7:

       ldaa   stateVariableState  
       deca   
       beq    ON_OFF_PROMPT           
       deca
       beq    OPEN_CLOSED_PROMPT        
       deca
       beq    AUTO_MANUAL_PROMPT
	   movb	  #$01, stateVariableState
	   movb	  #$01, displayState             
       rts 

ON_OFF_PROMPT:

       tst    promptUpFlag
	   lbne	  SKIP_STATE_VARIABLE_PRINT
       tst    RUN    
       lbeq    DISPLAY_STOP_VARIABLE
	   lbra	  DISPLAY_RUN_VARIABLE
	   
OPEN_CLOSED_PROMPT:

	   tst	  loopSetFlag
	   beq	  DISPLAY_CL_VARIABLE
	   bra	  DISPLAY_OL_VARIABLE
	   
AUTO_MANUAL_PROMPT:

	   tst	  autoManualFlag
	   lbne	  DISPLAY_AUTO_VARIABLE
	   lbra	  DISPLAY_MANUAL_VARIABLE
	   
DISPLAY_RUN_VARIABLE:

    ldaa   #$64                           ; Load Accumulator A with $40
    ldx    #RUN_VARIABLE_MESSAGE         ; Load Index Register X with Address of F2_INIT_MESSAGE
    jsr    DISPLAY_CHAR   	              ; Jump to Subroutine DISPLAY_CHAR
    ldx    displayPointer                 ; Load Index Register X with value in displayPointer
    ldab   0,x                            ; Load B with the Contents of X
    lbeq   DONE_RUN_VARIABLE_PRINT         ; If X = $00, Branch to DONE_F2_INIT_PRINT
    rts

RUN_VARIABLE_MESSAGE :

    .ascii 'R'
    .byte  $00               
	rts

DONE_RUN_VARIABLE_PRINT:
 
     movb   #$02, stateVariableState   
     movb   #$01, displayState       
     movb   #$01, firstChar      
     rts	
	
DISPLAY_STOP_VARIABLE:

    ldaa   #$64                           ; Load Accumulator A with $40
    ldx    #STOP_VARIABLE_MESSAGE         ; Load Index Register X with Address of F2_INIT_MESSAGE
    jsr    DISPLAY_CHAR   	              ; Jump to Subroutine DISPLAY_CHAR
    ldx    displayPointer                 ; Load Index Register X with value in displayPointer
    ldab   0,x                            ; Load B with the Contents of X
    lbeq   DONE_STOP_VARIABLE_PRINT       ; If X = $00, Branch to DONE_F2_INIT_PRINT
    rts

STOP_VARIABLE_MESSAGE :

    .ascii 'S'
    .byte  $00               
	rts

DONE_STOP_VARIABLE_PRINT:

       movb   #$02, stateVariableState   
       movb   #$01, displayState       
       movb   #$01, firstChar      
       rts	  
	
DISPLAY_OL_VARIABLE:

    ldaa   #$65                           ; Load Accumulator A with $40
    ldx    #OL_VARIABLE_MESSAGE         ; Load Index Register X with Address of F2_INIT_MESSAGE
    jsr    DISPLAY_CHAR   	              ; Jump to Subroutine DISPLAY_CHAR
    ldx    displayPointer                 ; Load Index Register X with value in displayPointer
    ldab   0,x                            ; Load B with the Contents of X
    lbeq   DONE_OL_VARIABLE_PRINT         ; If X = $00, Branch to DONE_F2_INIT_PRINT
    rts

OL_VARIABLE_MESSAGE :

    .ascii 'OL'
    .byte  $00               
	rts

DONE_OL_VARIABLE_PRINT:

     movb   #$03, stateVariableState   
     movb   #$01, displayState       
     movb   #$01, firstChar      
     rts	
	
DISPLAY_CL_VARIABLE:

    ldaa   #$65                           ; Load Accumulator A with $40
    ldx    #CL_VARIABLE_MESSAGE         ; Load Index Register X with Address of F2_INIT_MESSAGE
    jsr    DISPLAY_CHAR   	              ; Jump to Subroutine DISPLAY_CHAR
    ldx    displayPointer                 ; Load Index Register X with value in displayPointer
    ldab   0,x                            ; Load B with the Contents of X
    lbeq   DONE_CL_VARIABLE_PRINT         ; If X = $00, Branch to DONE_F2_INIT_PRINT
    rts

CL_VARIABLE_MESSAGE :

    .ascii 'CL'
    .byte  $00               
	rts


DONE_CL_VARIABLE_PRINT:

     movb   #$03, stateVariableState   
     movb   #$01, displayState       
     movb   #$01, firstChar      
     rts	
	
DISPLAY_AUTO_VARIABLE:

    ldaa   #$67                           ; Load Accumulator A with $40
    ldx    #AUTO_VARIABLE_MESSAGE         ; Load Index Register X with Address of F2_INIT_MESSAGE
    jsr    DISPLAY_CHAR   	              ; Jump to Subroutine DISPLAY_CHAR
    ldx    displayPointer                 ; Load Index Register X with value in displayPointer
    ldab   0,x                            ; Load B with the Contents of X
    lbeq   DONE_AUTO_VARIABLE_PRINT         ; If X = $00, Branch to DONE_F2_INIT_PRINT
    rts

AUTO_VARIABLE_MESSAGE :

    .ascii 'A'
    .byte  $00               
	rts


DONE_AUTO_VARIABLE_PRINT:

     movb   #$01, stateVariableState 
	 movb   #$00, stateVariableFlag    
     movb   #$01, displayState       
     movb   #$01, firstChar
	 movb	#$00, promptUpFlag      
     rts	
	
DISPLAY_MANUAL_VARIABLE:

    ldaa   #$67                           ; Load Accumulator A with $40
    ldx    #MANUAL_VARIABLE_MESSAGE         ; Load Index Register X with Address of F2_INIT_MESSAGE
    jsr    DISPLAY_CHAR   	              ; Jump to Subroutine DISPLAY_CHAR
    ldx    displayPointer                 ; Load Index Register X with value in displayPointer
    ldab   0,x                            ; Load B with the Contents of X
    lbeq   DONE_MANUAL_VARIABLE_PRINT         ; If X = $00, Branch to DONE_F2_INIT_PRINT
    rts

MANUAL_VARIABLE_MESSAGE :

    .ascii 'M'
    .byte  $00               
	rts


DONE_MANUAL_VARIABLE_PRINT:

     movb   #$01, stateVariableState 
	 movb   #$00, stateVariableFlag    
     movb   #$01, displayState       
     movb   #$01, firstChar
	 movb	#$00, promptUpFlag      
     rts	

SKIP_STATE_VARIABLE_PRINT:

     movb   #$01, stateVariableState 
	 movb   #$00, stateVariableFlag    
     movb   #$01, displayState       
     movb   #$01, firstChar      
     rts	
	 
;===================== Display State 8 -  Update LCD Display ==================
	
displaystate8:
 	
	tst	   autoManualFlag
	beq    UPDATE_LCD_DONE
	         
	tst    promptUpFlag         
    bne    UPDATE_LCD_DONE  	        
	      
    movb   #$00, LCDUpdateFlag       
	   
    jsr    UPDATELCDL1         ; Update the LCD top line
    tst    updateLine2Flag         ; See if I want update LCD Screen Line 2
    beq    UPDATE_LCD_DONE 	   	   
    jsr    UPDATELCDL2         ;Update the LCD bottom line
	movb   #$01, stateVariableFlag
    movb   #$00, updateLine2Flag   ;Clear Update line 2
	   
UPDATE_LCD_DONE:
    movb   #$01, displayState       ; Set next state to: Display HUB
	movb   #$01, stateVariableFlag
    movb   #$00, LCDUpdateFlag       ; Clear LCD flag
    rts	  
	   
;=========  Display - Miscellaneous Sub-Rountines / Branches   =================

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
	
	addd   #$3E80                       ; Adds Interval Value 800 to Current Timer Count
	
	std    TC0H						    ; Stores Interval + TCNT
	   
	rts                                 ; Return from Subroutine
	
;================== Timer Channel 0 State 1 - Arbitrary State ==================

tc0state1:

	rts   	                            ; Return from Subroutine
	
;==================== Interrupt Service Routine & Branches =====================
	  
TC0_ISR:
   
       ldd    V_Ref                
       tst    loopSetFlag
       bne    SKIPtoOPEN_LOOP
       subd   V_Act                ; Subtract VACT from VREF
	   bmi    SET_ERROR_NEW_NEG
	   bra    SKIPtoOPEN_LOOP
	   
SET_ERROR_NEW_NEG:
       movb    #$01, errorSign
	   	   
SKIPtoOPEN_LOOP:   
       std    New_Error           ; Store into ERROR_NEW
       addd   E_Sum           ; Add ERROR_SUM to ERROR_NEW
       bvc    VALID_ESUM          ; Exit if no overflow from ERROR_SUM+ERROR_NEW
       tst    E_Sum           ; If overflow, determine sign of ERROR_SUM and
       bmi    NEG_ESUM            ; saturate accordingly.
       ldd    #$7FFF            ; Load D with maximum positive value: 32,767
       bra    VALID_ESUM          ; Branch now that ESUM is valid
NEG_ESUM:
       ldd    #8000            ; Load D with maximum negative value: -32,768
	      
VALID_ESUM:                       ; Calculation for KI*ERROR_SUM	
       std    E_Sum           ; Store value in D into ERROR_SUM
       tst    RUN
       bne    KEEP_ERROR_SUM      ; If RUN = TRUE, keep current ERROR_SUM
       movw   #$0000, E_Sum   ; If RUN = FALSE, set ERROR_SUM to $0000
       ldd    E_Sum           ; Load D with ERROR_SUM
    
KEEP_ERROR_SUM:
       ldy    Ki                  ; Load Y with KI
       emuls                      ; (D)x(Y) ==> Y:D
       ldx    #$400               ; Load X with value of 1024
       edivs                      ; (Y:D)/X ==> Result into Y, Remainder ==> D

       sty    Kidivs              	
	    
; Calculation for KP*ERROR_NEW	      
       ldd    New_Error           ; Load D with ERROR_NEW
       ldy    Kp                  ; Load Y with KP
       emuls                      ; (D)x(Y) ==> Y:D
       ldx    #$400               ; Load X with value of 1024
       edivs                      ; (Y:D)/X ==> Result into Y, Remainder ==> D
   ; check saturation by checking V flag, if V=1 then saturate to largest pos or neg, check sign of ERROR_NEW, if + then pos sat, if - then neg sat	   
       sty    Kpdivs                 ; Store result into KPE		      
       ldd    Kpdivs                 ; Load D with KPE
       tst    Ki
       beq    DESTROY_KIDIVS
       addd   Kidivs                 ; Add KPE to KIE
	   
DESTROY_KIDIVS:
       addd   #$0000              ; In the KI=0 case, need to add to set V flag	   
       bvc    VALID_a             ; Exit if no overflow from KPE+KIE
       tst    Kidivs                 ; If overflow, determine sign of KIE and
       bmi    NEG_a               ; saturate accordingly.
       ldd    #$7FFF           ; Load D with maximum positive value: 32,767
       bra    VALID_a             ; Branch now that "a" is valid
NEG_a:
       ldd    #$8000          ; Load D with maximum negative value: -32,768	   
	   
VALID_a:
       std    A_Prime
       tst    RUN
       beq    MOTOR_STOP          ; If RUN=0, branch to MOTOR_STOP  
       addd   #$099A               ; Add 2458 for 6 Volt offset     
       bvc    VALID_a_prime       ; Branch now that "a prime" is valid
       tst    A_Prime
       bmi    NEG_a_prime
       ldd    #$7FFF            ; Load D with maximum positive value: 32,767
       bra    VALID_a_prime       ; Branch now that "a prime" is valid
	   
NEG_a_prime:
       ldd    #8000            ; Load D with maximum negative value: -32,768
	   	   
VALID_a_prime:	          
       cpd    #$0D9A              ; Compare D to 3482
       bpl    VDAC8.5             ; If greater than, branch to VDAC8.5
       cpd    #$59A               ; Compare D to 1434
       bmi    VDAC3.5             ; If less than, branch to VDAC3.5
       std    Dac_Value 	          ; Store D into VALUE
       bra    exit_PI_CONTROL   
	   
MOTOR_STOP:
       movw   #$99A, Dac_Value        ; 6.0V (2458)
       bra    exit_PI_CONTROL
VDAC8.5:
       movw   #$D9A, Dac_Value        ; 8.5V (3482) 
       bra    exit_PI_CONTROL   
VDAC3.5:	   
       movw   #$59A, Dac_Value        ; 3.5V (1434)	
       bra    exit_PI_CONTROL
	   
exit_PI_CONTROL:
       jsr    EFFORT_CALC
       bra    ENCODER_READ
	   
EFFORT_CALC:
       ldd   #$7805               ; Load D with $7805 = 30725
       ldx   #$80                 ; Load X with $80 = 128
       ldy   #$0000               ; Clear Y
       edivs                      ; (Y:D)/X ==> Result into Y, Remainder ==> D
       sty   bConstant              ; Store result into B_CONST
       ldy   #$19                 ; Load Y with $19 = 25
       ldd   Dac_Value                ; Load D with VALUE(DAC n value)
       emuls                      ; Multiply Y and D and the result into Y:D
       ldx   #$100                ; Load X with $100 = 256
       edivs                      ; (Y:D)/X ==> Result into Y, Remainder ==> D
       sty   slopeTimesDacValue          ; Store Y into MtimesVALUE
       ldd   slopeTimesDacValue          ; Load D with MtimesVALUE
       subd  bConstant              ; Subtract B_CONST from D
	   bmi   SET_EFFORT_NEG       ; If resulting EFFORT is neg, branch SET_EFFORT_NEG
	   bra   SKIP_NEGATING_EFFORT ; If positive, branch SKIP_NEGATING_EFFORT
	   
SET_EFFORT_NEG:	  
 
       movb  #$01, effortSign     ; Set error sign to negative
	   
SKIP_NEGATING_EFFORT:	
   
       std   Effort               ; Store D into EFFORT
       rts

ENCODER_READ:	   
	   ldd    ENCODER               ; Load D with current ENCODER value (THETA_NEW)
       std    Theta_New
       subd   Theta_Old             ; Subtract THETA_OLD from D
	   bmi    SET_VACT_NEG
	   bra    SKIP_NEGATING_VACT
	   
SET_VACT_NEG:
       movb   #$01, VActSign
	   
SKIP_NEGATING_VACT:	
   	   
       std    V_Act                
       movw   Theta_New,Theta_Old 
       movb   #$01, VActFlag    
       movb   #$01, errorFlag    
       movb   #$01, effortFlag    
	   movb   #$01, updateValuesFlag    
 
OUTDAC:

   ldd     Dac_Value                      ; Load Accumulator D With VALUE
   staa    $0301                          ; Store Address of DACs MSB in A
   stab    $0300                          ; Store Address of DACs LSB in B
   bclr    PORTJ, pin5                    ; Clear pin 5 in Port J
   bset    PORTJ, pin5                    ; Set pin 5 in Port J
   ldd     Dac_Value                      ; Load Accumulator D With VALUE
   staa    $0303                          ; Store Address of DACs MSB in A
   stab    $0302                          ; Store Address of DACs LSB in B
   bclr    PORTJ, pin5                    ; Clear pin 5 in Port J
   bset    PORTJ, pin5                    ; Set pin 5 in Port J
   
FINAL_ISR_CHECK:
  
    tst		LCDUpdateCounter
	bne	    NOT_YET
	dec		LCDUpdateCounter
	movb	#$01, LCDUpdateFlag
	bra	    ISR_DONE 
	
NOT_YET:
    
	dec	    LCDUpdateCounter
	bra	    ISR_DONE
	
ISR_DONE:
 
  	ldd	  	TC0H				; Grab the Timer Count Corresponding to ISR
  	addd 	#$3E80				; Add the Interval to The Current Timer Count
  	std		TC0H				; Store the New Timer Count Into the TC0 CR
  	ldaa 	TFLG1               ; LOAD TIMER FLAG ONTO ACC. A
  	oraa 	#01                 ; CLEAR CONTENTS (TIMER FLAG) OF ACC. A
  	staa 	TFLG1               ; LOAD ACC. A BACK INTO TIMER FLAG
	rti
  	  
  	   
;===============================================================================

.area interrupt_vectors (abs)
	  .org   $FFEE                        ; Address of Next Interrupt        
	  .word  TC0_ISR                      ; Load Interrupt Address
	  .org    $FFFE                       ; At Reset Vector Location
	  .word   __start                     ; Load Starting Address