; Robert Cory Molloy & Oscar Andrade
; ME 305 - 02 :: Intro to Mechatronics
; Labratory 5 :: Motor Controller 

;==================== Assembler Equates ====================

ENCODER		       		= $0280				; Encoder Address 
PORTJ              		= $0028             ; Port J Address
DDRJ	   		   	= $0029             ; Make Port J an Output Address
pin5           	   		= 0b00010000        ; Pin 5 of Port J
TIOS               		= $0080             ; Timer Output Compare Address
TFLG1              		= $008E             ; Timer Flag Register Address
TSCR               		= $0086             ; Timer System Control Register Address
TC0H               		= $0090             ; Timer Channel Zero High Address
TCNT               		= $0084             ; Timer Count Register High and Low Address
TMSK1              		= $008C             ; Timer Mask Address
TCTL2              		= $0089             ; Timer Control Register Address
VREF_BUF		   	= $BB2			    ; Buffer Address for Reference Velocity
VACT_BUF		   	= $BB6			    ; Buffer Address for Actual Velocity
ERROR_BUF		   	= $BBA			    ; Buffer Address for Calculated Error
EFFORT_BUF		   	= $BBE				; Buffer Address for Calculated Effort
KI_BUF		   	   	= $BC2              ; Buffer Address for Integral Constant
KP_BUF		   	   	= $BC7			 	; Buffer Address for Proportional Constant

;==================== RAM area ====================
.area bss

; Task Variables

mmState::			.blkb 1				; Master Mind State Variable
kpdState::			.blkb 1    			; Key Pad Driver State Variable
displayState::			.blkb 1   			; Display State Variable
backspaceState::		.blkb 1				; Backspace State Variable
stateVariableState::		.blkb 1				; State Variable State Variable
tc0State::			.blkb 1				; Timer Channel Zero State Variable

; ISR Variables

V_Ref::             	.blkb 2    			; Voltage Reference Inputted By User [BDI/BTI]
V_Act::             	.blkb 2     		; Actual Voltage at Encoder
Error::     			.blkb 2    			; V_Ref - V_act
E_Sum::             	.blkb 2     		; Integral Error Sum
KiplusKp::          	.blkb 2     		; (Kp*Error)+(Ki/s*Esum)
A_Prime::           	.blkb 2     		; [A +/- 2458]
A_Star::            	.blkb 2     		; Dac Value 
Ki::                	.blkb 2     		; Integral Control
oldKi::					.blkb 2				; Old Integral Control
Kp::                	.blkb 2     		; Proportional Control
Kpdivs::            	.blkb 2     		; Kp*Error, After edivs Command
Kidivs::            	.blkb 2     		; Ki*Esum, After edivs Command
Dac_Value::         	.blkb 2    			; Voltage Value to be Fed to DAC
Theta_New::         	.blkb 2     		; New Displacment Interval Read from Encoder
Theta_Old::         	.blkb 2     		; Previous Displacement Interval Read from Encoder
Effort::				.blkb 2     		; Value for Calculated Effort  
slopeTimesDacValue::	.blkb 2				;
bConstant::				.blkb 2				;
DAC_PLUS_FIVE::         .blkb 2 
SS_ERROR::              .blkb 2

;==================== Storing Variables ====================

keyStore::				.blkb 1				; Stores Most Recent Digit Pressed
buffer::				.blkb 6				; Stores All Digits for Processing to Value
result::				.blkb 2				; Stores Converted ASCII Numbers Before Push to Value
updateBuffer::			.blkb 5				; Stores BCD Converted Value to Convert to ASCII Values
updateResult::			.blkb 2				; Stores Converted BCD to ASCII Values for Template Buffers
stateVariable::			.blkb 1
Dac_ValueMinusSixVolts::.blkb 2
Dac_ValueTimesHundred:: .blkb 2

;==================== Counter Variables ====================

digitCounter::			.blkb 1				; Counts Up Current Digits Input into Buffer
updateCounter::			.blkb 1				; Counts Up to See if All BCD to ASCII Values Are Done 
LCDUpdateCounter::		.blkb 1				; Counts Down From 256 to 0 Interrupts to Update the Template

;==================== Flag Variables ====================

keyFlag::				.blkb 1				; Notifies Program a Key Has Been Pressed
echoFlag::				.blkb 1				; Notifies Program that a Key Needs to Be Echoed
enterFlag::				.blkb 1				; Notifies Program that Enter Procedure is Done
firstChar::				.blkb 1				; Notifies Program the First Character is Ready
backspaceFlag::			.blkb 1				; Notifies Program that a Entered Digit Needs to Be Cleared
digitFlag::				.blkb 1				;
charFlag::				.blkb 1				;

RUN::		        	.blkb 1				; Notifies The Program That The DAC Can Recieve Voltage
loopSetFlag::			.blkb 1				; Nofities The Program That The Loop is Open or Closed
stateVariableFlag::		.blkb 1 			; Notifies The Program That That The State Variables Need to Be Updated
autoManualFlag::		.blkb 1 			; Notifies The Program Whether the Template Updates Automatically Or Manually
LCDUpdateFlag::			.blkb 1				; Notifies The Program to Update the LCD Template

VRefFlag::		  		.blkb 1				; Notifies The Program The VRef (C Key) Was Pressed
VActFlag::				.blkb 1				; Notifies The Program The VAct is Ready to Be Updated
effortFlag::			.blkb 1				; Notifies The Program The Effort is Ready to Be Updated
errorFlag::		    	.blkb 1				; Notifies The Program The Error is Ready to Be Updated
KiFlag::      	  		.blkb 1				; Notifies The Program That KI is Ready to Be Updated
KpFlag::      	 		.blkb 1				; Notifies The Program That KP is Ready to Be Updated

AFlag::					.blkb 1				; Notifies The Program That A Has Been Pressed
BFlag::					.blkb 1				; Notifies The Program That B Has Been Pressed
CFlag::					.blkb 1				; Notifies The Program That C Has Been Pressed
DFlag::					.blkb 1				; Notifies The Program That D Has Been Pressed
EFlag::					.blkb 1				; Notifies The Program That E Has Been Pressed
FFlag::					.blkb 1				; Notifies The Program That F Has Been Pressed
firstKiFlag::			.blkb 1


onPrintFlag::			.blkb 1				; Notifies The Program That the R State Var. Should Be Printed
offPrintFlag::			.blkb 1				; Notifies The Program That the S State Var. Should Be Printed
openLoopPrintFlag::	 	.blkb 1				; Notifies The Program That the OL State Var. Should Be Printed
closedLoopPrintFlag::	.blkb 1				; Notifies The Program That the CL State Var. Should Be Printed
autoPrintFlag::			.blkb 1				; Notifies The Program That the A State Var. Should Be Printed
manualPrintFlag::		.blkb 1				; Notifies The Program That the M State Var. Should Be Printed
VRefNegPrintFlag::	   	.blkb 1				; Notifies The Program That the '+' Should Be Printed
VRefPosPrintFlag::		.blkb 1				; Notifies The Program That the '-' Should Be Printed
backspacePrint::		.blkb 1				; Notifies The Program That a Backspace Should Be Printed

VRefPromptFlag::		.blkb 1				; Notifies The Program to Print the VRef Prompt
KiPromptFlag::			.blkb 1				; Notifies The Program to Print the Ki Prompt
KpPromptFlag::			.blkb 1				; Notifies The Program to Print the Kp Prompt

digitAllowed::			.blkb 1				; Notifies The Program That A Digit is or is not Allowed to Be Entered
VRefSignFlag::			.blkb 1				; Notifies The Program That A '+' or '-' Has Been Entered 

updateValuesFlag::		.blkb 1				; Notifies The Program to Update the Template Values
updateLine1Flag::		.blkb 1				; Notifies The Program to Update Line 1 in the Template
updateLine2Flag::		.blkb 1				; Notifies The Program to Update Line 2 in the Template

promptUpFlag::			.blkb 1				; Notifies The Program That a Prompt Has Been Printed

; Sign Variables

VRefSign::				.blkb 1				; Notifies The Program If VRef is '+' or '-'
VActSign::				.blkb 1				; Notifies The Program If VAct is '+' or '-'
effortSign::			.blkb 1				; Notifies The Program If Effort is '+' or '-'
errorSign::				.blkb 1				; Notifies The Program If Error is '+' or '-'

; Other Variables

pointer::		    	.blkb 2    			; Holds the Next Address of buffer
updatePointer::			.blkb 2				; Holds the Next Address of updateBuffer	
displayPointer::		.blkb 2     		; Holds the Next ASCII Value to Be Printed

;==================== Flash ====================

.area text

;==================================  Main Program  =============================

_main::
 
	jsr    	INIT        		; Initialization
 
TOP: 
bgnd
	jsr    	MASTERMIND			; Mastermind Sub-Routines
 
	jsr    	KPD		  			; Key Pad Driver Sub-Routines
 
	jsr    	DISPLAY      		; Display Sub-Routines
 
	jsr		TIMER_C0        	; Timer Channel Zero Sub-Routines

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
	lbeq	mmstate6			; Character State
	deca	
	lbeq    mmstate7			; Update Values State
	rts							; Return to Main 

;=========== Mastermind State 0 - Initialization of Mastermind & Buffer ========

mmstate0:	
	
	jsr		CLEAR_TEMPLATE						; Clear the LCD Template Buffers
	clr		buffer					    	 	; Clear the buffer Variable
	clr		updateBuffer						; Clear the updateBuffer Variable				
	movw    #buffer, pointer 		   			; Stores the First Address of buffer into pointer
	movw    #updateBuffer, updatePointer 		; Stores the First Address of updateBuffer into updatePointer
	movb  	#$00, RUN           				; Motor stop at Intialization
    movw   	#$0019, V_Ref       				; Set Initial V_Ref value $19=25
    movw   	#$0400, Ki           				; Set Initial Ki value $400=1024=1024(1)
	movw   	#$0400, oldKi           				; Set Initial Ki value $400=1024=1024(1)
    movw   	#$1400, Kp          				; Set Initial Kp value $1400=5120=1024(5)
	movb	#$01, autoManualFlag				; Set the AutoManualFlag to Auto
	movb	#$01, mmState	   					; Set the Mastermind State Variable to 1    
	rts											; Return to Main

;====  Mastermind State 1 - Splash Screen and Setting Displays Flags & Counters  =========

