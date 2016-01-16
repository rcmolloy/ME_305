; ME 305-02: Intro to Mechatronics :: Robert Cory Molloy & Oscar Andrade
; Display Test Program for Labratory 3

;
;==============================================================================
;

; RAM area
.area bss 

; Tasks

mmState::    		  .blkb 1     	; Master Mind State Variable
kpdState::   		  .blkb 1    	; Key Pad Driver State Variable
displayState::  	  .blkb 1   	; Display State Variable
pat1State::    		  .blkb 1  		; Pattern 1 State Variable
time1State::    	  .blkb 1   	; Timing 1 State Variable
pat2State::    	   	  .blkb 1     	; Pattern 2 State Variable
time2State::       	  .blkb 1     	; Timing 2 State Variable
dlyState::    	   	  .blkb 1     	; Delay State Variable

; Display Variables

displayPointer::   	  .blkb 2		; Pointer for the Address of the Next Char 
displayTime1:: 	   	  .blkb 1		; Display Time 1 Flag
displayTime2:: 	   	  .blkb 1		; Display Time 2 Flag
firstChar::		   	  .blkb 1		; First Character in a Message Flag

; Key Pad Variables

keyPressed::	   	  .blkb 1		; Key Has Been Pressed Flag
keyStore::			  .blkb 2		; Storing the Key for Processing
echoDigitInit::		  .blkb 1		;
echoDigitPrint::      .blkb 1		;

; Flag Variables

F1Flag::			  .blkb 1		;
F2Flag::			  .blkb 1		;

; Misc Variables

POINTER::			  .blkb 2
BUFFER::			  .blkb 6
RESULT::			  .blkb 2
COUNT::				  .blkb 1
digitCounter::		  .blkb 1

.area text

;
;==============================================================================
;

_main::
	   bgnd
       jsr    	INIT        		; Initialization
TOP:   bgnd
       jsr    	MASTERMIND			; Mastermind Sub-Routines

       jsr    	KPD		  			; Key Pad Driver Sub-Routines

       jsr    	DISPLAY      		; Display Sub-Routines

       bra    	TOP

;
;==============================================================================
;

; Initialize Sub-Routine State Variables

INIT:

	   clr		mmState				; Initialize  All Sub-Routine State Variables to State 0
	   clr	  	kpdState
	   clr		displayState
	   rts	

;
;==============================================================================
;

; Mastermind Sub-Routine

MASTERMIND:

	   ldaa		mmState				; Grabbing the current state of Mastermind & Branching
	   lbeq		mmstate0			; Initialize Mastermind State 1
	   deca
	   lbeq		mmstate1			; Display & Keypad Activation
	   deca
	   lbeq		mmstate2
	   rts							; Return to Main 

; Mastermind State 0 - Initialization of Mastermind & Buffer

mmstate0:	
					
	   movw		#BUFFER, POINTER 	; Stores the
	   clr		BUFFER				; Clear the BUFFER Variable
	   clr		RESULT				; Clear the RESULT Variable
	   movb		#$01, mmState		; Set the Mastermind State Variable to 1
	   rts							; Return to Main

; Mastermind State 1 - Splash Screen and Setting Certain Display Flags
	   
mmstate1:

	   movb   	#$01, firstChar     ; Set firstChar flag to 1 (True) 
       movb   	#$01, displayTime1  ; Set displayTime1 flag to 1 (True)
	   movb   	#$01, displayTime2  ; Set displayTime1 flag to 1 (True)
	   movb		#$02, mmState		; Set the Mastermind State Variable to 2 (Hub)
	   rts							; Return to Main
	   
mmstate2:
	   tst		keyPressed			; Raises the flag for the keyPressed
	   bne		KEYCHECK			;
	   movb		#$02, mmState		; Set the Mastermind State Variable to 2 (Hub)
	   rts
	   
KEYCHECK:
	
	   ldab		keyStore			;
	   cmpb		#$F1				;
	   beq		F1PRESSED			;
	   cmpb		#$F2				;
	   beq		F2PRESSED			;
	   cmpb		#$0A				;
	   beq		ENTPRESSED			;
	   cmpb		#$08				;
	   beq		BSPACEPRESSED		;
	   cmpb		#$41				;
	   lblo		DIGIT
	   bra		NOTDIGIT			;

F1PRESSED:
	   movb		#$01, F1Flag		;
       movb		#$01, echoDigitInit	;	  
       movb		#$02, mmState		;
	   movb		#$00, keyPressed	;
	   rts
