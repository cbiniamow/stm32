;==================================================================
; CAMERON BINIAMOW
; 10/30/2020
; Lab 3-1
; Description: A single file tutorial for blue pill programming
;              that will toggle the on-board LED ~1 time per second
;
; Note: Be wary of indentiation. ARM Labels must be located
;       on the left margin, while instructions and directives
;       must be indented.
;==================================================================

;========================Port Locations============================
RCC_APB2ENR EQU 0x40021018 ;Clock enable register
GPIOC_CRL EQU 0x40011000 ;CRL = Control Register Low (Pins 0-7)
GPIOC_CRH EQU 0x40011004 ;CRH = Control Register High (Pins 8-15)
GPIOC_ODR EQU 0x4001100C ;ODR = Output Data Register

;These are for the linker
    EXPORT Reset_Handler
    EXPORT __Vectors

;=======================Vector Area=================================
; Area will define the name of area, type (code or data), and access
; (READONLY, READWRITE)
    AREA VECTORS, DATA, READONLY
    THUMB
; When the controller boots, it reads the location for the top of stack
; (our stack pointer) at 0x0000 0000 and begins code execution at the
; address contained in 0x0000 0004. Therefore, we must define constants
; (DCD) with these values.
__Vectors
    DCD 0x20000190 ;Points to top of stack
    DCD Reset_Handler ;Points to our reset location

;=======================Startup Area=================================
; Here we provide the restart behavior of the device written with the
; THUMB instruction set
    AREA STARTUP, CODE, READONLY
    THUMB
; The reset handler can be used for many things, but our main focus
; is to enter the main area of our code
Reset_Handler PROC
    ;---------------------------------------------
    ; ADDITIONAL RESET INITIALIZATION GOES HERE
    ;---------------------------------------------
    LDR R5, =__main
    BX R5 ;Branch to our main code
    ENDP

;=========================MAIN CODE================================
    AREA MAIN, CODE, READONLY
    THUMB
;Now that our setup is complete, lets get to the task at hand!
__main
    LDR R1,=RCC_APB2ENR ;Enable all of our GPIO clocks
    LDR R0,[R1]
    ORR R0,R0,#0xFC
    STR R0,[R1]
    LDR R1,=GPIOC_CRH ;Each pin has a nibble in the control register
    LDR R0,=0x44344444
    STR R0,[R1]
    LOOP
    LDR R1,=GPIOC_ODR
    LDR R0,[R1] ;Move contents of ODR to R0
    EOR R0,R0,#0x2000 ;Toggle value at position 13
    STR R0,[R1] ;Move contents of R0 to ODR
    BL DELAY
    B LOOP ;Infinite loop
    DELAY
    LDR R0,= 50
    L1 LDR R1,= 50000 ; Play with these values to change delay time
    L2 SUBS R1,R1,#1
    BNE L2 ; Branch until R1 is 0
    SUBS R0,R0,#1
    BNE L1 ; Branch until R0 is 0
    BX LR ; Branch and exchange instruction set (return)
    NOP ;To remove alignment warning. Disregard