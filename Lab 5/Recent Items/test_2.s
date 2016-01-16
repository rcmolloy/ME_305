; Lab 5 - KP Controller

; Assembler Equates

ENCODER		   = 	 $0280				 ;


; RAM area
.area bss

FRED:: .blkb 2

; code area
.area text

_main::
 
TOP:
 
 jsr LCD_TEMPLATE_INIT
 
 
 
 ;jsr ENCODER_PUSH

 ;jsr TOP

 Spin:
 	  bra Spin

LCD_TEMPLATE_INIT:

 jsr	   INITLCD                        ; Initalize LCD Screen
 jsr    CLRSCREEN                      ; Clear LCD Screen
 jsr    CURSOR                         ; Show Cursor in LCD Screen
 jsr LCDTEMPLATE
 ldx #L$VREF_BUF
 movb #'-',0,x
 movb #'1',1,x
 movb #'2',2,x
 movb #'5',3,x
 jsr UPDATELCDL1
 ldx #L$VACT_BUF
 movb #'-',0,x
 movb #'1',1,x
 movb #'2',2,x
 jsr UPDATELCDL1
 ldx #L$ERR_BUF
 movb #'-',0,x
 movb #'1',1,x
 movb #'1',2,x
 movb #'3',3,x
 jsr UPDATELCDL1
 ldx #L$EFRT_BUF
 movb #'-',0,x
 movb #'8',1,x
 movb #'7',2,x
 jsr UPDATELCDL1
 ldx #L$KI_BUF
 movb #'1',0,x
 movb #'0',1,x
 movb #'2',2,x
 movb #'4',3,x
 movb #'0',4,x
 jsr UPDATELCDL2
 ldx #L$KP_BUF
 movb #'2',0,x
 movb #'0',1,x
 movb #'4',2,x
 movb #'8',3,x
 movb #'0',4,x
 jsr UPDATELCDL2
 
 jsr UPDATELCDL1
 rts
 
ENCODER_PUSH:

 ldd ENCODER
 
 std FRED
 
 rts
	
	
.area interrupt_vectors (abs)
        .org   $FFFE               ; at reset vector location, 
        .word  __start             ; load starting address