mmstate1:

	movb   #$01, firstChar     	     			; Set firstChar to 1 (True) 
    movb   #$01, VRefFlag      					; Set VRefFlag to 1 (True) 
	movb   #$01, KiFlag      					; Set KiFlag to 1 (True) 
	movb   #$01, KpFlag      					; Set KpFlag to 1 (True) 
	movb   #$01, VActFlag      					; Set VActFlag to 1 (True) 
	movb   #$01, errorFlag						; Set errorFlag to 1 (True) 
	movb   #$01, effortFlag						; Set VRefFlag to 1 (True) 
	movb   #$01, offPrintFlag					; Set offPrintFlag to 1 (True) 
	movb   #$01, closedLoopPrintFlag			; Set closedLoopPrintFlag to 1 (True) 
	movb   #$01, autoPrintFlag					; Set autoPrintFlag to 1 (True) 
	movb   #$01, updateValuesFlag				; Set updateValuesFlag to 1 (True) 
	movb   #$02, mmState			   			; Set the Mastermind State Variable to 2 (Hub)
	rts								    		; Return to Main

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
	lbne	BACKSPACE_GO                 ; If backspaceFlag Not 0 (False), Branch to BACKSPACE_GO
	tst		enterFlag                    ; Test enterFlag
	lbne	ENTER_GO                     ; If enterFlag Not 0 (False), Branch to ENTER_GO
	tst		digitFlag                    ; Test digitFlag
	lbne	DIGIT_GO                     ; If digitFlag Not 0 (False), Branch to DIGIT_GO
	tst		charFlag                     ; Test charFlag
	lbne	CHAR_GO                      ; If charFlag Not 0 (False), Branch to CHAR_GO
	tst		updateValuesFlag			 ; Test updateValuesFlag
	lbne	UPDATE_VALUES_GO			 ; If updateValuesFlag Not $00, Branch to UPDATE_VALUES_GO
	movb 	#$02, mmState                ; If No Key was Pressed, Return to Hub
	rts									 ; Return to Main
	
F1_TRUE:

    tst		promptUpFlag
	beq		F1_DONE
	tst		VRefSignFlag				 ; Test VRefSignFlag
	bne		F1_DONE						 ; If VRefSignFlag is 0 (False), Branch to F1_DONE
	tst		digitCounter				 ; Test digitCounter
	bne		F1_DONE						 ; If digitCounter is 0 (False), Branch to F1_DONE
	movb	#$01, VRefPosPrintFlag		 ; Set VRefPosPrintFlag to 1 (True)
	movb	#$00, VRefSign				 ; Set VRefSign to 0 (False)
	movb	#$01, echoFlag				 ; Set echoFlag to 1 (True)
	movb 	#$02, mmState                ; Set the Mastermind State Variable to 2 (Hub)
	rts									 ; Return to Main

F1_DONE:
	
	movb 	#$02, mmState                ; Set the Mastermind State Variable to 2 (Hub)
	rts									 ; Return to Main
		
F2_TRUE:

    tst		promptUpFlag
	beq		F2_DONE
	tst		VRefSignFlag				 ; Test VRefSignFlag
	bne		F2_DONE						 ; If VRefSignFlag is 0 (False), Branch to F2_DONE
	tst		digitCounter				 ; Test digitCounter
	bne		F2_DONE						 ; If digitCounter is 0 (False), Branch to F2_DONE
	movb	#$01, VRefNegPrintFlag		 ; Set VRefPosPrintFlag to 1 (True)
	movb	#$01, VRefSign				 ; Set VRefSign to 0 (False)
	movb	#$01, echoFlag				 ; Set echoFlag to 1 (True)
	movb 	#$02, mmState                ; Set the Mastermind State Variable to 2 (Hub) 
	rts									 ; Return to Main

F2_DONE:
	
	movb 	#$02, mmState                ; Set the Mastermind State Variable to 2 (Hub) 
	rts									 ; Return to Main

BS_TRUE:
	
	movb 	#$01, backspaceFlag          ; Set backspaceFlag to 1 (True)
	rts									 ; Return to Main
	
ENT_TRUE:
	
	movb 	#$01, enterFlag              ; Set enterFlag to 1 (True)
	rts									 ; Return to Main

DIGIT_TRUE:
		   
	movb 	#$01, digitFlag              ; Set digitFlag to 1 (True)
	rts									 ; Return to Main

A_TRUE:

	movb	#$01, charFlag				 ; Set charFlag to 1 (True)
	movb	#$01, AFlag					 ; Set AFlag to 1 (True)
	rts									 ; Return to Main
	
B_TRUE:

	movb	#$01, charFlag				 ; Set charFlag to 1 (True)
	movb	#$01, BFlag					 ; Set BFlag to 1 (True)
	rts									 ; Return to Main
	
C_TRUE:

	movb	#$01, charFlag			 	 ; Set charFlag to 1 (True)
	movb	#$01, CFlag					 ; Set CFlag to 1 (True)
	movb    #$01, promptUpFlag			 ; Set promptUpFlag to 1 (True)
	rts									 ; Return to Main
	
D_TRUE:

	movb	#$01, charFlag				 ; Set charFlag to 1 (True)
	movb	#$01, DFlag					 ; Set DFlag to 1 (True)
	movb    #$01, promptUpFlag			 ; Set promptUpFlag to 1 (True)
	rts									 ; Return to Main
	
E_TRUE:

	movb	#$01, charFlag				 ; Set charFlag to 1 (True)
	movb	#$01, EFlag					 ; Set EFlag to 1 (True)
	movb    #$01, promptUpFlag			 ; Set promptUpFlag to 1 (True)
	rts									 ; Return to Main

F_TRUE:

	movb	#$01, charFlag				 ; Set charFlag to 1 (True)
	movb	#$01, FFlag					 ; Set EFlag to 1 (True)
	rts									 ; Return to Main
	
	
BACKSPACE_GO:

	movb 	#$03, mmState                ; Set next Mastermind State (mmstate) to Backspace
	rts									 ; Return to Main
	
ENTER_GO:

	movb 	#$04, mmState                ; Set next Mastermind State (mmstate) to Enter
	rts									 ; Return to Main
		
DIGIT_GO:
	
	clr     digitFlag					 ; Clear the digitFlag
	movb 	#$05, mmState                ; Set next Mastermind State (mmstate) to Digit
	rts									 ; Return to Main
	
CHAR_GO:

    clr	 	charFlag				 	 ; Clear the charFlag
	movb 	#$06, mmState                ; Set next Mastermind State (mmstate) to Character
	rts									 ; Return to Main

UPDATE_VALUES_GO:

    clr	 	updateValuesFlag			 ; Clear the updateValuesFlag
	movb 	#$07, mmState                ; Set next Mastermind State (mmstate) to Update Values
	rts									 ; Return to Main

	
;===================== Mastermind State 3 - Backspace State ====================

mmstate3:

	tst     VRefSignFlag				 ; Test the VRefSignFlag
	bne     BACKSPACE_SIGN				 ; If VRefSignFlag is 1 (True), Branch to BACKSPACE_SIGN
	tst  	digitCounter                 ; Test digitCounter
	beq 	BACKSPACE_DONE               ; If digitCounter is 0, Branch to BSPACE_DONE
	tst 	backspaceFlag                ; Test backspaceFlag
	beq 	BACKSPACE_DONE               ; If backspaceFlag is 0 (False), Branch to BSPACE_DONE
	bra 	BACKSPACE_SET				 ; Branch Always to BACKSPACE_SET

BACKSPACE_SIGN:

    movb	#$00, VRefSignFlag			 ; Set VRefSignFlag to 0 (False)
    movb	#$01, backspacePrint		 ; Set backspacePrint to 1 (True)
    rts								 	 ; Return to Main

BACKSPACE_SET:

	movb 	#$01, backspacePrint         ; Set backspacePrint to 1 (True)
	rts									 ; Return to Main	
	
BACKSPACE_DONE:

	movb	#$00, backspaceFlag			 ; Set backspaceFlag to 1 (True)
	movb 	#$02, mmState                ; Set the Mastermind State Variable to 2 (Hub)
	rts								     ; Return to Main

;===================== Mastermind State 4 - Enter State ========================

mmstate4:

	tst	 	enterFlag					 ; Test the enterFlag
	bne		ENTER_INIT					 ; If enterFlag is 1 (True), Branch to ENTER_INIT
	lbeq	ENTER_DONE					 ; If enterFlag is 0 (False), Branch to ENTER_DONE
		
ENTER_INIT:
		
	tst 	digitCounter                  ; Test digitCounter
	lbeq 	EMPTY_VALUE                   ; If digitCounter is 0 (False), Branch to EMPTY_VALUE
	bra 	ASCII_BCD                     ; Otherwise Branch to ASCII_BCD

ASCII_BCD:

	movw    #buffer, pointer              ; Load First Address of buffer into pointer
	movw	#$0000, result                ; Clear the Value of result
		
	LOOP:

		ldy 	#$0A                      ; Load Accumulator A with 10    
		ldd 	result                    ; Load Accumulator B with result    
		emul                              ; Multiply A and B, Store in A:B or D
		cmpy 	#$0000                    ; Compare Accumulator D with 0 
		bne 	TOO_BIG_VALUE          	  ; If a Carry Present in Y, Branch to TOO_BIG_VALUE
		std 	result                    ; Store Accumulator D into result    
		ldx 	pointer                   ; Load X with buffer Address Stored In pointer    
		ldab 	0,x                       ; Load Accumulator B with the Contents in X  
		subb 	#$30                      ; Subtract 30 From Accumulator B  
		clra                              ; Clear Accumulator A 
		addd 	result                    ; Add result To B and Store Back Into B
		bvs 	TOO_BIG_VALUE		      ; If greater than 32767 hex, Branch to TOO_BIG_VALUE  
		std 	result                    ; Store D in result 
		dec 	digitCounter              ; Decrement digitCounter
		tst		digitCounter              ; Test digitCounter         
		beq 	VALUE_PUSH_MAIN           ; If digitCounter is zero, Branch to VALUE_PUSH_MAIN        
		inx                               ; Increment Address in X
		stx		pointer                   ; Store Address In X Into Pointer
		bra 	LOOP                      ; Branch Back Into LOOP         	
	
VALUE_PUSH_MAIN:

    tst		VRefFlag					  ; Test VRefFlag
	bne		VREF_STORE					  ; If VRefFlag is 1 (True), Branch to VREF_STORE
	tst		KiFlag						  ; Test KiFlag
	bne		KI_STORE					  ; If KiFlag is 1 (True), Branch to KI_STORE
	tst		KpFlag						  ; Test KpFlag
	bne    	KP_STORE					  ; If KpFlag is 1 (True), Branch to KP_STORE
	lbra	ENTER_DONE                    ; Otherwise Branch To ENTER_DONE
	
TOO_BIG_VALUE:

	movw	 #$7FFF, result				  ; Load $7FFF (32767) to result
	bra		 VALUE_PUSH_MAIN			  ; Branch Always to VALUE_PUSH_MAIN
		
EMPTY_VALUE:
	
	movw	#$0000, result                ; Clear the Value of result
	movw    #buffer, pointer              ; Move The First Address of buffer into Pointer
	clr	    digitCounter                  ; Clear the digitCounter
	movb	#$00, enterFlag               ; Set enterFlag to 1 (True)
	rts		                              ; Return to Main

VREF_STORE:

    tst	   VRefSign						  ; Test VRefSign
	bne	   VREF_NEG_STORE                 ; If VRefFlag is 1 (Negative), Branch to VREF_NEG_STORE
	movw   result, V_Ref				  ; Move the Value of result into V_Ref
	movb   #$01, VRefFlag				  ; Set VRefFlag to 1 (True)
	bra	   ENTER_DONE 					  ; Branch Always to ENTER_DONE

VREF_NEG_STORE:

    ldd     #$0000             			  ; Load D with $0000 (0)
    subd    result             			  ; Subracting result from $0000 (0) to Return Neg Value
	std     V_Ref						  ; Storing D into V_Ref
	movb	#$01, VRefFlag				  ; Set VRefFlag to 1 (True)
	bra		ENTER_DONE 					  ; Branch Always to ENTER_DONE
	
