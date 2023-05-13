//constants
.equ UART_BASE, 0xff201000	//UART base address
.org    0x1000    			// Start at memory location 1000
.equ MaxSize, 10			//max size of array will be an array of 10 elements
.equ VALID, 0x8000 			//used to indicate if queue is empty for UART

.text  // Code Section
.global _start
_start:

			//FOR INPUT SUBROUTINE
//push parameters on the stack
MOV r1, #MaxSize
LDR r2, =array
//push
STMFD sp!, {r1, r2} //push onto stack. r2 will be pushed first, then r1

//call subroutine with branch and link
BL Input

//release the parameter memory from stack
ADD sp, sp, #8


			//FOR SORT AND PRINT SUBROUTINE
//push parameters onto the stack
MOV r1, r0 		//move actual size into register 1
LDR r2, =array 	//load beginnig address of array into register 2
//push
STMFD sp!, {r1, r2} //push onto stack. r2 will be pushed first, then r1

//call subroutine with branch and link
BL SortAndPrint

//release the parameter memory from stack
ADD sp, sp, #8


_stop:
b _stop

//-----------------------------------------------------------------------------------------------------
Input: //input subroutine
/*
-------------------------------------------------------
get array from UART as well as calculate the actual size of the array
-------------------------------------------------------
Parameters:
 r1 - MaxSize
 r2 - address of beginning of array
Returns:
 r0 - returns actual size of the array

Uses:
 r3 - holds value read from UART (only 1 byte)
 r4 - UARTbase
 r5 - variable for calculations
 r6 - divisor
 r7 - used to determine if the UART is empty
-------------------------------------------------------
*/

//epilogue
STMFD sp!, {fp, lr} //push onto stack
MOV fp, sp //save current stack top to frame pointer
STMFD sp!, {r1-r7} //r0 is returned

