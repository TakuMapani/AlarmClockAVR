;
;Alarm_Clock
;
; Created: XX/03/2019 12:33:00 PM
; Author : TakuMapani
;
.DSEG
	.org 0x0500
	secCount: .byte 1
	secCountDis: .byte 1
	setDis: .byte 2
	;daylight savings state
	;1 - 1 October to 1 April
	;0 - daylight off
	dayLightSavingsState: .byte 1
	daylightTimeState: .byte 1 ;1 check october 0 - check april
	AMPM_mode: .byte 1
	hourMode: .byte 1
	button_1224: .byte 1
	;display state
	;1 - it shows the current time and the day
	;2 - it shows time allows to increment date
	;3 - it shows the date allows to increment date
	displayState: .byte 1

	;Alarm values
	;state 0-off 1-On 2-ringing
	AlarmState: .byte 1
	AlarmMinutes: .byte 1
	AlarmHours: .byte 1
	AlarmHourTenth: .byte 1
	AlarmHourUnit: .byte 1

	AlarmMinTenth: .byte 1
	AlarmMinUnit: .byte 11

	buzzerNote: .byte 1


	;Modulus values
	mod10Value: .byte 1 ;This stores the scratch value to be used in Modulus
	modTenth: .byte 1
	modUnit: .byte 1

	;binary values for clock
	second: .byte 1
	minute: .byte 1
	hour: .byte 1
	day: .byte 1
	month: .byte 1
	year: .byte 1

;display values needed
  setAM_PM: .byte 2 ; 0x41 0x4d(AM) or 0x50 0x4D (PM)
  setSpace: .byte 1 ;0x20
  hTenth: .byte 1
  hUnit: .byte 1
  setHSemi: .byte 1 ;0x3a
  mTenth: .byte 1
  mUnit: .byte 1
  setMSemi: .byte 1 ;0x3a
  sTenth: .byte 1
  sUnit: .byte 1
	sSpace:.byte 1
	daylightSign: .byte 1

;second line display normal
  newLine: .byte 1

  AlarmCharacters: .byte 2
  spaceAlarm: .byte 1

  dayTenth: .byte 1
  dayUnit: .byte 1
  slashYear: .byte 1

  monthTenth: .byte 1
  monthUnit: .byte 1
  slashMonth: .byte 1

  yearTenth: .byte 1
  yearUnit: .byte 1



; Demonstration of the Timer Usage and Periodic interrupt capabilities of the ATmega328
; Generate an interrupt 3 seconds from now

; Replace with your application code
.CSEG
	.org	0x0000		; start at beginning of program address
	jmp RESET ; Reset	; reset and interrupt vectors
	jmp INT0_IR ; IRQ0
	jmp INT1_IR ; IRQ1
	jmp PCINT0_IR ; PCINT0
	jmp PCINT1_IR ; PCINT1
	jmp PCINT2_IR ; PCINT2
	jmp WDT_IR ; Watchdog Timeout
	jmp TIM2_COMPA ; Timer2 CompareA
	jmp TIM2_COMPB ; Timer2 CompareB
	jmp TIM2_OVF ; Timer2 Overflow
	jmp TIM1_CAPT ; Timer1 Capture
	jmp TIM1_COMPA ; Timer1 CompareA
	jmp TIM1_COMPB ; Timer1 CompareB
	jmp TIM1_OVF ; Timer1 Overflow
	jmp TIM0_COMPA ; Timer0 CompareA
	jmp TIM0_COMPB ; Timer0 CompareB
	jmp TIM0_OVF ; Timer0 Overflow
	jmp SPI_STC ; SPI Transfer Complete
	jmp USART_RXC ; USART RX Complete
	jmp USART_UDRE ; USART UDR Empty
	jmp USART_TXC ; USART TX Complete
	jmp ADC_CC ; ADC Conversion Complete
	jmp EE_RDY ; EEPROM Ready
	jmp ANA_COMP ; Analog Comparator
	jmp TWI_IR ; 2-wire Serial
	jmp SPM_RDY ; SPM Ready
;
; non configured interrupts - do nothing
;
INT0_IR: rjmp  noint		; we use interrupt 0
INT1_IR: rjmp  noint
PCINT0_IR: rjmp  noint
PCINT1_IR: rjmp  noint
PCINT2_IR: rjmp  noint
WDT_IR: rjmp  noint
TIM2_COMPA: rjmp  noint
TIM2_COMPB: rjmp  noint
TIM2_OVF: rjmp  noint
TIM1_CAPT: rjmp  noint
;TIM1_COMPA: rjmp  noint
TIM1_COMPB: rjmp  noint	; we use Timer 1, comparitor B
TIM1_OVF: rjmp  noint
TIM0_COMPA: rjmp  noint
TIM0_COMPB: rjmp  noint
TIM0_OVF: rjmp  noint
SPI_STC: rjmp  noint
USART_RXC: rjmp  noint
USART_UDRE: rjmp  noint
USART_TXC: rjmp  noint
ADC_CC: rjmp  noint
EE_RDY: rjmp  noint
ANA_COMP: rjmp  noint
TWI_IR: rjmp  noint
SPM_RDY: rjmp  noint
;
; Generic catch everything routine.
; We could jump back to reset to restart everything again, which would be safer.
;
error:
noint:	inc	r16
	rjmp	noint