KI_STORE: ; MIGHT BE REDUNDANT SO WE NEED TO TEST

    ldx     #$7FFF						  ; Load X with $7FFF (32767)
    cpx		result						  ; Compare X with the Value of result
    bpl     NO_KI_SATURATION			  ; If result is Less Than $7FFF (32767), Branch to NO_KI_SATURATION
	movw	#$7FFF, Ki					  ; Storing $7FFF (32767) into Ki
	movb	#$01, KiFlag				  ; Set KiFlag to 1 (True)	 
	bra		ENTER_DONE 					  ; Branch Always to ENTER_DONE

NO_KI_SATURATION:

	movw	result, Ki					  ; Move the Value in result into Ki
	movw	result, oldKi				  ; Move the Value in result into oldKi
	movb	#$01, KiFlag				  ; Set KiFlag to 1 (True)
	bra 	ENTER_DONE					  ; Branch Always to ENTER_DONE

KP_STORE: ; MIGHT BE REDUNDANT SO WE NEED TO TEST
    
    ldx     #$7FFF						  ; Load X with $7FFF (32767)
    cpx     result						  ; Compare X with the Value of result
    bpl     NO_KP_SATURATION			  ; If result is Less Than $7FFF (32767), Branch to NO_KP_SATURATION
	movw	#$7fff, Kp					  ; Storing $7FFF (32767) into Kp
	movb	#$01, KpFlag				  ; Set KpFlag to 1 (True)
	bra		ENTER_DONE  				  ; Branch Always to ENTER_DONE
	
NO_KP_SATURATION:

	movw	result, Kp				      ; Move the Value in result into Kp
	movb	#$01, KpFlag				  ; Set KpFlag to 1 (True)
    bra 	ENTER_DONE					  ; Branch Always to ENTER_DONE

ENTER_DONE:

	movw	#$0000, result                ; Clear the Value of result
	clr	    digitCounter                  ; Clear the digitCounter
	movw    #buffer, pointer              ; Move the First Address of buffer into pointer
	movb	#$00, enterFlag               ; Set KpFlag to 1 (True)
	movb	#$00, digitAllowed			  ; Set digitAllowed to 1 (True)
	movb    #$00, promptUpFlag			  ; Set promptUpFlag to 1 (True)		   
	movb	#$01, updateValuesFlag		  ; Set updateValuesFlag to 1 (True)	
	movb	#$01, updateLine2Flag		  ; Set KpFlag to 1 (True)
	movb    #$01, LCDUpdateFlag			  ; Set KpFlag to 1 (True)
	movb    #$01, updateValuesFlag		  ; Set KpFlag to 1 (True)
	movb    #$00, promptUpFlag			  ; Set KpFlag to 1 (True)
	movb    #$00, VRefSignFlag			  ; Set KpFlag to 1 (True)
	movb	#$02, mmState				  ; Set the Mastermind State Variable to 2 (Hub)			              
	rts 

;====================  Mastermind State 5 - Digit Entered   ====================

mmstate5:

	tst		digitAllowed				  ; Test digitAllowed
	lbeq	DIGIT_DONE					  ; If digitAllowed is 0 (Not Allowed), Branch to DIGIT_DONE
	tst		digitFlag					  ; Test digitFlag
	bne		DIGIT_WAIT					  ; If digitAllowed is 1 (True), Branch to DIGIT_WAIT
	cmpb	#$41				          ; Compare Hexadecimal Value In B to $41
	lblo	DIGIT				          ; If Value in B < $40, Branch to DIGIT
	bra		NOTDIGIT			          ; Otherwise Value in B is not a Digit, Branch to NOTDIGIT
  
DIGIT:

	movb	#$01, digitFlag				  ; Set KpFlag to 1 (True)
	lbra	BUFFER_STORE                  ; Branch Always BUFFER_STORE

NOTDIGIT:

	movb	#$00, keyFlag	              ; Set KpFlag to 0 (False)
	movb	#$02, mmState				  ; Set the Mastermind State Variable to 2 (Hub)
	rts									  ; Return to Main

DIGIT_WAIT:

	tst     echoFlag					  ; Set KpFlag to 0 (False)
	lbeq	DIGIT_DONE				      ; If echoFlag is 0 (False), Branch to DIGIT_DONE
	rts									  ; Return to Main
	
DIGIT_DONE:

    movb   	#$00, digitFlag				  ; Set digitFlag to 0 (False)
	movb 	#$02, mmState                 ; Set the Mastermind State Variable to 2 (Hub)
	rts 								  ; Return to Main

;===================== Mastermind State 6 - Character Entered ==================

mmstate6:

    tst   	VRefFlag					  ; Test VRefFlag
	lbne   	VALUE_CHAR_DONE				  ; If VRefFlag is 1 (True), Branch to VALUE_CHAR_DONE
	tst   	KiFlag						  ; Test KiFlag
	lbne   	VALUE_CHAR_DONE				  ; If KiFlag is 1 (True), Branch to VALUE_CHAR_DONE
	tst   	KpFlag						  ; Test KpFlag
	lbne   	VALUE_CHAR_DONE				  ; If KpFlag is 1 (True), Branch to VALUE_CHAR_DONE
	tst   	AFlag						  ; Test AFlag
	lbne   	AFLAG_GO					  ; If AFlag is 1 (True), Branch to AFLAG_GO
	tst   	BFlag						  ; Test BFlag
	lbne   	BFLAG_GO					  ; If BFlag is 1 (True), Branch to BFLAG_GO		
	tst   	CFlag						  ; Test CFlag
	lbne   	CFLAG_GO					  ; If CFlag is 1 (True), Branch to CFLAG_GO
	tst   	DFlag						  ; Test DFlag
	lbne   	DFLAG_GO					  ; If DFlag is 1 (True), Branch to DFLAG_GO
	tst   	EFlag						  ; Test EFlag
	lbne   	EFLAG_GO				      ; If EFlag is 1 (True), Branch to EFLAG_GO
	tst   	FFlag						  ; Test FFlag
	lbne   	FFLAG_GO					  ; If FFlag is 1 (True), Branch to FFLAG_GO
	movb   	#$02, mmState				  ; Set the Mastermind State Variable to 2 (Hub)
	rts 								  ; Return to Main				
	
AFLAG_GO:

    tst   	RUN							  ; Test RUN
	lbne   	MOTOR_OFF					  ; If RUN is 1 (Off), Branch to MOTOR_OFF
	lbra   	MOTOR_ON					  ; Branch Always to MOTOR_ON
	
MOTOR_OFF:
	
	movb   	#$00, RUN					  ; Set RUN to 0 (False)
	movb   	#$01, offPrintFlag			  ; Set offPrintFlag to 1 (True)
	movb   	#$00, onPrintFlag			  ; Set onPrintFlag to 0 (False)
	movb   	#$00, AFlag					  ; Set AFlag to 0 (False)
	lbra   	STATE_CHAR_DONE				  ; Branch Always to STATE_CHAR_DONE
	
MOTOR_ON:
	
	movb   	#$01, RUN					  ; Set RUN to 1 (True)
	movb   	#$00, offPrintFlag			  ; Set offPrintFlag to 0 (False)
	movb   	#$01, onPrintFlag			  ; Set onPrintFlag to 1 (True)
	movb   	#$00, AFlag				      ; Set AFlag to 0 (False)
	lbra   	STATE_CHAR_DONE				  ; Branch Always to STATE_CHAR_DONE
	
BFLAG_GO:

    tst   	loopSetFlag					  ; Test loopSetFlag
	lbeq   	OPEN_LOOP_SET				  ; If loopSetFlag is 0 (Next State - Open), Branch to OPEN_LOOP_SET 
	lbne   	CLOSED_LOOP_SET				  ; If loopSetFlag is 1 (Next State - Closed), Branch to CLOSED_LOOP_SET
	
OPEN_LOOP_SET:

	movb   	#$00, closedLoopPrintFlag	  ; Set closedLoopPrintFlag to 0 (False)
	movb   	#$01, openLoopPrintFlag		  ; Set openLoopPrintFlag to 1 (True)
	movb   	#$01, loopSetFlag			  ; Set loopSetFlag to 1 (Next State - Closed)
	movb   	#$00, BFlag					  ; Set BFlag to 0 (False)
	movb    #$01, firstKiFlag
	movw	Ki, oldKi
	movw	#$0000, Ki
	movb	#$01, KiFlag
	lbra   	STATE_CHAR_DONE				  ; Branch Always to STATE_CHAR_DONE
	
CLOSED_LOOP_SET:

	movb   	#$01, closedLoopPrintFlag	  ; Set closedLoopPrintFlag to 1 (True)		 
	movb   	#$00, openLoopPrintFlag		  ; Set openLoopPrintFlag to 0 (False)
	movb   	#$00, loopSetFlag			  ; Set loopSetFlag to 1 (Next State - Open)
	movb   	#$00, BFlag					  ; Set BFlag to 0 (False)
	movw	oldKi, Ki
	movb	#$01, KiFlag
	lbra   	STATE_CHAR_DONE				  ; Branch Always to STATE_CHAR_DONE		
		
CFLAG_GO:

	movb   	#$01, VRefFlag				  ; Set VRefFlag to 1 (True) 
	movb   	#$01, VRefPromptFlag		  ; Set VRefPromptFlag to 1 (True)
	movb   	#$00, CFlag					  ; Set CFlag to 0 (False)
	lbra   	VALUE_CHAR_DONE				  ; Branch Always to VALUE_CHAR_DONE	
		
DFLAG_GO:
	
	movb   	#$00, RUN					  ; Set RUN to 0 (Stop) 
	movb   	#$01, offPrintFlag			  ; Set offPrintValue to 1 (True)  
	movb   	#$01, stateVariableFlag		  ; Set stateVariableFlag to 1 (True) 
	movb   	#$01, KiFlag				  ; Set KiFlag to 1 (True) 
	movb   	#$01, KiPromptFlag			  ; Set KiPromptFlag to 1 (True) 
	movb   	#$00, DFlag					  ; Set DFlag to 0 (False) 
	lbra   	VALUE_CHAR_DONE				  ; Branch Always to VALUE_CHAR_DONE

EFLAG_GO:

	movb   	#$00, RUN					  ; Set RUN to 0 (Stop) 					
	movb   	#$01, offPrintFlag			  ; Set offPrintValue to 1 (True)
	movb   	#$01, stateVariableFlag		  ; Set stateVariableFlag to 1 (True)
	movb   	#$01, KpFlag				  ; Set KpFlag to 1 (True)
	movb   	#$01, KpPromptFlag			  ; Set KpPromptFlag to 1 (True) 
	movb   	#$00, EFlag					  ; Set EFlag to 0 (False) 
	lbra   	STATE_CHAR_DONE				  ; Branch Always to STATE_CHAR_DONE	

FFLAG_GO:

    tst   autoManualFlag				  ; Test autoManualFlag 
	lbeq   AUTO_SET						  ; If autoManualFlag is 0 (Next State - Auto), Branch to AUTO_SET
	lbne   MANUAL_SET					  ; If autoManualFlag is 1 (Next State - Manual), Branch to MANUAL_SET
	
