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

V_Ref::         .blkb 2                   ; Voltage Reference Inputted By User [BDI/BTI]
V_Act::         .blkb 2                   ; Actual Voltage at Encoder
New_Error::     .blkb 2                   ; V_Ref - V_act
Old_Error::     .blkb 2                   ; Previous Calculated Error
E_Sum::         .blkb 2                   ; Integral
KiplusKp::             .blkb 2                   ; (Kp*Error)+(Ki/s*Esum)
A_Prime::       .blkb 2                   ; [A + 2458]
A_Star::        .blkb 2                   ; Dac Value 
Ki::            .blkb 2                   ; Integral Control
Kp::            .blkb 2                   ; Proportional Control
Kpdivs::        .blkb 2                   ; Kp*e, After Edivs
Kidivs::        .blkb 2                   ; Ki*esum, after Edivs
Dac_Value::     .blkb 2                   ; Voltage Value to be Fed to DAC
Theta_New::     .blkb 2                   ; New Displacment Interval Read From Encoder
Theta_Old::     .blkb 2                   ; Previous Displacement Interval Read From Encoder

;==================== Flags ====================

RUN::		    .blkb 1
OpenLoop::		.blkb 1
NegErrorFlag::  .blkb 1                   ; Notifies The Program That New_Error is Negative
NegESumFlag::   .blkb 1                   ; Notifies the Progream That E_Sum is Negative
KpNegSatFlag::  .blkb 1                   ; Notifies The Program that Kp
KpPosSatFlag::  .blkb 1                   ; Notifies The Program that Kp


;==================== Flash ====================
.area text

_main::
 
	jsr    	INIT        		         ; Initialization
 
TOP: 
 
	;jsr    	MASTERMIND			         ; Mastermind Sub-Routines
 
	;jsr    	KPD		  			         ; Key Pad Driver Sub-Routines
 
	;jsr    	DISPLAY      		         ; Display Sub-Routines
 
	jsr		TIMER_C0                     ; Timer Channel Zero Sub-Routines

	bra		TOP
 
;================================  Initialization  =======================================

INIT:

	clr		mmState				         ; Initialize All Sub-Routine State Variables to State 0
	clr	  	kpdState                     ; Clear Keypad Driver States Variable
	clr		displayState                 ; Clear Displaysate State Variable
	clr		backspaceState               ; Clear Backspace State Variable
	clr		delayState			         ; Clear Delay State Variable
	clr		backspaceState		         ; Clear Backspace State Variable
	clr 	errorDelayState		         ; Clear Error Delay State Variable
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

	rts   	; Return from Subroutine
	 
;==================== Interrupt Service Routine & Branches =====================
	  
TC0_ISR:

   tst   RUN
   bne   STOP_MOTOR   
   tst   OpenLoop
   ldd   V_Ref
   subd  V_Act
   std   New_Error
   tst   New_Error
   bmi   NEG_ERROR_SIGN
   bra   POS_ERROR_SIGN
   
STOP_MOTOR:
    
   movw   SIX_VOLTS, Dac_Value
   lbra   OUTDAC
	
NEG_ERROR_SIGN:
    
   movb  #$01, NegErrorFlag
	
POS_ERROR_SIGN:

   ldd   New_Error
   addd  E_Sum
   bvc   NO_SDBA_ESUM
   bvs   SDBA_ESUM
	
SDBA_ESUM:

   ldy    New_Error
   cpy    #$00
   bpl    POS_ESUM_SAT
   bmi    NEG_ESUM_SAT
	
POS_ESUM_SAT:
   
   movw   #$7FFF, E_Sum
   bra    NO_SDBA_ESUM
 
NEG_ESUM_SAT:
   
   movb   #$01, NegESumFlag
   movw   #8000, E_Sum
   bra    NO_SDBA_ESUM  
	
NO_SDBA_ESUM:

   ldy    New_Error
   ldd    Kp
   emuls  
   ldx    #$0400
   edivs  
   bvc    NO_SAT_Kp_DIV
   bvs    SAT_Kp_DIV
   
SAT_Kp_DIV:
   
   tst    NegErrorFlag
   beq    POS_Kp_SAT
   movw   #$7FFF, Kpdivs
   bra    CALCULATE_A
   
POS_Kp_SAT:

   movw   #$0800, Kpdivs
   bra    CALCULATE_A
      
NO_SAT_Kp_DIV:
   
   sty    Kpdivs
   bra    CALCULATE_A
   
CALCULATE_A:

   ldd    Kpdivs
   addd   Kidivs
   bvc    NO_A_SAT
   bvs    SAT_A
   
NO_A_SAT:

   std    KiplusKp
   bra    CALCUALTE_A_PRIME

SAT_A:

   ldy    Kpdivs
   cpy    #$00
   bpl    POS_A_SAT
   bmi    NEG_A_SAT
   
POS_A_SAT:

   movw   #$7FFF, KiplusKp
   bra    CALCUALTE_A_PRIME

NEG_A_SAT:  

   movw   #$0800, KiplusKp
   bra    CALCUALTE_A_PRIME

CALCUALTE_A_PRIME:

   ldd    KiplusKp
   addd   SIX_VOLTS
   bvc    NO_APRIME_SAT
   bvs    SAT_APRIME
      
SAT_APRIME:
   
   ldy    KiplusKp
   cpy    #$00
   bpl    POS_APRIME_SAT
   bmi    NEG_APRIME_SAT
   
POS_APRIME_SAT:

   movw   #$7FFF, A_Prime
   bra    GET_ASTAR
   
NEG_APRIME_SAT:

   movw   #$0800, A_Prime
   bra    GET_ASTAR

NO_APRIME_SAT:

   std    A_Prime
   bra    GET_ASTAR

GET_ASTAR:
   
   ldd    A_Prime
   cpd    #$0D9A
   bgt    HIGH_SAT
   cpd    #$059A
   blt    LOW_SAT
   std    Dac_Value
   bra    OUTDAC
   
HIGH_SAT:
   
   movw   #$0D9A, Dac_Value
   bra    OUTDAC
     
LOW_SAT:

   movw   #$059A, Dac_Value
   bra    OUTDAC

OUTDAC:
	
	ldd  Dac_Value                      ; Load Accumulator D With VALUE
	
	staa $0303                          ; Store Address of DACs MSB in A
	
	stab $0302                          ; Store Address of DACs LSB in B
	
	bclr PORTJ, pin5                    ; Clear pin 5 in Port J
	
	bset PORTJ, pin5                    ; Set pin 5 in Port J
	
	rts		







;===============================================================================

.area interrupt_vectors (abs)
	  .org   $FFEE                      ; Address of Next Interrupt        
	  .word  TC0_ISR                    ; Load Interrupt Address
	  .org    $FFFE                     ; At Reset Vector Location
	  .word   __start                   ; Load Starting Address