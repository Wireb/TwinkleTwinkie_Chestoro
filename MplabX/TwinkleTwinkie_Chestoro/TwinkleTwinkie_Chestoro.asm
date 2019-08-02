;#########################################################################################################################################################
;Copyright (c) 2019 Peter Shabino
;
;Permission is hereby granted, free of charge, to any person obtaining a copy of this hardware, software, and associated documentation files 
;(the "Product"), to deal in the Product without restriction, including without limitation the rights to use, copy, modify, merge, publish, 
;distribute, sublicense, and/or sell copies of the Product, and to permit persons to whom the Product is furnished to do so, subject to the 
;following conditions:
;
;The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Product.
;
;THE PRODUCT IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF 
;MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE 
;FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION 
;WITH THE PRODUCT OR THE USE OR OTHER DEALINGS IN THE PRODUCT.
;#########################################################################################################################################################
; 13Jul2019 V0 PJS New (based heavily on mad cat backpack) Added button override code (new function) 
; 21Jul2019 V1 PJS Fixed init code to tristate the 2 I2C pins to not screw up other's badges. 
    
#define	CODE_VER_STRING "Peter Shabino 21Jul2019 code V1 for Chestoro by TwinkleTwinkie www.wire2wire.org" ;Just in ROM !!! update vars below with true level!!