AUTO_SET:

	movb   #$01, autoPrintFlag			  ; Set autoPrintFlag to 1 (True) 		  
	movb   #$00, manualPrintFlag		  ; Set manualPrintFlag to 0 (False) 
	movb   #$01, autoManualFlag			  ; Set autoManualFlag to 1 (Auto) 
	movb   #$00, FFlag					  ; Set FFlag to 0 (False) 
	lbra   STATE_CHAR_DONE			      ; Branch Always to STATE_CHAR_DONE

MANUAL_SET:

	movb   #$00, autoPrintFlag			  ; Set autoPrintFlag to 0 (False)
	movb   #$01, manualPrintFlag		  ; Set manualPrintFlag to 1 (True) 	
	movb   #$00, autoManualFlag			  ; Set autoManualFlag to 1 (Manual)
	movb   #$00, FFlag					  ; Set FFlag to 0 (False) 
	lbra   STATE_CHAR_DONE			      ; Branch Always to STATE_CHAR_DONE	

STATE_CHAR_DONE:

	movb   #$01, stateVariableFlag		  ; Set stateVariableFlag to 0 (True)
	movb   #$02,	mmState				  ; Set the Mastermind State Variable to 2 (Hub)
	rts									  ; Return to Main
	
VALUE_CHAR_DONE:

	movb   #$02,	mmState				  ; Set the Mastermind State Variable to 2 (Hub)
	rts									  ; Return to Main

;===================== Mastermind State 7 - Update Values ======================

mmstate7:

	stab   stateVariable	 
    tst    promptUpFlag					  ; Test promptUpFlag 
	lbne   UPDATE_BUFFER_EXIT   		  ; If promptUpFlag is 1 (True), Branch to UPDATE_BUFFER_EXIT
	tst    VRefFlag						  ; Test VRefFlag
	lbne   UPDATE_VREF					  ; If VRefFlag is 1 (True), Branch to UPDATE_VREF
	tst    KiFlag						  ; Test KiFlag
	lbne   UPDATE_KI					  ; If KiFlag is 1 (True), Branch to UPDATE_KI
	tst    KpFlag						  ; Test KpFlag
	lbne   UPDATE_KP					  ; If KiFlag is 1 (True), Branch to UPDATE_KI
	tst    VActFlag						  ; Test VActFlag
	lbne   UPDATE_VACT					  ; If VActFlag is 1 (True), Branch to UPDATE_VACT
	tst    errorFlag					  ; Test errorFlag
	lbne   UPDATE_ERROR					  ; If errorFlag is 1 (True), Branch to UPDATE_ERROR
	tst    effortFlag					  ; Test effortFlag
	lbne   UPDATE_EFFORT				  ; If effortFlag is 1 (True), Branch to UPDATE_EFFORT
	movb   #$02, mmState				  ; Set the Mastermind State Variable to 2 (Hub)
	rts									  ; Return to Main

UPDATE_VREF:
	
	tst  	VRefSign					  ; Test VRefSign 	           
	bne    	NEGATIVE_VREF    			  ; If VRefSign is 1 (Negative), Branch to NEGATIVE_VREF
    ldd    	V_Ref						  ; Load Accumulator D with V_Ref
    bra    	BINARY_ASCII         		  ; Branch Always to BINARY_ASCII

NEGATIVE_VREF:
	   
    ldd    	#$0000 						  ; Load Accumulator D with $0000 (0)            
    subd   	V_Ref               		  ; Subtract V_Ref from $0000 (0) to Get V_Ref to Convert 
    bra    	BINARY_ASCII 				  ; Branch Always to BINARY_ASCII 

UPDATE_VACT:
	
	tst  	VActSign  	            	  ; Test VActSign
	bne    	NEGATIVE_VACT    		      ; If VActSign is 1 (Negative), Branch to NEGATIVE_VACT
    ldd    	V_Act						  ; Load Accumulator D with V_Act
    bra    	BINARY_ASCII         		  ; Branch Always to BINARY_ASCII
	
NEGATIVE_VACT:
	   
    ldd    	#$0000             			  ; Load Accumulator D with $0000 (0)  
    subd   	V_Act               		  ; Subtract V_Act from $0000 (0) to Get V_Act to Convert 
    bra    	BINARY_ASCII				  ; Branch Always to BINARY_ASCII 
	
UPDATE_KI:
    
    ldd    	Ki							  ; Load Accumulator D with Ki 
    bra   	BINARY_ASCII				  ; Branch Always to BINARY_ASCII 
	
UPDATE_KP:
  
    ldd    	Kp							  ; Load Accumulator D with Kp
    bra    	BINARY_ASCII				  ; Branch Always to BINARY_ASCII 	

UPDATE_ERROR:
	
	tst  	errorSign            		  ; Test errorSign
	bne    	NEGATIVE_ERROR    			  ; If errorSign is 1 (Negative), Branch to NEGATIVE_ERROR
    ldd    	Error						  ; Load Accumulator D with Error
    bra    	BINARY_ASCII         		  ; Branch Always to BINARY_ASCII

NEGATIVE_ERROR:
	   
    ldd    	#$0000             			  ; Load Accumulator D with $0000 (0)
    subd   	Error               		  ; Subtract Error from $0000 (0) to Get Error to Convert
    bra    	BINARY_ASCII				  ; Branch Always to BINARY_ASCII
	
UPDATE_EFFORT:
	
	tst  	effortSign 					  ; Test effortSign           
	bne    	NEGATIVE_EFFORT   			  ; If effortSign is 1 (Negative), Branch to NEGATIVE_EFFORT
    ldd    	Effort						  ; Load Accumulator D with Effort
    bra    	BINARY_ASCII  				  ; Branch Always to BINARY_ASCII       

NEGATIVE_EFFORT:
	   
    ldd    	#$0000             			  ; Load Accumulator D with $0000 (0)
    subd   	Effort               		  ; Subtract Effort from $0000 (0) to Get Effort to Convert
    bra    	BINARY_ASCII  				  ; Branch Always to BINARY_ASCII
	
BINARY_ASCII:
	  
	movw   	#updateBuffer, updatePointer  ; Load First Address of updateBuffer into updatePointer	
	movb	#$00, updateCounter			  ; Clear updateCounter
	   
BINARY_ASCII_LOOP:

    ldx    	#$000A              		  ; Load Accumulator A with $000A (10)
    ldy    	#$0000              		  ; Load Y with $0000 (0)
    edivs                      			  ; (Y:D)/X ==> Result into Y, Remainder ==> D
    sty   	updateResult              	  ; Store Y into updateResult
    addb   	#$30                          ; Add $30 (30) to Accumulator B
    clra                       		      ; Clear Accumulator A
    ldx    	updatePointer                 ; Load X with updatePointer Address
    stab   	0,x                 		  ; Store ASCII Value into updatePointer Address
    inc    	updateCounter                 ; Increment the updateCounter
    cpy    	#$0000             			  ; Compare Y to $0000 (0)
    lbeq   	SIGN_CHECK          		  ; If Y is 0, Branch to SIGN_CHECK
    inx                       			  ; Increment X (updatePointer Address)
    stx    	updatePointer         		  ; Store X into updatePointer
	ldd    	updateResult      			  ; Load D with updateResult
	bra    	BINARY_ASCII_LOOP  			  ; Branch Always to BINARY_ASCII_LOOP

SIGN_CHECK:

	tst     VRefFlag					  ; Test VRefFlag
	bne		VREF_SIGN_CHECK				  ; If VRefFlag is 1 (True), Branch to VREF_SIGN_CHECK
	tst		KiFlag						  ; Test KiFlag			
	lbne	KI_KP_CHECK					  ; If KiFlag is 1 (True), Branch to KI_KP_CHECK		
	tst		KpFlag						  ; Test KpFlag
	lbne	KI_KP_CHECK					  ; If KiFlag is 1 (True), Branch to KI_KP_CHECK
	tst 	VActFlag					  ; Test VActFlag
	lbne 	VACT_SIGN_CHECK				  ; If VActFlag is 1 (True), Branch to VACT_SIGN_CHECK	
	tst 	errorFlag					  ; Test errorFlag	
	lbne	ERROR_SIGN_CHECK			  ; If errorFlag is 1 (True), Branch to ERROR_SIGN_CHECK
	tst 	effortFlag					  ; Test effortFlag	
	lbne	EFFORT_SIGN_CHECK			  ; If effortFlag is 1 (True), Branch to EFFORT_SIGN_CHECK
	lbra    UPDATE_BUFFER_DONE			  ; Branch Always to UPDATE_BUFFER_DONE
				  
VREF_SIGN_CHECK:

    movb    #$00, VRefFlag				  ; Set VRefFlag to 0 (False)
	movb    #$01, updateLine1Flag		  ; Set updateLine1Flag to 1 (True)	
	movb    #$01, updateLine2Flag		  ; Set updateLine2Flag to 1 (True)	 
	ldx     #updateBuffer				  ; Load X With the First Address of updateBuffer
    ldy     #VREF_BUF        			  ; Load Y With the First Address of VRef_BUF
    tst	    VRefSign					  ; Test VRefSign
	bne	    NEG_SIGN					  ; If VRefSign is 1 (Negative), Branch to NEG_SIGN	
	bra	    POS_SIGN                      ; Branch Always to POS_SIGN		                  	   

VACT_SIGN_CHECK:
     
	movb	#$00, VActFlag				  ; Set VActFlag to 0 (False)
	ldx	  	#updateBuffer				  ; Load X With the First Address of updateBuffer
    ldy    	#VACT_BUF          			  ; Load Y With the First Address of VACT_BUF
    tst   	VActSign           			  ; Test VActSign	
	beq    	POS_SIGN					  ; If VActSign is 0 (Positive), Branch to NEG_SIGN
 	movb   	#$00, VActSign				  ; Set VActFlag to 1 (Negative)
	bra	  	NEG_SIGN   					  ; Branch Always to NEG_SIGN
	                                      	    
ERROR_SIGN_CHECK:
       
	movb	#$00, errorFlag				  ; Set errorFlag to 0 (False)
	ldx	  	#updateBuffer				  ; Load X With the First Address of updateBuffer
	ldy   	#ERROR_BUF         			  ; Load Y With the First Address of ERROR_BUF
    tst    	errorSign           		  ; Test errorSign		
	beq    	POS_SIGN				      ; If errorSign is 0 (Positive), Branch to POS_SIGN  
	movb   	#$00, errorSign			      ; Set errorSign to 1 (Negative)
	bra	  	NEG_SIGN                      ; Branch Always to NEG_SIGN    		                           		   

EFFORT_SIGN_CHECK:
       
	movb    #$00, effortFlag			  ; Set effortFlag to 0 (False)
	ldx	  	#updateBuffer				  ; Load X With the First Address of updateBuffer
    ldy    	#EFFORT_BUF          		  ; Load Y With the First Address of EFFORT_BUF	 
	tst		effortSign
	bne		NEG_SIGN
	bra		POS_SIGN
	   
POS_SIGN:

	movb	#'+',0,y					  ; Move '+' into the First Buffer Address		
	bra    	UPDATE_OUT				  	  ; Branch Always to UPDATE_OUT
	   
NEG_SIGN:   
	   	  	
	movb   	#'-',0,Y              	 	  ; Move '-' into the First Buffer Address	
	bra    	UPDATE_OUT			      	  ; Branch Always to UPDATE_OUT	

