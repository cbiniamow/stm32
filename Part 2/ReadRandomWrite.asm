; CAMERON BINIAMOW
; ECEN 3320
; LAB 3.2.1A: I/O PORTS, LCDs, & READ/RANDOM/WRITE
; DUE: 11/05/2020


;========================Port Locations============================

; CLOCK ENABLE 
RCC_APB2ENR EQU 0x40021018

; Port C Register Addresses
GPIOC_CRL 	EQU 0x40011000
GPIOC_CRH 	EQU 0x40011004
GPIOC_IDR 	EQU 0x40011008
GPIOC_ODR 	EQU 0x4001100C
GPIOC_BSRR 	EQU 0x40011010
GPIOC_BRR 	EQU 0x40011014
GPIOC_LCKR 	EQU 0x40011018

; Port B Register Addresses
GPIOB_CRL 	EQU 0x40010C00
GPIOB_CRH 	EQU 0x40010C04
GPIOB_IDR 	EQU 0x40010C08
GPIOB_ODR 	EQU 0x40010C0C
GPIOB_BSRR 	EQU 0x40010C10
GPIOB_BRR 	EQU 0x40010C14
GPIOB_LCKR 	EQU 0x40010C18
	
; Port A register Addresses
GPIOA_CRL 	EQU 0x40010800
GPIOA_CRH 	EQU 0x40010804
GPIOA_IDR 	EQU 0x40010808
GPIOA_ODR 	EQU 0x4001080C
GPIOA_BSRR 	EQU 0x40010810
GPIOA_BRR 	EQU 0x40010814
GPIOA_LCKR 	EQU 0x40010818
	
RS 			EQU 0x2000 			;Pin 13
RW 			EQU 0x4000 			;Pin 14
EN 			EQU 0x8000 			;Pin 15
	
	EXPORT Reset_Handler
    EXPORT __Vectors
		
;=======================Vector Area=================================

    AREA VECTORS, DATA, READONLY
    THUMB
        
__Vectors
    DCD 0x20000190                ;Points to top of stack
    DCD Reset_Handler            ;Points to our reset location
        
;=======================Startup Area=================================        

    AREA STARTUP, CODE, READONLY
    THUMB

Reset_Handler    PROC
   
    LDR R5, =__main            
    BX R5               
    ENDP

;=========================MAIN CODE================================
    AREA MAIN, CODE, READONLY
    THUMB

__main

	; ENABLE CLOCKS ON EACH PORT
	LDR R1,=RCC_APB2ENR 			;Setup address
	LDR R0,[R1] 					;Read current value
	ORR R0,R0,#0xFC 				;Only affect bits we want to change
	STR R0,[R1] 					;Rewrite with clocks enabled

	; SET PORT A AS INPUTS
	LDR R1, =GPIOA_CRH 				
	LDR R0, =0x44444444 			
	STR R0, [R1] 					
	LDR R1, =GPIOA_CRL 				
	LDR R0, =0x33333333 			
	STR R0, [R1] 					
	
	; SET PORT B AS OUTPUTS
	LDR R1, =GPIOB_CRL 
	LDR R0, =0x88888888 
	STR R0, [R1] 
	LDR R1, =GPIOB_ODR 
	LDR R0, =0x0000 
	STR R0, [R1] 
	
	; SET PC.13, PC.14, PC.15 AS OUTPUTS
	LDR R1,=GPIOC_CRH 
	LDR R0,=0x33344444 
	STR R0, [R1] 

	BL	LCD_INIT				; INITIALIZE LCD
	
	BL	READ					; READ DIP SWITCHES
	BL	RANDOM					; FIRST RANDOM NUMBER
	MOV	R2, R0					; STORE FIRST RANDOM NUMBER IN R2
	BL	RANDOM					; SECOND RANDOM NUMBER
	MOV	R11, R0
	BL 	WRITE					; WRITE BINARY VALUES ON LCD
	
HERE
	B	HERE
	
	
;========================READ============================
; READS DIP SWITCHES

READ
	LDR	R1, =GPIOB_IDR
	LDR R0, [R1]				; READ PORTA. STORE VALUE IN R0
	
	BX	LR						; RETURN
	

;========================RANDOM==========================
; PRODUCES RANDOM 8-BIT VALUE

RANDOM
	MOV	R1, R0					; COPY PORTA DATA INTO R1
	LSL	R0, R0, #1						; LEFT SHIFT ONCE
	EOR	R1, R1, R0				; XOR BITS 6 & 7
	ASR	R1, R1, #6				; RIGHT SHIFT XOR BIT TO BIT 0
	AND	R0, R0, #0x7E				; MASK BITS 1 - 6
	AND	R1, R1, #0x01			; MASK BIT 0
	ORR	R0, R0, R1				; REPLACE BIT 0 WITH XOR BIT
	BX	LR						; RETURN

;========================WRITE============================
; WRITES RANDOM VALUES ON LCD