//get parameters
LDR r1, [fp, #8] //maxsize
LDR r2, [fp, #12] //beginning of array

MOV r0, #0 //initialize actual size of array
LDR r4, =UART_BASE //use to read a string from the UART
MOV r5, #0 //initialize variable to 0
MOV r6, #10 //set divisor to 10


getIntegers:
	//read character from UART
	LDR r7, [r4] //read single byte from UART

	AND r3, r7, #0xFF //this allows for us to store into r3 the first byte
	
	//check if UART is empty
	TST r7, #VALID
	BEQ done //end program if UART is empty
	

	//check if character is a digit
	CMP r3, #'0'
	BLT store //exit loop if non digit character was entered (this includes spaces)
	CMP r3, #'9'
	BGT store //exit loop if non digit character was entered (this includes spaces)
	
	//convert character to string
	SUB r3, r3, #'0'
	MUL r5, r5, r6
	ADD r5, r5, r3


	b getIntegers //keep looping until we run into a non-digit character


store:
	STR r5, [r2] //store integer into array
	ADD r2, r2, #4 //then increment r2 by 4 to move to next memory location
	MOV r5, #0 //initialize variable to 0 again
	ADD r0, r0, #1 //increment counter for actual size of array

	//check if actual array length has become equal to MaxSize
	CMP r0, r1
	BEQ done //end program is UART is empty
	
	//check if UART is empty
	TST r7, #VALID
	BEQ done //end program if UART is empty
	
	BNE getIntegers

done:
//stop getting integers when length of array becomes equal to MaxSize or when UART queue has been emptied
//store last variable if register 5 still has values to store
CMP r5, #0
BNE store

//prologue
_Input:
LDMFD sp!, {r1-r7} //pop stack
LDMFD sp!, {fp, pc} //pop frame pointer and program counter

//-----------------------------------------------------------------------------------------------------



SortAndPrint:
/*
-------------------------------------------------------
Bubble sort and print algorithm
-------------------------------------------------------
Parameters:
 r1 - actual array size
 r2 - array address

Uses:
 r3 - counter i
 r4 - counter j
 r5 - stores value from array
 r6 - stores value from array
 r7 - extra local variable that helps to access value from array

-------------------------------------------------------
*/
//epilogue
STMFD sp!, {fp, lr} //push onto stack
MOV fp, sp //save current stack top to frame pointer
STMFD sp!, {r1-r7}


//get parameters
LDR r1, [fp, #8] //actual array size
LDR r2, [fp, #12] //beginning of array

//BUBBLE SORT ALGORITHM
MOV r3, #0 //initialize counter

out_loop:
	CMP r3, r1 //compare counter with array size
	BGE bubble_sort_done //if counter is >= array length, end loop

	MOV r4, #1 //initialize 2nd counter variable

in_loop:
	CMP r4, r1 //compare second counter with array length
	BGE next_outer //if counter is >= array length, end loop
	
	ADD r7, r4, #-1
	
	LDR r5, [r2, r7, lsl #2] //load into r5 the array value at index counter
	LDR r6, [r2, r4, lsl #2] //load into r6 the array value at index counter + 1

	CMP r5, r6 //compare array[j] with array[j+1]
	BLE no_swapping //if array[j] <= array[j+1], we do not need to swap

	STR r6, [r2, r7, lsl #2] //store array[j+1] in array[j]
	STR r5, [r2, r4, lsl #2] //store array[j] in array[j+1]

no_swapping:
	ADD r4, r4, #1 //increment 2nd counter
	b in_loop //loop back to inner loop

next_outer:
	ADD r3, r3, #1 //increment 1st counter
	b out_loop //loop back to outer loop


bubble_sort_done:
	//call print subroutine
	BL Print //branch and link to subroutine

//prologue
_SortAndPrint:
LDMFD sp!, {r1-r7} //pop stack
LDMFD sp!, {fp, pc} //pop frame pointer and program counter



//-----------------------------------------------------------------------------------------------------
Print:
STMFD  sp!, {r1-r8, lr}

LDR r4, =array 		//array address
MOV r1, r0 			//move actual size into register 1
MOV r2, #0 			//index
LDR r5, =UART_BASE 	//use to copy character back to UART

print_loop:
//mov r8, #0 //initialize

CMP r2, r1 //compare index and array size
BGE _Print //if index >= size, exit

LDR r0, [r4, r2, lsl #2] //load value from array to r0
BL print_integer

//mov r0, #32 //ascii code for space character
//str r0, [r5] //write space to UART

ADD r2, #1 //increment index
b print_loop


_Print:
LDMFD  sp!, {r1-r8, pc}



//-----------------------------------------------------------------------------------------------------
print_integer: //for positive integers up to 3 digits
STMFD  sp!, {r1-r7, lr}
//r0 has integer from memory
LDR r6, =UART_BASE	//UART base address


loopTOconvert:
	MOV r3, #0 //initialize quotient1
	MOV r4, #0 //initialize quotient2

loop_once:
	CMP r0, #10 //compare the dividend to 10
	BLT d1 //branch to done1 if the dividend is less than 10
	SUB r0, r0, #10 //subtract 10 from the dividend
	ADD r3, r3, #1 //increment the quotient
	b loop_once

loop_twice:
	CMP r3, #10 //compare the dividend to 10
	BLT d2 //branch to done2 if the dividend is less than 10
	SUB r3, r3, #10 //subtract 10 from the dividend
	ADD r4, r4, #1 //increment the quotient
	b loop_twice


d1:
//see if r3 value is greater than 10
CMP r3, #10
BGT loop_twice
BLT d_first_int

d_first_int:
CMP r3, #0
MOVGT r7, r3
BGT writing

//see if value is still greater than 0
CMP r0, #0
MOVGT r7, r0 //so that first value gets printed
MOVGT r0, #0 //set r0 to 0
b writing


writing:
ADD r5, r7, #48 //add 48 which is the offset for ASCII '0'. add to remainder
STRB r5, [r6] //store the remainder in the UART


CMP r3, #0 //compare quotient to 0
BNE loopTOconvert //branch if the quotient is not 0 (more digits to process)
MOV r7, #32 //set r3 to ASCII code for space bar
STRB r7, [r6] //store the remainder in the UART
b _print_integer


d2:
MOV r7, r4 //so that the third digit gets printed
ADD r5, r7, #48
STRB r5, [r6]

MOV r7, r3
ADD r5, r7, #48
STRB r5, [r6]

MOV r7, r0
ADD r5, r7, #48
STRB r5, [r6]

MOV r7, #32 //set r3 to ASCII code for space bar
STRB r7, [r6] //store the remainder in the UART


_print_integer:
LDMFD  sp!, {r1-r7, pc}



//declare array and space required for size of array based on MaxSize
.data
array:
.space MaxSize * 4 //this creates a space of 40 bytes for me
endarray:

.end