KI_KP_CHECK:

	tst   	KiFlag						  ; Test KiFlag
	bne   	KI_CHECK					  ; If KiFlag is 1 (True), Branch to KI_CHECK
	tst   	KpFlag						  ; Test KpFlag
	bne   	KP_CHECK					  ; If KpFlag is 1 (True), Branch to KP_CHECK
	lbra    UPDATE_BUFFER_DONE			  ; Branch Always to UPDATE_BUFFER_DONE

KI_CHECK:
bgnd
    movb    #$00, KiFlag			      ; Set KiFlag to 0 (False)
	movb	#$01, updateLine2Flag		  ; Set updateLine2Flag to 0 (False)
	ldaa	updateCounter
	cmpa	#$01
	ldx		#updateBuffer				  ; Load X With the First Address of updateBuffer	
    ldy    	#KI_BUF                       ; Load Y With the First Address of KI_BUF
	ldaa	updateCounter
	cmpa	#$01
	beq		KI_SINGLE_CORRECT	 	
	bra    	UPDATE_OUT			          ; Branch Always to UPDATE_OUT_KI_KP

KI_SINGLE_CORRECT:
    
	movb   	#'0',4,y				   	  ; Move 0 into the First Buffer Position            
    lbra    UPDATE_OUT		  			  ; Branch Always to UPDATE_OUT
		
KP_CHECK:
	
	movb    #$00, KpFlag			      ; Set KpFlag to 0 (False)	 
	movb	#$01, updateLine2Flag		  ; Set updateLine2Flag to 1 (False)		
	ldx	  	#updateBuffer				  ; Load X With the First Address of updateBuffer
    ldy    	#KP_BUF                       ; Load Y With the First Address of KP_BUF
	ldaa	updateCounter
	cmpa	#$01
	beq		KP_SINGLE_CORRECT	 			
	bra    	UPDATE_OUT 			  		  ; Branch Always to UPDATE_OUT_KI_KP
	
KP_SINGLE_CORRECT:

	movb   	#'0',4,y				   	  ; Move 0 into the First Buffer Position            
    lbra    UPDATE_OUT		  			  ; Branch Always to UPDATE_OUT
			   	   
UPDATE_OUT:

    dec    	updateCounter		  		  ; Decrement updateCounter
    beq    	ONE_VALUE          			  ; If One ASCII Value, Branch to ONE_VALUE
    dec    	updateCounter		  		  ; Decrement updateCounter	
    beq    	TWO_VALUES	      			  ; If Two ASCII Values, Branch to TWO_VALUES   
    dec    	updateCounter		  		  ; Decrement updateCounter	
    beq    	THREE_VALUES	      		  ; If Three ASCII Values, Branch to THREE_VALUES 	
    dec    	updateCounter		  		  ; Decrement updateCounter	
    lbeq    FOUR_VALUES	      			  ; If Four ASCII Values, Branch to FOUR_VALUES 		   	   
    dec    	updateCounter		  		  ; Decrement updateCounter	
    lbeq    FIVE_VALUES	      			  ; If Five ASCII Values, Branch to FIVE_VALUES 
    lbra	UPDATE_BUFFER_DONE			  ; Branch Always to UPDATE_BUFFER_DONE
    
ONE_VALUE:
                    
    movb	0,x,3,y					  	  ; Move the Single Value into the Third Buffer Position
	movb   	#'0',2,y					  ; Move 0 into the Second Buffer Position
	movb   	#'0',1,y				   	  ; Move 0 into the First Buffer Position            
    lbra    UPDATE_BUFFER_DONE		  	  ; Branch Always to UPDATE_BUFFER_DONE
	
TWO_VALUES:
	
    movb   0,x,3,y             		      ; Move the First Value into the Third Buffer Position
    movb   1,x,2,y					  	  ; Move the Second Value into the Second Buffer Position
	movb   #'0',1,y					  	  ; Move 0 into the First Buffer Position
    bra    UPDATE_BUFFER_DONE		  	  ; Branch Always to UPDATE_BUFFER_DONE

THREE_VALUES:

    movb   0,x,3,y             		      ; Move the First Value into the Third Buffer Position
    movb   1,x,2,y						  ; Move the Second Value into the Second Buffer Position
    movb   2,x,1,y             			  ; Move the Third Value into the First Buffer Position
    bra    UPDATE_BUFFER_DONE		  	  ; Branch Always to UPDATE_BUFFER_DONE

FOUR_VALUES:

    movb   0,x,4,y             			  ; Move the First Value into the Fourth Buffer Position
    movb   1,x,3,y             			  ; Move the Second Value into the Third Buffer Position
    movb   2,x,2,y             			  ; Move the Third Value into the Second Buffer Position
    movb   3,x,1,y             			  ; Move the Fourth Value into the First Buffer Position
	movb   #'0',0,y					  	  ; Move 0 into the First Buffer Position
    bra    UPDATE_BUFFER_DONE		  	  ; Branch Always to UPDATE_BUFFER_DONE

FIVE_VALUES:
	movb    #$00, KiFlag
	movb    #$00, KpFlag
    movb   0,x,4,y             			  ; Move the First Value into the Fifth Buffer Position
    movb   1,x,3,y             			  ; Move the Second Value into the Fourth Buffer Position
    movb   2,x,2,y               		  ; Move the Third Value into the Third Buffer Position
    movb   3,x,1,y             			  ; Move the Fourth Value into the Second Buffer Position
    movb   4,x,0,y             			  ; Move the Fifth Value into the First Buffer Position
    bra    UPDATE_BUFFER_DONE		  	  ; Branch Always to UPDATE_BUFFER_DONE


	
UPDATE_BUFFER_DONE:

	tst    VRefFlag						  ; Test VRefFlag
	lbne   UPDATE_VREF					  ; If VRefFlag is 1 (True), Branch to UPDATE_VREF
	tst    KiFlag						  ; Test KiFlag
	lbne   UPDATE_KI					  ; If KiFlag is 1 (True), Branch to UPDATE_KI
	tst    KpFlag						  ; Test KpFlag
	lbne   UPDATE_KP					  ; If KiFlag is 1 (True), Branch to UPDATE_KI
	tst    VActFlag						  ; Test VActFlag
	lbne   UPDATE_VACT					  ; If VActFlag is 1 (True), Branch to UPDATE_VACT
	tst    errorFlag					  ; Test errorFlag
	lbne   UPDATE_ERROR					  ; If errorFlag is 1 (True), Branch to UPDATE_ERROR
	tst    effortFlag					  ; Test effortFlag
	lbne   UPDATE_EFFORT				  ; If effortFlag is 1 (True), Branch to UPDATE_EFFORT
	   
UPDATE_BUFFER_EXIT: 

	ldab   stateVariable			
    movb   #$00, updateValuesFlag		  ; Set updateValuesFlag to 0 (False)
	movb   #$02, mmState     		  	  ; Set the Mastermind State Variable to 2 (Hub)  		  
	rts									  ; Return to Main
	
;=========  Mastermind - Miscellaneous Sub-Rountines / Branches   ==============

BUFFER_STORE:

	tst	   VRefFlag						  ; Test VRefFlag
	bne	   BUFFER_STORE_VREF		 	  ; If VRefFlag is 1 (True), Branch to BUFFER_STORE_VREF
	ldaa   digitCounter                   ; Load Accumulator A with digitCounter
	cmpa   #$05                           ; Compare Accumulator A with $05 (5)
	bge    BUFFER_STORE_LIMIT             ; If A is higher or equal than $05 (5), Branch to BUFFER_STORE_LIMIT
	inc    digitCounter					  ; Increment digitCounter
	ldx    pointer                        ; Load X with pointer
	ldab   keyStore				      	  ; Load Accumulator B with digitStore
	stab   0,x                            ; Store Contents of B into X
	inx                                   ; Increment X
	stx    pointer                        ; Store Contents of X into pointer
	movb   #$01, echoFlag                 ; Set echoFlag to 1 (True)
	movb   #$00, keyFlag	              ; Set keyFlag to 0 (False)
	movb   #$02, mmState				  ; Set the Mastermind State Variable to 2 (Hub)
	rts									  ; Return to Main

BUFFER_STORE_VREF:

	ldaa   digitCounter                   ; Load Accumulator A with digitCounter
	cmpa   #$03                           ; Compater Accumulator with $03 (3)
	bge    BUFFER_STORE_LIMIT             ; If A is higher or equal than $03 (3), Branch to BUFFER_STORE_LIMIT
	inc    digitCounter					  ; Increment digitCounter
	ldx    pointer                        ; Load X with pointer
	ldab   keyStore				      	  ; Load Accumulator B with digitStore
	stab   0,x                            ; Store Contents of B into X
	inx                                   ; Increment X
	stx    pointer                        ; Store Contents of X into pointer
	movb   #$01, echoFlag                 ; Set echoFlag to 1 (True)
	movb   #$00, keyFlag	              ; Set keyFlag to 0 (False)
	movb   #$02, mmState				  ; Set the Mastermind State Variable to 2 (Hub)
	rts									  ; Return to Main
	
BUFFER_STORE_LIMIT:

	ldab   #$00                           ; Load Accumulator B with $00 (0)
	movb   #$00, echoFlag                 ; Set echoFlag to 0 (True)
	movb   #$00, keyFlag	              ; Set keyFlag to 0 (False)
	movb   #$00, digitFlag                ; Set digitFlag to 0 (True)
	movb   #$02, mmState				  ; Set the Mastermind State Variable to 2 (Hub)
	rts									  ; Return to Main	

CLEAR_TEMPLATE:

    ldx    VREF_BUF         			  ; Moves Zeros and '+' into VREF_BUF
    movb   #'+',0,x
    movb   #'0',1,x
    movb   #'0',2,x
    movb   #'0',3,x
       
	ldx    VACT_BUF         			  ; Moves Zeros and '+' into VACT_BUF
    movb   #'+',0,x
    movb   #'0',1,x
    movb   #'0',2,x
    movb   #'0',3,x
       
	ldx    ERROR_BUF         			  ; Moves Zeros and '+' into ERROR_BUF
    movb   #'+',0,x
    movb   #'0',1,x
    movb   #'0',2,x
    movb   #'0',3,x
	
    ldx    EFFORT_BUF         			  ; Moves Zeros and '+' into EFFORT_BUF
    movb   #'+',0,x
    movb   #'0',1,x
    movb   #'0',2,x
    movb   #'0',3,x
	
    ldx    KI_BUF         			      ; Moves Zeros into KI_BUF
    movb   #'0',0,x
    movb   #'0',1,x
    movb   #'0',2,x
    movb   #'0',3,x
    movb   #'0',4,x	
	   
    ldx    KP_BUF         			      ; Moves Zeros into KI_BUF
    movb   #'0',0,x
    movb   #'0',1,x
    movb   #'0',2,x
    movb   #'0',4,x
    jsr    UPDATELCDL1         			  ; Jump to subtrountine to Update Line 1 of LCD
    jsr    UPDATELCDL2         			  ; Jump to subtrountine to Update Line 2 of LCD
	rts								  	  ; Return to Main	
	
;=========================  Key Pad Driver Sub-Routine   =======================

KPD:

	ldaa   kpdState			              
	lbeq   kpdstate0			          ; Initialization of Key Pad Driver
	deca                                  
	lbeq   kpdstate1			          ; Wait for the Key Press to Be Stored in Buffer
	rts								  	  ; Return to Main	