WRITE
	PUSH	{LR}				; STORE LINK ADDRESS ON STACK
	
	LDR		R10,=FIRST			; WRITE "FIRST: " STRING
	BL		LCD_STRING	
	
	MOV	R3, R2
	ASR	R3, R3, #4				; MOVE UPPER NIBBLE TO LOWER NIBBLE
	AND	R3, R3, #0x0F			; MASK LOWER NIBBLE
	
	BL		CONVERT
	BL		LCD_STRING
	
	MOV	R3, R2
	AND	R3, R3, #0x0F			; MASK LOWER NIBBLE
	
	BL		CONVERT
	BL		LCD_STRING
	
	MOV		R2, R11
	
	LDR		R10,=SECOND			; WRITE "SECOND: " STRING
	BL		LCD_STRING	
	
	MOV	R3, R2
	ASR	R3, R3, #4				; MOVE UPPER NIBBLE TO LOWER NIBBLE
	AND	R3, R3, #0x0F			; MASK LOWER NIBBLE
	
	BL		CONVERT
	BL		LCD_STRING
	
	MOV	R3, R2
	AND	R3, R3, #0x0F			; MASK LOWER NIBBLE
	
	BL		CONVERT
	BL		LCD_STRING

	
	POP	{LR}
	BX	LR
	
	
;========================CONVERT==========================
; CONVERTS TO BINARY

CONVERT
	CMP	R3, #0
	BNE	CK1
	LDR	R10,=ZERO
	BX	LR
CK1	CMP	R3, #1
	BNE	CK2
	LDR	R10,=ONE
	BX	LR
CK2	CMP	R3, #2
	BNE	CK3
	LDR	R10,=TWO
	BX	LR
CK3	CMP	R3, #3
	BNE	CK4
	LDR	R10,=THREE
	BX	LR
CK4	CMP	R3, #4
	BNE	CK5
	LDR	R10,=FOUR
	BX	LR
CK5	CMP	R3, #5
	BNE	CK6
	LDR	R10,=FIVE
	BX	LR
CK6	CMP	R3, #6
	BNE	CK7
	LDR	R10,=SIX
	BX	LR
CK7	CMP	R3, #7
	BNE	CK8
	LDR	R10,=SEVEN
	BX	LR
CK8	CMP	R3, #8
	BNE	CK9
	LDR	R10,=EIGHT
	BX	LR
CK9	CMP	R3, #9
	BNE	CKA
	LDR	R10,=NINE
	BX	LR
CKA	CMP	R3, #10
	BNE	CKB
	LDR	R10,=TEN
	BX	LR
CKB	CMP	R3, #11
	BNE	CKC
	LDR	R10,=ELEVEN
	BX	LR
CKC	CMP	R3, #12
	BNE	CKD
	LDR	R10,=TWELVE
	BX	LR
CKD	CMP	R3, #13
	BNE	CKE
	LDR	R10,=THIRTEEN
	BX	LR
CKE	CMP	R3, #14
	BNE	CKF
	LDR	R10,=FOURTEEN
	BX	LR
CKF	LDR	R10,=FIFETEEN
	BX	LR

;========================LCD_INIT========================
; INITITALIZES LCD

LCD_INIT
	PUSH {LR}					; STORE LINK ADDRESS
	
	MOV	R0, #15					; 15ms DELAY	
	BL	DELAY_ms		
	
	MOV R0, #0x30				; FUNCTION SET COMMAND
	BL	LCD_CMD
	
	MOV	R0, #5					; 5ms DELAY			
	BL	DELAY_ms
	
	MOV R0, #0x30				; FUNCTION SET COMMAND
	BL	LCD_CMD
	
	BL	DELAY_1ms				; 1ms DELAY
	
	MOV R0, #0x30				; FUNCTION SET COMMAND
	BL	LCD_CMD
	
	MOV R0, #0x3C				; 8-BIT INTERFACE
	BL	LCD_CMD
	
	MOV R0, #0x08				; DISPLAY OFF
	BL	LCD_CMD
	
	MOV R0, #0x06				; ENTRY MODE SET
	BL	LCD_CMD
		
	MOV R0, #0x0F				; DISPLAY ON
	BL	LCD_CMD
		
	BL	LCD_CLEAR				; CLEAR DISPLAY
	
	POP	{LR}					; RESTORE LINK ADDRESS

	BX	LR						; RETURN

	
;========================LCD_CMD========================
; EXECUTES ALL COMMANDS ON THE LCD

LCD_CMD
	PUSH {LR}					; STORE LINK ADDRESS
	
	LDR R3, =GPIOC_BSRR			; RS = 0 / RW = 0
	LDR R4, =(RS << 16 :OR:RW << 16) 
	STR R4, [R3]
	
	BL	DELAY_1ms				; 1ms DELAY
	
	LDR R3, =GPIOC_BSRR			; EN = 1
	LDR R4, =EN 
	STR R4, [R3]
	
	BL	DELAY_1ms				; 1ms DELAY
	
	LDR R5, =GPIOA_ODR 			; OUTPUT COMMAND THROUGH PORT A
	LDR	R9, [R0]
	STR R9, [R5] 
	
	BL	DELAY_1ms				; 1ms DELAY
	
	LDR R3, =GPIOC_BSRR			; EN = 0
	LDR R4, =(EN << 16) 
	STR R4, [R3] 
	
	POP	{LR}					; RESTORE LINK ADDRESS
	
	BX	LR						; RETURN


