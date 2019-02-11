; SHIFT REGISTER CONTROLLER
;
; This program drives a CD74AC164 to display digits on a 7-segment display.
; The SR is really fast on input. At minimal voltage, it has a minimum clock of
; 73ns and at nominal voltage, 8ns. At 16MHz, there are 62ns between each of our
; ticks, so we can hardly go too fast. For good measure though, we add a NOP in
; between our CP toggling, just to be sure. But it should be more than enough.
; (actually, after some real world tests, 2 NOPs were needed)
;
; REGISTER USAGE
;
; R16: tmp stuff
; R17: digit selector
; R20: data being sent to the SR
; R21: data send counter. set to 8 before calling SENDSR

; PIN USAGE
;
; PORTD2: CP
; PORTD3: DS

.org 0x0000
	RJMP    MAIN

MAIN:
        LDI     R16, 0xff	; low RAMEND
        OUT     0x3d, R16	; SPL
        LDI     R16, 0x08	; high RAMEND
        OUT     0x3e, R16	; SPH

        SBI     0x0a, 2		; DDRD2, output
        SBI     0x0a, 3		; DDRD3, output

	SBR	R17, 0x4	; select a digit to display
	RCALL	LDDIGIT
	SBR	R21, 0x08
	RCALL	SENDSR		; send data to SR
LOOP:	RJMP    LOOP

; Load the digit selected in R17 into R20
LDDIGIT:
	; load DIGITS' address into Z
	SBR	R31, hi8(DIGITS)
	SBR	R30, lo8(DIGITS)
	CLR	R16		; we need a R with 0 in it for ADC below
	ADD	R30, R17	; Add selected digit offset
	ADC	R31, R16	; in case we carried earlier
	LPM	R20, Z		; deref Z pointer into R20
	RET

; send R20 to shift register.
; set R21 to 8 before calling
SENDSR:
	CBI	0x0b, 3		; PORTD3, low (DS)
	SBRC	R20, 0		; if latest bit isn't cleared, set DS high
	SBI	0x0b, 3		; PORTD3, high (DS)
	RCALL	TOGCP
	LSR	R20		; shift our data right
	DEC	R21
	BRNE	SENDSR		; not zero yet? loop!
	RET

; toggle CP, waiting 1us between pin changes
TOGCP:
	CBI	0x0b, 2		; PORTD2, low (CP)
	NOP			; 62ns between our pin changes
	NOP			; ... and another one
	SBI	0x0b, 2		; PORTD2, high (CP)
	RET

DIGITS: .byte \
	0b00000010, \
	0b01001111, \
	0b00010001, \
	0b00000101, \
	0b01001100, \
	0b00100100, \
	0b00100000, \
	0b00001111, \
	0b00000000, \
	0b00000100