;
; Main program start. Configure the system and execute the main loop
;
;#define secondTC 45
;#define secCount 46
RESET:	ldi	r16,high(RAMEND) ; Set Stack Pointer to top of RAM
	out	SPH,r16
	ldi	r16,low(RAMEND)
	out	SPL,r16

;******************************************************************************
;LCD Display setup
	cbi DDRC,4
	cbi DDRC,5
	sbi PORTC,4
	sbi PORTC,5

;						  Setup TWI interface
	ldi		r16,193		; setup TWI frequency scaling
	sts		TWBR,r16
	ldi		r16,0x00
	sts		TWSR,r16

	ldi		r24,0x27
	call	LCD_Setup
	call	LCD_Clear
;******************************************************************************
;USART (Serial) setup

				sbi	PORTD,1		; set TxD to an RS232 idle value
				sbi	DDRD,1		; and make it output
				clr	r16
				sts	UCSR0A,r16
				ldi	r16,0x18	; enable receiver and transmitter
				sts	UCSR0B,r16
				ldi	r16,0x06	; async, no parity, 1 stop, 8 bits
				sts	UCSR0C,r16
				clr	r16
				sts	UBRR0H,r16
				ldi	r16,0x67	; baud rate divisor 103 (16M/9600 - 1)
				sts	UBRR0L,r16
				clr	r16
;*******************************************************************************
;Button
				cbi DDRD,2 ;Change 12/24hour mode
				sbi PORTD,2

				cbi DDRD,7 ;turn alarm on and off
				sbi PORTD,7

				sbi DDRD,3
				cbi PORTD,3


;*******************************************************************************
;SPI setup
ldi	r16,0b00101100		; set pin directions
out	DDRB,r16
sbi	PORTB,2			; and SS back high
				ldi	r16,(1<<SPE)|(1<<MSTR); set master SPI, (SPI mode 0 operation is 00)
				out	SPCR,r16			; SCK is set fosc/4 => 4MHz
				clr	r16				; clear interrupt flags and oscillator mode.
				out	SPSR,r16
;led output for alarm
				ldi r20,0
				ldi r21,0
				call SPI_Send_Command
;setup button on pin0 PORTB
				ldi r20,0x01
				ldi r21,0xff
				call SPI_send_command
;configure pullup resistor PORTB pin0
				ldi r20,0x0d
				ldi r21,0xff
				call SPI_Send_Command

;DSEG initilization
	DSEG_init:
				ldi r16,0x40
				sts newLine,r16

				ldi r16,0x20
				sts setSpace,r16
				sts spaceAlarm,r16
				sts sSpace,r16
				sts daylightSign,r16

				ldi r16,0x3A
				sts setHSemi,r16
				sts setMSemi,r16

				ldi r16,0x2F
				sts slashYear, r16
				sts slashMonth,r16
;initial time
				ldi r16,20
				sts second,r16
				sts hour,r16
				ldi r16,18
				sts minute,r16


				ldi r16,1
				sts hourMode,r16

;initial date
				ldi r16,15
				sts day,r16

				ldi r16,1
				sts month, r16

				ldi r16,12
				sts year, r16

;alarm initilization
				ldi r16,1
				sts AlarmState,r16
				ldi r16,20
				sts AlarmMinutes,r16
				sts AlarmHours,r16

;setup display data variables
				ldi yl,low(setdis)
				ldi yh,high(setdis)
				ldi r16,0x0c ;
				st y+,r16
				ldi r16,0x01 ;clear display
				st y+,r16

				call	t1_int_in_1Sec	; configure for an interrupt in 3 seconds
				sei			; enable interrupts globally
				call initialise_time
				call display_update

;*************************************MAIN**************************************
; The main loop is just a sleep instruction
;
main_loop:
				sleep
				rjmp	main_loop

	updating:
				lds r18,button_1224
				tst r18
				breq no_change
				call Mode12_24
				clr r18
				sts button_1224,r18
	no_change:
				call update_second
				call check_daylight_savings
				call Check_Alarm
				rjmp display_update

	display_update:
				ldi		r24,0x27
				ldi		r25,0x00
				call	LCD_Position
				ldi		ZL,LOW(setAM_PM)
				ldi		ZH,HIGH(setAM_PM)
				ldi		r25,11
				call	LCD_Text
				lds   r25,newLine
				call  LCD_Position

				ldi		ZL,LOW(AlarmCharacters)
				ldi		ZH,HIGH(AlarmCharacters)
				ldi		r25,11
				call LCD_Text

				clr		r20
				ret