;========  Key Pad Driver State 0 - Initialization of Key Pad Driver   =========

kpdstate0: 	
			
    jsr    INITKEY                        ; Jump to Subroutine INITKEY
    jsr    FLUSH_BFR                      ; Jump to Subroutine FLUSH_BFR
    jsr    KP_ACTIVE                      ; Jump to Subroutine KP_ACTIVE
    movb   #$01, kpdState                 ; Set the KPD State Variable to 1
 	rts								  	  ; Return to Main	

;== Key Pad Driver State 1 - Wait for the Key Press to Be Stored in Buffer   ===

kpdstate1:
       
    tst    L$KEY_FLG                      ; Test L$KEY_FLG
	bne	   NO_KEY_PRESS			          ; If L$KEY_FLG has Key, Branch to NO_KEY_PRESS
    jsr    GETCHAR                        ; Jump to Subroutine GETCHAR
	stab   keyStore                       ; Store ASCII Char from Accumulator B into keyStore
	movb   #$01, keyFlag                  ; Set keyFlag to 1 (True)
	movb   #$01, kpdState				  ; Set the KPD State Variable to 1
	rts								  	  ; Return to Main

NO_KEY_PRESS:

	movb   #$01,kpdState				  ; Set the KPD State Variable to 1
	rts								  	  ; Return to Main

;=============================  Display Sub-Routine   ==========================

DISPLAY:

	ldaa   displayState                   ; Display to be Branched to Depending on Value
	lbeq   displaystate0                  ; Initalize LCD Screen & Cursor
	deca
	lbeq   displaystate1                  ; Display Hub
	deca
	lbeq   displaystate2                  ; Update LCD Template Values
	deca
	lbeq   displaystate3                  ; Display Ref Velocity Prompt 
	deca
	lbeq   displaystate4                  ; Display Ki Prompt
	deca
	lbeq   displaystate5                  ; Display Kp Prompt
	deca
	lbeq   displaystate6                  ; Initializing & Printing Digit
	deca
	lbeq   displaystate7                  ; Backspace	
	deca
	lbeq   displaystate8                  ; LCD Update
    rts		

;==================== Display State 0 - Initialize LCD Screen & Cursor ===================
	
displaystate0:

	jsr	   INITLCD                        ; Initalize LCD Screen
	jsr    CLRSCREEN                      ; Clear LCD Screen
	jsr    CURSOR                         ; Show Cursor in LCD Screen
	jsr	   LCDTEMPLATE					  ;	Library Command to Update LCD Screen 	      
	movb   #$01, displayState		      ; Set Next Display to HUB
	rts

;============================= Display State 1 - Display Hub =============================
	
displaystate1:
 
    tst	   VRefPromptFlag	              ; Test to see if C Character (V_Ref) has been Pressed
    bne	   DISPLAY_VREF_PROMPT            ; Branch VREFFLAG if true
    tst	   KiPromptFlag                   ; Test KIFLAG
    bne	   DISPLAY_KI_PROMPT              ; Branch to KI_DISPLAY, if true
    tst	   KpPromptFlag                   ; TEST WAVE_FLAG
    bne	   DISPLAY_KP_PROMPT              ; If it is true then branch and display
    tst	   echoFlag                       ; Test ECHOFLAG
    lbne   KEY_PRINT                      ; If ECHOFLAG is TRUE, branch to ECHO
    tst	   backspacePrint                 ; Test BSPACEFLAG
    lbne   BACKSPACE_PRINT                ; If BSPACEFLAG is TRUE, branch to DISPBSPACE
	tst	   stateVariableFlag              ; Test VariableFlag
	lbne   STATE_VARIABLE_PRINT           ; If stateVariableFlag is TRUE, Branch to STATE_VARIABLE_PRINT
	tst	   LCDUpdateFlag                  ; Test LCDUpdateFlag
	lbne   LCD_UPDATE_PRINT               ; If LCDUpdateFlag is TRUE , Branch to LCD_UPDATE_PRINT
    rts
	
DISPLAY_VREF_PROMPT:

    movb   #$02, displayState             ; Set state to display DISP VREF message
    rts	
	 	
DISPLAY_KI_PROMPT: 

    movb   #$03, displayState             ; Set state to KI display
    rts
	   
DISPLAY_KP_PROMPT:

    movb   #$04, displayState             ; Set state to KP display
    rts
	
KEY_PRINT:

    movb   #$05, displayState             ; Set state to echo digits pressed
    rts
 
BACKSPACE_PRINT:

    movb   #$06, displayState             ; Set state to display Backspace
    rts

STATE_VARIABLE_PRINT:

    movb   #$07, displayState             ; Set state to Update LCD screen
    rts

LCD_UPDATE_PRINT:

    movb   #$08, displayState             ; Set state to Update LCD screen
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
	
	ldaa   #$4C                           ; Load A with LCD Address of 76
	jsr	   SETADDR                        ; Set the Cursor at The Address in A
	movb   #$00, VRefPromptFlag           ; Clear the VRefPromptFlag
	movb   #$01, firstChar                ; Clear firstChar Flag
	movb   #$01, digitAllowed		      ; Clear the digitAllowed Flag   
    movb   #$01, displayState             ; Return to Display State 1
	rts
	
;===================== Display State 3 - Ki Prompt Print =======================
	
displaystate3:

    ldaa   #$40                           ; Load Accumulator A with LCD Address 64
    ldx    #KI_PRINT_MESSAGE              ; Load Index Register X with Address of NO_DIGITS_PRINT
    jsr    DISPLAY_CHAR   	              ; Jump to Subroutine DISPLAY_CHAR
    ldx    displayPointer                 ; Load X with displayPointer
    ldab   0,x                            ; Load B with the Contents in X
    lbeq   DONE_KI_PRINT			      ; If B=$00, Branch to DONE_NO_DIGITS_PRINT
    rts

KI_PRINT_MESSAGE:

	.ascii 	'ENTER 1024*KI:                     '
    .byte  	$00
    rts               
	   
DONE_KI_PRINT:
	
	ldaa   #$4F                           ; Load Accumulator A with LCD Address 79
	jsr	   SETADDR                        ; Set the Cursor at The Address in A
	movb   #$00, KiPromptFlag             ; Clear KiPromptFlag
	movb   #$01, firstChar                ; Clear firstChar Flag 
	movb   #$01, digitAllowed		      ; Clear digitAllowed           
    movb   #$01, displayState             ; Return to Display State 1
	rts
	
;===================== Display State 4 - Ki Prompt Print =======================
	
displaystate4:

    ldaa   #$40                           ; Load Accumulator A with LCD Address $07
    ldx    #KP_PRINT_MESSAGE              ; Load Index Register X with Address of NO_DIGITS_PRINT
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
	
	ldaa   #$4F                           ; Load Accumulator A with LCD Address 79
	jsr	   SETADDR                        ; Set the Cursor at The Address in A
	movb   #$00, KpPromptFlag             ; Clear KpPromptFlag
	movb   #$01, firstChar                ; Clear firstChar
	movb   #$01, digitAllowed		      ; Clear digitAllowed   
    movb   #$01, displayState             ; Return to Display State 1
	rts
	
;================ Display State 5 - Initializing & Printing Digit for Entry ====
	
displaystate5:

	tst    VRefPosPrintFlag               ; Test VRefPosPrintFlag
	lbne   PRINT_POSITIVE                 ; If VRefPosPrintFlag TRUE, Branch to PRINT_POSITIVE
	tst	   VRefNegPrintFlag               ; Test VRefNegPrintFlag
	lbne   PRINT_NEG                      ; If VRefNegPrintFlag TRUE, Branch to PRINT_NEG
	lbra   PRINT_INIT                     ; Otherwise, Branch to PRINT_INIT
	
PRINT_POSITIVE:

	ldab   #$2B                           ; Load Accumulator B with ASCII value of '+'
	jsr	   OUTCHAR                        ; Print Character Stored in B
	lbra   SIGN_PRINT_DONE                ; Branch to SIGN_PRINT_DONE
	
PRINT_NEG:
	
	ldab   #$2D                           ; Load Accumulator B with ASCII value of '-'
	jsr	   OUTCHAR                        ; Print Character Stored in B
	lbra   SIGN_PRINT_DONE                ; Branch to SIGN_PRINT_DONE
	
PRINT_INIT:	
	  
    ldaa   digitCounter                   ; Load Accumulator A with digitCounter
    cmpa   #$00                           ; Compare A with $00 
	bne	   DIGIT_NOT_FIRST                ; If A not $00, Branch to DIGIT_NOT_FIRST
	bra	   PRINT_FIRST_DIGIT              ; Otherwise, Branch to PRINT_FIRST_DIGIT
  
PRINT_FIRST_DIGIT:

	ldab   keyStore                       ; Load Accumulator B With digitStore
	jsr	   OUTCHAR                        ; Print Character Stored in B
	bra	   DIGIT_PRINT_DONE               ; Branch to INIT_PRINT_DONE
	   
DIGIT_NOT_FIRST:

	tst	   VRefFlag                       ; Test VRefFlag
	lbne   DIGIT_NOT_FIRST_VREF           ; If VRefFlag TRUE, Branch to DIGIT_NOT_FIRST_VREF
	ldaa   digitCounter                   ; Load Accumulator A with digitCounter
	cmpa   #$06                           ; Compare A with $03
    bge    DIGIT_PRINT_DONE               ; If Value in A > $03, Branch to DIGIT_PRINT_DONE
	ldab   keyStore                       ; Load Accumulator B with digitStore
	jsr	   OUTCHAR                        ; Print Character of ASCII Value in Stored in B
	bra	   DIGIT_PRINT_DONE               ; Branch to INIT_PRINT_DONE
	
DIGIT_NOT_FIRST_VREF:

	ldaa   digitCounter                   ; Load Accumulator A with digitCounter
	cmpa   #$04                           ; Compare A with $03
    bge    DIGIT_PRINT_DONE               ; If Value in A > $03, Branch to DIGIT_PRINT_DONE
	ldab   keyStore                       ; Load Accumulator B with digitStore
	jsr	   OUTCHAR                        ; Print Character of ASCII Value in Stored in B
	bra	   DIGIT_PRINT_DONE               ; Branch to INIT_PRINT_DONE 
	
DIGIT_PRINT_DONE:

	clr	   echoFlag                       ; Set echoFlag to FALSE
	movb   #$01, digitFlag                ; Clear digitFlag
	movb   #$01, displayState             ; Return Back to Display Hub
	rts

SIGN_PRINT_DONE:

	clr	   echoFlag                       ; Set echoFlag to FALSE
	movb   #$01, VRefSignFlag             ; Set VRefSignFlag
	clr    VRefPosPrintFlag               ; Clear VRefPosPrintFlag
	clr    VRefNegPrintFlag               ; Clear VRefPosPrintFlag AGAIN =)
	movb   #$01, displayState             ; Return Back to Display Hub
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

	dec	   digitCounter                   ; Decrement digitCounter
	ldx    pointer                        ; Load Index Register X with pointer
	dex 	                              ; Decrement Index Register X
	stx	   pointer                        ; Store Index Register X into pointer	
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
	clr	   backspacePrint                 ; Set backspaceFlag to FALSE
	rts
  
;===================== Display State 7 - State Variable Print ==================

