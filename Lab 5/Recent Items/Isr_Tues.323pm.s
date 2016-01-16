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

;==================== RAM area ====================
.area bss

; Task Variables

mmState::			.blkb 1		         ; Master Mind State Variable
kpdState::			.blkb 1    	         ; Key Pad Driver State Variable
displayState::		.blkb 1   	         ; Display State Variable
delayState::	    .blkb 1		         ; Delay State Variable
backspaceState::	.blkb 1		         ; Backspace State Variable
errorDelayState::   .blkb 1		         ; Error Delay State Variable
fgState:: 			.blkb 1              ; Function Generator State Variable
tc0State:: 			.blkb 1              ; Timer Channel 0 State Variable

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


;==================== Flags ====================

RUN::		        .blkb 1
OpenLoop::		    .blkb 1
NegErrorFlag::      .blkb 1              ; Notifies The Program That New_Error is Negative
NegESumFlag::       .blkb 1              ; Notifies the Progream That E_Sum is Negative
KpNegSatFlag::      .blkb 1              ; Notifies The Program that Kp
KpPosSatFlag::      .blkb 1              ; Notifies The Program that Kp
NegVactSign::       .blkb 1


;==================== Flash ====================
.area text

;==================================  Main Program  =======================================

_main::
 
	jsr    	INIT        		         ; Initialization
 
TOP: 
 
    bgnd 
	 
	;jsr    	MASTERMIND			     ; Mastermind Sub-Routines
 
	;jsr    	KPD		  			     ; Key Pad Driver Sub-Routines
 
	;jsr    	DISPLAY      		     ; Display Sub-Routines
 
	jsr		    TIMER_C0                 ; Timer Channel Zero Sub-Routines

	bra		    TOP
 
;================================  Initialization  =======================================

INIT:

	clr		mmState				         ; Initialize All Sub-Routine State Variables to State 0
	clr	  	kpdState                     ; Clear Keypad Driver States Variable
	clr		displayState                 ; Clear Displaysate State Variable
	clr		backspaceState               ; Clear Backspace State Variable
	clr		delayState			         ; Clear Delay State Variable
	clr		backspaceState		         ; Clear Backspace State Variable
	clr 	errorDelayState		         ; Clear Error Delay State Variable
	movw	#$0100, V_Ref
	movw	#$1400, Kp
	rts	 

;=============================  Mastermind Sub-Routine  ==================================

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
	lbeq	mmstate6			         ; Error Wait State
	rts							         ; Return to Main 

;============  Mastermind State 0 - Initialization of Mastermind & Buffer  ===============

mmstate0:	
					
	movw    #buffer, pointer 		     ; Stores the first address of buffer into pointer
	clr		buffer					     ; Clear the buffer Variable
	movw    #$0000, result			     ; Clear the result Variable
    
    bset   DDRJ, PIN5          ; Set Data Direct Register J to PIN5
    bset   PORTJ, PIN5         ; Set PORTJ to PIN5
    movb   #$00, RUN           ; Motor stop at intialization
    movw   #$99A, Dac_Value        ; 6.0V (2458)
    
    movw   #$19, V_Ref         ; Initial VREF value $19=25
    movw   #$400, Ki           ; Initial KP value $400=1024=1024(1)
    movw   #$1400, Kp          ; Initial KP value $1400=5120=1024(5)
    
    movw   #$0000, V_Act       ; Clear VACT
    movw   #$0000, E_Sum       ; Clear ERROR_SUM
    movw   #$0000, New_Error   ; Clear ERROR_NEW
    movw   #$0000, Theta_Old   ; Clear THETA_OLD
    
	movb	#$01, mmState	   ; Set the Mastermind State Variable to 1    
	rts

;====  Mastermind State 1 - Splash Screen and Setting Displays Flags & Counters  =========

mmstate1:

	movb	 #$01, firstChar     	     ; Set firstChar flag to 1 (True) 
    movb     #$01, displayWaveValues	 ; Set displayTopPrint flag to 1 (True)
    movw     #25000, errorDelayCounter   ; Set Error Delay Counter to 1500

	movb	 #$02, mmState			     ; Set the Mastermind State Variable to 2 (Hub)
	rts								     ; Return to Main

;===============  Mastermind State 2 - Hub  ============================