update_second:
				push r16
				push r17
				push r18

				lds r16,sUnit
				lds r17,sTenth
				lds r18,second

				cpi r18,59
				breq update_minute
				inc r18
				rjmp return_s
	update_minute:
				clr r18
				call update_minuteF


  return_s:
				sts second,r18
				sts mod10Value,r18
				call mod10F
				lds r16,modUnit
				lds r17,modTenth
				sts sUnit,r16
				sts sTenth, r17

				pop r18
				pop r17
				pop r16
				ret
;***************************update_minute***************************************
update_minuteF:
				push r16
				push r17
				push r18
				push r19

				lds r19,AlarmState
				lds r18,minute
				lds r16,mUnit
				lds r17,mTenth

				cpi r18,59
				breq update_hour
				inc r18
				rjmp return_m

		update_hour:
				call update_hourF
				clr r18

		return_m:
		;check if alarm is ringing and turn it off after minute increment
				cpi r19,2
				brne cont_return
				ldi r19,1
				sts AlarmState,r19
		cont_return:
				sts minute, r18
				sts mod10Value,r18
				call mod10F

				lds r16,modUnit
				lds r17,modTenth
				sts mUnit,r16
				sts mTenth, r17

				pop r19
				pop r18
				pop r17
				pop r16
				ret

