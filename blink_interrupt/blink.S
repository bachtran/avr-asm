; REGISTER USAGE
;
; R1: overflow counter.
; R2: pin status
; R16: tmp stuff
; R17: interrupt tmp stuff

.org 0x0000
        RJMP    MAIN

.org 0x0040		; TIMER0_OVF
		RJMP	OVF

MAIN:
        LDI     R16, 0xff	; low RAMEND
        OUT     0x3d, R16	; SPL
        LDI     R16, 0x08	; high RAMEND
        OUT     0x3e, R16	; SPH

		SBI		0x04, 5		; DDRB5, output
		CBI		0x05, 5		; PORTB5, off

		; To have a blinking delay that's visible, we have to prescale a lot.
		; The maximum prescaler is 1024, which makes our TCNT0 increase
		; 15625 times per second, which means that it overflows 61 times per
		; second. That's manageable. If we keep a count of overflows in a
		; register and tie our LED to its highest bit, we get a 4 seconds span
		; for that counter. Good enough.
		IN		R16, 0x25	; TCCR0B
		ORI		R16, 0x05	; CS00 + CS02 = 1024 prescaler
		OUT		0x25, R16

		; Enable TIMER0_OVF
		LDS		R16, 0x6e	; TIMSK0
		ORI		R16, 0x01	; TOIE0
		STS		0x6e, R16

		; Initialize counters
        CLR     R1
		CLR		R2

		SEI

LOOP:
		SLEEP				; no use doing anything until we have an interrupt
		SBRC	R1, 7		; is overflow counter under 0x80?
		RCALL	TOGGLE		; no? then toggle
        RJMP    LOOP

; Toggle R2 and update PORTB5 status
TOGGLE:
		CLR		R1
		COM		R2			; toggle pin
		CBI		0x05, 5		; PORTB5, off
		SBRC	R2, 0		; is R2 cleared?
		SBI		0x05, 5		; no? then turn PB5 on
		RET

; Increase R1 counter every time we have a timer0 overflow
OVF:
		IN		R17, 0x3f	; SREG
		INC		R1
		OUT		0x3f, R17	; SREG
		RETI
