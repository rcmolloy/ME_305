; ME 305-02: Intro to Mechatronics :: Robert Cory Molloy & Oscar Andrade
; Display Test Program for Labratory 3

;
;==============================================================================
;

; RAM area
.area bss 

; Tasks

mmstate::    		  .blkb 1     	; Master Mind State Variable
kpdstate::   		  .blkb 1    	; Key Pad Driver State Variable
displayState::  	  .blkb 1   	; Display State Variable
pat1state::    		  .blkb 1  		; Pattern 1 State Variable
time1state::    	  .blkb 1   	; Timing 1 State Variable
pat2state::    	   	  .blkb 1     	; Pattern 2 State Variable
time2state::       	  .blkb 1     	; Timing 2 State Variable
dlystate::    	   	  .blkb 1     	; Delay State Variable

; Display Variables

displayPointer::   	  .blkb 2		; Pointer for the Address of the Next Char 
displayTime1:: 	   	  .blkb 1		; Display Time 1 Flag
displayTime2:: 	   	  .blkb 1		; Display Time 2 Flag
firstChar::		   	  .blkb 1		; First Character in a Message Flag

; Misc Variables

POINTER::			  .blkb 2
BUFFER::			  .blkb 6
RESULT::			  .blkb 2

.area text

;
;==============================================================================
;

_main::
	   bgnd
       jsr    	INIT        		; Initialization
TOP:   bgnd
       jsr    	MASTERMIND			; Mastermind Sub-Routines
	   bgnd
       jsr    	KPD		  			; Key Pad Driver Sub-Routines
	   bgnd
       jsr    	DISPLAY      		; Display Sub-Routines
	   bgnd
       bra    	TOP

;
;==============================================================================
;

; Initialize Sub-Routine State Variables

INIT:

	   clr		mmstate				; Initialize  All Sub-Routine State Variables to State 0
	   clr	  	kpdstate
	   clr		displayState
	   rts	

;
;==============================================================================
;

; Mastermind Sub-Routine

MASTERMIND:

	   ldaa		mmstate				; Grabbing the current state of Mastermind & Branching
	   lbeq		mmstate0			; Initialize Mastermind State 1
	   deca
	   lbeq		mmstate1			; Display & Keypad Activation
	   rts							; Return to Main 

; Mastermind State 0 - Initialization of Mastermind & Buffer

mmstate0:	
					
	   movw		#BUFFER, POINTER 	; Stores the
	   clr		BUFFER				; Clear the BUFFER Variable
	   clr		RESULT				; Clear the RESULT Variable
	   movb		#$01, mmstate		; Set the Mastermind State Variable to 1
	   rts							; Return to Main

; Mastermind State 1 - Splash Screen and Setting Certain Display Flags
	   
mmstate1:

	   movb   	#$01, firstChar     ; Set firstChar flag to 1 (True) 
       movb   	#$01, displayTime1  ; Set displayTime1 flag to 1 (True)
	   movb   	#$01, displayTime2  ; Set displayTime1 flag to 1 (True)
	   movb		#$02, mmstate		; Set the Mastermind State Variable to 2 (Hub)
	   rts							; Return to Main
	   
mmstate2:
	   
	   movb		#$02, mmstate		; Set the Mastermind State Variable to 2 (Hub)
	   rts
;
;==============================================================================
;

; Key Pad Driver Sub-Routine

KPD:

	   ldaa		kpdstate			; Grabbing the current state of Key Pad Driver & Branching
	   lbeq		kpdstate0			; Initialize Key Pad Driver
	   deca
	   lbeq		kpdstate1			; 
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
       
       ;tst      L$KEY_FLG           ; Test Key Available Flag
       ;jsr      GETCHAR             ; Library Command to Get the Character & Store in B
	   rts
	   
;
;==============================================================================
;

; Display Sub-Routine

DISPLAY:

	   ldaa		displayState		; Grabbing the current state of Key Pad Driver & Branching
	   lbeq		displaystate0		; Initialize Display
	   deca
	   lbeq		displaystate1		; 
	   deca
	   lbeq		displaystate2		;
	   deca
	   lbeq		displaystate3		; 
	   rts							; Return to Main 