mmstate2:

	tst 	keyFlag                      ; Test keyFlag
	beq		NO_KEY                       ; If keyFlag is False, Branch to NO_KEY
	clr 	keyFlag                      ; Clear keyFlag
	cmpb 	#$F1                         ; Compare Acc. B to Hex Value of 'F1'
	beq 	F1_TRUE                      ; If B = '$F1', Branch to F1_TRUE
	cmpb 	#$F2                         ; Compare Acc. B to Hex Value of 'F2'
	beq		F2_TRUE                      ; If B = '$F2', Branch to F2_TRUE
	cmpb 	#$08                         ; Compare Acc. B to Hex Value of '08'
	beq 	BS_TRUE                      ; If B = '$08', Branch to BS_TRUE
	cmpb 	#$0A                         ; Compare Acc. B to Hex Value of '0A'
	beq 	ENT_TRUE                     ; If B = '$0A', Branch to ENT_TRUE
	lbra	DIGIT_TRUE                   ; Otherwise Branch to DIGIT_TRUE

NO_KEY:
	
	tst		backspaceFlag                ; Test backspaceFlag
	bne		BACKSPACE_GO                 ; If backspaceFlag Not $00, Branch to BACKSPACE_GO
	tst		enterFlag                    ; Test enterFlag
	bne		ENTER_GO                     ; If enterFlag Not $00, Branch to ENTER_GO
	tst		digitFlag                    ; Test digitFlag
	bne		DIGIT_GO                     ; If digitFlag Not $00, Branch to DIGIT_GO
	tst		errorDelayFlag               ; Test errorDelayFlag
	bne 	ERROR_DELAY_TRUE             ; If errorDelayFlag Not $00, Branch to ERROR_DELAY_TRUE
	movb 	#$02, mmState                ; If No Key was Pressed, Return to Hub
	rts
	
F1_TRUE:
	
	movb 	#$02, mmState                ; Set next Mastermind State (mmstate) to Hub
	rts	
		
F2_TRUE:
	
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


;========================= Mastermind State 3 - Backspace State ==========================
	
mmstate3:
		 
	tst 	digitCounter                 ; Test digitCounter
	beq 	BSPACE_DONE                  ; If digitCounter is $00, Branch to BSPACE_DONE
	tst 	backspaceFlag                ; Test digitCounter
	beq 	BSPACE_DONE                  ; If digitCounter is $00, Branch to BSPACE_DONE
	movb 	#$01, backspacePrint         ; Set backspaceFlag = 1,
	rts

BSPACE_DONE:
	movb	#$00, backspaceFlag          ; Set backspaceFlag = 0
	movb 	#$02, mmState                ; Set next Mastermind State (mmstate) to M^2 Hub
	rts

;=========================== Mastermind State 4 - Enter State ============================
	
mmstate4:
	
	tst	 	RUN                          ; Test RUN
	lbne	WAVE_RUNNING                 ; If RUN Not $00, Branch to WAVE_RUNNING
	tst	 	enterFlag                    ; Test enterFlag
	bne		ENTER_INIT                   ; If enterFlag Not $00, Branch to ENTER_INIT
	tst		errorDelayFlag               ; Test errorDelayFlag
	bne 	ERROR_DELAY_TRUE             ; If errorDelayFlag Not $00, Branch to ERROR_DELAY_TRUE
	lbeq	ENTER_DONE                   ; If errorDelayFlag $00, Branch to ENTER_DONE
	rts
	
ERROR_DELAY_TRUE:
                          
	movb   #$06, mmState                 ; Set next Mastermind State (mmstate) to Err Dly
	rts	
	
ENTER_INIT:
			
	tst 	digitCounter                 ; Test digitCounter
	lbeq 	EMPTY_VALUE                  ; If digitCounter is $00, Branch to EMPTY_VALUE
	bra 	ASCII_BCD                    ; Otherwise Branch to ASCII_BCD

ASCII_BCD:

	movw    #buffer, pointer             ; Load buffer Address Into pointer
		
	LOOP:

		ldaa 	#$0A                     ; Load Accumulator A with 10    
		ldab 	result                   ; Load Accumulator B with result    
		mul                              ; Multiply A and B, Store in A:B or D
		cmpa 	#$00                     ; Compare Accumulator D with 0   
		bhi 	TOO_BIG_VALUE		     ; If greater than 255 hex, Branch to TOO_BIG_VALUE         
		stb 	result                   ; Store Accumulator D into result    
		ldx 	pointer                  ; Load X with buffer Address Stored In pointer    
		ldab 	0,x                      ; Load Accumulator B with the Contents in X  
		subb 	#$30                     ; Subtract 30 From Accumulator B  
		clra                             ; Clear Accumulator A 
		addb 	result                   ; Add result To B and Store Back Into B
		bcs 	TOO_BIG_VALUE		     ; If greater than 255 hex, Branch to TOO_BIG_VALUE  
		stb 	result                   ; Store D in result 
		dec 	digitCounter             ; Decrement digitCounter
		tst		digitCounter             ; Test digitCounter         
		beq 	VALUE_PUSH_MAIN          ; If digitCounter is zero, Branch to VALUE_PUSH_MAIN        
		inx                              ; Increment Address in X
		stx		pointer                  ; Store Address In X Into Pointer
		bra 	LOOP                     ; Branch Back Into LOOP          	
	