F2PRESSED:
       movb		#$02, mmState		;
	   movb		#$00, keyPressed	;
	   rts 
ENTPRESSED:
       movb		#$02, mmState		;
	   movb		#$00, keyPressed	;
	   rts
BSPACEPRESSED:
       movb		#$02, mmState		;
	   movb		#$00, keyPressed	;
	   rts
DIGIT:
	   jsr		BUFFERSTR
	   movb		#$02, mmState		;
	   movb		#$01, echoDigitPrint;
	   movb		#$00, keyPressed	;
	   rts
	     
NOTDIGIT:
       movb		#$02, mmState		;
	   movb		#$00, keyPressed	;
	   rts
;
;==============================================================================
;

; Key Pad Driver Sub-Routine

KPD:

	   ldaa		kpdState			; Grabbing the current state of Key Pad Driver & Branching
	   lbeq		kpdState0			; Initialize Key Pad Driver
	   deca
	   lbeq		kpdState1			; 
	   rts							; Return to Main 

; Key Pad Driver State 0 - Initialization of Key Pad Driver

kpdState0: 	
			
       jsr      INITKEY             ; Library Command to Initialize Keypad
       jsr      FLUSH_BFR           ; Library Command to Flush the Buffer
       jsr      KP_ACTIVE           ; Libary Command to Unmask the Keypad Interrupts
       movb     #$01, kpdState      ; Set the KPD State Variable to 1
       rts

; Key Pad Driver State 1 - Wait for the Key Press to Be Stored in Buffer

kpdState1:
       
       tst      L$KEY_FLG           ; Test Key Available Flag
	   bne		NOKEYPRESS			;
       jsr      GETCHAR             ; Library Command to Get the Character & Store in B
	   stab		keyStore
	   movb		#$01, keyPressed	; Set keyPressed Variable to 1 (True)
	   movb		#$01, kpdState		; Return Back to Key Pad Driver State 1
	   rts
	   
NOKEYPRESS:

	   movb #$01,kpdState			; Return Back to Key Pad Driver State 1
	   rts   
;
;==============================================================================
;

; Display Sub-Routine

DISPLAY:

	   ldaa		displayState		; Grabbing the current state of Key Pad Driver & Branching
	   lbeq		displayState0		; Initialize Display
	   deca
	   lbeq		displayState1		; 
	   deca
	   lbeq		displayState2		;
	   deca
	   lbeq		displayState3		;
	   deca
	   lbeq		displayState4		;
	   deca
	   lbeq		displayState5		;   
	   rts							; Return to Main 

; Display State 0 - Initialization of the Display

displayState0: 	
			
       jsr    	INITLCD               ; Initialize the LCD Screen
       jsr    	CLRSCREEN             ; Clears LCD Screen
	   jsr    	CURSOR                ; Initialize the Cursor
       movb   	#$01, displayState    ; Set next state to: Display HUB
       rts
	
;
;==================   Display State 1 - Display Branch Hub   ===================
;
	      
displayState1:

	   bgnd
	   tst    	displayTime1           ; Test displayTime1
       bne    	INITTIME1              ; If displayTime1 = 1 (True), branch to initTime1
       tst    	displayTime2           ; Test displayTime1
       bne    	INITTIME2              ; If displayTime1 = 1 (True), branch to initTime1
	   tst    	echoDigitInit          ; Test echoDigit
       bne    	INITPRINTDIGIT         ; If displayTime1 = 1 (True), branch to initTime1
	   tst    	echoDigitPrint         ; 
       bne    	PRINTDIGIT         	   ; 
       movb   	#$01, displayState     ; Set next state as Display HUB
       rts
	   
INITTIME1:
       
	   movb   	#$02, displayState     ; Set state to initialize display of TIME 1
       rts
	   
INITTIME2:
       
	   movb   	#$03, displayState     ; Set state to initialize display of TIME 2
       rts

INITPRINTDIGIT:
			   	   
	   movb   	#$04, displayState     ; Set state to initialize display of digit
       rts
	   
PRINTDIGIT:
			   	   
	   movb   	#$05, displayState     ; Set state to print the digit in buffer
       rts	   
;
;=================   Display State 2 - Time 1 Prompt On LCD   ==================
;
	      