; Display State 0 - Initialization of the Display

displaystate0: 	
			
       jsr    	INITLCD               ; Initialize the LCD Screen
       jsr    	CLRSCREEN             ; Clears LCD Screen
	   jsr    	CURSOR                ; Initialize the Cursor
       movb   	#$01, displayState    ; Set next state to: Display HUB
       rts
	   
; Display State 1 - Display Branch Hub
	      
displaystate1:

	   bgnd
	   tst    	displayTime1           ; Test displayTime1
       bne    	initTime1              ; If displayTime1 = 1 (True), branch to initTime1
       tst    	displayTime2           ; Test displayTime1
       bne    	initTime2              ; If displayTime1 = 1 (True), branch to initTime1
       movb   	#$01, displayState     ; Set next state as Display HUB
       rts
	   
initTime1:
       
	   movb   	#$02, displayState     ; Set state to initialize display of TIME 1
       rts
	   
initTime2:
       
	   movb   	#$03, displayState     ; Set state to initialize display of TIME 1
       rts

displaystate2:		  			  ; Display Time 1 Prompt On LCD
								  
       ldaa   #$00                ; LCD address range is $00 - $27 and $40 - $67      
       ldx    #MESSAGE_TIME_1     ; Starting address of string to be displayed
       jsr    DISPLAY_1ST_CHAR   ; Jump to DISPLAY_1ST_CHAR subroutine
       ldx    displayPointer      ; Load x with value in Display Pointer
       ldab   0,x                 ; Load accumulator B with value in x
       lbeq   DONE_MESSAGE_PAIR1  ; If x = $00, branch to DONE_MESSAGE_PAIR1
       rts  

MESSAGE_TIME_1:
  
       .ascii 'TIME1=        <F1> TO UPDATE LED1 PERIOD'
       .byte  $00               
       rts
	   
displaystate3:		  			  ; Display Time 2 Prompt On LCD
								  
       ldaa   #$40                ; LCD address range is $00 - $27 and $40 - $67      
       ldx    #MESSAGE_TIME_2     ; Starting address of string to be displayed
       jsr    DISPLAY_1ST_CHAR   ; Jump to DISPLAY_1ST_CHAR subroutine
       ldx    displayPointer      ; Load x with value in Display Pointer
       ldab   0,x                 ; Load accumulator B with value in x
       lbeq   DONE_MESSAGE_PAIR2  ; If x = $00, branch to DONE_MESSAGE_PAIR1
       rts  

MESSAGE_TIME_2:
  
       .ascii 'TIME2=        <F1> TO UPDATE LED1 PERIOD'
       .byte  $00               
       rts

DISPLAY_1ST_CHAR:
      tst    firstChar             ; Test firstChar to Raise Flags
      beq    DISPLAY_WRITE         ; Branch to DISPLAY_WRITE if firstChar = 0 (FALSE)
      stx    displayPointer        ; Store value of x into displayPointer
	  jsr    SETADDR               ; Set cursor to particular LCD address in A
      clr    firstChar             ; Clear firstChar
      rts
	  
DISPLAY_WRITE:
      ldx    displayPointer       ; Load x with value in Display Pointer
      inx                         ; Increment x
      stx    displayPointer       ; Store Display Pointer with incremented x
      jsr    OUTCHAR              ; Print character
      rts
	  
DONE_MESSAGE_PAIR1:               	; Message completely displayed	   
       movb   #$00, displayTime1  	; Set displayTime1 to FALSE
	   movb   #$01, displayState 	; Set next state to the Display HUB
	   movb   #$01, firstChar      	; Set firstChar to TRUE
       rts
	   
DONE_MESSAGE_PAIR2:               	; Message completely displayed	   
       movb   #$00, displayTime2  	; Set displayTime1 to FALSE
	   movb   #$01, displayState 	; Set next state to the Display HUB
	   movb   #$01, firstChar      	; Set firstChar to TRUE
       rts
	   
	   
.area interrupt_vectors (abs)
.org    $FFFE             ; At reset vector location
.word   __start           ; Load starting address		