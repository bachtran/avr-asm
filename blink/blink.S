.include "m328Pdef.inc"

; REGISTER USAGE
;
; R1: overflow counter. pin status tied to 7th bit
; R16: tmp stuff

	SBI     DDRB, DDB5
	CBI     PORTB, PORTB5

	; To have a blinking delay that's visible, we have to prescale a lot.
	; The maximum prescaler is 1024, which makes our TCNT0 increase
	; 15625 times per second, which means that it overflows 61 times per
	; second. That's manageable. If we keep a count of overflows in a
	; register and tie our LED to its highest bit, we get a 4 seconds span
	; for that counter. Good enough.
	IN      R16, TCCR0B
	ORI     R16, 0x05	; CS00 + CS02 = 1024 prescaler
	OUT     TCCR0B, R16
	CLR     R1		; initialize overflow counter

LOOP:
	IN	R16, TIFR0
	SBRS	R16, TOV0
	RJMP	LOOP		; no overflow
	; overflow, toggle
	LDI	R16, 0x01
	OUT	TIFR0, R16
	INC	R1
	CBI     PORTB, PORTB5
	SBRS    R1, 7		; if LED is on
	SBI     PORTB, PORTB5
	RJMP	LOOP