displayState2:		  			  ; Display Time 1 Prompt On LCD
								  
       ldaa   #$00              ; LCD address range is $00 - $27 and $40 - $67      
       ldx    #MESSAGETIME1     ; Starting address of string to be displayed
       jsr    DISPLAY1STCHAR   	; Jump to DISPLAY_1ST_CHAR subroutine
       ldx    displayPointer    ; Load x with value in Display Pointer
       ldab   0,x               ; Load accumulator B with value in x
       lbeq   DONEMESSAGETIME1  ; If x = $00, branch to DONE_MESSAGE_PAIR1
       rts  

MESSAGETIME1:
  
       .ascii 'TIME1=        <F1> TO UPDATE LED1 PERIOD'
       .byte  $00               
       rts
	   
DONEMESSAGETIME1:               	; Time 1 Message Displayed	   
       
	   movb   #$00, displayTime1  	; Set displayTime1 Variable to 0 (False)
	   movb   #$01, displayState 	; Set the Mastermind State Variable to 2 (Hub)
	   movb   #$01, firstChar      	; Set firstChar Variable to 1(True)
       rts
	   
;
;=================   Display State 3 - Time 2 Prompt On LCD   ==================
;	   
	   
displayState3:		  			  ; Display Time 2 Prompt On LCD
								  
       ldaa   #$40                ; LCD address is $40 for Second Row First Add      
       ldx    #MESSAGETIME2		  ; First Address for Time 2 Message
       jsr    DISPLAY1STCHAR      ; Jump to DISPLAY1STCHAR subroutine
       ldx    displayPointer      ; Load x with value in Display Pointer
       ldab   0,x                 ; Load accumulator B with value in x
       lbeq   DONEMESSAGETIME2    ; If x = $00, branch to DONE_MESSAGE_PAIR1
       rts  

MESSAGETIME2:
  
       .ascii 'TIME2=        <F2> TO UPDATE LED2 PERIOD'
       .byte  $00               
       rts

DONEMESSAGETIME2:               	; Time 2 Message Displayed	   
       
	   movb   #$00, displayTime2  	; Set displayTime2 Variable to 0 (False)
	   movb   #$01, displayState 	; Set the Mastermind State Variable to 2 (Hub)
	   movb   #$01, firstChar      	; Set firstChar Variable to 1(True)
       rts

;
;=================   Display State 4 - Initialize Digit Print   ================
;	   
	   
displayState4:		  			  ; Digit Print for F1 or F2
		
	   tst	  F1Flag			  ; Test to See F1 Flag				  	
	   bne	  F1DIGITINIT  	      ; Branch if F1 Flag is 1 (True)
	   rts

F1DIGITINIT:
       ldaa   #$07                ; LCD address is $07 for Second Row First Add      
       jsr	  SETADDR			  ;
	   movb	  #$05, displayState  ;
	   rts
	   
;
;========================  Display State 5 - Digit Printing   ==================
;		   

displayState5:		  			  ; 
		
	   ldx	  POINTER			  ; Test to See F1 Flag				  	
	   ldab	  -1,x	  			  ; Branch if F1 Flag is 1 (True)
	   jsr 	  OUTCHAR			  ;
	   movb   #$01, displayState  ;
	   rts
	  
;
;==========================   Store Digit Value to Buffer  =====================
;

BUFFERSTR:
	       ldx  POINTER                    ;Load index register "X" with Pointer Address
		   ldab	keyStore
	       stab 0,x                        ;Stores the contents of B into X
	       inc  COUNT                      ;Increment the digit count
	       inx                             ;Increment X
	       stx  POINTER                    ;Store X into pointer
		   rts								   ;Branch Back to loop
	       
	
;END BUFFERSTR
	   
;
;==========================   Write to Display Branches  =======================
;		   
	   
DISPLAY1STCHAR:
      tst    firstChar              ; Test firstChar to Raise Flags
      beq    DISPLAYWRITE           ; Branch to DISPLAY_WRITE if firstChar = 0 (FALSE)
      stx    displayPointer         ; Store value of x into displayPointer
	  jsr    SETADDR                ; Set cursor to particular LCD address in A
      clr    firstChar              ; Clear firstChar
      rts
	  
DISPLAYWRITE:
      ldx    displayPointer         ; Load x with value in Display Pointer
      inx                           ; Increment x
      stx    displayPointer         ; Store Display Pointer with incremented x
      jsr    OUTCHAR                ; Print character
      rts
	  	   
.area interrupt_vectors (abs)
.org    $FFFE             ; At reset vector location
.word   __start           ; Load starting address		