;========================LCD_DATA========================
; TRANSFERS DATA FROM R0 TO THE LCD

LCD_DATA
	PUSH {LR}					; STORE LINK ADDRESS

	LDR R3, =GPIOC_BSRR			; RS = 1 / RW = 0
	LDR R4, =(RS :OR: RW << 16) 
	STR R4, [R3]
	
	BL	DELAY_1ms				; 1ms DELAY
	
	LDR R3, =GPIOC_BSRR			; EN = 1
	LDR R4, =EN 
	STR R4, [R3]
	
	BL	DELAY_1ms				; 1ms DELAY
	
	LDR R5, =GPIOA_ODR 			; R0 => PORT A
	STR R0, [R5] 
	
	BL	DELAY_1ms				; 1ms DELAY
	
	LDR R3, =GPIOC_BSRR			; EN = 0
	LDR R4, =(EN << 16) 
	STR R4, [R3] 
	
	POP	{LR}					; RESTORE LINK ADDRESS
	BX	LR						; RETURN


;========================LCD_CHAR========================
; WRITE A SINGLE CHARACTER FROM R0 TO THE LCD

LCD_CHAR
	PUSH {LR}					; STORE LINK ADDRESS
	BL	LCD_DATA				; SEND DATA TO LCD
	POP	{LR}					; RESTORE LINK ADDRESS
	BX	LR						; RETURN
	
	
;========================LCD_CLEAR========================
; CLEARS THE LCD

LCD_CLEAR
	PUSH	{LR}				; STORE LINK ADDRESS
	MOV	R0, #0x01				; CLEAR COMMAND
	BL	LCD_CMD					; SEND COMMAND TO LCD
	POP {LR}					; RESTORE LINK ADDRESS
	BX	LR						; RETURN


;========================LCD_2NDLINE========================
; MOVES CURSOR TO THE SECOND LINE OF THE LCD

LCD_2NDLINE
	PUSH {LR}					; STORE LINK ADDRESS
	MOV R0, #0xC0				; 2ND LINE COMMAND
	BL LCD_CMD					; SEND COMMAND TO LCD
	POP {LR}					; RESTORE LINK ADDRESS
	BX LR						; RETURN


;========================LCD_STRING========================
; WRITES A STRING FROM R0 ON THE LCD

LCD_STRING
	PUSH {LR}					; STORE LINK ADDRESS
	
	LDR R5, =GPIOA_ODR 			; SETUP ADDRESS
LOOP
	LDRB R0, [R10]				; LOAD BYTE OF STRING INTO R10
	CMP	R0, #0					; CHECK FOR TERMINATOR
	BEQ	LOOP1					; END IF TERMINATOR
	BL	LCD_DATA				; SEND DATA TO LCD
	BL	DELAY_1ms				; 1ms DELAY
	ADD	R10, R10, #1			; NEXT BYTE OF STRING
	B	LOOP					; CONTINUE FOR STRING LENGTH
LOOP1
	POP {LR}					; RESTORE LINK ADDRESS
	BX	LR						; RETURN
	

;========================DELAY_1ms========================
; 1ms DELAY

DELAY_1ms
	MOV		R6, #50				; LOAD COUNTER 2
L1    
	MOV 	R7, #255			; LOAD COUNTER 1 
L2    
	SUBS 	R7,R7,#1        	; DECREMENT COUNTER 1
	BNE    	L2            		; LOOP UNTIL COUNTER 1 = 0
    SUBS 	R6,R6,#1    		; DECREMENT COUNTER 2
    BNE 	L1           		; LOOP UNTIL COUNTER 2 = 0
    BX    	LR            		; RETURN 


;========================DELAY_ms========================
; (n)ms DELAY

DELAY_ms
	PUSH	{LR}				; STORE LINK ADDRESS
	MOV		R8, R0				; LOAD # OF ms
JUMP
	BL		DELAY_1ms			; 1ms DELAY
	SUBS 	R8,R8,#1       		; DECREMENT COUNTER
	BNE    	JUMP           		; LOOP UNTIL COUNTER = 0
	POP		{LR}				; RESTORE LINK ADDRESS
	BX		LR					; RETURN
	
	
;========================STRINGS========================

	AREA	STRINGS, DATA, READONLY
FIRST
	DCB		"FIRST: ",0
SECOND
	DCB		"SECOND: ",0
ZERO
	DCB		"0000", 0
ONE
	DCB		"0001", 0
TWO
	DCB		"0010", 0
THREE
	DCB		"0011", 0
FOUR
	DCB		"0100", 0
FIVE
	DCB		"0101", 0	
SIX
	DCB		"0110", 0
SEVEN
	DCB		"0111", 0	
EIGHT
	DCB		"1000", 0
NINE
	DCB		"1001", 0
TEN
	DCB		"1010", 0
ELEVEN
	DCB		"1011", 0
TWELVE
	DCB		"1100", 0
THIRTEEN
	DCB		"1101", 0
FOURTEEN
	DCB		"1110", 0
FIFETEEN
	DCB		"1111", 0

	
	END