;==================== Assembler Equates ====================

ENCODER		   = 	 $0280				 ; Encoder Address 
SIX_VOLTS      =     $009A               ; Voltage Offset to be Added to A

;==================== RAM area ====================
.area bss

V_Ref::         .blkb 2                   ; Voltage Reference Inputted By User [BDI/BTI]
V_Act::         .blkb 2                   ; Actual Voltage at Encoder
New_Error::     .blkb 2                   ; V_Ref - V_act
Old_Error::     .blkb 2                   ; Previous Calculated Error
E_Sum::         .blkb 2                   ; Integral
A::             .blkb 2                   ; (Kp*Error)+(Ki/s*Esum)
A_Prime::       .blkb 2                   ; [A + 2458]
A_Star::        .blkb 2                   ; Dac Value 
Ki::            .blkb 2                   ; Integral Control
Kp::            .blkb 2                   ; Proportional Control
Kpdivs::        .blkb 2                   ; Kp*e, After Edivs
Kidivs::        .blkb 2                   ; Ki*esum, after Edivs
Dac_Input::     .blkb 2                   ; Voltage Value to be Fed to DAC
Theta_New::     .blkb 2                   ; New Displacment Interval Read From Encoder
Theta_Old::     .blkb 2                   ; Previous Displacement Interval Read From Encoder

;==================== Flags ====================

NegErrorFlag::  .blkb 1                   ; Notifies The Program That New_Error is Negative
NegESumFlag::   .blkb 1                   ; Notifies the Progream That E_Sum is Negative
KpNegSatFlag::  .blkb 1                   ; Notifies The Program that Kp
KpPosSatFlag::  .blkb 1                   ; Notifies The Program that Kp


;==================== Flash ====================
.area text

_main::
 

;==================== Interrupt Service Routine & Branches =====================
	  
TC0_ISR:

   ldd   V_Ref
   subd  V_Act
   std   New_Error
   tst   New_Error
   bmi   NEG_ERROR_SIGN
   bra   POS_ERROR_SIGN
	
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
   movw   #7FFF, kpdivs
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

   std    A
   bra    CALCUALTE_A_PRIME

SAT_A:

   ldy    Kpdivs
   cpy    #$00
   bpl    POS_A_SAT
   bmi    NEG_A_SAT
   
POS_A_SAT:

   movw   #$7FFF, A
   bra    CALCUALTE_A_PRIME

NEG_A_SAT:  

   movw   #$0800, A
   bra    CALCUALTE_A_PRIME

CALCUALTE_A_PRIME:

   ldd    A
   addd   SIX_VOLTS
   bvc    NO_APRIME_SAT
   bvs    SAT_APRIME
      
SAT_APRIME:
   
   ldy    A
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



	
	
NOT_YET:

	ldd  TC0H                           ; Store TC0H into D
	
	addd #$0320                         ; Adds interval 800 to D
	
	std  TC0H                           ; Loads interval + TC0H back into D
		
	bset TFLG1, #$0001   	            ; Clear the TC0 Compare Interrupt Flag
		
	rti                                 ; Return From Interrupt

OUTDAC:
	
	ldd VALUE                           ; Load Accumulator D With VALUE
	
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