displaystate7:

    ldaa   stateVariableState  
    deca   
    beq    ON_OFF_PROMPT                  ; Determine State (on/off)
    deca
    beq    OPEN_CLOSED_PROMPT             ; Open Loop Display
    deca
    beq    AUTO_MANUAL_PROMPT             ; Update LCD Automatically
	movb   #$01, stateVariableState       ; Go to ON_OFF_PROMPT on Next Pass Through Display State 7
	movb   #$01, displayState             ; Return to Display HUB On Next Pass Through Display
    rts  

ON_OFF_PROMPT:

    tst    promptUpFlag                   ; Test promptUpFlag
	lbne   SKIP_STATE_VARIABLE_PRINT      ; If promptUpFlag is TRUE, Branch to SKIP_STATE_VARIABLE_PRINT
    tst    RUN                            ; Test RUN
    lbeq   DISPLAY_STOP_VARIABLE          ; If RUN is TRUE, Branch to DISPLAY_STOP_VARIABLE
	lbra   DISPLAY_RUN_VARIABLE           ; Otherwise, Branch to DISPLAY_RUN_VARIABLE

OPEN_CLOSED_PROMPT:

	tst	   loopSetFlag                    ; Test loopSetFlag
	lbeq   DISPLAY_CL_VARIABLE            ; If loopSetFlag is TRUE, Branch to DISPLAY_CL_VARIABLE
	lbra   DISPLAY_OL_VARIABLE            ; Otherwise, Branch to DISPLAY_OL_VARIABLE

AUTO_MANUAL_PROMPT:

	tst	   autoManualFlag                 ; Test autoManualFlag
	lbne   DISPLAY_AUTO_VARIABLE          ; If autoManualFlag is TRUE, Branch to DISPLAY_AUTO_VARIABLE
	lbra   DISPLAY_MANUAL_VARIABLE        ; Otherwise, Branch to DISPLAY_MANUAL_VARIABLE
	
DISPLAY_RUN_VARIABLE:

    ldaa   #$64                           ; Load Accumulator A with $40
    ldx    #RUN_VARIABLE_MESSAGE          ; Load Index Register X with Address of F2_INIT_MESSAGE
    jsr    DISPLAY_CHAR   	              ; Jump to Subroutine DISPLAY_CHAR
    ldx    displayPointer                 ; Load Index Register X with value in displayPointer
    ldab   0,x                            ; Load B with the Contents of X
    lbeq   DONE_RUN_VARIABLE_PRINT        ; If X = $00, Branch to DONE_F2_INIT_PRINT
    rts

RUN_VARIABLE_MESSAGE :

    .ascii 'R'
    .byte  $00               
	rts

DONE_RUN_VARIABLE_PRINT:
 
    movb   #$02, stateVariableState       ; Set next Display State 7 to Execute OPEN_CLOSED_PROMPT
    movb   #$01, displayState             ; Return to Display State HUB
    movb   #$01, firstChar                ; Clear firstChar
    rts	
	
DISPLAY_STOP_VARIABLE:

    ldaa   #$64                           ; Load Accumulator A with $40
    ldx    #STOP_VARIABLE_MESSAGE         ; Load Index Register X with Address of F2_INIT_MESSAGE
    jsr    DISPLAY_CHAR   	              ; Jump to Subroutine DISPLAY_CHAR
    ldx    displayPointer                 ; Load Index Register X with value in displayPointer
    ldab   0,x                            ; Load B with the Contents of X
    lbeq   DONE_STOP_VARIABLE_PRINT       ; If X = $00, Branch to DONE_F2_INIT_PRINT
    rts

STOP_VARIABLE_MESSAGE:

    .ascii 'S'
    .byte  $00               
	rts

DONE_STOP_VARIABLE_PRINT:

    movb   #$02, stateVariableState       ; Set next Display State 7 to Execute OPEN_CLOSED_PROMPT
    movb   #$01, displayState             ; Return to Display State HUB
    movb   #$01, firstChar                ; Clear firstChar
	stab   stateVariable                  ; Store Contents of B into stateVariable
    rts	  
	
DISPLAY_OL_VARIABLE:

    ldaa   #$65                           ; Load Accumulator A with $40
    ldx    #OL_VARIABLE_MESSAGE           ; Load Index Register X with Address of F2_INIT_MESSAGE
    jsr    DISPLAY_CHAR   	              ; Jump to Subroutine DISPLAY_CHAR
    ldx    displayPointer                 ; Load Index Register X with value in displayPointer
    ldab   0,x                            ; Load B with the Contents of X
    lbeq   DONE_OL_VARIABLE_PRINT         ; If X = $00, Branch to DONE_F2_INIT_PRINT
    rts

OL_VARIABLE_MESSAGE:

    .ascii 'OL'
    .byte  $00               
	rts

DONE_OL_VARIABLE_PRINT:

    movb   #$03, stateVariableState       ; Set Next Display State 7 to Execute AUTO_MANUAL_PROMPT
    movb   #$01, displayState             ; Return to Display State HUB
    movb   #$01, firstChar                ; Clear firstChar
	stab   stateVariable                  ; Store Contents of B into stateVariable
    rts	
	
DISPLAY_CL_VARIABLE:

    ldaa   #$65                           ; Load Accumulator A with $40
    ldx    #CL_VARIABLE_MESSAGE           ; Load Index Register X with Address of F2_INIT_MESSAGE
    jsr    DISPLAY_CHAR     	   	      ; Jump to Subroutine DISPLAY_CHAR
    ldx    displayPointer                 ; Load Index Register X with value in displayPointer
    ldab   0,x                            ; Load B with the Contents of X
    lbeq   DONE_CL_VARIABLE_PRINT         ; If X = $00, Branch to DONE_F2_INIT_PRINT
    rts

CL_VARIABLE_MESSAGE :

    .ascii 'CL'
    .byte  $00               
	rts


DONE_CL_VARIABLE_PRINT:

    movb   #$03, stateVariableState       ; Set Next Display State 7 to Execute AUTO_MANUAL_PROMPT
    movb   #$01, displayState             ; Return to Display State HUB
    movb   #$01, firstChar                ; Clear firstChar
    rts	
	
DISPLAY_AUTO_VARIABLE:

    ldaa   #$67                           ; Load Accumulator A with $40
    ldx    #AUTO_VARIABLE_MESSAGE         ; Load Index Register X with Address of F2_INIT_MESSAGE
    jsr    DISPLAY_CHAR   	              ; Jump to Subroutine DISPLAY_CHAR
    ldx    displayPointer                 ; Load Index Register X with value in displayPointer
    ldab   0,x                            ; Load B with the Contents of X
    lbeq   DONE_AUTO_VARIABLE_PRINT       ; If X = $00, Branch to DONE_F2_INIT_PRINT
    rts

AUTO_VARIABLE_MESSAGE :

    .ascii 'A'
    .byte  $00               
	rts


DONE_AUTO_VARIABLE_PRINT:

    movb   #$01, stateVariableState       ; Set next Display State 7 to Execute OPEN_CLOSED_PROMPT
	movb   #$00, stateVariableFlag        ; Clear stateVariableFlag
    movb   #$01, displayState             ; Return to Display State HUB
    movb   #$01, firstChar                ; Set firstChar
	movb   #$00, promptUpFlag             ; Clear promptUpFlag
    rts	
	
DISPLAY_MANUAL_VARIABLE:

    ldaa   #$67                           ; Load Accumulator A with $40
    ldx    #MANUAL_VARIABLE_MESSAGE       ; Load Index Register X with Address of F2_INIT_MESSAGE
    jsr    DISPLAY_CHAR				      ; Jump to Subroutine DISPLAY_CHAR
    ldx    displayPointer                 ; Load Index Register X with value in displayPointer
    ldab   0,x                            ; Load B with the Contents of X
    lbeq   DONE_MANUAL_VARIABLE_PRINT     ; If X = $00, Branch to DONE_F2_INIT_PRINT
    rts

MANUAL_VARIABLE_MESSAGE :

    .ascii 'M'
    .byte  $00               
	rts


DONE_MANUAL_VARIABLE_PRINT:

    movb   #$01, stateVariableState       ; Set next Display State 7 to Execute OPEN_CLOSED_PROMP
	movb   #$00, stateVariableFlag        ; Clear stateVariableFlag
    movb   #$01, displayState             ; Return to Display State HUB
    movb   #$01, firstChar                ; Set firstChar
	movb   #$00, promptUpFlag             ; Clear promptUpFlag
    rts	

SKIP_STATE_VARIABLE_PRINT:

    movb   #$01, stateVariableState       ; Set next Display State 7 to Execute OPEN_CLOSED_PROMP
	movb   #$00, stateVariableFlag        ; Clear stateVariableFlag
    movb   #$01, displayState             ; Return to Display State HUB
    movb   #$01, firstChar                ; Set firstChar
    rts	
	
;===================== Display State 8 -  Update LCD Display ==================
	
displaystate8:
 	
	tst	   autoManualFlag                 ; Test autoManualFlag
	beq    UPDATE_LCD_DONE                ; If autoManualFlag is FALSE, Branch to UPDATE_LCD_DONE
	
	tst    promptUpFlag                   ; Test promptUpFlag
    bne    UPDATE_LCD_DONE  	          ; If promptUpFlag is TRUE, Branch to UPDATE_LCD_DONE 
	
    movb   #$00, LCDUpdateFlag            ; Otherwise, Clear LCDUpdateFlag

    jsr    UPDATELCDL1                    ; Update the LCD top line
    tst    updateLine2Flag                ; See if I want Update LCD Screen Line 2
    beq    UPDATE_LCD_DONE 	   	          ; If updateLine2Flag FALSE, Branch to UPDATE_LCD_DONE
    jsr    UPDATELCDL2                    ; Update the LCD bottom line
	movb   #$01, stateVariableFlag        ; Set stateVariableFlag
    movb   #$00, updateLine2Flag          ; Clear Update Line 2

UPDATE_LCD_DONE:
    movb   #$01, displayState             ; Set next state to: Display HUB
	movb   #$01, stateVariableFlag        ; Set stateVariableFlag
    movb   #$00, LCDUpdateFlag            ; Clear LCD flag
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
	
	ldaa   tc0State                       ; Load Accumulator A with tc0State
	beq    tc0state0                      ; Branch to Timer Channel 0 State 0
	deca                                  ; Decrement Accumulator A
	beq    tc0state1                      ; Branch to Timer Channel 0 State 1
	rts
	
;================ Timer Channel 0 State 0 - Timer Initialization ===============

tc0state0:
	
	bset   PORTJ, $10                     ; initialize to off
    bset   DDRJ, $10                      ; set PORTJ to output
	bset   TIOS, #$01                     ; Setting TC0 for Output Compare
	bset   TCTL2, #$01                    ; Initialize OC0 to Toggle on Successful Compare   
	bclr   TCTL2, #$02                    ; Initialize OC0 to Toggle on Successful Compare
	bset   TFLG1, #$0001                  ; Clearing the Timer Output Compare Flage if Set 
    bset   TMSK1, #$01            		  ; Enabling Timer Channel 0 Output Compare Interrupt
	movb   #$01, tc0State                 ; Set Next Interrupt State to 1
	movb   #$A0, TSCR                     ; Enable the Timer and Stopping While in BGND Mode
	cli                                   ; Enable Maskable Interrupts
	ldd    TCNT                           ; Reads Current Count and Stores it in D
	addd   #$3E80                         ; Adds Interval Value 800 to Current Timer Count
	std    TC0H						      ; Stores Interval + TCNT  
	rts                                   ; Return from Subroutine
	