VALUE_PUSH_MAIN:

	ldx		result                       ; Load Index Register X with result
	cpx		#$0000                       ; Compare Index Register X with 0
	beq		ZERO_VALUE                   ; If Index Register is 0, Branch to ZERO_VALUE
	bne		NINT_ENT                     ; If Index Register is 1, Branch to NINT_ENT
	bra		ENTER_DONE                   ; Otherwise Branch To ENTER_DONE
	
ZERO_VALUE:

	movb	#$01, zeroValuePrint         ; Set zeroTicksPrint to TRUE
	movb    #$01, errorDelayFlag         ; Set errorDelayFlag to TRUE
	movw	#$0000, result               ; Set result to 0
	movw    #buffer, pointer             ; Move Buffer Address into pointer
	clr	    digitCounter                 ; Clear the digitCounter
	movb	#$00, enterFlag              ; Set enterFlag to FALSE
	rts
		
EMPTY_VALUE:
	
	movb	#$01, emptyValuePrint        ; Set emptyValuePrint to TRUE
	movb    #$01, errorDelayFlag         ; Set errorDelayFlag to TRUE
	movw	#$0000, result               ; Set result to FALSE
	movw    #buffer, pointer             ; Move buffer Address Into Pointer
	clr	    digitCounter                 ; Clear the digitCounter
	movb	#$00, enterFlag              ; Set enterFlag to FALSE
	rts		
	
TOO_BIG_VALUE:

	movb	#$01, valueTooBigPrint       ; Set valueTooBigPrint to TRUE
	movb    #$01, errorDelayFlag         ; Set errorDelayFlag to TRUE
	movw	#$0000, result               ; Set result to FALSE
	movw    #buffer, pointer             ; Move buffer Address Into Pointer
	clr	    digitCounter                 ; Clear the digitCounter
	movb	#$00, enterFlag              ; Set enterFlag to FALSE
	rts
	
NINT_ENT:

    movb	#$00, enterFlag              ; Set enterFlag to FALSE
	movb 	result, NINT                 ; Move Contents of Result Into NINT
	bra		ENTER_DONE                   ; Branch to ENTER_DONE
WAVE_RUNNING:

	clr		enterFlag		             ; Clear the enterFlag
	movb	#$02, mmState                ; Set next Mastermind State (mmstate) to M^2 Hub
	rts  
	 		
ENTER_DONE:

	movw	#$0000, result               ; Set result to 0
	clr	    digitCounter                 ; Clear the digitCounter
	movw    #buffer, pointer             ; Move buffer Address Into pointer
	movb	#$00, enterFlag              ; Set enterFlag to FALSE
	movb	#$01, NINTOkFlag             ; Set the NINTOkFlag
	movb	#$02, mmState                ; Set next Mastermind State (mmstate) to M^2 Hub
	rts          			
 
	
;====================  Mastermind State 5 - Digit Entered   ====================

mmstate5:

	tst	    waveValue                    ; Test waveFlag
	beq		WAVE_SELECT                  ; If waveFlag $00, Branch to WAVE_SELECT
 	tst	    RUN                          ; Test RUN
	bne		CANCEL_RUN                   ; If RUN Not $00, Branch to CANCEL_RUN
	tst		digitFlag                    ; Test digitFlag
	lbne	DIGIT_WAIT				     ; If digitFlag Not $00, Branch to DIGIT_WAIT
	cmpb	#$41				         ; Compare Hexadecimal Value In B to $41
	lblo	DIGIT				         ; If Value in B < $40, Branch to DIGIT
	lbra	NOTDIGIT			         ; Otherwise Value in B is not a Digit, Branch to NOTDIGIT
	
CANCEL_RUN:

    cmpb   #$34                          ; Compare Accumulator B with 34
	lbhi   NOTDIGIT                      ; If Accumulator B > 34, Branch to NOTDIGIT
	cmpb   #$30                          ; Compare Accumulator B with 30
	lbeq   NOTDIGIT                      ; If Accumulator B = 30, Branch to NOTDIGIT
	movb   #$00, RUN                     ; Set RUN = 0
	bra	   WAVE_SELECT	                 ; Branch to WAVE_SELECT
	
