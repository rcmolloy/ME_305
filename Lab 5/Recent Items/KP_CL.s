; DAC Equates:
PORTJ  =   $0028          ; Port J
DDRJ   =   $0029          ; Data Direct Register J
PIN5   =   0b00010000     ; Mask for Pin 5
DACA_MS  =  $0301         ; DAC: A most significant bit
DACA_LS  =  $0300         ; DAC: A least significant bit
DACB_MS  =  $0303         ; DAC: B most significant bit
DACB_LS  =  $0302         ; DAC: B least significant bit

TC0_ISR:

;===== Proportional Controller (Closed Loop) =====

; First Step - Summing Junction

ldd	vReference
subd vActual
std	newError

; Second Step - Accounting for Error

ldd newError
addd errorSum
std errorSum
tst errorSum
bvc PROP_MUL
tst errorSum
bmi NEGATIVE_ERROR_SAT
bra	POSITIVE_ERROR_SAT


PROP_MUL:

	ldd newError
	ldy kPConstant
	emuls
	ldx $0400
	edivs
	sty	kPError
	bra GAIN_SUM
	
GAIN_SUM:

	ldd kPError
	addd sixVoltValue
	
	
	
	
POSITIVE_ERROR_SAT:

	ldd #$7FFF
	bra PROP_MUL

NEGATIVE_ERROR_SAT:

	ldd #$8000
	bra PROP_MUL