;================== Timer Channel 0 State 1 - Arbitrary State ==================

tc0state1:

	rts   	                              ; Return from Subroutine
	
;==================== Interrupt Service Routine & Branches =====================

TC0_ISR:
   
    ldd    V_Ref                          ; Load D with V_Ref
    tst    loopSetFlag                    ; Test loopSetFlag
    bne    OPEN_LOOP_START                ; If Open Loop Desired, Branch to OPEN_LOOP_INIT
    subd   V_Act                          ; Subtract VACT from VREF
	bmi    SET_ERROR_NEW_NEG              ; If the N flag was set Branch to SET_ERROR_NEW_NEG
	bra    SKIPtoOPEN_LOOP                ; Otherwise, Branch to SKIPtoOPEN_LOOP
		
OPEN_LOOP_START:

	subd   V_Act                          ; Subtract V_act from V_Ref
	STD    SS_ERROR
	ldd    V_Ref
	bmi    SET_ERROR_NEW_NEG              ; If the N flag was set Branch to SET_ERROR_NEW_NEG
	bra    SKIPtoOPEN_LOOP                ; Otherwise, Branch to SKIPtoOPEN_LOOP
	
SET_ERROR_NEW_NEG:

    movb   #$01, errorSign                ; Set errorSign if V_Ref-V_act Resulted in a Negative #

SKIPtoOPEN_LOOP:   

    std    Error                          ; Store into ERROR_NEW
    addd   E_Sum                          ; Add ERROR_SUM to ERROR_NEW
    bvc    VALID_ESUM                     ; Exit if no overflow from ERROR_SUM+ERROR_NEW
    tst    E_Sum                          ; If overflow, determine sign of ERROR_SUM and
    bmi    NEG_ESUM                       ; saturate accordingly.
    ldd    #$7FFF                         ; Load D with maximum positive value: 32,767
    bra    VALID_ESUM                     ; Branch now that ESUM is valid

NEG_ESUM:

    ldd    #8000                          ; Load D with maximum negative value: -32,768

VALID_ESUM:                               ; Calculation for KI*ERROR_SUM	

    std    E_Sum                          ; Store value in D into ERROR_SUM
    tst    RUN                            ; Test RUN
    bne    KEEP_ERROR_SUM                 ; If RUN = TRUE, keep current ERROR_SUM
    movw   #$0000, E_Sum                  ; If RUN = FALSE, set ERROR_SUM to $0000
    ldd    E_Sum                          ; Load D with ERROR_SUM
    
KEEP_ERROR_SUM:

    ldy    Ki                             ; Load Y with KI
    emuls                                 ; (D)x(Y) ==> Y:D
    ldx    #$400                          ; Load X with value of 1024
    edivs                                 ; (Y:D)/X ==> Result into Y, Remainder ==> D
	sty    Kidivs              	          ; Store Result in Y into Kidivs
  
; Calculation for KP*ERROR_NEW	   
   
    ldd    Error                          ; Load D with ERROR_NEW
    ldy    Kp                             ; Load Y with KP
    emuls                                 ; (D)x(Y) ==> Y:D
    ldx    #$400                          ; Load X with value of 1024
    edivs                                 ; (Y:D)/X ==> Result into Y, Remainder ==> D	   
    sty    Kpdivs                         ; Store result into KPE		      
    ldd    Kpdivs                         ; Load D with KPE
    tst    Ki                             ; Test Ki
    beq    NO_KIDIVS                      ; If Ki is zero, Get Rid of the K Division
    addd   Kidivs                         ; Add KPE to KIE

NO_KIDIVS:

    addd   #$0000                         ; In the KI=0 case, need to add to set V flag	   
    bvc    VALID_a                        ; Exit if no overflow from KPE+KIE
    tst    Kidivs                         ; If overflow, determine sign of KIE and
    bmi    NEG_a                          ; saturate accordingly.
    ldd    #$7FFF                         ; Load D with maximum positive value: 32,767
    bra    VALID_a                        ; Branch now that "a" is valid
NEG_a:

    ldd    #$8000                         ; Load D with maximum negative value: -32,768	   
 
VALID_a:

    std    A_Prime                        ; Store Contents of D into A_Prime
    tst    RUN                            ; Test Run
    beq    MOTOR_STOP                     ; If RUN=0, branch to MOTOR_STOP  
    addd   #$099A                         ; Add 2458 for 6 Volt offset     
    bvc    VALID_a_prime                  ; Branch now that "a prime" is valid
    tst    A_Prime                        ; Test A_Prime
    bmi    NEG_a_prime                    ; If A_Prime Negative, Branch to NEG_a_prime
    ldd    #$7FFF                         ; Load D with maximum positive value: 32,767
    bra    VALID_a_prime                  ; Branch now that "a prime" is valid
	
NEG_a_prime:

    ldd    #8000                          ; Load D with maximum negative value: -32,768
  
VALID_a_prime:	
     
    cpd    #$0D9A                         ; Compare D to 3482
    bpl    VDAC8.5                        ; If greater than, branch to VDAC8.5
    cpd    #$59A                          ; Compare D to 1434
    bmi    VDAC3.5                        ; If less than, branch to VDAC3.5
    std    Dac_Value 	                  ; Store D into VALUE
    bra    exit_PI_CONTROL   

MOTOR_STOP:

    movw   #$99A, Dac_Value               ; 6.0V (2458)
    bra    exit_PI_CONTROL                ; Branch to exit_PI_CONTROL
	
VDAC8.5:

    movw   #$D9A, Dac_Value               ; 8.5V (3482) 
    bra    exit_PI_CONTROL                ; Branch to exit_PI_CONTROL
	
VDAC3.5:	  
 
    movw   #$59A, Dac_Value               ; 3.5V (1434)	
    bra    exit_PI_CONTROL                ; Branch to exit_PI_CONTROL

exit_PI_CONTROL:

    jsr    EFFORT_CALC                    ; Calcualte Effort Of Motor
    bra    ENCODER_READ                   ; Branch to ENCODER_READ

EFFORT_CALC:


    ldd    Dac_Value
	cpd    #$099A
	blo    EFFORT_NEGATIVE
	subd   #$099A
	std	   Dac_ValueMinusSixVolts
	ldy	   #$0064
	emuls
	std	   Dac_ValueTimesHundred
	ldd	   Dac_ValueTimesHundred
	ldx	   #$0400
	idivs
	bra	   EFFORT_POS
	   
EFFORT_NEGATIVE:

    ldd	   #$099A
	subd   Dac_Value
	std	   Dac_ValueMinusSixVolts
	ldy	   #$0064
	emuls
	std	   Dac_ValueTimesHundred
	ldd	   Dac_ValueTimesHundred
	ldx	   #$0400
	idivs
	bra    EFFORT_NEG	   

EFFORT_POS:

    ldy	   #EFFORT_BUF
	movb   #'+',0,Y              	 	  ; Move '-' into the First Buffer Address
    cpx	   #$0064
	bhi	   EFFORT_SAT
	stx	   Effort
	rts
	
EFFORT_SAT:
	
	movw   #$0064, Effort
	rts
	
EFFORT_NEG:

    ldy	   #EFFORT_BUF
	movb   #'-',0,Y              	 	  ; Move '-' into the First Buffer Address	  
    cpx	   #$0064
	bhi	   EFFORT_SAT
	stx	   Effort
	rts	

ENCODER_READ:
	   
	ldd    ENCODER                        ; Load D with current ENCODER value (THETA_NEW)
    std    Theta_New                      ; Store Encoder Value in Theta_New
    subd   Theta_Old                      ; Subtract THETA_OLD from D
	bmi    SET_VACT_NEG                   ; If Subtraction is Negative, Branch to SET_VACT_NEG
	bra    SKIP_NEGATING_VACT             ; Otherwise, Branch to SKIP_NEGATING_VACT

SET_VACT_NEG:

    movb   #$01, VActSign                 ; Set the VActSign to TRUE

SKIP_NEGATING_VACT:	
   	
    std    V_Act                          ; Store Contents of D into V_act
    movw   Theta_New,Theta_Old            ; Move Current Theta_Value into Theta_Old
    movb   #$01, VActFlag                 ; Set VActFlag
    movb   #$01, errorFlag                ; Set errorFlag
    movb   #$01, effortFlag               ; Set effortFlag
	movb   #$01, updateValuesFlag         ; Set updateValuesFlag
 
OUTDAC:

   ldd     Dac_Value                      ; Load Accumulator D With VALUE
   staa    $0301                          ; Store Address of DACs MSB in A
   stab    $0300                          ; Store Address of DACs LSB in B
   bclr    PORTJ, pin5                    ; Clear pin 5 in Port J
   bset    PORTJ, pin5                    ; Set pin 5 in Port J

SCOPE_CALC:
   
   LDD     V_Act
   LDY     #$0D
   EMULS
   ADDD    #$800
   STD     DAC_PLUS_FIVE
   BRA     CHANB_OUTDAC
   
CHANB_OUTDAC:

   LDD     DAC_PLUS_FIVE                  ; Load Accumulator D With VALUE
   STAA    $0303                          ; Store Address of DACs MSB in B
   STAB    $0302                          ; Store Address of DACs LSB in B
   BCLR    PORTJ, pin5                    ; Clear pin 5 in Port J
   BSET    PORTJ, pin5                    ; Set pin 5 in Port J
   
FINAL_ISR_CHECK:

	tst    loopSetFlag
	bne    SET_SS_ERROR
	bra    LCD_COUNTER_CHECK

SET_SS_ERROR:

    movw   SS_ERROR, Error
	
LCD_COUNTER_CHECK:
	
    tst	   LCDUpdateCounter               ; Test LCDUpdateCounter
	bne	   NOT_YET                        ; If LCDUpdateCounter is TRUE, Branch to LCDUpdateCounter
	dec	   LCDUpdateCounter               ; Otherwise Branch to LCDUpdateCounter
	movb   #$01, LCDUpdateFlag            ; Set LCDUpdateFlag
	bra	   ISR_DONE                       ; Branch to ISR_DONE

NOT_YET:
    
	dec	   LCDUpdateCounter               ; Decrement LCDUpdateCounter
	bra	   ISR_DONE                       ; Branch to ISR_DONE
	
ISR_DONE:
 
  	ldd	   TC0H				              ; Grab the Timer Count Corresponding to ISR
  	addd   #$3E80				          ; Add the Interval to The Current Timer Count
  	std	   TC0H				              ; Store the New Timer Count Into the TC0 CR
  	ldaa   TFLG1                          ; LOAD TIMER FLAG ONTO ACC. A
  	oraa   #01                            ; CLEAR CONTENTS (TIMER FLAG) OF ACC. A
  	staa   TFLG1                          ; LOAD ACC. A BACK INTO TIMER FLAG
	rti
  
;===============================================================================

.area interrupt_vectors (abs)

	.org   $FFEE                          ; Address of Next Interrupt        
	.word  TC0_ISR                        ; Load Interrupt Address
	.org    $FFFE                         ; At Reset Vector Location
	.word   __start                       ; Load Starting Address




   
    
   