WAVE_SELECT:

	cmpb	#$31                         ; Compare Accumulator B with 31
	beq		WAVE_SELECT_SAW              ; If Accumulator B = 31, Branch to WAVE_SELECT_SAW
	cmpb	#$32                         ; Compare Accumulator B with 32
	beq		WAVE_SELECT_SINE7            ; If Accumulator B = 32, Branch to WAVE_SELECT_SINE7
	cmpb	#$33                         ; Compare Accumulator B with 33
	beq		WAVE_SELECT_SQUARE           ; If Accumulator B = 32, Branch to WAVE_SELECT_SQUARE
	cmpb	#$34                         ; Compare Accumulator B with 34
	beq		WAVE_SELECT_SINE15           ; If Accumulator B = 32, Branch to WAVE_SELECT_SINE15
	clr		keyFlag                      ; Clear keyFlag
	movb	#$02, mmState                ; Return to Mastermind HUB
	rts
	
WAVE_SELECT_SAW:

	ldx		#SAWTOOTH                    ; Load Index Register X with Address of SAWTOOTH Wave Data
	stx		WAVEPTR                      ; Store Address in X into WAVEPTR
	clr    	waveFlag                     ; Clear waveFlag
	stab	waveValue                    ; Store Contents In Accumulator B in waveValue
	movb	#$01, digitFlag              ; Set the digitFlag
	movb	#$01, displayWave            ; Set the displayWave 
	rts
	
WAVE_SELECT_SINE7:

	ldx		#SINE_7                      ; Load Index Register X with Address of SINE_7 Wave Data
	stx		WAVEPTR	                     ; Store Address in X into WAVEPTR
	clr    	waveFlag                     ; Clear waveFlag
	stab	waveValue                    ; Store Contents In Accumulator B in waveValue
	movb	#$01, digitFlag              ; Set the digitFlag
	movb	#$01, displayWave            ; Set the displayWave 
	rts
	
WAVE_SELECT_SQUARE:
	
	ldx		#SQUARE                      ; Load Index Register X with Address of SQUARE Wave Data
	stx		WAVEPTR                      ; Store Address in X into WAVEPTR
	clr    	waveFlag                     ; Clear waveFlag
	stab	waveValue                    ; Store Contents In Accumulator B in waveValue
	movb	#$01, digitFlag              ; Set the digitFlag
	movb	#$01, displayWave            ; Set the displayWave
	rts
	
WAVE_SELECT_SINE15:

	ldx		#SINE_15                     ; Load Index Register X with Address of SINE_15 Wave Data
	stx		WAVEPTR	                     ; Store Address in X into WAVEPTR
	clr    	waveFlag                     ; Clear waveFlag
	stab	waveValue                    ; Store Contents In Accumulator B in waveValue
	movb	#$01, digitFlag              ; Set the digitFlag
	movb	#$01, displayWave            ; Set the displayWave
	rts
  
DIGIT:

    inc		digitCounter                 ; Increment digitCounter
	movb	#$01, digitFlag              ; Set the digitFlag
	bra		BUFFER_STORE                 ; Jump To Subroutine BUFFER_STORE

NOTDIGIT:

	movb	#$00, keyFlag	             ; Clear the keyFlag
	movb	#$02, mmState				 ; Set next Mastermind State (mmstate) to M^2 Hub
	rts

DIGIT_WAIT:

	tst     echoFlag                     ; Test the echoFlag
	lbeq	DIGIT_DONE                   ; If echoFlag = $00, Branch to DIGIT_DONE
	rts
	
DIGIT_DONE:

    movb   	#$00, digitFlag              ; Clear the digitFlag
	movb 	#$02, mmState                ; Set next Mastermind State (mmstate) to M^2 Hub
	rts 
		
	
;====================  Mastermind State 6 - Error Delay State   ================	
	
mmstate6:

	tst    errorDelayFlag                ; Test errorDelayFlag
	beq	   ERROR_DELAY_HANDOFF           ; If errorDelayFlag = $00, Branch ERROR_DELAY_HANDOFF
	ldaa   errorDelayState               ; Load Accumulator A with errorDelayState
    beq    errordelaystate0              ; If errorDelayState = $0, Branch to errordelaystate0
    deca                                 ; Otherwise Decrement Accumulator A
    beq    errordelaystate1              ; If errorDelayState = $0, Branch to errordelaystate0
    rts                       

