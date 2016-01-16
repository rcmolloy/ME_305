; ME 305-02: Intro to Mechatronics :: Robert Cory Molloy & Oscar Andrade
; Display Test Program for Labratory 3

;
;==============================================================================
;

; RAM area
.area bss 

; Tasks
mmstate::    	.blkb 1     	; Master Mind State Variable
kpdstate::   	.blkb 1    		; Key Pad Driver State Variable
dispstate::   	.blkb 1   		; Display State Variable
pat1state::    	.blkb 1  		; Pattern 1 State Variable
time1state::    .blkb 1   		; Timing 1 State Variable
pat2state::    	.blkb 1     	; Pattern 2 State Variable
time2state::    .blkb 1     	; Timing 2 State Variable
dlystate::    	.blkb 1     	; Delay State Variable

; Display Variables
DISPADD:: 	.blkb 2				; Address of the next character ready to read and displayed

.area text

;
;==============================================================================
;

_main::

       jsr    	INIT        		; Initialization
TOP:   bgnd
       jsr    	MASTERMIND			; Mastermind Sub-Routines
       jsr    	KPD		  			; Key Pad Driver Sub-Routines
       jsr    	DISP      			; Display Sub-Routines
       jsr    	PAT_1      			; Pattern 1 Sub-Routines
       jsr    	TIME_1      		; Timing_1
       jsr    	PAT_2      			; Pattern_2
       jsr    	TIME_2     			; Timing_2
       jsr    	DELAY      			; Delay
       bra    	TOP

;
;==============================================================================
;

; Initialize Sub-Routine State Variables

INIT:

	   clr		mmstate				; Initialize  All Sub-Routine State Variables to State 0
	   clr	  	kpdstate
	   clr		dispstate
	   clr	  	kpdstate
	   clr		pat1state
	   clr	  	time1state
	   clr		pat2state
	   clr		time2state
	   clr		dlystate		

;
;==============================================================================
;

; Mastermind Sub-Routine

MASTERMIND:

	   ldaa		mmstate				; Grabbing the current state of Mastermind & Branching
	   lbeq		mmstate0			; Initialize Mastermind State 1
	   deca
	   lbeq		mmstate1			; Display & Keypad Activation
	   deca
	   lbdq		mmstate2			; Mastermind Hub
	   rts							; Return to Main 

; Mastermind State 0 - Initialization of Mastermind & Buffer

mmstate0:						
	   movw		#BUFFER, POINTER 	; Stores the
	   clr		BUFFER				; Clear the BUFFER Variable
	   clr		RESULT				; Clear the RESULT Variable
	   movb		#$01, mmstate		; Set the Mastermind State Variable to 1
	   rts							; Return to Main
	   
;
;==============================================================================
;

; Key Pad Driver Sub-Routine

KPD:

	   ldaa		kpdstate			; Grabbing the current state of Key Pad Driver & Branching
	   lbeq		kpdstate0			; Initialize Key Pad Driver
	   deca
	   lbeq		kpdstate1			; 
	   deca
	   lbdq		kpdstate2			; 
	   rts							; Return to Main 

; Key Pad Driver State 0 - Initialization of Key Pad Driver

kpdstate0: 	
			
       jsr      INITKEY             ; Library Command to Initialize Keypad
       jsr      FLUSH_BFR           ; Library Command to Flush the Buffer
       jsr      KP_ACTIVE           ; Libary Command to Unmask the Keypad Interrupts
       movb     #$01, kpdstate      ; Set the KPD State Variable to 1
       rts

; Key Pad Driver State 1 - Wait for the Key Press to Be Stored in Buffer

kpdstate1:
       
       tst      L$KEY_FLG           ; Test Key Available Flag
       bne      exitkpdstate1       ; Exit Key Pad Driver State 1 if Key Flag is Zero
       jsr      GETCHAR             ; Library Command to Get the Character & Store in B
       cmp


.area interrupt_vectors (abs)
.org    $FFFE             ; At reset vector location
.word   __start           ; Load starting address		