;****************************************************************************************
; port list [SSOP28]
; Vss(14)
; Vdd(1)
; RA0(13)	[ICSPDAT]
; RA1(12)	[ICSPCLK]
; RA2(11)	led left eye
; RA3(4)	[#MCLR]
; RA4(3)	led tooth 4
; RA5(2)	led tooth 3
; RC0(10)	led tooth 1 left
; RC1(9)	button in 
; RC2(8)	led tooth 2
; RC3(7)	
; RC4(6)	led right eye
; RC5(5)	led tooth 5 right
;****************************************************************************************

	
; PIC16F1503 Configuration Bit Settings
#include "p16f1503.inc"
; CONFIG1
; __config 0xFF04
 __CONFIG _CONFIG1, _FOSC_INTOSC & _WDTE_OFF & _PWRTE_ON & _MCLRE_OFF & _CP_OFF & _BOREN_ON & _CLKOUTEN_OFF
; CONFIG2
; __config 0xF7FF
 __CONFIG _CONFIG2, _WRT_OFF & _STVREN_ON & _BORV_LO & _LPBOR_OFF & _LVP_OFF	
 
 
 
;------------------
; constants
;------------------	
PWM_DELAY		equ 0x7D
	
;------------------
; vars (0x20 - 0x6f) bank 0
;------------------
right_eye		equ 0x20
left_eye		equ 0x21
tooth1			equ 0x22
tooth2			equ 0x23
tooth3			equ 0x24
tooth4			equ 0x25
tooth5			equ 0x26
pwm_cnt			equ	0x28
delay_l			equ 0x29
delay_h			equ	0x2A
counter1		equ 0x2B
temp			equ 0x2C
LFSR_0			equ	0x2D			
LFSR_1			equ	0x2E			
LFSR_2			equ	0x2F			
LFSR_3			equ	0x30	
LFSR_count		equ 0x31
counter2		equ 0x32
button			equ	0x33
next_animation	equ	0x34
mode			equ	0x35
 
 
;------------------
; vars (0x70 - 0x7F) global regs
;------------------
gtemp			equ	0x70

 
;put the following at address 0000h
	org     0000h
	goto    START			    ;vector to initialization sequence

;###########################################################################################################################
; intrupt routine
;###########################################################################################################################
;put the following at address 0004h
	org     0004h	
	; following regs are autosaved
	; W
	; STATUS (except TO and PD)
	; BSR
	; FSR
	; PCLATH
	
	
	;------------------
	clrf    BSR			    ; bank 0
	;------------------
	btfss	INTCON, TMR0IF
	goto	IRQ_not_tmr0
		
	; update PWM timer
	incf	pwm_cnt, F
	btfss	STATUS, Z
	goto	IRQ_tmr0_pwm_not_zero
	movf	left_eye, W
	btfss	STATUS, Z
	bcf		PORTA, 2
	movf	right_eye, W
	btfss	STATUS, Z
	bcf		PORTC, 4
	movf	tooth1, W
	btfss	STATUS, Z
	bcf		PORTC, 0
	movf	tooth2, W
	btfss	STATUS, Z
	bcf		PORTC, 2
	movf	tooth3, W
	btfss	STATUS, Z
	bcf		PORTA, 5
	movf	tooth4, W
	btfss	STATUS, Z
	bcf		PORTA, 4
	movf	tooth5, W
	btfss	STATUS, Z
	bcf		PORTC, 5
	goto	IRQ_tmr0_done
	
IRQ_tmr0_pwm_not_zero	
	movf	pwm_cnt, W
	subwf	left_eye, W
	btfss	STATUS, C
	bsf		PORTA, 2
	movf	pwm_cnt, W
	subwf	right_eye, W
	btfss	STATUS, C
	bsf		PORTC, 4
	movf	pwm_cnt, W
	subwf	tooth1, W
	btfss	STATUS, C
	bsf		PORTC, 0
	movf	pwm_cnt, W
	subwf	tooth2, W
	btfss	STATUS, C
	bsf		PORTC, 2
	movf	pwm_cnt, W
	subwf	tooth3, W
	btfss	STATUS, C
	bsf		PORTA, 5
	movf	pwm_cnt, W
	subwf	tooth4, W
	btfss	STATUS, C
	bsf		PORTA, 4
	movf	pwm_cnt, W
	subwf	tooth5, W
	btfss	STATUS, C
	bsf		PORTC, 5
	
IRQ_tmr0_done	
	movlw	PWM_DELAY		; prime timer 0 with inital value
	movwf	TMR0
	bcf		INTCON, TMR0IF	
IRQ_not_tmr0
	
	
	btfss	PIR1, TMR1IF
	goto	IRQ_not_tmr1
	bcf		PIR1, TMR1IF

	; check if delay is already 0
	movf	delay_l, W
	btfss	STATUS,Z
	goto	IRQ_tmr1_not_zero
	movf	delay_h, W
	btfsc	STATUS,Z
	goto	IRQ_not_tmr1
IRQ_tmr1_not_zero	
	; subtract 1
	movlw	0x01
	subwf	delay_l, F
	btfss	STATUS, C
	decf	delay_h, F
IRQ_not_tmr1
	
	retfie
;###########################################################################################################################
; end of IRQ code
;###########################################################################################################################	
	
START
	; init crap
	;------------------
	clrf    BSR			    ; bank 0
	;------------------
	clrf	INTCON			; disable interupts
	
	; init timers
	movlw	PWM_DELAY		; prime timer 0 with inital value
	movwf	TMR0
	clrf	T1GCON			; disable timer 1 gate control
	bcf		PIR1, TMR1IF	; clear interrupt
	movlw	0x31			; timer1 Fosc/4, 1:8 pre, on
	movwf	T1CON
	movlw	0xFF
	movwf	PR2
	movlw	0x3E			; timer 2 on, 1:8 post, 1:16 pre scaler
	movwf	T2CON
	clrf	TMR2

	
	; clear vars
	movlw	0x20			; start of bank 0 vars
	movwf	FSR0L
	clrf	FSR0H
	movlw	0x50			; clear all of bank other than globals
	movwf	gtemp
init_bank0_loop
	clrf	INDF0
	incf	FSR0L, F
	decfsz	gtemp, F
	goto	init_bank0_loop	
	
	; init LFSR
	movlw	0x55
	movwf	LFSR_0
	movwf	LFSR_1
	movwf	LFSR_2
	movwf	LFSR_3	

	
	;------------------
	movlw	d'3'
	movwf	BSR		
	;------------------
	clrf	ANSELA
	clrf	ANSELC

	;------------------
	movlw	d'2'
	movwf	BSR		
	;------------------
	movlw	0x2B
	movwf	LATA
	movlw	0x00
	movwf	LATC

	;------------------
	movlw	d'1'
	movwf	BSR		
	;------------------
	clrf	TRISA			    ; 0 = output
	movlw	0x02				; C1 button input rest outputs
	movwf	TRISC				; 0 = output
	movlw	0x78
	movwf	OSCCON
	movlw	0xD8				; timer 0 internal clock, prescaler to timer 0, 2 divider
	movwf	OPTION_REG
	bsf		PIE1, TMR1IE		; enable timer 1 interrupt
	
	;------------------
	clrf    BSR					; bank 0
	;------------------
	movlw	0xE0				; global, PE, and Timer 0 on
	movwf	INTCON			    ; enable interrupts

	
	
	goto	START_ANIMATION
	
;--------------------------------------------------------------------------------------------------------------------------------------------------	
MAINLOOP

	; check for button down
	btfsc	PORTC, 1
	goto	mainloop_no_button
	
	; debounce the release
	clrf	button
mainloop_button_chk
	clrf	temp
mainloop_button_delay
	decfsz	temp, F
	goto	mainloop_button_delay
	bsf		STATUS, C
	btfss	PORTC, 1
	bcf		STATUS, C
	rrf		button, F
	comf	button, W
	btfss	STATUS, Z
	goto	mainloop_button_chk
	
	; select the next animation in the order
	incf	next_animation, F
	; set mode on to shorten or fix delay timers
	bsf		mode, 0
	
	movf	next_animation, W
	andlw	0x07
	brw 
	goto	animation_smile_in_out
	goto	animation_blink
	goto	animation_lip_lick_right
	goto	animation_lip_lick_left
	goto	animation_lip_piano
	goto	animation_eye_bobble
	goto	animation_talk
	goto	animation_sparkles	
	
	goto	MAINLOOP
	
	
	
mainloop_no_button	
	clrf	mode
	; delay between animation seq (all LEDs on)
	call	_CYCLE_LFSR	
	movwf	delay_l	
mainloop_delay
	btfss	PORTC, 1
	clrf	delay_l
	movf	delay_l, W
	btfss	STATUS, Z
	goto	mainloop_delay

	
	call	_CYCLE_LFSR	
	andlw	0x1F
	brw 
	goto	animation_smile_in_out
	goto	animation_blink
	goto	animation_lip_lick_right
	goto	animation_lip_lick_left
	goto	animation_lip_piano
	goto	animation_eye_bobble
	goto	animation_talk
	goto	animation_sparkles

	goto	animation_blink
	goto	animation_blink	
	goto	animation_smile_in_out
	goto	animation_lip_lick_right
	
	goto	animation_lip_lick_left
	goto	animation_lip_piano
	goto	animation_eye_bobble
	goto	animation_talk

	goto	animation_blink
	goto	animation_blink
	goto	animation_blink
	goto	animation_blink

	goto	animation_lip_lick_right
	goto	animation_lip_lick_left
	goto	animation_eye_bobble
	goto	animation_blink
	
	
	goto	animation_blink
	goto	animation_blink	
	goto	animation_smile_in_out
	goto	animation_lip_lick_right
	
	goto	animation_lip_lick_left
	goto	animation_lip_piano
	goto	animation_eye_bobble
	goto	animation_talk
	
	
	goto	MAINLOOP


;-----------------------------------------
animation_sparkles
;-----------------------------------------

	; see if in manual mode if so do a fixed duration every time.
	btfss	mode, 0
	goto	sparkles_normal
	movlw	0x40
	movwf	counter2
	goto	sparkles_loop		

sparkles_normal	
	call	_CYCLE_LFSR	
	movwf	counter2

sparkles_loop
	call	_CYCLE_LFSR	
	call	_pwm_values
	movwf	tooth1
	call	_CYCLE_LFSR	
	call	_pwm_values
	movwf	tooth2
	call	_CYCLE_LFSR	
	call	_pwm_values
	movwf	tooth3
	call	_CYCLE_LFSR	
	call	_pwm_values
	movwf	tooth4
	call	_CYCLE_LFSR	
	call	_pwm_values
	movwf	tooth5
	call	_CYCLE_LFSR	
	call	_pwm_values
	movwf	left_eye
	call	_CYCLE_LFSR	
	call	_pwm_values
	movwf	right_eye

	call	_CYCLE_LFSR	
	andlw	0x07
	btfsc	STATUS, Z
	movlw	0x01	
	call	_delay	
	
	
	decfsz	counter2, F
	goto	sparkles_loop
	
	movlw	0xFF
	movwf	tooth1
	movwf	tooth2
	movwf	tooth3
	movwf	tooth4
	movwf	tooth5
	movwf	left_eye
	movwf	right_eye
	
	goto	MAINLOOP	
;-----------------------------------------
animation_talk
;-----------------------------------------
#define	talk_delay 0x03
	
	; see if in manual mode if so do a fixed duration every time.
	btfss	mode, 0
	goto	talk_normal
	movlw	0x05
	movwf	counter2
	goto	talk_loop	

talk_normal	
	call	_CYCLE_LFSR	
	andlw	0x07
	iorlw	0x01
	movwf	counter2
		
talk_loop
	movlw	0x0F
	movwf	counter1
talk_loop1
	movf	counter1, W
	call	_pwm_values
	movwf	tooth1
	movwf	tooth5	
	call	_CYCLE_LFSR	
	andlw	talk_delay
	btfsc	STATUS, Z
	movlw	0x01	
	call	_delay
	decf	counter1, F
	movf	counter1, W
	xorlw	0x07
	btfss	STATUS, Z
	goto	talk_loop1
	
	
talk_loop2
	movf	counter1, W
	call	_pwm_values
	movwf	tooth1
	movwf	tooth5	
	movf	counter1, W
	addlw	0x08
	call	_pwm_values
	movwf	tooth2
	movwf	tooth4	
	call	_CYCLE_LFSR	
	andlw	talk_delay
	btfsc	STATUS, Z
	movlw	0x01
	call	_delay
	decfsz	counter1, F
	goto	talk_loop2
	clrf	tooth1
	clrf	tooth5

	movlw	0x08
	movwf	counter1	
talk_loop3
	movf	counter1, W
	call	_pwm_values
	movwf	tooth2
	movwf	tooth4	
	call	_CYCLE_LFSR	
	andlw	talk_delay
	btfsc	STATUS, Z
	movlw	0x01
	call	_delay
	decfsz	counter1, F
	goto	talk_loop3
	
talk_loop4
	movf	counter1, W
	call	_pwm_values
	movwf	tooth2
	movwf	tooth4	
	call	_CYCLE_LFSR	
	andlw	talk_delay
	btfsc	STATUS, Z
	movlw	0x01
	call	_delay
	incf	counter1, F
	movf	counter1, W
	xorlw	0x09
	btfss	STATUS, Z
	goto	talk_loop4
	
talk_loop5
	movf	counter1, W
	call	_pwm_values
	movwf	tooth2
	movwf	tooth4	
	movlw	0x08
	subwf	counter1, W
	call	_pwm_values
	movwf	tooth1
	movwf	tooth5	
	call	_CYCLE_LFSR	
	andlw	talk_delay
	btfsc	STATUS, Z
	movlw	0x01
	call	_delay
	incf	counter1, F
	movf	counter1, W
	xorlw	0x0F
	btfss	STATUS, Z
	goto	talk_loop5
	movlw	0xFF
	movwf	tooth2
	movwf	tooth5
	
	movlw	0x08
	movwf	counter1
talk_loop6
	movf	counter1, W
	call	_pwm_values
	movwf	tooth1
	movwf	tooth5	
	call	_CYCLE_LFSR	
	andlw	talk_delay
	btfsc	STATUS, Z
	movlw	0x01
	call	_delay
	incf	counter1, F
	movf	counter1, W
	xorlw	0x0F
	btfss	STATUS, Z
	goto	talk_loop6
	movlw	0xFF
	movwf	tooth1
	movwf	tooth4
	
	decfsz	counter2, F
	goto	talk_loop
	
	goto	MAINLOOP		
	
;-----------------------------------------
animation_eye_bobble
;-----------------------------------------
	; see if in manual mode if so do a fixed duration every time.
	btfss	mode, 0
	goto	eye_bobble_normal
	movlw	0x05
	movwf	counter2
	goto	eye_bobble_loop	
	
eye_bobble_normal	
	call	_CYCLE_LFSR	
	andlw	0x07
	iorlw	0x01
	movwf	counter2
		
eye_bobble_loop	
	movlw	0x0F
	movwf	counter1	
eye_bobble_loop1
	movf	counter1, W
	call	_pwm_values
	movwf	left_eye
	movlw	0x01
	call	_delay
	decfsz	counter1, F
	goto	eye_bobble_loop1	
	
	movlw	0xF0
	movwf	counter1	
eye_bobble_loop2
	movf	counter1, W
	call	_pwm_values
	movwf	left_eye
	movlw	0x01
	call	_delay
	incfsz	counter1, F
	goto	eye_bobble_loop2

	movlw	0x0F
	movwf	counter1	
eye_bobble_loop3	
	movf	counter1, W
	call	_pwm_values
	movwf	right_eye
	movlw	0x01
	call	_delay
	decfsz	counter1, F
	goto	eye_bobble_loop3
	
	movlw	0xF0
	movwf	counter1	
eye_bobble_loop4
	movf	counter1, W
	call	_pwm_values
	movwf	right_eye
	movlw	0x01
	call	_delay
	incfsz	counter1, F
	goto	eye_bobble_loop4
	
	decfsz	counter2, F
	goto	eye_bobble_loop
	
	
	goto	MAINLOOP		
	
;-----------------------------------------
animation_lip_piano
;-----------------------------------------
	; see if in manual mode if so do a fixed duration every time.
	btfss	mode, 0
	goto	piano_normal
	movlw	0x07
	movwf	counter2
	goto	piano_start
	
piano_normal	
	call	_CYCLE_LFSR	
	andlw	0x07
	iorlw	0x01
	movwf	counter2
	
piano_start
	movlw	0x0F
	movwf	counter1	
piano_out_loop
	movf	counter1, W
	call	_pwm_values
	movwf	tooth5
	movlw	0x01
	call	_delay
	decfsz	counter1, F
	goto	piano_out_loop
	
	movlw	0xF0
	movwf	counter1	
piano_in_loop
	movf	counter1, W
	call	_pwm_values
	movwf	tooth5
	movlw	0x01
	call	_delay
	incfsz	counter1, F
	goto	piano_in_loop
	
piano_loop	
	movlw	0x0F
	movwf	counter1	
piano_out_loop1	
	movf	counter1, W
	call	_pwm_values
	movwf	tooth2
	movwf	tooth4
	movlw	0x01
	call	_delay
	decfsz	counter1, F
	goto	piano_out_loop1	
	
	movlw	0xF0
	movwf	counter1	
piano_in_loop1
	movf	counter1, W
	call	_pwm_values
	movwf	tooth2
	movwf	tooth4
	movlw	0x01
	call	_delay
	incfsz	counter1, F
	goto	piano_in_loop1

	movlw	0x0F
	movwf	counter1	
piano_out_loop2	
	movf	counter1, W
	call	_pwm_values
	movwf	tooth1
	movwf	tooth3
	movwf	tooth5
	movlw	0x01
	call	_delay
	decfsz	counter1, F
	goto	piano_out_loop2
	
	movlw	0xF0
	movwf	counter1	
piano_in_loop2
	movf	counter1, W
	call	_pwm_values
	movwf	tooth1
	movwf	tooth3
	movwf	tooth5
	movlw	0x01
	call	_delay
	incfsz	counter1, F
	goto	piano_in_loop2
	
	decfsz	counter2, F
	goto	piano_loop
	
	
	goto	MAINLOOP	

	
;-----------------------------------------
animation_lip_lick_left
;-----------------------------------------
	
	movlw	0x20
	movwf	tooth5

	movlw	0x08
	call	_delay

	movlw	0xFF
	movwf	tooth5
	movlw	0x20
	movwf	tooth4

	movlw	0x08
	call	_delay

	movlw	0xFF
	movwf	tooth4
	movlw	0x20
	movwf	tooth3

	movlw	0x08
	call	_delay

	movlw	0xFF
	movwf	tooth3
	movlw	0x20
	movwf	tooth2

	movlw	0x08
	call	_delay

	movlw	0xFF
	movwf	tooth2
	movlw	0x20
	movwf	tooth1

	movlw	0x08
	call	_delay

	movlw	0xFF
	movwf	tooth1
	
	goto	MAINLOOP	
	
	
;-----------------------------------------
animation_lip_lick_right
;-----------------------------------------
	
	movlw	0x20
	movwf	tooth1

	movlw	0x08
	call	_delay

	movlw	0xFF
	movwf	tooth1
	movlw	0x20
	movwf	tooth2

	movlw	0x08
	call	_delay

	movlw	0xFF
	movwf	tooth2
	movlw	0x20
	movwf	tooth3

	movlw	0x08
	call	_delay

	movlw	0xFF
	movwf	tooth3
	movlw	0x20
	movwf	tooth4

	movlw	0x08
	call	_delay

	movlw	0xFF
	movwf	tooth4
	movlw	0x20
	movwf	tooth5

	movlw	0x08
	call	_delay

	movlw	0xFF
	movwf	tooth5
	
	goto	MAINLOOP	
	
;-----------------------------------------
animation_blink
;-----------------------------------------
	call	_CYCLE_LFSR	
	btfss	LFSR_2,0
	clrf	left_eye
	btfss	LFSR_2,1
	clrf	right_eye

	; if no eye is off blink both
	btfss	LFSR_2,0
	goto	blink_ok
	btfss	LFSR_2,1
	goto	blink_ok
	clrf	left_eye
	clrf	right_eye
	
blink_ok
	; blink lenght
	; check if in manual mode
	btfss	mode, 0
	goto	blink_norm
	movlw	0x18
	movwf	delay_l
	goto	blink_delay	
blink_norm	
	call	_CYCLE_LFSR	
	andlw	0x7F
	iorlw	0x03
blink_delay	
	call	_delay
	
	movlw	0xFF
	movwf	left_eye
	movwf	right_eye
	
	goto	MAINLOOP
	
;-----------------------------------------
animation_smile_in_out	
;-----------------------------------------
	movlw	0x0F
	movwf	counter1	
eye_out_loop	
	movf	counter1, W
	call	_pwm_values
	movwf	left_eye
	movwf	right_eye
	movlw	0x07
	call	_delay
	decfsz	counter1, F
	goto	eye_out_loop	
	clrf	left_eye
	clrf	right_eye
	
	
	; delay between eyes off and smile off
	; check if in manual mode
	btfss	mode, 0
	goto	eye_out_loop1_norm
	movlw	0x08
	movwf	delay_l
	goto	eye_out_loop1
eye_out_loop1_norm
	call	_CYCLE_LFSR	
	andlw	0x3F
	iorlw	0x01
	movwf	delay_l	
eye_out_loop1
	btfss	PORTC, 1
	clrf	delay_l	
	movf	delay_l, W
	btfss	STATUS, Z
	goto	eye_out_loop1
	
	movlw	0x0F
	movwf	counter1	
smile_out_loop	
	movf	counter1, W
	call	_pwm_values
	movwf	tooth1
	movwf	tooth2
	movwf	tooth3
	movwf	tooth4
	movwf	tooth5
	movlw	0x07
	call	_delay
	decfsz	counter1, F
	goto	smile_out_loop
	clrf	tooth1
	clrf	tooth2
	clrf	tooth3
	clrf	tooth4
	clrf	tooth5
	
	; Delay in all off state
	; check if in manual mode
	btfss	mode, 0
	goto	smile_out_loop1_norm
	movlw	0x08
	movwf	delay_l
	goto	smile_out_loop1
smile_out_loop1_norm
	call	_CYCLE_LFSR	
	iorlw	0x10
	movwf	delay_l	
smile_out_loop1
	btfss	PORTC, 1
	clrf	delay_l	
	movf	delay_l, W
	btfss	STATUS, Z
	goto	smile_out_loop1

START_ANIMATION	
	
	movlw	0xF0
	movwf	counter1	
smile_in_loop	
	movf	counter1, W
	call	_pwm_values
	movwf	tooth1
	movwf	tooth2
	movwf	tooth3
	movwf	tooth4
	movwf	tooth5
	movlw	0x07
	call	_delay
	incfsz	counter1, F
	goto	smile_in_loop
	
	; delay between smile on and eyes on
	; check if in manual mode
	btfss	mode, 0
	goto	smile_in_loop1_norm
	movlw	0x08
	movwf	delay_l
	goto	smile_in_loop1
smile_in_loop1_norm
	call	_CYCLE_LFSR	
	andlw	0x3F
	iorlw	0x01
	movwf	delay_l	
smile_in_loop1
	btfss	PORTC, 1
	clrf	delay_l	
	movf	delay_l, W
	btfss	STATUS, Z
	goto	smile_in_loop1

	movlw	0xF0
	movwf	counter1	
eyes_in_loop	
	movf	counter1, W
	call	_pwm_values
	movwf	left_eye
	movwf	right_eye
	movlw	0x07
	call	_delay
	incfsz	counter1, F
	goto	eyes_in_loop
	

	goto	MAINLOOP
	
;################################################################################
; cycle the LFSR generator 8 bits and return the new result in W
;################################################################################
_CYCLE_LFSR
	movlw	0x08
	movwf	LFSR_count
cycle_lfsr_loop
	; seed register with inial value
	bcf		temp, 0
	btfsc	LFSR_0, 0
	bsf		temp, 0
	; test bit invert result if set
	btfsc	LFSR_0, 2
	comf	temp, f
	; test bit invert result if set
	btfsc	LFSR_0, 6
	comf	temp, f
	; test bit invert result if set
	btfsc	LFSR_0, 7
	comf	temp, f
	
	; set carry bit
	bcf		STATUS, C
	btfsc	temp, 0
	bsf		STATUS, C
	
	; rotat the bits 
	rrf		LFSR_3, F
	rrf		LFSR_2, F
	rrf		LFSR_1, F
	rrf		LFSR_0, F
	decfsz	LFSR_count, F
	goto	cycle_lfsr_loop
	movf	LFSR_0, W
	return
	
;################################################################################
_delay
	movwf	temp
	clrf	TMR2
	bcf		PIR1, TMR2IF
delay_loop1
	btfss	PORTC, 1			; check if the button was pressed if so skip out of the delay loop
	return				
	btfss	PIR1, TMR2IF
	goto	delay_loop1
	bcf		PIR1, TMR2IF
	decfsz	temp, F
	goto	delay_loop1
	
	return
	
;################################################################################
_pwm_values
	andlw	0x0F
	brw		
	retlw	0x00
	retlw	0x01
	retlw	0x03
	retlw	0x07
	retlw	0x0B
	retlw	0x12
	retlw	0x1E
	retlw	0x28
	retlw	0x32
	retlw	0x41
	retlw	0x50
	retlw	0x64
	retlw	0x7D
	retlw	0xA0
	retlw	0xC8
	retlw	0xFF
	
	return

	
; stuff in the 	code description at the end of the code. 
	de	CODE_VER_STRING
	
	;### end of program ###
	end	