errordelaystate0:                         
    movb   #$01, errorDelayState         ; Set errorDelayState to $0
    rts
		
errordelaystate1:                         
    ldx    errorDelayCounter             ; Load Index Register X with errorDelayCounter
	cpx	   #$0000                        ; Compare Index Register X with $0
	beq	   ERROR_DELAY_DONE              ; If X=$0 , Branch to ERROR_DELAY_DONE
    dex                                  ; Otherwise Decrement Index Register X
    stx    errorDelayCounter             ; Store Index Register X with errorDelayCounter    
    rts
	
ERROR_DELAY_DONE:

  	movw   #25000, errorDelayCounter     ; Set errorDelayCounter to 1500		 
    movb   #$00, errorDelayState         ; Set errorDelayState to $0
    movb   #$00, errorDelayFlag          ; Set errorDelayFlag to FALSE
    movb   #$01, displayPrompt			 ; Set displayPrompt to TRUE
	movb   #$01, firstChar               ; Set firstChar to TRUE
	rts

ERROR_DELAY_HANDOFF:

  	movb	#$02, mmState                ; Set Next Mastermind State to HUB 
	rts

;=========  Mastermind - Miscellaneous Sub-Rountines / Branches   ==============

BUFFER_STORE:

	ldaa   digitCounter                  ; Load Accumulator A with digitCounter
	cmpa   #$03                          ; Compater Accumulator with $03
	bhi    BUFFER_STORE_LIMIT            ; If A is higher or equal than $03, Branch to BUFFER_STORE_LIMIT
	ldx    pointer                       ; Load X with pointer
	ldab   digitStore				     ; Load B with digitStore
	stab   0,x                           ; Store Contents of B into X
	inx                                  ; Increment X
	stx     pointer                      ; Store X in Pointer
	movb	#$01, echoFlag               ; Set echoFlag to TRUE
	movb	#$00, keyFlag	             ; Set keyFlag to FALSE
	rts
	
BUFFER_STORE_LIMIT:

	dec	   digitCounter                  ; Decrement digitCounter
	clr	   keyFlag                       ; Clear the keyFlag
	clr	   echoFlag                      ; Clear the echoFlag
	rts	
	
CLEAR_BUFFER:
		
	movb   #$00, clrBufferCounter        ; Clear clrBufferCounter
	movw   #buffer, pointer              ; Move buffer Address into pointer
		  
	C_B_LOOP:
	
		 ldx  	   pointer               ; Load Index Register X with pointer
		 ldab	   #$00                  ; Load Accumulator B with $00
		 stab 	   0,x                   ; Store Contents Of B into X
		 inc	   clrBufferCounter      ; Increment clrBufferCounter
		 ldaa	   clrBufferCounter      ; Load clrBufferCounter Into Accumulator A
		 cmpa	   #$05                  ; Compare A with $05
		 beq	   CLEAR_BUFFER_DONE     ; If A=$00,  Branch to CLEAR_BUFFER_DONE
		 ldx	   pointer               ; Load Index Register X with pointer
		 inx  	                         ; Increment X
		 stx	   pointer               ; Store Contents of X into pointer
		 bra	   C_B_LOOP              ; Branch to C_B_LOOP
		 
CLEAR_BUFFER_DONE:
		
	clr	   digitCounter		             ; Clear the digitCounter
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
   
   bne     STOP_MOTOR
   
   tst     OpenLoop
   
   bne     RUNOPENLOOP  
    
   ldd     V_Ref
   
   subd    V_Act
   
   std     New_Error
   
   tst     New_Error
   
   bmi     NEG_ERROR_SIGN
   
   bra     POS_ERROR_SIGN
   
STOP_MOTOR:
    
   movw    SIX_VOLTS, Dac_Value
   lbra    OUTDAC  
   
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
   addd    SIX_VOLTS
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
    bra    OUTDAC
 
OUTDAC:
	
   ldd     Dac_Value                      ; Load Accumulator D With VALUE
   staa    $0303                          ; Store Address of DACs MSB in A
   stab    $0302                          ; Store Address of DACs LSB in B
   bclr    PORTJ, pin5                    ; Clear pin 5 in Port J
   bset    PORTJ, pin5                    ; Set pin 5 in Port J
	
   rti		

;===============================================================================

.area interrupt_vectors (abs)
	  .org   $FFEE                        ; Address of Next Interrupt        
	  .word  TC0_ISR                      ; Load Interrupt Address
	  .org    $FFFE                       ; At Reset Vector Location
	  .word   __start                     ; Load Starting Address