;*******************************update_hourF************************************
update_hourF:
				push r16
				push r17
				push r18
				push r19
				push r20 ;AMPM state
				push r21 ;scratch for now for hours


				lds r16,hUnit
				lds r17,hTenth
				lds r18,hour
				lds r19,hourMode

				;increment hours upto 23 and clear to 0
				cpi r18,23
				breq clr_hour
				inc r18
				rjmp cont_hour
	clr_hour:
				call update_dayF
				clr r18
				;We dont need to set AM PM characters everyTime
				;but for now we have to do it sigh :(

	cont_hour:
				tst r19
				breq Hour_24

				cpi r18,12
				brlo AM_time

	PM_time:
				ldi r20,1
				mov r21,r18 ;use scratch for subtraction
				subi r21,12
				tst r21 ;checking to see if its 12PM
				breq time_12
				sts mod10Value,r21
				;call mod10F ;getting Tens and units
				rjmp return_h

	AM_time:
				ldi r20,0

				tst r18
				breq time_12
				sts mod10Value,r18
				rjmp return_h

	time_12:
				ldi r21,12
				sts mod10Value,r21
				rjmp return_h



	Hour_24:
				ldi r20,2
				sts mod10Value,r18

	return_h:
				;setAMPM_mode
				sts AMPM_mode,r20
				call setAMPM_mode

				;get the tens and units using mod10/reminder10
				call mod10F
				lds r16,modUnit
				lds r17,modTenth

				cpi r17,0x30
				breq insert_space
				sts hTenth,r17
				breq continue_hour
	insert_space:
				ldi r17,0x20
				sts hTenth,r17
	continue_hour:
				sts hUnit, r16
				sts hour,r18

				pop r21
				pop r20
				pop r19
				pop r18
				pop r17
				pop r16
				ret

;**************************update_dayF***************************************
update_dayF:
				push r16
				push r17
				push r18
				push r19
				push r20
				push r21

				lds r16,dayUnit
				lds r17, dayTenth
				lds r18, month
				mov r19,r18 ; make a copy of month to use for Modulus
				lds r20,year
				lds r21,day

				cpi r18,8
				brlo before_august

after_august:
				andi r19,0x01
				cpi r19,0
				brne second_half_30_days

	second_half_31_days:
				cpi r21,31
				breq reset_day
				inc r21
				rjmp return_day

	second_half_30_days:
				cpi r21,30
				breq reset_day
				inc r21
				rjmp return_day

before_august:
				andi r19,0x01
				cpi r19,0
				brne first_half_31days

	first_half_not_31days:
				cpi r18,2
				breq february_update

				cpi r21,30
				breq reset_day
				inc r21

				/* cpi r17,0x33 ;check to see if its the 30th and reset date
				breq reset_day
				cpi r16,0x39
				breq inc_dayTenth */
				inc r16
				rjmp return_day

	february_update:
				cpi r21,20
				brlt february_before_20

		leap_year_maybe:
				andi r20,0x03
				cpi r20,0
				breq leap_year
				cpi r21,28
				breq reset_day
				inc r21
				rjmp return_day

		leap_year:
				cpi r21,29
				breq reset_day
				inc r21
				rjmp return_day


		february_before_20:
				inc r21
				rjmp return_day



	first_half_31days:
				cpi r21,31
				breq reset_day
				inc r21
				rjmp return_day

reset_day:
				ldi r21,1
				sts month,r18
				call update_monthF
				;rjmp return_day



return_day:
				;obtaining the tens and units for days using MOD10 function
				sts mod10Value,r21
				call mod10F
				lds r16,modUnit
				lds r17,modTenth
				sts dayUnit,r16
				sts dayTenth, r17
				sts day,r21

				pop r21
				pop r20
				pop r19
				pop r18
				pop r17
				pop r16
				ret

;****************************************update_monthF**************************
update_monthF:
				push r16
				push r17
				push r18


				lds r16,monthUnit
				lds r17,monthTenth
				lds r18,month

				cpi r18,12
				breq reset_month
				inc r18
				rjmp return_month

	reset_month:
				call update_yearF
				ldi r18,1

	return_month:
				sts mod10Value,r18
				call mod10F
				lds r16,modUnit
				lds r17,modTenth
				sts monthUnit,r16
				sts monthTenth, r17
				sts month,r18

				pop r18
				pop r17
				pop r16
				ret

;****************************update_yearF***************************************
update_yearF:
				push r16
				push r17
				push r18

				lds r16,yearUnit
				lds r17,yearTenth
				lds r18,year

				cpi r16,0x39
				breq done
				inc r18
				rjmp return_done


	done:
				ldi r18,0

	return_done:
				sts		mod10Value,r18
				call 	mod10F
				lds		r16,modUnit
				lds		r17,modTenth
				sts 	yearUnit,r16
				sts 	yearTenth, r17
				sts 	year,r18

				pop r18
				pop r17
				pop r16
				ret

;*****************************Mode12_24*****************************************
Mode12_24:
				push r16
				push r17
				push r18
				push r19
				push r20 ;AMPM state
				push r21 ;scratch for now for hours


				lds r16,hUnit
				lds r17,hTenth
				lds r18,hour
				lds r19,hourMode


				;We dont need to set AM PM characters everyTime
				;but for now we have to do it sigh :(

				tst r19
				breq Hour_24Mode

				cpi r18,12
				brlo AM_timeMode

	PM_timeMode:
				ldi r20,1
				mov r21,r18
				subi r21,12
				tst r21 ;checking to see if its 12PM
				breq time_12Mode
				sts mod10Value,r21
				;call mod10F ;getting Tens and units
				rjmp return_Mode1224

	AM_timeMode:
				ldi r20,0

				tst r18
				breq time_12Mode
				sts mod10Value,r18
				rjmp return_Mode1224

	time_12Mode:
				ldi r21,12
				sts mod10Value,r21
				rjmp return_Mode1224



	Hour_24Mode:
				ldi r20,2
				sts mod10Value,r18

	return_Mode1224:
				;setAMPM_mode
				sts AMPM_mode,r20
				call setAMPM_mode

				;get the tens and units using mod10/reminder10
				call mod10F
				lds r16,modUnit
				lds r17,modTenth

				cpi r17,0x30
				breq insert_space_Mode1224
				sts hTenth,r17
				rjmp continue_mode12_24
	insert_space_Mode1224:
				ldi r17,0x20
				sts hTenth,r17
	continue_mode12_24:
				sts hUnit, r16

				pop r21
				pop r20
				pop r19
				pop r18
				pop r17
				pop r16
				ret
;********************Funtction AM PM mode***************************************
setAMPM_mode:
				push r16
				push r17
				push r18
				lds r16,AMPM_mode
				ldi r18,0x4D

				cpi r16,1
				breq setModePM
				cpi r16,0
				breq setModeAM

				ldi r17,0x20
				ldi r18,0x20
				rjmp return_modeAMPM

	setModePM:
				ldi r17,0x50
				rjmp return_modeAMPM

	setModeAM:
				ldi r17,0x41

	return_modeAMPM:
				ldi YL,LOW(setAM_PM)
				ldi YH,HIGH(setAM_PM)
				st Y+,r17
				st Y+,r18

				pop r18
				pop r17
				pop r16
				ret

	;**********************************Mod10*************************************
	mod10F:
				push r16
				push r17
				push r18

				lds r16,mod10Value
				ldi r17,0x30 ; Tens
				ldi r18,0x30 ;Units

	mod10:
				cpi r16,10
				brlt contMod
				subi r16,10
				inc r17
				rjmp mod10
	contMod:
				add r18,r16
				sts modTenth,r17
				sts modUnit,r18

				pop r18
				pop r17
				pop r16
				ret
;************************Check_Alarm********************************************
Check_Alarm:
				push r16
				push r17
				push r18
				push r19
				push r20
				push r21
				push r22
				push r23
				push r24

				lds r16,AlarmState
				;hours and minutes
				lds r19,hour
				lds r20,minute
				;Alarm hours and minutes
				lds r21,AlarmHours
				lds r22,AlarmMinutes
				lds r23,buzzerNote ;state for buzzerNote played

				call turn_on_off_spi_led
				tst r16
				breq Alarm_off_state
				ldi r17,0x41
				ldi r18,0x6C
				cpi r16,2
				breq alarm_ringing
				clr r24
				sts TCCR2B,r24
				cbi PORTB,0 ;clear bit for showing alarm on
				cp r19,r21
				breq cp_minutes
				rjmp return_check_alarm
cp_minutes:
				cp r20,r22
				breq cp_minYes
				rjmp return_check_alarm
cp_minYes:
				ldi r16,2
				sts AlarmState,r16
				rjmp return_check_alarm

alarm_ringing:
				;buzzer will alternate between 2 frequencies
				call Buzzer
				call check_external_button

				tst r23
				breq otherNote
				sbi PORTB,0
				clr r23

				rjmp return_check_alarm
	otherNote:
				cbi PORTB,0
				inc r23
				rjmp return_check_alarm
Alarm_off_state:
				clr r24
				sts TCCR2B,r24
				ldi r17,0x20
				ldi r18,0x20
return_check_alarm:
				ldi YL,LOW(AlarmCharacters)
				ldi YH,HiGH(AlarmCharacters)
				st	Y+,r17
				st	Y,r18
				sts buzzerNote,R23

				pop r24
				pop r23
				pop r22
				pop r21
				pop r20
				pop r19
				pop r18
				pop r17
				pop r16
				ret
Buzzer:
				push r16
				push r17
				push r18

				ldi r17,0b00010010
				sts TCCR2A,r17
				ldi r17,0b00000100
				sts TCCR2B,r17

				lds r16,buzzerNote
				tst r16
				breq buzzerOtherNote
				ldi r17,0x20
				sts OCR2A,r17
				rjmp return_buzzer

buzzerOtherNote:
				ldi r17,0x4e
				sts OCR2A,r17

return_buzzer:
				pop r18
				pop r17
				pop r16
				ret

;SPI check button
check_external_button:
			push r16
			push r17
			push r18
			push r20
			push r21

			ldi r17,0xff
			ldi r20,0x13
poll_SPI_button:
			call SPI_Read_Command
			andi r16,0x01
			rjmp return_check_external_button
			dec r17
			brne poll_SPI_button
			ldi r18,0x00 ;turn off ringing alarm
return_check_external_button:
			sts AlarmState,r18
			pop r21
			pop r20
			pop r18
			pop r17
			pop r16
			ret

turn_on_off_spi_led:
			push r16
			push r18
			push r20
			push r21

			ldi r20,0x14
			lds r18,AlarmState
			cpi r18,0x02
			breq turn_on_LED
			ldi r21,0x00
			call SPI_send_command
			rjmp return_turn_on_off_spi_led
turn_on_LED:
			ldi r21,0x01
			call SPI_Send_Command

return_turn_on_off_spi_led:
			pop r21
			pop r20
			pop r18
			pop r16
			ret


;******************************check_daylight_savings***************************
check_daylight_savings:
				push r16
				push r17
				push r18
				push r19

				lds r16,dayLightSavingsState
				lds r17,month
				lds r18,day
				tst r16
				breq test_turn_on_DayLight
				;check april date
				cpi r17,4
				breq check_Apr_date
				rjmp return_check_daylight
		check_Apr_date:
				cpi r18,1
				breq check_time
				rjmp return_check_daylight

		test_turn_on_DayLight:
				;check october date
				cpi r17,10
				breq check_Oct_date
				rjmp return_check_daylight
		check_Oct_date:
				cpi r18,1
				breq check_time
				rjmp return_check_daylight
		check_time:
				call check_daylight_time

return_check_daylight:
				pop r19
				pop r18
				pop r17
				pop r16
				ret

check_daylight_time:
				push r16
				push r17
				push r18
				push r19

				lds r16,second
				lds r17,minute
				lds r18,hour
				lds r19,dayLightSavingsState

				tst r19
				breq check_oct
				cpi r18,2
				breq check_minute_Apr
				rjmp return_check_daylight_time
	check_minute_Apr:
				cpi r17,59
				breq check_sec_Apr
				rjmp return_check_daylight_time
	check_sec_Apr:
				cpi r16,59
				breq turn_off_daylight
				rjmp return_check_daylight_time
	turn_off_daylight:
				ldi r17,0
				ldi r16,0
				ldi r19,0
				rjmp return_check_daylight_time


check_oct:
				cpi r18,1
				breq check_minute_Oct
				cpi r18,2 ;if time is set to 2AM somehow
				breq turn_on_daylight_special
				rjmp return_check_daylight_time
		check_minute_Oct:
				cpi r17,59
				breq check_sec_oct
				rjmp return_check_daylight_time
		check_sec_oct:
				cpi r16,59
				breq turn_on_daylight

		turn_on_daylight:
				ldi r18,3
				ldi r17,0
				ldi r16,0
				ldi r19,1
				rjmp return_check_daylight_time

		turn_on_daylight_special:
				ldi r18,3
				inc r19
				rjmp return_check_daylight_time

	return_check_daylight_time:
				sts dayLightSavingsState,r19
				sts hour,r18
				sts minute,r17
				sts second,r16

				pop r19
				pop r18
				pop r17
				pop r16
				ret


;********************************init time**************************************
initialise_time:
				push r16
				push r17
				push r18

				lds r16,second
				sts mod10Value,r16
				call mod10F
				lds r17,modUnit
				lds r18,modTenth
				sts sUnit, r17
				sts sTenth,r18
				call initialise_minute

				pop r18
				pop	r17
				pop r16
				ret

initialise_minute:
			push r16
			push r17
			push r18

			lds r16,minute
			sts mod10Value,r16
			call mod10F
			lds r17,modUnit
			lds r18,modTenth
			sts mUnit, r17
			sts mTenth,r18
			call initialise_hour

			pop r18
			pop	r17
			pop r16
			ret

initialise_hour:
			push r16
			push r17
			push r18

			lds r16,hour
			sts mod10Value,r16
			call mod10F
			lds r17,modUnit
			lds r18,modTenth
			sts hUnit, r17
			sts hTenth,r18
			call Mode12_24
			call initialise_day

			pop r18
			pop	r17
			pop r16
			ret

initialise_day:
			push r16
			push r17
			push r18

			lds r16,day
			sts mod10Value,r16
			call mod10F
			lds r17,modUnit
			lds r18,modTenth
			sts dayUnit, r17
			sts dayTenth,r18
			call initialise_month

			pop r18
			pop	r17
			pop r16
			ret

initialise_month:
			push r16
			push r17
			push r18

			lds r16,month
			sts mod10Value,r16
			call mod10F
			lds r17,modUnit
			lds r18,modTenth
			sts monthUnit, r17
			sts monthTenth,r18
			call initialise_year

			pop r18
			pop	r17
			pop r16
			ret

initialise_year:
			push r16
			push r17
			push r18

			lds r16,year
			sts mod10Value,r16
			call mod10F
			lds r17,modUnit
			lds r18,modTenth
			sts yearUnit, r17
			sts yearTenth,r18


			pop r18
			pop	r17
			pop r16
			ret
;*******************************************************************************


; Enable an interrupt in 1 seconds using timer 1.

;
t1_int_in_1Sec:
			push	r16
			push	r17
			push	r18
			lds	r18,TIMSK1	; save current value
			clr	r16		; disables all interrupts from Timer 1
			sts	TIMSK1,r16
			sts	TCCR1B,r16	; temporarily stop the clock
			ldi	r16,0b00000000	; port A normal, port B normal, WGM=0000 (Normal)
			sts	TCCR1A,r16
			ldi	r17,HIGH(3625)	; set counter to 46875
			ldi	r16,LOW(3625)
			sts	OCR1AH,r17
			sts	OCR1AL,r16
			clr	r16		; clear current count
			sts	TCNT1H,r16
			sts	TCNT1L,r16
			ldi	r16,0b00001101	; noise = 0, WGM=0000, clk = /1024
			sts	TCCR1B,r16
			ldi	r16,0b00000000
			sts	TCCR1C,r16
			ori	r18,0b00000010	; interrupt enabled when OCB match (and other interrupts)
			sts	TIMSK1,r18
			pop	r18
			pop	r17
			pop	r16
			ret
;
; Clear any pending interrupts from timer 1.
;
t1_clear:
			push	r16
			clr	r16		; disables all interrupts from Timer 1
			sts	TIMSK1,r16
			sts	TCCR1B,r16	; temporarily stop the clock
			pop	r16
			ret
;
; Interrupt handling routines.
;


;********************************Buttons****************************************

;Function that switches from 12 to 24 hour Mode_24
;It polls a switch on timer interupt and checks the hourmode and changes it
change_Hour_Mode:
poll_button:
			push r16
			push r17
			push r18

			lds r17,hourMode
			ldi r16,0xff
		polling:
			sbic PIND,2
			rjmp return_polling
			dec r16
			brne polling
			tst r17
			breq change_12Hour
			clr r17
			;call Mode12_24
			rjmp return_polling

			change_12Hour:
			inc r17
			;call Mode12_24

		return_polling:
			inc r18
			sts button_1224,r18
			sts hourMode,r17
			pop r18
			pop r17
			pop r16
			ret

Alarm_OnOff:
			push r16
			push r17

			lds r16,AlarmState
			ldi r17,0xff
pollingAlarm:
			sbic PIND,7
			rjmp return_pollingAlarm
			dec r17
			brne pollingAlarm
			tst r16
			breq AlarmOnState
			clr r16
			rjmp return_pollingAlarm
AlarmOnState:
			ldi r16,1

return_pollingAlarm:
			sts AlarmState,r16
			pop r17
			pop r16
			ret




;
; interrupt timer 1 match compare B
;
TIM1_COMPA:
	;call sec_timer
	call change_Hour_Mode
	call Alarm_OnOff
	call updating
	reti

;*******************************************************************************

;
;	Send the string pointed to by Z register
;
puts:
	push	r16
puts0:
	ld	r16,Z+
	tst	r16
	breq	puts1
	call	putc	; send the character in r16
	rjmp	puts0	; and loop until end of string
puts1:			; finished the string
	pop	r16
	ret
;
;	Send the character in r16
;
putc:
	push	r17
putc0:
	lds	r17,UCSR0A
	andi	r17,0x20	; check if there is space to put the character in the buffer
	breq	putc0
	sts	UDR0,r16
	pop	r17
	ret
;
;	Send the byte in r16 as a hexadecimal number
;
puth:
	push	r17
	push	r16
	lds		r16,secCountDis
	swap	r16
	call	putn
	pop	r16
	call	putn
	pop	r17
	ret
;
;	send the lower 4 bits in r16 as a hexadecimal character
;
putn:
	push	r16

	andi	r16,0x0f
	cpi	r16,10
	brlt	putn0
	subi	r16,-7
putn0:
	subi	r16,-48
	call	putc
	pop	r16
	ret

;******************************************************************************
; Send TWI start address.
; On return Z flag is set if completed correctly
; r15 and r16 destroyed
sendTWI_Start:
	ldi		r16,(1<<TWINT) | (1<<TWSTA) | (1<<TWEN)
	sts		TWCR,r16

	call	waitTWI

	lds		r16,TWSR
	andi	r16,0xf8		; mask out
	cpi		r16,0x08		; TWSR = START (0x08)
	ret
;
; Send TWI slave address. Address is in r16
; On return Z flag is set if completed correctly
; r15 and r16 destroyed
sendTWI_SLA:
	sts		TWDR,r16
	ldi		r16,(1<<TWINT) | (1<<TWEN)
	sts		TWCR,r16

	call	waitTWI

	lds		r16,TWSR
	andi	r16,0xf8		; mask out
	cpi		r16,0x18		; TWSR = SLA+W sent, ACK received (0x18)
	ret
;
; Send 8 bits of data as two 4 bit nibbles.
; The data is in r16, the lower 4 bits are in r17
; we assume the TWI operation is waiting for data to be sent.
; r15, r18 and r19 all destroyed
sendTWI_Byte:
	mov		r18,r16
	andi	r18,0xF0
	or		r18,r17
	call	sendTWI_Nibble
	mov		r18,r16
	swap	r18
	andi	r18,0xF0
	or		r18,r17
	call	sendTWI_Nibble
	ret

;
; send 4 bits of data, changing the enable bit as we send it.
; data is in r18. r15, r18 and r19 are destroyed
;
sendTWI_Nibble:
	ori		r18,0x04
	sts		TWDR,r18
	ldi		r19,(1<<TWINT) | (1<<TWEN)
	sts		TWCR,r19

	call	waitTWI			; destroys r15

	lds		r19,TWSR
	andi	r19,0xf8		; mask out
	cpi		r19,0x28		; TWSR = data sent, ACK received (0x28)
	brne	sendTWI_Nibble_exit

	andi	r18,0xFB		; set enable bit low

	sts		TWDR,r18
	ldi		r19,(1<<TWINT) | (1<<TWEN)
	sts		TWCR,r19

	call	waitTWI

	lds		r19,TWSR
	andi	r19,0xf8		; mask out
	cpi		r19,0x28		; TWSR = data sent, ACK received (0x28)
sendTWI_Nibble_exit:
	ret

;
;	Send the data pointed to by the Z register to the TWI interface.
;	r25 contains the number of bytes to send
;	r24 contains the address of the I2C controller
;	r17 contains the lower 4 bits of each nibble to send
;
SendTWI_Data:
	call	sendTWI_Start
	brne	serror

	mov		r16,r24			; use this address
	add		r16,r16			; and move over the r/w bit
	call	sendTWI_SLA
	brne	serror

	cpi		r25,0x00		; any bytes left?
	breq	sendTWI_done	; if not all done

sendTWI_loop:
	ld		r16,Z+
	call	sendTWI_Byte
	brne	serror

	dec		r25
	brne	sendTWI_loop

sendTWI_done:
serror:
;
; send stop bit and we're done
;
sendTWI_Stop:
	ldi		r16,(1<<TWINT) | (1<<TWEN) | (1<<TWSTO)		; and send stop
	sts		TWCR,r16
	ldi		r16,0
sendTWI_Delay:
	dec		r16
	brne	sendTWI_Delay
	ret
;
; Wait until the TWI (I2C) interface has sent the byte and received an ack/nak
; destroys r15
;
waitTWI:
	lds	r15,TWCR
	sbrs	r15,TWINT		; wait until transmitted
	rjmp	waitTWI
	ret
;
; Initialisation strings for the LCD panel
;

;
; LCD Position - set the write poswition in the DRAM
; r24 holds the LCD I2C address
; r25 holds the address (0-127)
; r17 holds the lower 4 bits
;
LCD_Position:
	call	sendTWI_Start
	brne	LCD_serror

	mov		r16,r24			; use this address
	add		r16,r16			; and move over the r/w bit
	call	sendTWI_SLA
	brne	LCD_serror

	mov		r16,r25
	ori		r16,0x80		; set DDRAM address command
	ldi		r17,8			; backlight
	call	sendTWI_Byte

	rjmp	sendTWI_Stop

;
; LCD Clear - Clears the LCD and places the cursor at location 0
; r24 holds the LCD I2C address
; r17 holds the lower 4 bits
;
LCD_Clear:
	call	sendTWI_Start
	brne	LCD_serror

	mov		r16,r24			; use this address
	add		r16,r16			; and move over the r/w bit
	call	sendTWI_SLA
	brne	LCD_serror

	ldi		r16,0x01		; set DDRAM address command
	ldi		r17,8			; backlight
	call	sendTWI_Byte

	rjmp	sendTWI_Stop
;
; LCD_Text - send a string to the LCD for displaying
; Z points to the string,
; r25 holds the number of characters to print,
; r24 is the address of the LCD
;
LCD_Text:
	call	sendTWI_Start
	brne	LCD_serror

	mov		r16,r24			; use this address
	add		r16,r16			; and move over the r/w bit
	call	sendTWI_SLA
	brne	LCD_serror

	cpi		r25,0x00		; any bytes left?
	breq	LCD_Text_done	; if not all done
	ldi		r17,9			; backlight + data byte
LCD_Text_loop:
	ld		r16,Z+
	call	sendTWI_Byte
	brne	LCD_serror

	dec		r25
	brne	LCD_Text_loop

LCD_Text_done:
LCD_serror:
	rjmp	sendTWI_Stop
;
; LCDSetup - setup the LCD display connected at I2C port in r16
;
LCD_Setup:
	call	sendTWI_Start						; send start bit
	breq	LCD_Setup_0
	jmp		LCD_Setup_Err
LCD_Setup_0:
	mov		r16,r24
	add		r16,r16
	call	sendTWI_SLA
	breq	LCD_Setup_1
	jmp		LCD_Setup_Err
LCD_Setup_1:
	clr		r18
	clr		r19
	call	sendTWI_Nibble
	call	sendTWI_Stop

	ldi		r18,LOW(5)
	ldi		r19,HIGH(5)
;	call	delay_ms							; wait 5 ms

;
; Send the first of three 0x30 to the display
;

	call	sendTWI_Start						; send start bit
	breq	LCD_Setup_2
	jmp		LCD_Setup_Err
LCD_Setup_2:
	mov		r16,r24
	add		r16,r16
	call	sendTWI_SLA
	breq	LCD_Setup_3
	jmp		LCD_Setup_Err
LCD_Setup_3:
	ldi		r18,0x30
	clr		r19
	call	sendTWI_Nibble
	call	sendTWI_Stop

	ldi		r18,LOW(5)
	ldi		r19,HIGH(5)
;	call	delay_ms							; wait 5 ms

;
; Send the second of three 0x30 to the display
;

	call	sendTWI_Start						; send start bit
	brne	LCD_Setup_Err
	mov		r16,r24
	add		r16,r16
	call	sendTWI_SLA
	brne	LCD_Setup_Err
	ldi		r18,0x30
	clr		r19
	call	sendTWI_Nibble
	call	sendTWI_Stop

	ldi		r18,LOW(5)
	ldi		r19,HIGH(5)
;	call	delay_ms							; wait 5 ms

;
; Send the third of three 0x30 to the display
;

	call	sendTWI_Start						; send start bit
	brne	LCD_Setup_Err
	mov		r16,r24
	add		r16,r16
	call	sendTWI_SLA
	brne	LCD_Setup_Err
	ldi		r18,0x30
	clr		r19
	call	sendTWI_Nibble
	call	sendTWI_Stop


;
; Send 0x28 to the display to reset to 4 bit mode
;

	call	sendTWI_Start						; send start bit
	brne	LCD_Setup_Err
	mov		r16,r24
	add		r16,r16
	call	sendTWI_SLA
	brne	LCD_Setup_Err
	ldi		r18,0x28
	clr		r19
	call	sendTWI_Nibble
	call	sendTWI_Stop


	ldi		ZL,LOW(setDis)
	ldi		ZH,HIGH(setDis)
	ldi		r25,2								; all 2 bytes
	ldi		r17,8								; lower 4 bits zero (Backlight on)
	call	SendTWI_Data
	ret

LCD_Setup_Err:
	rjmp	main_loop


;
;SPI commands
;
; Send a command + byte to SPI interface
; CMD is in r20, DATA is in r21
; r16 is destroyed by this subroutine
SPI_Send_Command:
	cbi	PORTB,2		; SS low
	ldi	r16,0x40
	call	SPI_SendByte
	mov	r16,r20
	call	SPI_SendByte
	mov	r16,r21
	call	SPI_SendByte
	sbi	PORTB,2		; and SS back high
	ret
; Send a command + byte to SPI interface
; CMD is in r20, DATA is in r21 (if necessary)
;
SPI_Read_Command:
	cbi	PORTB,2		; SS low
	ldi	r16,0x41
	call	SPI_SendByte
	mov	r16,r20
	call	SPI_SendByte
	mov	r16,r21
	call	SPI_SendByte
	sbi	PORTB,2		; and SS back high
	ret
;
; Send one SPI byte (Returned data in r16)
;
SPI_SendByte:
	out	SPDR,r16
SPI_wait:
	in	r16,SPSR
	sbrs	r16,SPIF
	rjmp	SPI_wait
	in	r16,SPDR
	ret
